The Models
Create the property classes for the tabs. The item needs an Id to link the anchor to the section.
C#
using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Razor.TagHelpers;

namespace WTS.RazorComponentLibrary.Models.RclComponents
{
    public class TabProperties
    {
        [HtmlAttributeNotBound]
        public string Content { get; set; } = string.Empty;
    }

    public class TabItemProperties
    {
        [Required(ErrorMessage = "A heading is required for the tab navigation.")]
        public string Heading { get; set; } = string.Empty;

        [Required(ErrorMessage = "An Id is required to link the tab to its content.")]
        public string Id { get; set; } = string.Empty;

        [HtmlAttributeNotBound]
        public string Content { get; set; } = string.Empty;
    }
}
2. The Renderers
This is where the magic happens. The RclTabRenderer intercepts the child content, extracts the metadata to build the <ul>, and formats the final output.
C#
using System.Text;
using System.Text.RegularExpressions;
using WTS.RazorComponentLibrary.Models.RclComponents;

namespace WTS.RazorComponentLibrary.Renderers
{
    public static class RclTabRenderer
    {
        public static string Render(TabProperties p)
        {
            var ulBuilder = new StringBuilder();
            ulBuilder.AppendLine("  <ul>");

            string content = p.Content ?? string.Empty;

            // Extract the id and heading from the rendered child sections
            var matches = Regex.Matches(content, @"<section\s+id=""([^""]+)""\s+data-tab-heading=""([^""]+)"">");

            foreach (Match match in matches)
            {
                string id = match.Groups[1].Value;
                string heading = match.Groups[2].Value;
                
                ulBuilder.AppendLine($@"    <li>
      <a href=""#{id}"">{heading}</a>
    </li>");
            }
            ulBuilder.AppendLine("  </ul>");

            // Clean up the temporary data-tab-heading attribute for the final HTML
            string cleanContent = Regex.Replace(content, @"\s+data-tab-heading=""[^""]+""", "");

            return $@"<div class=""tabs"">
{ulBuilder.ToString()}
{cleanContent}
</div>";
        }
    }

    public static class RclTabItemRenderer
    {
        public static string Render(TabItemProperties p)
        {
            // Inject data-tab-heading so the parent renderer can find it and build the navigation
            return $@"  <section id=""{p.Id}"" data-tab-heading=""{p.Heading}"">
    {p.Content}
  </section>";
        }
    }
}
3. The Tag Helpers
Wire up the standard Tag Helpers for your Razor pages.
C#
using Microsoft.AspNetCore.Components;
using Microsoft.AspNetCore.Razor.TagHelpers;
using System.Threading.Tasks;
using System.ComponentModel.DataAnnotations;
using WTS.RazorComponentLibrary.Models.RclComponents;
using WTS.RazorComponentLibrary.Renderers;

namespace WTS.RazorLibrary.TagHelpers
{
    [HtmlTargetElement("rcl-tab")]
    public class TabHelper : TabProperties, ITagHelper
    {
        public int Order => 0;
        public void Init(TagHelperContext context) { }

        public async Task ProcessAsync(TagHelperContext context, TagHelperOutput output)
        {
            var childContent = await output.GetChildContentAsync();
            this.Content = childContent.GetContent();

            output.TagName = null;

            var htmlResult = RclTabRenderer.Render(this);
            output.Content.SetHtmlContent(htmlResult);
        }
    }

    [HtmlTargetElement("rcl-tab-item", ParentTag = "rcl-tab")]
    public class TabItemHelper : TabItemProperties, ITagHelper
    {
        public int Order => 0;
        public void Init(TagHelperContext context) { }

