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



#######################
using Microsoft.AspNetCore.Mvc.Rendering;
using Microsoft.AspNetCore.Razor.TagHelpers;
using System;
using System.Collections.Generic;
using System.Net;
using System.Text.RegularExpressions;
using System.Threading.Tasks;

namespace YourNamespace.TagHelpers
{
    [HtmlTargetElement("*", Attributes = TargetAttributeName)]
    public class CopyToClipboardTagHelper : TagHelper
    {
        private const string TargetAttributeName = "bar-btn-copy-to-clipboard";
        private const string ContentAttributeName = "content-to-copy-to-clipboard";

        // HTML elements that cannot safely contain or be morphed into a flex container with a button
        private static readonly HashSet<string> DisallowedTags = new(StringComparer.OrdinalIgnoreCase) 
        { 
            "input", "button", "textarea", "select", "img", "br", "hr", "meta" 
        };

        public string ButtonCssClass { get; set; } = "btn btn-link p-0 ms-1 copy-to-clipboard-trigger";
        public string IconCssClass { get; set; } = "ca-gov-icon-clipboard text-muted copy-to-clipboard-icon";
        public string TooltipCssClass { get; set; } = "copy-to-clipboard-tooltip";
        public string DefaultTooltipText { get; set; } = "Copy to clipboard";

        [HtmlAttributeName(ContentAttributeName)]
        public string? CopyValue { get; set; }

        public override async Task ProcessAsync(TagHelperContext context, TagHelperOutput output)
        {
            if (DisallowedTags.Contains(context.TagName))
            {
                throw new InvalidOperationException($"The '{TargetAttributeName}' attribute cannot be used on <{context.TagName}> elements.");
            }

            // 1. Get raw HTML for visual rendering
            var childContent = await output.GetChildContentAsync();
            var originalHtmlContent = childContent.GetContent();

            // 2. Extract strictly plain text for the copy button
            // Strip out HTML tags (e.g. <span>123</span> -> 123) and decode entities (e.g. &amp; -> &)
            var plainTextContent = Regex.Replace(originalHtmlContent, "<.*?>", string.Empty);
            plainTextContent = WebUtility.HtmlDecode(plainTextContent).Trim();

            // Use the explicit attribute if provided, otherwise fallback to the cleaned plain text
            var valueToCopy = CopyValue ?? plainTextContent;

            // 3. Build the Copy Button
            var copyButton = new TagBuilder("button");
            copyButton.Attributes.Add("type", "button");
            copyButton.Attributes.Add("style", "text-decoration:none");
            copyButton.Attributes.Add("class", ButtonCssClass);
            copyButton.Attributes.Add(ContentAttributeName, valueToCopy);

            var iconSpan = new TagBuilder("span");
            iconSpan.Attributes.Add("class", IconCssClass);
            iconSpan.Attributes.Add("aria-hidden", "true");

            var tooltipSpan = new TagBuilder("span");
            tooltipSpan.Attributes.Add("class", TooltipCssClass);
            tooltipSpan.InnerHtml.Append(DefaultTooltipText);

            copyButton.InnerHtml.AppendHtml(iconSpan);
            copyButton.InnerHtml.AppendHtml(tooltipSpan);

            // 4. Handle rendering logic
            if (context.TagName.Equals("td", StringComparison.OrdinalIgnoreCase))
            {
                // Remove the custom trigger attributes from the TD so they don't bleed into the final HTML
                output.Attributes.RemoveAll(TargetAttributeName);
                output.Attributes.RemoveAll(ContentAttributeName);

                // Wrap visual content and button in a flex span, keep TD as the parent output
                var flexWrapper = new TagBuilder("span");
                flexWrapper.Attributes.Add("class", "d-flex align-items-center");
                
                flexWrapper.InnerHtml.AppendHtml(originalHtmlContent); // Keep original HTML for visuals
                flexWrapper.InnerHtml.AppendHtml(copyButton);

                output.Content.SetHtmlContent(flexWrapper);
            }
            else
            {
                // For other tags (like <a>), rebuild the original tag so we can wrap it in a div
                var originalTag = new TagBuilder(context.TagName);

                // Transfer all attributes (like href, class) from the original tag to the rebuilt tag, 
                // EXCEPT our custom tag helper attributes.
                foreach (var attr in output.Attributes)
                {
                    if (attr.Name != TargetAttributeName && attr.Name != ContentAttributeName)
                    {
                        originalTag.Attributes.Add(attr.Name, attr.Value.ToString());
                    }
                }

                // Add the original HTML content inside the rebuilt tag
                originalTag.InnerHtml.AppendHtml(originalHtmlContent); 

                // Morph the parent output into the wrapper DIV
                output.TagName = "div";
                
                // Clear the original attributes off the wrapper div (they are now on the rebuilt inner tag)
                output.Attributes.Clear(); 
                output.Attributes.SetAttribute("class", "d-flex align-items-center");
                
                // Inject the rebuilt original tag and the button into the new wrapper div
                output.Content.SetHtmlContent(originalTag);
                output.Content.AppendHtml(copyButton);
            }
        }
    }
}