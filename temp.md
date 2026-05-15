Update appsettings.json

You can mirror your XML targets and rules directly within an "NLog" configuration section. I have also corrected a few syntax typos from your XML layout (like $({event-properties...}) and ${(newline)}) to use standard NLog syntax ${event-properties...} and ${newline}.
JSON

{
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  },
  "AllowedHosts": "*",
  "NLog": {
    "autoReload": true,
    "throwConfigExceptions": true,
    "internalLogLevel": "Info",
    "internalLogFile": "C:\\Logs\\WebTemplateDemo\\dev\\internal-nlog.txt",
    "extensions": [
      { "assembly": "NLog.Web.AspNetCore" }
    ],
    "targets": {
      "allfile": {
        "type": "File",
        "fileName": "C:\\Logs\\WebTemplateDemo\\dev\\WebTemplateDemo\\nlog-all.log",
        "archiveFileName": "C:\\Logs\\WebTemplateDemo\\dev\\WebTemplateDemo\\Archive\\nlog-all-{0}.log",
        "maxArchiveFiles": 60,
        "archiveNumbering": "Date",
        "archiveEvery": "Day",
        "archiveDateFormat": "yyyy-MM-dd",
        "layout": "${longdate}|${event-properties:item=EventId_Id}|${uppercase:${level}}|${logger}|${message} ${exception:format=tostring}|url: ${aspnet-request-uri}|ip:${aspnet-request-ip:CheckForHostname=true}"
      },
      "ownFile-web": {
        "type": "File",
        "fileName": "C:\\Logs\\WebTemplateDemo\\dev\\WebTemplateDemo\\nlog-own.log",
        "archiveFileName": "C:\\Logs\\WebTemplateDemo\\dev\\WebTemplateDemo\\Archive\\nlog-own-{0}.log",
        "maxArchiveFiles": 60,
        "archiveNumbering": "Date",
        "archiveEvery": "Day",
        "archiveDateFormat": "yyyy-MM-dd",
        "layout": "${longdate}|${event-properties:item=EventId_Id}|Level=${uppercase:${level}}|Logger=${logger}|Message=${message}|Exception=${exception:format=tostring}|URL=${aspnet-request-uri}|IP=${aspnet-request-ip:CheckForHostname=true}"
      },
      "email": {
        "type": "Mail",
        "header": "At: ${date:format=yyyy-MM-dd HH\\:mm\\:ss}${newline}In: ${logger}${newline}",
        "layout": "${longdate}${newline}EventID=${event-properties:item=EventId_Id}${newline}Level=${uppercase:${level}}${newline}Logger=${logger}${newline}Message=${message}${newline}Exception=${exception:format=tostring}",
        "from": "barnoreply@dca.ca.gov",
        "to": "YOUR_RECIPIENT_EMAIL_HERE",
        "smtpServer": "YOUR_SMTP_SERVER_HERE"
      }
    },
    "rules": [
      {
        "logger": "*",
        "minLevel": "Trace",
        "writeTo": "allfile"
      },
      {
        "logger": "Microsoft.*",
        "maxLevel": "Info",
        "final": true
      },
      {
        "logger": "System.Net.Http.*",
        "maxLevel": "Info",
        "final": true
      },
      {
        "logger": "*",
        "minLevel": "Trace",
        "writeTo": "ownFile-web"
      },
      {
        "logger": "*",
        "minLevel": "Error",
        "writeTo": "email"
      }
    ]
  }
}

(Note: Be sure to populate the to and smtpServer properties in the email target, as the XML snippet cut off before showing them).
2. Update Program.cs

Since you have a try/catch block setup for early initialization to catch startup errors, you can no longer call NLogBuilder.ConfigureNLog("nlog.config").

Instead, you need to manually build the configuration builder to read from appsettings.json first, and then pass that configuration over to NLog.
C#

using NLog;
using NLog.Web;

namespace WebTemplateDemo
{
    /// <summary>
    /// Program class.
    /// </summary>
    public class Program
    {
        /// <summary>
        /// This is the main entry point for the program.
        /// </summary>
        /// <param name="args"></param>
        public static void Main(string[] args)
        {
            // Early init requires building the configuration manually to read from appsettings.json
            var config = new ConfigurationBuilder()
                .SetBasePath(Directory.GetCurrentDirectory())
                .AddJsonFile("appsettings.json", optional: false, reloadOnChange: true)
                .AddJsonFile($"appsettings.{Environment.GetEnvironmentVariable("ASPNETCORE_ENVIRONMENT") ?? "Production"}.json", optional: true)
                .Build();

            // Load NLog configuration from the "NLog" section in appsettings
            LogManager.Configuration = new NLog.Extensions.Logging.NLogLoggingConfiguration(config.GetSection("NLog"));
            var logger = LogManager.GetCurrentClassLogger();

            try
            {
                logger.Debug("init main");
                CreateHostBuilder(args).Build().Run();
            }
            catch (Exception ex)
            {
                // NLog: catch setup errors
                logger.Error(ex, "Stopped program because of exception");
                throw;
            }
            finally
            {
                // Ensure to flush and stop internal timers/threads before application-exit
                NLog.LogManager.Shutdown();
            }
        }