        public async Task ProcessAsync(TagHelperContext context, TagHelperOutput output)
        {
            var childContent = await output.GetChildContentAsync();
            this.Content = childContent.GetContent();

            var validationContext = new ValidationContext(this);
            Validator.ValidateObject(this, validationContext, validateAllProperties: true);

            output.TagName = null;

            var htmlResult = RclTabItemRenderer.Render(this);
            output.Content.SetHtmlContent(htmlResult);
        }
    }
}
4. Markdown Registration
Finally, add the new components to your RclComponentRenderer dictionary so the Markdig custom containers (using :::) are processed correctly.  
CS
C#
// Inside WTS.MarkdownLibrary.Classes.RclComponentRenderer
_handlers = new Dictionary<string, Func<Dictionary<string, string>, string, string>>(StringComparer.OrdinalIgnoreCase)
{
    { "rcl-accordion", (metadata, content) => RclAccordionRenderer.Render(ComponentMapper.Map<AccordionProperties>(metadata, content))},
    { "rcl-accordion-item", (metadata, content) => RclAccordionItemRenderer.Render(ComponentMapper.Map<AccordionItemProperties>(metadata, content))},
    
    // Add Tabs
    { "rcl-tab", (metadata, content) => RclTabRenderer.Render(ComponentMapper.Map<TabProperties>(metadata, content))},
    { "rcl-tab-item", (metadata, content) => RclTabItemRenderer.Render(ComponentMapper.Map<TabItemProperties>(metadata, content))}
};




#######




The PageModel (AssetLibrary.cshtml.cs)
This code injects IWebHostEnvironment, verifies the web root and assets path exist, and grabs all image files. Adjust the namespace and [Area] attribute to match your project's structure.
C#
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.AspNetCore.Hosting;
using System.IO;
using System.Collections.Generic;
using System.Linq;

namespace WTS.RazorLibrary.Areas.StyleGuide.Pages
{
    [Area("StyleGuide")] // Replace with your actual Area name
    public class AssetLibraryModel : PageModel
    {
        private readonly IWebHostEnvironment _env;

        public AssetLibraryModel(IWebHostEnvironment env)
        {
            _env = env;
        }

        public List<AssetItem> Images { get; set; } = new();

        public void OnGet()
        {
            // Fallback in case WebRootPath is not configured in the host
            if (string.IsNullOrWhiteSpace(_env.WebRootPath))
            {
                return;
            }

            string assetsPath = Path.Combine(_env.WebRootPath, "assets");
            
            if (!Directory.Exists(assetsPath))
            {
                return;
            }

            var allowedExtensions = new[] { ".png", ".jpg", ".jpeg", ".gif", ".svg", ".webp" };

            // Fetch physical files and filter by image extensions
            var files = Directory.GetFiles(assetsPath)
                .Where(file => allowedExtensions.Contains(Path.GetExtension(file).ToLowerInvariant()));

            foreach (var file in files)
            {
                Images.Add(new AssetItem 
                {
                    FileName = Path.GetFileName(file),
                    // Create the relative URL for the browser
                    Url = $"/assets/{Path.GetFileName(file)}"
                });
            }
        }
    }

    public class AssetItem
    {
        public string FileName { get; set; } = string.Empty;
        public string Url { get; set; } = string.Empty;
    }
}
2. The Razor View (AssetLibrary.cshtml)
This creates a responsive CSS grid to showcase the images alongside their filenames, making it easy to browse the available assets.
HTML
@page
@model WTS.RazorLibrary.Areas.StyleGuide.Pages.AssetLibraryModel
@{
    ViewData["Title"] = "Asset Library";
}

<h2 class="m-t-0">Asset Library</h2>
<p>Showcasing all available images from the main web application's <strong>wwwroot/assets</strong> directory.</p>

<hr />

<div style="display: grid; grid-template-columns: repeat(auto-fill, minmax(200px, 1fr)); gap: 20px;">
    @if (Model.Images.Any())
    {
        foreach (var image in Model.Images)
        {
            <div style="border: 1px solid #ddd; padding: 10px; text-align: center; border-radius: 4px; background: #fafafa;">
                <img src="@image.Url" alt="@image.FileName" style="max-width: 100%; height: auto; max-height: 120px; object-fit: contain;" />
                <div style="margin-top: 10px; font-size: 0.85em; word-break: break-all; color: #333;">
                    <strong>@image.FileName</strong>
                </div>
            </div>
        }
    }
    else
    {
        <div style="grid-column: 1 / -1; padding: 20px; background-color: #fff3cd; border: 1px solid #ffeeba; color: #856404;">
            No assets found in the <code>/assets</code> folder, or the directory does not exist in the host application.
        </div>
    }
</div>



########


. The PageModel (AssetLibrary.cshtml.cs)
We'll add a structured list of your color variables grouped by category (Highlight, Primary, Standout, etc.) so they render in organized rows.
C#
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.AspNetCore.Hosting;
using System.IO;
using System.Collections.Generic;
using System.Linq;

namespace WTS.RazorLibrary.Areas.StyleGuide.Pages
{
    [Area("StyleGuide")]
    public class AssetLibraryModel : PageModel
    {
        private readonly IWebHostEnvironment _env;

