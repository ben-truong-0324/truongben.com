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


Markdown

Check out our new portal here:
:::rcl-button text="Log In to Portal" color="Highlight" href="/login" isOutline="true" :::

Here is how to extract the HTML logic and wire it into the exact same Markdown processing pipeline you built for the cards.
Step 1: Extract the Button HTML Logic

Just like the card, we need a static builder that generates the raw Bootstrap HTML so both your TagHelper and your Markdown parser can use the exact same rendering engine.
C#

public static class ButtonHtmlBuilder
{
    public static string Build(string text, ButtonColor color, ButtonSize size, bool isOutline, bool isDisabled, bool isHover, string href)
    {
        var classes = new List<string> { "btn" };

        // 1. Resolve Color and Outline
        string outlineModifier = isOutline ? "-outline" : "";
        string colorString = color.ToString().ToLower();
        classes.Add($"btn{outlineModifier}-{colorString}");

        // 2. Resolve Size
        if (size == ButtonSize.Lg) classes.Add("btn-lg");
        else if (size == ButtonSize.Sm) classes.Add("btn-sm");
        else if (size == ButtonSize.Xs) classes.Add("btn-xs");

        // 3. Resolve States
        if (isDisabled) classes.Add("disabled");
        if (isHover) classes.Add("btn-hover");

        string classString = string.Join(" ", classes);

        // 4. Resolve Tag Type
        if (!string.IsNullOrWhiteSpace(href))
        {
            return $"<a href=\"{href}\" role=\"button\" class=\"{classString}\">{text}</a>";
        }
        else
        {
            string disabledAttr = isDisabled ? " disabled=\"disabled\"" : "";
            return $"<button{disabledAttr} class=\"{classString}\">{text}</button>";
        }
    }
}

(You can now replace the logic inside your ButtonTagHelper.Process method to simply call this Build method and output the result using output.Content.SetHtmlContent() and setting output.TagName = null;).
Step 2: Add the Button Parser to your Markdown Pipeline

We will add a new [GeneratedRegex] to your existing parser class that looks for the single-line button syntax.
C#

using System.Text.RegularExpressions;

public partial class MarkdownComponentParser // Renamed from MarkdownCardParser since it handles both now!
{
    // Match the single-line block: :::rcl-button [attributes] :::
    [GeneratedRegex(@":::rcl-button[ \t]+(.*?):::", RegexOptions.IgnoreCase)]
    private static partial Regex RclButtonRegex();

    // Your existing Attribute regex
    [GeneratedRegex(@"([a-zA-Z0-9_-]+)=""([^""]+)""")]
    private static partial Regex AttributeRegex();

    // Your existing ProcessCards method goes here...
    // public static string ProcessCards(string rawMarkdown) { ... }

    public static string ProcessButtons(string rawMarkdown)
    {
        return RclButtonRegex().Replace(rawMarkdown, match =>
        {
            string attributesString = match.Groups[1].Value;

            // 1. Parse the key="value" attributes
            var attributes = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
            foreach (Match attrMatch in AttributeRegex().Matches(attributesString))
            {
                attributes[attrMatch.Groups[1].Value] = attrMatch.Groups[2].Value;
            }

            // 2. Safely extract standard values
            string text = attributes.GetValueOrDefault("text", "Click Here");
            string href = attributes.GetValueOrDefault("href", string.Empty);

            // 3. Parse Enums safely
            ButtonColor color = ButtonColor.Primary;
            if (attributes.TryGetValue("color", out string? colorStr))
            {
                Enum.TryParse(colorStr, true, out color);
            }

            ButtonSize size = ButtonSize.Default;
            if (attributes.TryGetValue("size", out string? sizeStr))
            {
                Enum.TryParse(sizeStr, true, out size);
            }

            // 4. Parse Booleans safely
            bool.TryParse(attributes.GetValueOrDefault("isoutline", "false"), out bool isOutline);
            bool.TryParse(attributes.GetValueOrDefault("isdisabled", "false"), out bool isDisabled);
            bool.TryParse(attributes.GetValueOrDefault("ishover", "false"), out bool isHover);

            // 5. Generate the raw HTML string
            return ButtonHtmlBuilder.Build(text, color, size, isOutline, isDisabled, isHover, href);
        });
    }
}

Step 3: Run the full pipeline

Now, right before you pass the markdown to your final HTML converter, you just chain your component processors together.
C#

string markdownContent = File.ReadAllText(filePath);

// 1. Process custom extensions
string processedContent = MarkdownComponentParser.ProcessCards(markdownContent);
processedContent = MarkdownComponentParser.ProcessButtons(processedContent);

// 2. Convert to final HTML (using Markdig or whatever library you have)
string finalHtml = markdownToHtml(processedContent); 

A Quick Note on the text attribute

Because buttons are small, extracting the text from an attribute (text="Click Here") is much easier for your non-technical users than putting the text on a new line and closing it with a second ::: block. It prevents them from accidentally injecting markdown paragraphs inside a standard HTML button!