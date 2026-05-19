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


Updated C# Tag Helper (With Guardrails)

Here is the updated C# code. I added a DisallowedTags hash set. If a developer tries to add bar-btn-copy-to-clipboard to an <input> or <button>, it will intentionally fail during compilation/rendering to prevent broken UI bugs in production.
C#

using Microsoft.AspNetCore.Mvc.Rendering;
using Microsoft.AspNetCore.Razor.TagHelpers;
using System;
using System.Collections.Generic;
using System.Linq;
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
            // Guardrail: Prevent usage on void or interactive elements
            if (DisallowedTags.Contains(context.TagName))
            {
                throw new InvalidOperationException($"The '{TargetAttributeName}' attribute cannot be used on <{context.TagName}> elements. Apply it to a wrapper <div> or <span> instead.");
            }

            var childContent = await output.GetChildContentAsync();
            var originalContent = childContent.GetContent();
            var valueToCopy = CopyValue ?? originalContent;

            // Build Button
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

            // Output logic
            if (context.TagName.Equals("td", StringComparison.OrdinalIgnoreCase))
            {
                output.Content.SetHtmlContent($"<span class=\"d-flex\">{originalContent}</span>");
                output.Content.AppendHtml(copyButton);
            }
            else
            {
                var originalTagName = context.TagName;
                var originalAttributes = output.Attributes
                    .Where(a => a.Name != TargetAttributeName && a.Name != ContentAttributeName)
                    .ToList();

                var originalTag = new TagBuilder(originalTagName);
                foreach (var attr in originalAttributes)
                {
                    originalTag.Attributes.Add(attr.Name, attr.Value.ToString());
                }
                originalTag.InnerHtml.AppendHtml(originalContent);

                output.TagName = "div";
                output.Attributes.Clear();
                output.Attributes.SetAttribute("class", "d-flex");
                output.Content.SetHtmlContent(originalTag);
                output.Content.AppendHtml(copyButton);
            }
        }
    }
}

3. Updated JavaScript (With Error Handling)

Here is the updated JavaScript config that handles clipboard failures gracefully (e.g., if the browser blocks clipboard access due to missing HTTPS or permissions).
JavaScript

const CopyConfig = {
    selectors: {
        trigger: '.copy-to-clipboard-trigger',
        copiedState: '.copy-to-clipboard-copied',
        icon: '.copy-to-clipboard-icon',
        tooltip: '.copy-to-clipboard-tooltip'
    },
    attributes: {
        contentToCopy: 'content-to-copy-to-clipboard'
    },
    classes: {
        copiedState: 'copy-to-clipboard-copied',
        iconDefault: ['ca-gov-icon-clipboard', 'text-muted'],
        iconSuccess: ['ca-gov-icon-checklist', 'text-success'],
        iconError: ['ca-gov-icon-warning', 'text-danger'] // Added error icon classes
    },
    text: {
        default: 'Copy to clipboard',
        success: 'Copied',
        error: 'Failed to copy' // Added error text
    },
    timers: {
        revertWaitTimeMs: 10000
    }
};

const activeTimeouts = new WeakMap();

document.addEventListener('click', function (event) {
    const btn = event.target.closest(CopyConfig.selectors.trigger);
    if (!btn) return;

    const textToCopy = btn.getAttribute(CopyConfig.attributes.contentToCopy);
    if (!textToCopy) return;

    const prevBtn = document.querySelector(CopyConfig.selectors.copiedState);
    if (prevBtn && prevBtn !== btn) {
        resetButtonState(prevBtn);
    }

    navigator.clipboard.writeText(textToCopy).then(() => {
        setButtonState(btn, CopyConfig.classes.iconSuccess, CopyConfig.text.success);
        manageTimeout(btn);
    }).catch(err => {
        console.warn('Clipboard API blocked or failed: ', err);
        setButtonState(btn, CopyConfig.classes.iconError, CopyConfig.text.error);
        manageTimeout(btn);
    });
});

// Consolidated state updater for both success and error states
function setButtonState(btn, iconClasses, tooltipText) {
    btn.classList.add(CopyConfig.classes.copiedState);
    const icon = btn.querySelector(CopyConfig.selectors.icon);
    const tooltip = btn.querySelector(CopyConfig.selectors.tooltip);

    if (icon) {
        icon.classList.remove(...CopyConfig.classes.iconDefault);
        icon.classList.add(...iconClasses);
    }
    if (tooltip) {
        tooltip.textContent = tooltipText;
    }
}