        public AssetLibraryModel(IWebHostEnvironment env)
        {
            _env = env;
        }

        public List<AssetItem> Images { get; set; } = new();
        public List<ColorGroup> ThemeColors { get; set; } = new();

        public void OnGet()
        {
            LoadImages();
            LoadColors();
        }

        private void LoadImages()
        {
            if (string.IsNullOrWhiteSpace(_env.WebRootPath)) return;

            string assetsPath = Path.Combine(_env.WebRootPath, "assets");
            if (!Directory.Exists(assetsPath)) return;

            var allowedExtensions = new[] { ".png", ".jpg", ".jpeg", ".gif", ".svg", ".webp" };
            var files = Directory.GetFiles(assetsPath)
                .Where(file => allowedExtensions.Contains(Path.GetExtension(file).ToLowerInvariant()));

            foreach (var file in files)
            {
                Images.Add(new AssetItem 
                {
                    FileName = Path.GetFileName(file),
                    Url = $"/assets/{Path.GetFileName(file)}"
                });
            }
        }

        private void LoadColors()
        {
            ThemeColors = new List<ColorGroup>
            {
                new ColorGroup { GroupName = "Highlight (P1)", Variables = new List<string> { "--color-p1-lightest", "--color-p1-lighter", "--color-p1-light", "--color-p1", "--color-p1-dark", "--color-p1-darker", "--color-p1-darkest" } },
                new ColorGroup { GroupName = "Primary (P2)", Variables = new List<string> { "--color-p2-lightest", "--color-p2-lighter", "--color-p2-light", "--color-p2", "--color-p2-dark", "--color-p2-darker", "--color-p2-darkest" } },
                new ColorGroup { GroupName = "Standout (P3)", Variables = new List<string> { "--color-p3-lightest", "--color-p3-lighter", "--color-p3-light", "--color-p3", "--color-p3-dark", "--color-p3-darker", "--color-p3-darkest" } },
                new ColorGroup { GroupName = "Secondary 1", Variables = new List<string> { "--color-s1-lighter", "--color-s1", "--color-s1-darker" } },
                new ColorGroup { GroupName = "Secondary 2", Variables = new List<string> { "--color-s2", "--color-s2-dark", "--color-s2-darker" } },
                new ColorGroup { GroupName = "Secondary 3", Variables = new List<string> { "--color-s3-lighter", "--color-s3-light", "--color-s3", "--color-s3-dark" } },
                new ColorGroup { GroupName = "Component Backgrounds", Variables = new List<string> { "--sub-nav-bg", "--mobile-drawer", "--mobile-drawer-active" } }
            };
        }
    }

    public class AssetItem
    {
        public string FileName { get; set; } = string.Empty;
        public string Url { get; set; } = string.Empty;
    }

