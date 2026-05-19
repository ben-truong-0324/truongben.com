# Ben Truong — Personal Website

Welcome to my personal website and portfolio, built with [Hugo](https://gohugo.io/) and powered by the [HugoBlox framework](https://hugoblox.com/). This site showcases my work in machine learning, data science, fullstack development, and public-interest tech.

🚀 **Live site**: [https://truongben.com](https://truongben.com)  
📄 **Resume**: [View my resume](/files/resume.pdf)

---

## 💡 About the Site

- Showcase selected ML and NLP projects
- Serve as a technical blog & writing space
- Provide easy access to my resume, background, and social links

---

## 🛠️ Tech Stack

- **Static Site Generator:** Hugo (v0.126+)
- **Theme Engine:** HugoBlox (formerly Wowchemy)
- **Deployment:** GitHub Pages, Github Actions
- **Content Format:** Markdown + YAML frontmatter

---

## 🚧 Local Development

To build and preview locally:

```bash
git clone https://github.com/ben-truong-0324/truongben.com.git
cd truongben.com
hugo serve

chmod +x gitpush.sh
./gitpush.sh

docker compose up --build #build hugo for local dev with docker
localhost:1313

git add .
git commit -m "updated"
git push


#############

using Microsoft.Extensions.FileProviders;
using Microsoft.Extensions.Primitives;

namespace WebTemplateDemo.Providers
{
    public class MarkdownViewFileProvider : IFileProvider
    {
        private readonly PhysicalFileProvider _physicalFileProvider;

        public MarkdownViewFileProvider(string rootPath)
        {
            _physicalFileProvider = new PhysicalFileProvider(rootPath);
        }

        public IFileInfo GetFileInfo(string subpath)
        {
            // Intercept requests for Razor Views
            if (subpath.EndsWith(".cshtml", StringComparison.OrdinalIgnoreCase))
            {
                // Swap extension, check for a Markdown file
                var mdPath = subpath.Substring(0, subpath.Length - 7) + ".md";
                var mdFileInfo = _physicalFileProvider.GetFileInfo(mdPath);

                if (mdFileInfo.Exists)
                {
                    // Return custom wrapper that generates Razor syntax on the fly
                    return new MarkdownFileInfo(mdFileInfo);
                }
            }

            return _physicalFileProvider.GetFileInfo(subpath);
        }

        public IDirectoryContents GetDirectoryContents(string subpath) => _physicalFileProvider.GetDirectoryContents(subpath);
        public IChangeToken Watch(string filter) => _physicalFileProvider.Watch(filter);
    }
}



#######################


@{
    // If you need access to the parsed model variables (like AutoToc), you can pass them 
    // via ViewData from your MarkdownFileInfo builder, or extract them here if needed.
    var sideNavClass = "true"; 
    var mainClass = "main-class";
}

<div class="container">
    <div class="row">
        @* Side navigation *@
        <div class="col-lg-4 col-xl-3 pb-lg-5 @sideNavClass">
            @* Render the section injected by our MarkdownFileInfo builder *@
            @RenderSection("SideNav", required: false)
        </div>
        
        @* Content *@
        <main class="main-primary col-lg-8 col-xl-9 p-b-lg @mainClass">
            @RenderBody()
        </main>
    </div>
</div>


######################

private byte[] EnsureProcessed()
{
    if (_viewContent != null) return _viewContent;

    using var stream = _mdFileInfo.CreateReadStream();
    using var reader = new StreamReader(stream);
    var markdownContent = reader.ReadToEnd();

    var markdownLines = markdownContent.Split(new[] { "\r\n", "\n" }, StringSplitOptions.None);

    var fullRoute = "/" + Path.GetFileNameWithoutExtension(_mdFileInfo.Name);
    var vm = TemplateModel.GetTemplateModel(fullRoute);
    TemplateBaseModel? baseModel = vm as TemplateBaseModel;
    string partialName = baseModel?.TemplateView ?? "_RclErrorPartial";

    var model = new TwoColumnsSideNavArticleTemplateModel(
        new Dictionary<string, string>(), // actual metadata here
        markdownLines,
        contentStartIndex: 0 
    );

    model.UpdateSectionsToHtml();

    var sb = new StringBuilder();

    // 1. Declare page and inject tag helpers
    sb.AppendLine("@page");
    sb.AppendLine("@addTagHelper *, Microsoft.AspNetCore.Mvc.TagHelpers");
    sb.AppendLine("@addTagHelper *, WebTemplateDemo");

    // 2. Set Layout and pass primitive metadata via ViewData
    // Using verbatim strings @"" and escaping internal quotes "" ensures safe HTML/String injection
    sb.AppendLine("@{");
    sb.AppendLine($"    Layout = \"{partialName}\";");
    sb.AppendLine($"    ViewData[\"TemplateType\"] = @\"{model.TemplateType?.Replace("\"", "\"\"")}\";");
    sb.AppendLine($"    ViewData[\"DatePublished\"] = @\"{model.DatePublished}\";");
    sb.AppendLine($"    ViewData[\"AuthorName\"] = @\"{model.AuthorName?.Replace("\"", "\"\"")}\";");
    sb.AppendLine($"    ViewData[\"SideNavTitle\"] = @\"{model.SideNavTitle?.Replace("\"", "\"\"")}\";");
    sb.AppendLine($"    ViewData[\"Title\"] = @\"{model.Title?.Replace("\"", "\"\"")}\";");
    sb.AppendLine($"    ViewData[\"MetaDescription\"] = @\"{model.MetaDescription?.Replace("\"", "\"\"")}\";");
    sb.AppendLine("}");

    // 3. SideNav Content
    if (!string.IsNullOrWhiteSpace(model.SideNavContent))
    {
        sb.AppendLine("@section SideNav {");
        sb.AppendLine(model.SideNavContent);
        sb.AppendLine("}");
    }

    // 4. Build LinkButtons natively into the view as a Section
    if (model.LinkButtons != null && model.LinkButtons.Any())
    {
        sb.AppendLine("@section LinkButtons {");
        foreach (var item in model.LinkButtons)
        {
            var link = item.Replace("a href", "a class='btn btn-lg btn-primary' href");
            sb.AppendLine("    <div class=\"text-center m-3\">");
            sb.AppendLine($"        {link}");
            sb.AppendLine("    </div>");
        }
        sb.AppendLine("}");
    }

    // 5. Build PressContacts natively into the view as a Section
    if (model.PressContacts != null && model.PressContacts.Any())
    {
        sb.AppendLine("@section PressContacts {");
        foreach (var contact in model.PressContacts)
        {
            // If _PressContactCard doesn't need a model passed to it, this works as-is.
            // If it does need the contact data, you can pass it by serializing/deserializing the object here.
            sb.AppendLine("    <partial name=\"Components/Card/_PressContactCard\" />");
        }
        sb.AppendLine("}");
    }

    // 6. Main Body Content (RenderBody)
    sb.AppendLine(model.MainContent); 

    _viewContent = Encoding.UTF8.GetBytes(sb.ToString());
    return _viewContent;
}


##################################


@{
    // Read variables injected by MarkdownFileInfo
    var templateType = ViewData["TemplateType"]?.ToString() ?? string.Empty;
    var sideNavClass = templateType.Contains("AutoToc") ? "" : "";
    var sideNavAccordion = templateType.Contains("AutoToc") ? "section-default" : "section-understated";
    var mainClass = templateType.Contains("AutoToc") ? "" : "";
    
    var datePublished = ViewData["DatePublished"]?.ToString() ?? string.Empty;
    string updatedDateText = string.Empty;
    var authorName = ViewData["AuthorName"]?.ToString() ?? string.Empty;
    var hasAuthor = !string.IsNullOrWhiteSpace(authorName);

    var title = ViewData["Title"]?.ToString();
    var metaDescription = ViewData["MetaDescription"]?.ToString();
    var sideNavTitle = ViewData["SideNavTitle"]?.ToString();
}

<div class="container p-t-md p-b-lg">
    <div class="row">
        
        @* Side navigation *@
        <div class="col-lg-4 col-xl-3 pb-lg-5 @sideNavClass">
            @if (!string.IsNullOrEmpty(sideNavTitle))
            {
                @Html.Raw(sideNavTitle)
            }
            @RenderSection("SideNav", required: false)
        </div>

        @* Content *@
        <div class="col-lg-8 col-xl-9 pb-lg-5 @mainClass">
            <p class="m-t-md">
                @if (!string.IsNullOrWhiteSpace(updatedDateText))
                {
                    @updatedDateText @: |
                }
                Press release
            </p>
            
            <h1>@Html.Raw(title ?? string.Empty)</h1>
            <p class="lead">@Html.Raw(metaDescription)</p>

            @if (hasAuthor)
            {
                <p>By @Html.Raw(authorName)</p>
            }
            
            <partial name="Components/SocialMediaIcons/_SocialMediaIconsArticlePage" />
            <hr class="mb-lg" />
            
            @* The actual Markdig parsed HTML outputs here *@
            @RenderBody()

            @* Link Buttons *@
            @RenderSection("LinkButtons", required: false)

            @* Press Contacts *@
            @RenderSection("PressContacts", required: false)
        </div>
    </div>
</div>