function resetButtonState(btn) {
    btn.classList.remove(CopyConfig.classes.copiedState);
    const icon = btn.querySelector(CopyConfig.selectors.icon);
    const tooltip = btn.querySelector(CopyConfig.selectors.tooltip);

    if (icon) {
        icon.classList.remove(...CopyConfig.classes.iconSuccess, ...CopyConfig.classes.iconError);
        icon.classList.add(...CopyConfig.classes.iconDefault);
    }
    if (tooltip) {
        tooltip.textContent = CopyConfig.text.default;
    }
}

function manageTimeout(btn) {
    if (activeTimeouts.has(btn)) {
        clearTimeout(activeTimeouts.get(btn));
    }
    const timeoutId = setTimeout(() => {
        resetButtonState(btn);
        activeTimeouts.delete(btn);
    }, CopyConfig.timers.revertWaitTimeMs);
    activeTimeouts.set(btn, timeoutId);
}




####

using Microsoft.AspNetCore.Razor.TagHelpers;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using System.Text.Encodings.Web;
// Ensure you have a using statement for the namespace where your TagHelper lives
// using YourNamespace.TagHelpers; 

[TestClass]
public class CopyToClipboardTagHelperTests
{
    /// <summary>
    /// Helper method to create standard TagHelper Context and Output without mocking frameworks.
    /// </summary>
    private (TagHelperContext context, TagHelperOutput output) CreateTagHelperData(string tagName, string content)
    {
        var context = new TagHelperContext(
            tagName: tagName,
            allAttributes: new TagHelperAttributeList(),
            items: new Dictionary<object, object>(),
            uniqueId: "test-id");

        // Provide a real delegate to return the child content instead of mocking it
        var output = new TagHelperOutput(
            tagName: tagName,
            attributes: new TagHelperAttributeList(),
            getChildContentAsync: (useCachedResult, encoder) =>
            {
                var tagHelperContent = new DefaultTagHelperContent();
                tagHelperContent.SetContent(content);
                return Task.FromResult<TagHelperContent>(tagHelperContent);
            });

        return (context, output);
    }

    [TestMethod]
    public async Task ProcessAsync_GivenTdTag_WrapsContentAndAppendsButton()
    {
        // Arrange
        var helper = new CopyToClipboardTagHelper();
        var (context, output) = CreateTagHelperData("td", "Cell Data");

        // Act
        await helper.ProcessAsync(context, output);

        // Assert
        Assert.AreEqual("td", output.TagName); // TD should remain a TD
        
        var htmlContent = output.Content.GetContent();
        
        Assert.IsTrue(htmlContent.Contains("<span class=\"d-flex\">Cell Data</span>"), "Content should be wrapped in a flex span.");
        Assert.IsTrue(htmlContent.Contains("<button"), "Button tag should be appended.");
        Assert.IsTrue(htmlContent.Contains("content-to-copy-to-clipboard=\"Cell Data\""), "Button should contain the correct data attribute to copy.");
    }

    [TestMethod]
    public async Task ProcessAsync_GivenATag_MorphsToDivAndWrapsOriginalTag()
    {
        // Arrange
        var helper = new CopyToClipboardTagHelper 
        { 
            CopyValue = "https://example.com" 
        };
        var (context, output) = CreateTagHelperData("a", "Click Here");
        output.Attributes.Add("href", "https://example.com"); // Simulate an existing attribute on the A tag

        // Act
        await helper.ProcessAsync(context, output);

        // Assert
        Assert.AreEqual("div", output.TagName, "The output tag should be morphed into a div.");
        
        var hasFlexClass = output.Attributes.Any(a => a.Name == "class" && a.Value.ToString() == "d-flex");
        Assert.IsTrue(hasFlexClass, "The morphed div should have the 'd-flex' class applied.");

        var htmlContent = output.Content.GetContent();
        
        // Check if the original tag was properly reconstructed inside the wrapper
        Assert.IsTrue(htmlContent.Contains("<a href=\"https://example.com\">Click Here</a>"), "The original anchor tag should be preserved inside the div.");
        
        // Button is appended with the overridden copy value
        Assert.IsTrue(htmlContent.Contains("content-to-copy-to-clipboard=\"https://example.com\""), "The button should use the overridden CopyValue property.");
    }

    [TestMethod]
    public async Task ProcessAsync_GivenDisallowedTag_ThrowsInvalidOperationException()
    {
        // Arrange
        var helper = new CopyToClipboardTagHelper();
        var (context, output) = CreateTagHelperData("input", "test");

        // Act & Assert
        var exception = await Assert.ThrowsExceptionAsync<InvalidOperationException>(async () =>
        {
            await helper.ProcessAsync(context, output);
        });

        Assert.IsTrue(exception.Message.Contains("cannot be used on <input> elements"), "Exception message should specify the disallowed tag.");
    }
}
```</TagHelperContent>