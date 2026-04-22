### tag

using Microsoft.AspNetCore.Razor.TagHelpers;
using System.Collections.Generic;

namespace MyComponentLibrary.TagHelpers
{
    public enum ButtonColor
    {
        Primary,
        Highlight,
        Standout,
        Default
    }

    public enum ButtonSize
    {
        Default,
        Lg,
        Sm,
        Xs
    }

    [HtmlTargetElement("rcl-button")]
    public class ButtonTagHelper : TagHelper
    {
        public ButtonColor Color { get; set; } = ButtonColor.Primary;
        public ButtonSize Size { get; set; } = ButtonSize.Default;
        public bool IsOutline { get; set; }
        public bool IsDisabled { get; set; }
        public bool IsHover { get; set; }
        
        // If an Href is provided, it renders as an <a> tag instead of a <button>
        public string Href { get; set; }

        public override void Process(TagHelperContext context, TagHelperOutput output)
        {
            var classes = new List<string> { "btn" };

            // 1. Resolve Color and Outline
            string outlineModifier = IsOutline ? "-outline" : "";
            string colorString = Color.ToString().ToLower();
            classes.Add($"btn{outlineModifier}-{colorString}");

            // 2. Resolve Size
            if (Size == ButtonSize.Lg) classes.Add("btn-lg");
            else if (Size == ButtonSize.Sm) classes.Add("btn-sm");
            else if (Size == ButtonSize.Xs) classes.Add("btn-xs");

            // 3. Resolve States
            if (IsDisabled) classes.Add("disabled");
            if (IsHover) classes.Add("btn-hover");

            // 4. Resolve Tag Type
            if (!string.IsNullOrWhiteSpace(Href))
            {
                output.TagName = "a";
                output.Attributes.SetAttribute("href", Href);
                output.Attributes.SetAttribute("role", "button");
            }
            else
            {
                output.TagName = "button";
                // Optionally add the actual HTML disabled attribute for true buttons
                if (IsDisabled) output.Attributes.SetAttribute("disabled", "disabled");
            }

            output.Attributes.SetAttribute("class", string.Join(" ", classes));
        }
    }
}

## cshtml use

<div class="btn-row p-b">
    <rcl-button color="Primary">Primary color</rcl-button>
    <rcl-button color="Highlight">Highlight color</rcl-button>
    <rcl-button color="Standout">Standout color</rcl-button>
</div>

<div class="btn-row p-b">
    <rcl-button color="Primary" is-disabled="true" href="#">Primary color</rcl-button>
    <rcl-button color="Highlight" is-disabled="true" href="#">Highlight color</rcl-button>
</div>

<div class="btn-row p-b">
    <rcl-button color="Standout" is-hover="true" href="#">Standout color</rcl-button>
</div>

<div class="btn-row p-b">
    <rcl-button color="Primary" is-outline="true" href="">Primary color</rcl-button>
    <rcl-button color="Highlight" is-outline="true" href="">Highlight color</rcl-button>
</div>

<div class="btn-row m-b-lg">
    <rcl-button color="Default" size="Lg" href="">large</rcl-button>
    <rcl-button color="Default" href="">default</rcl-button>
    <rcl-button color="Default" size="Sm" href="">small</rcl-button>
    <rcl-button color="Default" size="Xs" href="">extra small</rcl-button>
</div>

#docs
Button Component (<rcl-button>)

Renders CA state template styled buttons. It automatically switches between <button> and <a> tags depending on whether an href property is provided.
Setup

Ensure the Tag Helpers are registered in your _ViewImports.cshtml:
HTML

@addTagHelper *, MyComponentLibrary

Properties
Attribute	Type	Default	Description
color	ButtonColor	Primary	Options: Primary, Highlight, Standout, Default.
size	ButtonSize	Default	Options: Default, Lg, Sm, Xs.
is-outline	bool	false	Renders the outlined version of the button color.
is-disabled	bool	false	Applies the disabled CSS class.
is-hover	bool	false	Applies the forced btn-hover state class.
href	string	null	If provided, renders an <a> tag with role="button". If omitted, renders a <button>.
Example
HTML

<rcl-button color="Highlight" size="Lg" is-outline="true" href="/next-page">
    Continue
</rcl-button>

# tests

using Microsoft.VisualStudio.TestTools.UnitTesting;
using Microsoft.AspNetCore.Razor.TagHelpers;
using MyComponentLibrary.TagHelpers;
using System.Collections.Generic;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc.Testing;
using System.Net.Http;
using MyComponentLibrary.TestHost; // Adjust to your test host app namespace