        /// <summary>
        /// Initializes a new instance of the HostBuilder class with pre-configured defaults,
        /// </summary>
        /// <param name="args"></param>
        /// <returns></returns>
        public static IHostBuilder CreateHostBuilder(string[] args) =>
            Host.CreateDefaultBuilder(args)
                .ConfigureWebHostDefaults(webBuilder =>
                {
                    webBuilder.UseStartup<Startup>();
                })
                .UseNLog(); // NLog: Setup NLog for Dependency injection
    }
}

Startup.cs

You do not need to make any logging-specific changes to your Startup.cs. NLog will automatically wire up dependency injection for ILogger<T> through the .UseNLog() call added to the HostBuilder. You can safely delete your nlog.config file.




##############################



Option 1: Block using IWebHostEnvironment (Development Only)

You can check the environment directly in the HTTP pipeline. Add this middleware to your Configure method in Startup.cs.

Important: Place this before app.UseStaticFiles() and app.UseRouting() so the request is blocked immediately.
C#

public void Configure(IApplicationBuilder app, IWebHostEnvironment env)
{
    // 1. Custom Middleware to block the template route
    app.Use(async (context, next) =>
    {
        // Check if the requested URL starts with /template
        if (context.Request.Path.StartsWithSegments("/template", StringComparison.OrdinalIgnoreCase))
        {
            // If we are NOT in the Development environment, block it
            if (!env.IsDevelopment())
            {
                // Return a 404 Not Found (better than 403 Forbidden to hide the existence of the route)
                context.Response.StatusCode = 404; 
                return; // Short-circuit the pipeline and stop processing
            }
        }
        
        // Otherwise, continue down the pipeline as normal
        await next.Invoke();
    });

    if (env.IsDevelopment())
    {
        app.UseDeveloperExceptionPage();
    }
    else
    {
        app.UseExceptionHandler("/Error");
        app.UseHsts();
    }

    app.UseSensitiveRedirection(); // (Assuming this is a custom extension method you have)
    app.UseStatusCodePagesWithReExecute("/Error", "?code={0}");
    app.UseStaticFiles();
    
    app.UseRouting();
    
    app.UseEndpoints(endpoints =>
    {
        endpoints.MapRazorPages();
    });
}

Option 2: Block using a Configuration Flag (More flexible)

If you want the ability to temporarily turn these templates on in Production without changing code (e.g., for debugging), you can bind the block to an environment variable or a setting in your appsettings.json.

1. Add the flag to your appsettings.json:
JSON

{
  "Logging": { ... },
  "AllowedHosts": "*",
  "FeatureToggles": {
    "EnableTemplatesArea": false
  }
}

2. Update your Configure method to check the configuration:
C#

public void Configure(IApplicationBuilder app, IWebHostEnvironment env)
{
    // Grab the setting from appsettings.json or Environment Variables
    // It defaults to false if it can't find the setting
    bool enableTemplates = Configuration.GetValue<bool>("FeatureToggles:EnableTemplatesArea", false);

    app.Use(async (context, next) =>
    {
        if (context.Request.Path.StartsWithSegments("/template", StringComparison.OrdinalIgnoreCase))
        {
            // If the toggle is false, block the route
            if (!enableTemplates)
            {
                context.Response.StatusCode = 404;
                return; 
            }
        }
        
        await next.Invoke();
    });

    // ... rest of your pipeline (UseStaticFiles, UseRouting, etc.)
}

Why Middleware over Razor Page Conventions?

You could write a Razor Page IPageFilter or use AuthorizeAreaFolder in ConfigureServices, but the middleware approach has a distinct advantage: it blocks everything under that URL path. If your RCL also serves static assets specific to the template area, or if someone tries to hit an API endpoint under /template, the middleware catches and blocks all of it instantly.



######################


Create a Custom IFileProvider

This class will act as a middleman. When the Razor engine looks for a view (e.g., /Pages/MyArticle.cshtml), this provider will check if a .md file exists instead.
C#

using Microsoft.Extensions.FileProviders;
using Microsoft.Extensions.Primitives;

namespace WebTemplateDemo.Providers
{
    public class MarkdownViewFileProvider : IFileProvider
    {
        private readonly PhysicalFileProvider _physicalFileProvider;

