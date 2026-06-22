C#

using Microsoft.AspNetCore.Mvc.ApplicationModels;

namespace WebTemplateDemo.Providers
{
    public class MarkdownPageRouteModelProvider : IPageRouteModelProvider
    {
        private readonly IWebHostEnvironment _env;

        public MarkdownPageRouteModelProvider(IWebHostEnvironment env)
        {
            _env = env;
        }

        // Run after the default Razor Pages providers
        public int Order => 1000; 

        public void OnProvidersExecuting(PageRouteModelProviderContext context)
        {
            var pagesDir = Path.Combine(_env.ContentRootPath, "Pages");
            if (!Directory.Exists(pagesDir)) return;

            // Find all .md files in the Pages directory
            var markdownFiles = Directory.GetFiles(pagesDir, "*.md", SearchOption.AllDirectories);

            foreach (var file in markdownFiles)
            {
                // Convert physical path to a relative route (e.g. "newsroom/page1")
                var relativePath = Path.GetRelativePath(pagesDir, file);
                var routeTemplate = relativePath.Replace("\\", "/").Replace(".md", "");
                
                // Define the virtual Razor view path (e.g. "/Pages/newsroom/page1.cshtml")
                var viewPath = $"/Pages/{routeTemplate}.cshtml";

                // Create the route model
                var routeModel = new PageRouteModel(viewPath, viewPath);
                routeModel.Selectors.Add(new SelectorModel
                {
                    AttributeRouteModel = new AttributeRouteModel
                    {
                        Template = routeTemplate
                    }
                });

                // Inject it into the route table
                context.RouteModels.Add(routeModel);
            }
        }

        public void OnProvidersExecuted(PageRouteModelProviderContext context)
        {
        }
    }
}

2. Put @page back in your String Builder

Because we are passing this back to the native Razor Pages engine instead of an MVC Controller, the generated file must be recognized as a Razor Page.

In your MarkdownFileInfo.cs, make sure the @page directive is at the very top:
C#

var sb = new StringBuilder();

sb.AppendLine("@page"); // <-- Required for Razor Pages
sb.AppendLine("@addTagHelper *, Microsoft.AspNetCore.Mvc.TagHelpers");
sb.AppendLine("@addTagHelper *, WebTemplateDemo");

sb.AppendLine("@{");
sb.AppendLine($"    Layout = \"_TwoColumnArticleLayout\";"); 
// ... rest of your ViewData code

3. Register the Provider in Program.cs

Now, tell ASP.NET Core to use both your Route Injector and your File Provider.

In Program.cs (or Startup.cs), update your service registrations to look like this:
C#

// 1. Register the Route Injector
builder.Services.AddSingleton<Microsoft.AspNetCore.Mvc.ApplicationModels.IPageRouteModelProvider, WebTemplateDemo.Providers.MarkdownPageRouteModelProvider>();

// 2. Register Razor Pages and the virtual file provider
builder.Services.AddRazorPages()
    .AddRazorRuntimeCompilation(options =>
    {
        options.FileProviders.Insert(0, new WebTemplateDemo.Providers.MarkdownViewFileProvider(builder.Environment.ContentRootPath));
    });