namespace MyComponentLibrary.Tests
{
    [TestClass]
    public class ButtonTagHelpersTests
    {
        // --- Unit Tests ---

        private (TagHelperContext, TagHelperOutput) CreateTagHelperData(string tagName)
        {
            var context = new TagHelperContext(
                tagName: tagName,
                allAttributes: new TagHelperAttributeList(),
                items: new Dictionary<object, object>(),
                uniqueId: "test");

            var output = new TagHelperOutput(
                tagName,
                new TagHelperAttributeList(),
                (useCachedResult, encoder) =>
                {
                    var tagHelperContent = new DefaultTagHelperContent();
                    tagHelperContent.SetContent("Test Button");
                    return Task.FromResult<TagHelperContent>(tagHelperContent);
                });

            return (context, output);
        }

        [TestMethod]
        public void ButtonTagHelper_NoHref_RendersButtonTag()
        {
            // Arrange
            var helper = new ButtonTagHelper { Color = ButtonColor.Primary };
            var (context, output) = CreateTagHelperData("rcl-button");

            // Act
            helper.Process(context, output);

            // Assert
            Assert.AreEqual("button", output.TagName);
            Assert.AreEqual("btn btn-primary", output.Attributes["class"].Value);
        }

        [TestMethod]
        public void ButtonTagHelper_WithHref_RendersAnchorTag()
        {
            // Arrange
            var helper = new ButtonTagHelper { Color = ButtonColor.Standout, Href = "https://ca.gov" };
            var (context, output) = CreateTagHelperData("rcl-button");

            // Act
            helper.Process(context, output);

            // Assert
            Assert.AreEqual("a", output.TagName);
            Assert.AreEqual("https://ca.gov", output.Attributes["href"].Value);
            Assert.AreEqual("button", output.Attributes["role"].Value);
            Assert.AreEqual("btn btn-standout", output.Attributes["class"].Value);
        }

        [TestMethod]
        public void ButtonTagHelper_Outline_AddsOutlineClass()
        {
            // Arrange
            var helper = new ButtonTagHelper { Color = ButtonColor.Highlight, IsOutline = true };
            var (context, output) = CreateTagHelperData("rcl-button");

            // Act
            helper.Process(context, output);

            // Assert
            Assert.AreEqual("btn btn-outline-highlight", output.Attributes["class"].Value);
        }

        [TestMethod]
        public void ButtonTagHelper_Sizes_AppendsCorrectClasses()
        {
            // Arrange
            var helper = new ButtonTagHelper { Color = ButtonColor.Default, Size = ButtonSize.Lg };
            var (context, output) = CreateTagHelperData("rcl-button");

            // Act
            helper.Process(context, output);

            // Assert
            Assert.AreEqual("btn btn-default btn-lg", output.Attributes["class"].Value);
        }

        [TestMethod]
        public void ButtonTagHelper_States_AppendsDisabledAndHoverClasses()
        {
            // Arrange
            var helper = new ButtonTagHelper { Color = ButtonColor.Primary, IsDisabled = true, IsHover = true };
            var (context, output) = CreateTagHelperData("rcl-button");

            // Act
            helper.Process(context, output);

            // Assert
            StringAssert.Contains(output.Attributes["class"].Value.ToString(), "disabled");
            StringAssert.Contains(output.Attributes["class"].Value.ToString(), "btn-hover");
            Assert.AreEqual("disabled", output.Attributes["disabled"].Value); // Native disabled attr for <button>
        }
    }

    [TestClass]
    public class ButtonIntegrationTests
    {
        // --- Integration Tests ---
        
        private WebApplicationFactory<Program> _factory;
        private HttpClient _client;

        [TestInitialize]
        public void Setup()
        {
            _factory = new WebApplicationFactory<Program>();
            _client = _factory.CreateClient();
        }

        [TestCleanup]
        public void Cleanup()
        {
            _client?.Dispose();
            _factory?.Dispose();
        }

        [TestMethod]
        public async Task Button_RendersCorrectHtml_OnPage()
        {
            // Act
            // Assume the test page has: <rcl-button color="Highlight" is-outline="true" href="#">Int Test</rcl-button>
            var response = await _client.GetAsync("/ButtonTestPage");
            response.EnsureSuccessStatusCode();

            var responseString = await response.Content.ReadAsStringAsync();

            // Assert
            StringAssert.Contains(responseString, "<a href=\"#\" role=\"button\" class=\"btn btn-outline-highlight\">");
            StringAssert.Contains(responseString, "Int Test");
            StringAssert.Contains(responseString, "</a>");
        }
    }
}



########################





The Shared Models (MyProject.Rcl.Core)