    public class ColorGroup
    {
        public string GroupName { get; set; } = string.Empty;
        public List<string> Variables { get; set; } = new();
    }
}
2. The Razor View (AssetLibrary.cshtml)
This view is split into two sections: the new color palette swatches at the top, and the image gallery at the bottom. The color swatches use standard flexbox layout and call upon the CSS variables directly via var().
HTML
@page
@model WTS.RazorLibrary.Areas.StyleGuide.Pages.AssetLibraryModel
@{
    ViewData["Title"] = "Asset & Color Library";
}

<h2 class="m-t-0">Color Palette</h2>
<p>Showcasing the active CSS color variables for the theme.</p>
<hr />

<div class="color-palette-container">
    @foreach (var group in Model.ThemeColors)
    {
        <h4 style="margin-top: 1.5rem; margin-bottom: 0.5rem; color: var(--color-p2);">@group.GroupName</h4>
        <div style="display: flex; flex-wrap: wrap; gap: 15px; margin-bottom: 1.5rem;">
            @foreach (var colorVar in group.Variables)
            {
                <div style="display: flex; flex-direction: column; align-items: center; width: 110px;">
                    <!-- The color swatch square -->
                    <div style="width: 80px; height: 80px; border-radius: 8px; border: 1px solid rgba(0,0,0,0.1); background-color: var(@colorVar); box-shadow: 0 2px 4px rgba(0,0,0,0.05);"></div>
                    
                    <!-- The variable name -->
                    <code style="margin-top: 8px; font-size: 0.75em; text-align: center; word-break: break-all; background: transparent; padding: 0;">
                        @colorVar
                    </code>
                </div>
            }
        </div>
    }
</div>

<h2 style="margin-top: 3rem;">Image Assets</h2>
<p>Showcasing all available images from the main web application's <strong>wwwroot/assets</strong> directory.</p>
<hr />

<div style="display: grid; grid-template-columns: repeat(auto-fill, minmax(200px, 1fr)); gap: 20px;">
    @if (Model.Images.Any())
    {
        foreach (var image in Model.Images)
        {
            <div style="border: 1px solid #ddd; padding: 10px; text-align: center; border-radius: 4px; background: #fafafa;">
                <img src="@image.Url" alt="@image.FileName" style="max-width: 100%; height: auto; max-height: 120px; object-fit: contain;" />
                <div style="margin-top: 10px; font-size: 0.85em; word-break: break-all; color: #333;">
                    <strong>@image.FileName</strong>
                </div>
            </div>
        }
    }
    else
    {
        <div style="grid-column: 1 / -1; padding: 20px; background-color: #fff3cd; border: 1px solid #ffeeba; color: #856404;">
            No assets found in the <code>/assets</code> folder, or the directory does not exist in the host application.
        </div>
    }
</div>




###########


1. Update the Markdown YAML Frontmatter
Add the new metadata fields to your .md files.
YAML
---
Template: SingleColumn
Title: My Custom Styled Page
ColorScheme: theme-dark  
FontFamily: "'Roboto', sans-serif"
---
# Page Content
This page will use the dark theme and Roboto font.
2. Update TemplateBaseModel
Since your SingleColumnTemplateModel calls this.LoadMetada(metadata), you need to add the new properties to your TemplateBaseModel and update the load method to map the new keys.  
CS
C#
namespace WTS.MarkdownLibrary.Models.TemplateModelsV6
{
    public abstract class TemplateBaseModel
    {
        public string Title { get; set; } = string.Empty;
        public string MainContent { get; set; } = string.Empty;
        
        // New styling properties
        public string ColorScheme { get; set; } = string.Empty;
        public string FontFamily { get; set; } = string.Empty;

        public virtual void LoadMetada(Dictionary<string, string> metadata)
        {
            if (metadata.TryGetValue("Title", out string title))
            {
                Title = title;
            }
            
            // Map the new styling metadata
            if (metadata.TryGetValue("ColorScheme", out string colorScheme))
            {
                ColorScheme = colorScheme;
            }
            
            if (metadata.TryGetValue("FontFamily", out string font))
            {
                FontFamily = font;
            }
        }
    }
}
3. Pass Data from the Page View to the Layout
In the .cshtml page that renders your Markdown model (e.g., your catch-all Markdown route), map the model's properties into ViewData. The _Layout.cshtml file executes after the view, so it will be able to read these values.
HTML
@page
@model WTS.MarkdownLibrary.Models.TemplateModelsV6.SingleColumnTemplateModel
@{
    // Pass the extracted metadata to the layout
    ViewData["Title"] = Model.Title;
    ViewData["ColorScheme"] = Model.ColorScheme;
    ViewData["FontFamily"] = Model.FontFamily;
}

@Html.Raw(Model.MainContent)
4. Override Styles in _Layout.cshtml
Finally, update your _Layout.cshtml to check for these ViewData keys. You can apply the color scheme as a CSS class on the <body> tag (which is a common way to trigger CSS variable overrides) and apply the font family directly as an inline style or via an injected <style> block.
HTML
@{
    // Extract the overrides, providing fallbacks if the Markdown didn't specify them
    var themeClass = ViewData["ColorScheme"]?.ToString() ?? "theme-default";
    var customFont = ViewData["FontFamily"]?.ToString();
}

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8" />
    <title>@ViewData["Title"]</title>
    <!-- Your standard stylesheets -->
    