        public MarkdownViewFileProvider(string rootPath)
        {
            // Point this to your content root so it can find your physical files
            _physicalFileProvider = new PhysicalFileProvider(rootPath);
        }

        public IFileInfo GetFileInfo(string subpath)
        {
            // Intercept requests for Razor Views
            if (subpath.EndsWith(".cshtml", StringComparison.OrdinalIgnoreCase))
            {
                // Swap the extension to check for a Markdown file
                var mdPath = subpath.Substring(0, subpath.Length - 7) + ".md";
                var mdFileInfo = _physicalFileProvider.GetFileInfo(mdPath);

                if (mdFileInfo.Exists)
                {
                    // Return our custom FileInfo wrapper that processes Markdig on the fly
                    return new MarkdownFileInfo(mdFileInfo);
                }
            }

            // If it's a normal .cshtml file, let the system handle it normally
            return _physicalFileProvider.GetFileInfo(subpath);
        }

        public IDirectoryContents GetDirectoryContents(string subpath) => _physicalFileProvider.GetDirectoryContents(subpath);
        public IChangeToken Watch(string filter) => _physicalFileProvider.Watch(filter);
    }
}

2. Create the Custom IFileInfo

This class is where the actual transformation happens. It reads your physical .md file, runs your TwoColumnsSideNavArticleTemplateModel logic, and returns a memory stream of the processed HTML injected with Razor directives.
C#

using Microsoft.Extensions.FileProviders;
using System.Text;

namespace WebTemplateDemo.Providers
{
    public class MarkdownFileInfo : IFileInfo
    {
        private readonly IFileInfo _mdFileInfo;
        private byte[]? _viewContent;

        public MarkdownFileInfo(IFileInfo mdFileInfo)
        {
            _mdFileInfo = mdFileInfo;
        }

        public bool Exists => true;
        public long Length => EnsureProcessed().Length;
        public string? PhysicalPath => null; // Must be null so Razor treats it as a virtual file
        public string Name => Path.GetFileNameWithoutExtension(_mdFileInfo.Name) + ".cshtml";
        public DateTimeOffset LastModified => _mdFileInfo.LastModified;
        public bool IsDirectory => false;

        public Stream CreateReadStream()
        {
            return new MemoryStream(EnsureProcessed());
        }

        private byte[] EnsureProcessed()
        {
            if (_viewContent == null)
            {
                // 1. Read the physical Markdown file
                using var stream = _mdFileInfo.CreateReadStream();
                using var reader = new StreamReader(stream);
                var markdownContent = reader.ReadToEnd();

                // 2. Run your existing Markdig parsing logic here
                // Note: You will need to extract your metadata and lines to feed your model
                var markdownLines = markdownContent.Split(["\r\n", "\r", "\n"], StringSplitOptions.None);
                
                var model = new TwoColumnsSideNavArticleTemplateModel(
                    new Dictionary<string, string>(), // Pass actual metadata here
                    markdownLines, 
                    contentStartIndex: 0 // Pass actual start index here
                );
                
                // Assuming this populates model.MainContent and model.SideNavContent
                model.UpdatesectionsToHtml(); 

                // 3. Construct the final Razor string. 
                // CRITICAL: You must include @addTagHelper so Razor knows to parse them!
                var stringBuilder = new StringBuilder();
                stringBuilder.AppendLine("@page"); // Required if treating as a routable page
                stringBuilder.AppendLine("@addTagHelper *, Microsoft.AspNetCore.Mvc.TagHelpers");
                stringBuilder.AppendLine("@addTagHelper *, WebTemplateDemo"); // Add your custom assembly here
                
                // You can inject standard Razor layout code here if needed
                stringBuilder.AppendLine("<div class=\"row\">");
                stringBuilder.AppendLine($"  <div class=\"col-3\">{model.SideNavContent}</div>");
                stringBuilder.AppendLine($"  <div class=\"col-9\">{model.MainContent}</div>");
                stringBuilder.AppendLine("</div>");

                _viewContent = Encoding.UTF8.GetBytes(stringBuilder.ToString());
            }

            return _viewContent;
        }
    }
}

3. Register the Provider in Startup.cs

Now, you need to tell the Razor compiler to use your new MarkdownViewFileProvider. Modify your existing ConfigureServices method:
C#

public void ConfigureServices(IServiceCollection services)
{
    // Configure runtime compilation to use our custom markdown interceptor
    services.AddRazorPages()
            .AddRazorRuntimeCompilation(options =>
            {
                options.FileProviders.Add(new Providers.MarkdownViewFileProvider(env.ContentRootPath));
            });

    // ... your data protection setup ...
}

(Note: Ensure you inject IWebHostEnvironment env into ConfigureServices, or just use the CurrentEnvironment property you already set up in your Startup constructor).