Move the enums and create a property DTO here so both the Markdown library and the TagHelper can see them.
C#

namespace MyComponentLibrary.Models
{
    public enum ButtonColor { Primary, Highlight, Standout, Default }
    public enum ButtonSize { Default, Lg, Sm, Xs }

    public class ButtonProperties
    {
        public ButtonColor Color { get; set; } = ButtonColor.Primary;
        public ButtonSize Size { get; set; } = ButtonSize.Default;
        public bool IsOutline { get; set; }
        public bool IsDisabled { get; set; }
        public bool IsHover { get; set; }
        public string Href { get; set; } = string.Empty;
        public string Content { get; set; } = string.Empty;
    }
}

2. The Portable Renderer (MyProject.Rcl.Core)

This contains the logic you previously had in the Process method, but returns a raw HTML string.
C#

using MyComponentLibrary.Models;
using System.Collections.Generic;

namespace MyComponentLibrary.Renderers
{
    public static class RclButtonRenderer
    {
        public static string Render(ButtonProperties p)
        {
            var classes = new List<string> { "btn" };

            // 1. Resolve Color and Outline
            string outlineModifier = p.IsOutline ? "-outline" : "";
            string colorString = p.Color.ToString().ToLower();
            classes.Add($"btn{outlineModifier}-{colorString}");

            // 2. Resolve Size
            if (p.Size == ButtonSize.Lg) classes.Add("btn-lg");
            else if (p.Size == ButtonSize.Sm) classes.Add("btn-sm");
            else if (p.Size == ButtonSize.Xs) classes.Add("btn-xs");

            // 3. Resolve States
            if (p.IsDisabled) classes.Add("disabled");
            if (p.IsHover) classes.Add("btn-hover");

            string classAttr = string.Join(" ", classes);

            // 4. Render as Link or Button
            if (!string.IsNullOrWhiteSpace(p.Href))
            {
                return $@"<a href=""{p.Href}"" class=""{classAttr}"" role=""button"">{p.Content}</a>";
            }
            else
            {
                string disabledAttr = p.IsDisabled ? " disabled=\"disabled\"" : "";
                return $@"<button type=""button"" class=""{classAttr}""{disabledAttr}>{p.Content}</button>";
            }
        }
    }
}

3. Update the TagHelper (MyComponentLibrary)

The TagHelper now becomes a very thin "shell" that just passes data to the renderer.
C#

using Microsoft.AspNetCore.Razor.TagHelpers;
using MyComponentLibrary.Models;
using MyComponentLibrary.Renderers;

namespace MyComponentLibrary.TagHelpers
{
    [HtmlTargetElement("rcl-button")]
    public class ButtonTagHelper : TagHelper
    {
        public ButtonColor Color { get; set; } = ButtonColor.Primary;
        public ButtonSize Size { get; set; } = ButtonSize.Default;
        public bool IsOutline { get; set; }
        public bool IsDisabled { get; set; }
        public bool IsHover { get; set; }
        public string Href { get; set; }

        public override async Task ProcessAsync(TagHelperContext context, TagHelperOutput output)
        {
            var childContent = await output.GetChildContentAsync();
            output.TagName = null; // Let the renderer handle the tag type

            var props = new ButtonProperties
            {
                Color = this.Color,
                Size = this.Size,
                IsOutline = this.IsOutline,
                IsDisabled = this.IsDisabled,
                IsHover = this.IsHover,
                Href = this.Href,
                Content = childContent.GetContent()
            };

            output.Content.SetHtmlContent(RclButtonRenderer.Render(props));
        }
    }
}

4. Create the Markdown Handler (MyProject.Markdown)

This handler lives in your Markdown library and wires the :::rcl-button syntax to the renderer.
C#

using MyComponentLibrary.Models;
using MyComponentLibrary.Renderers;
using System;
using System.Collections.Generic;

namespace MyProject.Markdown.Handlers
{
    public class ButtonHandler : IRclComponentHandler
    {
        public string Render(Dictionary<string, string> attrs, string htmlContent)
        {
            Enum.TryParse(attrs.GetValueOrDefault("color", "Primary"), true, out ButtonColor color);
            Enum.TryParse(attrs.GetValueOrDefault("size", "Default"), true, out ButtonSize size);

            var props = new ButtonProperties
            {
                Color = color,
                Size = size,
                IsOutline = attrs.ContainsKey("outline"), // Supports :::rcl-button outline="true" OR just outline
                IsDisabled = attrs.ContainsKey("disabled"),
                IsHover = attrs.ContainsKey("hover"),
                Href = attrs.GetValueOrDefault("href", string.Empty),
                Content = htmlContent // This is the text between the ::: lines
            };

            return RclButtonRenderer.Render(props);
        }
    }
}