    @if (!string.IsNullOrEmpty(customFont))
    {
        <!-- Override font if specified in Markdown -->
        <style>
            body {
                font-family: @Html.Raw(customFont) !important;
            }
        </style>
    }
</head>
<body class="@themeClass">
    
    <!-- Render Body -->
    @RenderBody()

</body>
</html>



########


. Create a Validation Result Model
First, create an object to store the results of the tests so you can easily display them on the frontend.
C#
using System.Collections.Generic;

namespace WTS.MarkdownLibrary.Models
{
    public class MarkdownValidationResult
    {
        public bool IsValid => Errors.Count == 0;
        public List<string> PassedChecks { get; set; } = new();
        public List<string> Errors { get; set; } = new();
    }
}
2. Build the Shared Validator
Extract the logic from your existing unit tests into a standalone class. We can even utilize your existing HelperClass methods.  
CS
C#
using System;
using WTS.MarkdownLibrary.Classes;
using WTS.MarkdownLibrary.Models;

namespace WTS.MarkdownLibrary.Services
{
    public class MarkdownValidator
    {
        public MarkdownValidationResult Validate(string markdownContent)
        {
            var result = new MarkdownValidationResult();

            // Test 1: Check YAML Frontmatter
            try
            {
                var metadata = HelperClass.ExtractYamlMetadata(markdownContent, out int _);
                if (metadata.Count > 0)
                {
                    result.PassedChecks.Add("YAML Frontmatter is formatted correctly.");
                    
                    // Test 2: Required Metadata Fields
                    if (metadata.ContainsKey("Template") && metadata.ContainsKey("Title"))
                    {
                        result.PassedChecks.Add("Required metadata fields (Template, Title) are present.");
                    }
                    else
                    {
                        result.Errors.Add("Missing required metadata fields. Must include 'Template' and 'Title'.");
                    }
                }
                else
                {
                    result.Errors.Add("No YAML Frontmatter found or it is malformed.");
                }
            }
            catch (Exception ex)
            {
                result.Errors.Add($"YAML Parsing Error: {ex.Message}");
            }

            // Test 3: Check Heading Nesting
            try
            {
                HelperClass.CheckHeadingNesting(markdownContent);
                result.PassedChecks.Add("Heading nesting is structurally sound.");
            }
            catch (Exception ex) // Your HelperClass throws an exception if nesting fails
            {
                result.Errors.Add($"Heading Structure Error: {ex.Message}");
            }

            // Add more tests here as needed...

            return result;
        }
    }
}
3. Update Your Unit Tests
Instead of writing inline assertions, have your test project call the new validator. This guarantees your tests and your web app are always in sync.
C#
[Fact]
public void Markdown_WithValidHeaders_PassesValidation()
{
    // Arrange
    var validator = new MarkdownValidator();
    string validMarkdown = "---\nTitle: Test\nTemplate: SingleColumn\n---\n# H1\n## H2";

    // Act
    var result = validator.Validate(validMarkdown);

    // Assert
    Assert.True(result.IsValid);
    Assert.Empty(result.Errors);
}
4. Implement in the Razor Page
Now, inject or instantiate the validator in your /trymarkdown PageModel and run it against the user's uploaded file.
C#
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using System.IO;
using System.Threading.Tasks;
using WTS.MarkdownLibrary.Services;
using WTS.MarkdownLibrary.Models;

namespace WTS.WebApp.Pages
{
    public class TryMarkdownModel : PageModel
    {
        [BindProperty]
        public IFormFile? UploadedFile { get; set; }

        public MarkdownValidationResult? ValidationResult { get; set; }
        public string? RenderedHtml { get; set; }

        public void OnGet() { }

        public async Task<IActionResult> OnPostAsync()
        {
            if (UploadedFile == null || UploadedFile.Length == 0)
            {
                ModelState.AddModelError("UploadedFile", "Please upload a valid Markdown file.");
                return Page();
            }

            using var reader = new StreamReader(UploadedFile.OpenReadStream());
            string content = await reader.ReadToEndAsync();

            // Run the same tests your unit test project uses
            var validator = new MarkdownValidator();
            ValidationResult = validator.Validate(content);

            // If it passes, optionally render it to show the user
            if (ValidationResult.IsValid)
            {
                // Render logic here...
            }

            return Page();
        }
    }
}
5. Display the Results in the View
Present the output to the user immediately upon upload.
HTML
@page
@model WTS.WebApp.Pages.TryMarkdownModel
@{
    ViewData["Title"] = "Try Markdown";
}

<h2>Upload Markdown for Testing</h2>

<form method="post" enctype="multipart/form-data">
    <input type="file" asp-for="UploadedFile" accept=".md" />
    <button type="submit">Upload and Test</button>
</form>

@if (Model.ValidationResult != null)
{
    <div style="margin-top: 20px; padding: 15px; border: 1px solid @(Model.ValidationResult.IsValid ? "green" : "red");">
        <h3>Test Results: @(Model.ValidationResult.IsValid ? "Passed" : "Failed")</h3>
        
        @if (Model.ValidationResult.PassedChecks.Any())
        {
            <ul style="color: green;">
                @foreach (var pass in Model.ValidationResult.PassedChecks)
                {
                    <li>✅ @pass</li>
                }
            </ul>
        }

        @if (Model.ValidationResult.Errors.Any())
        {
            <ul style="color: red;">
                @foreach (var error in Model.ValidationResult.Errors)
                {
                    <li>❌ @error</li>
                }
            </ul>
        }
    </div>
}



##########


Policy-Based Authorization (Best for specific individuals)
If you have a hardcoded list of specific usernames, you can define an authorization policy in your application's startup configuration and apply it directly to the PageModel.
Step 1: Define the Policy in Program.cs
C#
builder.Services.AddAuthorization(options =>
{
    options.AddPolicy("SpecificUsersOnly", policy =>
    {
        // Require specific Windows usernames (Domain\Username)
        policy.RequireUserName(@"DOMAIN\User1", @"DOMAIN\User2");
    });
});
Step 2: Apply to the PageModel
Attach the [Authorize] attribute to your page's backend class. If an unauthorized user tries to access it, they will automatically receive an Access Denied (403) response.
C#
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc.RazorPages;

namespace WTS.WebApp.Pages
{
    [Authorize(Policy = "SpecificUsersOnly")]
    public class RestrictedModel : PageModel
    {
        public void OnGet()
        {
            // Only DOMAIN\User1 and DOMAIN\User2 can reach this point
        }
    }
}
2. Role-Based Authorization (Best for Active Directory Groups)
In enterprise environments, it is usually better to restrict access based on Active Directory Security Groups rather than individual users. Windows Authentication automatically maps AD Groups to standard ASP.NET Core "Roles".
You don't need a policy in Program.cs for this; you can apply it directly to the page.
C#
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc.RazorPages;

namespace WTS.WebApp.Pages
{
    // Restrict to anyone inside the "IT_Admins" or "App_Managers" AD groups
    [Authorize(Roles = @"DOMAIN\IT_Admins, DOMAIN\App_Managers")]
    public class AdminDashboardModel : PageModel
    {
        public void OnGet()
        {
        }
    }
}
3. Inline Code Check (Best for dynamic databases)
If your list of allowed users lives in a database (like your Firestore or Oracle DB) and can change dynamically, attributes won't work because they require constant values at compile time. Instead, check the user's identity during the page request.
C#
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using System.Linq;

namespace WTS.WebApp.Pages
{
    // Require Windows Auth generally, but don't restrict to specific users yet
    [Authorize] 
    public class DynamicAccessModel : PageModel
    {
        public IActionResult OnGet()
        {
            // Grab the current Windows username
            string currentUser = User.Identity?.Name ?? string.Empty;

            // Example: Check against a dynamic list or database
            string[] allowedUsers = GetAllowedUsersFromDatabase();

            if (!allowedUsers.Contains(currentUser, System.StringComparer.OrdinalIgnoreCase))
            {
                // Kick them out with a 403 Forbidden
                return Forbid(); 
            }

            // Proceed with page load
            return Page();
        }