5. Register in the Parser

Finally, go into your MarkdownRclParser.cs and add the button to your _handlers dictionary.
C#

_handlers = new Dictionary<string, IRclComponentHandler>(StringComparer.OrdinalIgnoreCase)
{
    { "card", new CardHandler() },
    { "row", new RowHandler(this.Process) },
    { "button", new ButtonHandler() } // Add this line
};

How the User Uses It:

Your non-technical users can now drop buttons inside rows or cards:
Markdown

:::rcl-row
:::rcl-card title="Need Help?" column="col-md-6"
If you have questions, click the button below.

:::rcl-button color="Highlight" href="/contact" size="Lg"
Contact Support
:::
:::
:::




#######################


This documentation covers both the User Guide (how non-technical staff should write the Markdown) and the Technical Architecture (how the code is structured to avoid circular dependencies and ensure performance).
Part 1: User Documentation (Markdown Guide)

Our system uses a "Block" syntax (:::) to insert complex design system components into standard Markdown pages.
1. General Rules

    Every component starts with :::rcl-[name] and ends with :::.

    Attributes (like title or href) must be on the same line as the opening tag.

    The content inside the block can use standard Markdown (bold, links, etc.).

    Important: Do not indent the tags or the content. Keep everything flushed to the left margin.

2. The Card Component (:::rcl-card)

Used for service links, info boxes, or image-based navigation.

Attributes:

    variant: Default, Icon, Image, or Legacy.

    title: The main heading of the card.

    href: Where the card links to.

    icon: The CSS class for the icon (e.g., ca-gov-icon-computer).

    column: (Optional) Use when inside a row (e.g., col-md-4).

    griditem: Set to "true" to ensure all cards in a row have equal height.

Example:
Markdown

:::rcl-card variant="Icon" title="Online Services" icon="ca-gov-icon-computer" href="/services"
Access your **account** 24/7 through our secure portal.
:::

3. The Button Component (:::rcl-button)

Used for Call-to-Actions.

Attributes:

    color: Primary, Highlight, Standout, or Default.

    size: Default, Lg, Sm, or Xs.

    href: If provided, the button acts as a link. If omitted, it acts as a standard button.

    outline: (Optional) Add this to make it an outline-style button.

Example:
Markdown

:::rcl-button color="Highlight" size="Lg" href="/apply"
Apply Now
:::

4. Layouts (:::rcl-row)

Use this to place multiple cards side-by-side.

Example:
Markdown

:::rcl-row
:::rcl-card title="Card A" column="col-md-6" griditem="true"
Content for left side.
:::

:::rcl-card title="Card B" column="col-md-6" griditem="true"
Content for right side.
:::
:::

Part 2: Technical Architecture Recap

To support these components across both Razor (.cshtml) and Markdown (.md), we implemented a Decoupled 3-Tier Architecture. This prevents circular dependencies between your UI library and your Markdown engine.
1. The Project Structure

    MyProject.Rcl.Core (The Brain)

        No dependencies.

        Contains CardProperties, ButtonProperties, and Enums.

        Contains RclCardRenderer and RclButtonRenderer (Static classes returning pure HTML strings).

        Why: Both the Markdown engine and the Razor library need to "know" what a card looks like.

    MyProject.MarkdownEngine (The Parser)

        Depends on: Rcl.Core and Markdig.

        Contains MarkdownRclParser (The Router).

        Contains Handlers (e.g., CardHandler) that map Markdown attributes to Core renderers.

    MyProject.Rcl (The UI Library)

        Depends on: Rcl.Core and MarkdownEngine.

        Contains TagHelpers (e.g., CardTagHelper) that map Razor attributes to Core renderers.

        Why: This library handles the final display in the web app.

2. The Component Lifecycle (Markdown Flow)

    Regex Discovery: The MarkdownRclParser uses a "Nuclear Regex" to find :::rcl- blocks in the raw Markdown string.

    Dispatching: The parser identifies the tag name (e.g., card) and sends the attributes/body to the specific Handler.

    Recursive Processing: If the component is a row, it calls the parser again on its inner content to find nested cards/buttons.

    Rendering: The Handler calls the static Renderer in the Core library.

    HTML Injection: The parser replaces the :::...::: block with the resulting raw HTML, surrounded by newlines (\n\n) to ensure the Markdown engine treats it as a protected HTML block.

    Final Conversion: The modified string is passed to Markdig for final conversion to a full HTML page.