        private string[] GetAllowedUsersFromDatabase()
        {
            return new[] { @"DOMAIN\User1", @"DOMAIN\User2" };
        }
    }
}




##########



Here is how to set up a dynamic registration pipeline.
1. Create a Custom Attribute
Create an attribute to hold the metadata (the tag name and the property type) required for mapping.
C#
using System;

namespace WTS.MarkdownLibrary.Attributes
{
    [AttributeUsage(AttributeTargets.Method)]
    public class MarkdownComponentAttribute : Attribute
    {
        public string TagName { get; }
        public Type PropertyType { get; }

        public MarkdownComponentAttribute(string tagName, Type propertyType)
        {
            TagName = tagName;
            PropertyType = propertyType;
        }
    }
}
2. Tag Your Static Renderers
Add the new attribute to your existing static Render methods. This tells the application exactly which tag and property model this method is responsible for handling.
C#
using WTS.MarkdownLibrary.Attributes;
using WTS.RazorComponentLibrary.Models.RclComponents;

namespace WTS.RazorComponentLibrary.Renderers
{
    public static class RclAccordionItemRenderer
    {
        // Add the attribute here
        [MarkdownComponent("rcl-accordion-item", typeof(AccordionItemProperties))]
        public static string Render(AccordionItemProperties p)
        {
            return p.Variant switch
            {
                // ... your existing switch logic
            };
        }
    }
}
3. Rewrite RclComponentRenderer with Reflection
Update your RclComponentRenderer constructor. We will use Reflection to scan the assembly for any methods wearing the [MarkdownComponent] attribute, construct the generic ComponentMapper.Map<T> dynamically, and build the dictionary automatically.  
CS
C#
using System;
using System.Collections.Generic;
using System.Linq;
using System.Reflection;
using Markdig.Renderers.Html;
using Markdig.Extensions.CustomContainers;
using WTS.RazorComponentLibrary.Models;
using WTS.MarkdownLibrary.Attributes;

namespace WTS.MarkdownLibrary.Classes
{
    public class RclComponentRenderer : HtmlObjectRenderer<CustomContainer>
    {
        private readonly Dictionary<string, Func<Dictionary<string, string>, string, string>> _handlers;

        public RclComponentRenderer()
        {
            _handlers = new Dictionary<string, Func<Dictionary<string, string>, string, string>>(StringComparer.OrdinalIgnoreCase);

            // 1. Get the assembly containing your renderers (adjust the type if your renderers are in a different assembly)
            var assembly = typeof(WTS.RazorComponentLibrary.Renderers.RclAccordionRenderer).Assembly;

            // 2. Find all public static methods decorated with [MarkdownComponent]
            var methodsWithAttribute = assembly.GetTypes()
                .SelectMany(t => t.GetMethods(BindingFlags.Public | BindingFlags.Static))
                .Select(m => new { Method = m, Attribute = m.GetCustomAttribute<MarkdownComponentAttribute>() })
                .Where(x => x.Attribute != null);

            // 3. Get the open generic MethodInfo for ComponentMapper.Map<T>
            var baseMapMethod = typeof(ComponentMapper).GetMethod("Map", BindingFlags.Public | BindingFlags.Static);

            // 4. Dynamically build the _handlers dictionary
            foreach (var item in methodsWithAttribute)
            {
                var tagName = item.Attribute!.TagName;
                var propertyType = item.Attribute.PropertyType;

                // Create the specific generic version of Map<T> for this property type
                var specificMapMethod = baseMapMethod!.MakeGenericMethod(propertyType);

                // Register the handler
                _handlers[tagName] = (metadata, content) =>
                {
                    // Dynamically invoke: ComponentMapper.Map<T>(metadata, content)
                    var propertiesInstance = specificMapMethod.Invoke(null, new object[] { metadata, content });

                    // Dynamically invoke: The specific Renderer.Render(propertiesInstance)
                    return (string)item.Method.Invoke(null, new[] { propertiesInstance })!;
                };
            }
        }
    }
}
Why this is better:
Zero Maintenance: You never have to touch RclComponentRenderer or _handlers again.
Self-Documenting: Placing the attribute directly above the Render method keeps the tag string, the property model, and the rendering logic organized in a single location.
Startup Performance: The Reflection scan only happens once when the RclComponentRenderer class is instantiated, meaning it will not slow down the actual parsing of your Markdown documents.