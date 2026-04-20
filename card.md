# tag helper

using Microsoft.AspNetCore.Razor.TagHelpers;
using System.Threading.Tasks;

namespace MyComponentLibrary.TagHelpers
{
    public enum CardVariant
    {
        Default,
        Icon,
        Image,
        Legacy
    }

    public enum LegacyCardType
    {
        Default,
        Understated,
        Standout,
        Overstated,
        Primary,
        Danger,
        Inverted,
        Info,
        Success,
        Warning
    }

    [HtmlTargetElement("rcl-card")]
    public class CardTagHelper : TagHelper
    {
        public CardVariant Variant { get; set; } = CardVariant.Default;
        
        // General Properties
        public string Title { get; set; } = string.Empty;
        public string Href { get; set; } = "javascript:;";
        
        // Grid Layout Modifier
        public bool IsGridItem { get; set; } 

        // Default & Legacy properties
        public string ButtonText { get; set; } = string.Empty;
        
        // Icon Variant property
        public string IconClass { get; set; } = "ca-gov-icon-info";
        
        // Image Variant properties
        public string ImageSrc { get; set; } = string.Empty;
        public string ImageAlt { get; set; } = string.Empty;

        // Legacy Variant property
        public LegacyCardType LegacyType { get; set; } = LegacyCardType.Default;

        public override async Task ProcessAsync(TagHelperContext context, TagHelperOutput output)
        {
            var childContent = await output.GetChildContentAsync();
            var content = childContent.GetContent();

            // Grid height modifiers
            string h100 = IsGridItem ? " h-100" : "";
            string flexInner = IsGridItem ? " h-100 d-flex flex-column" : "";
            string mtAuto = IsGridItem ? "mt-auto" : "m-t-md";

            // Strip the outer <rcl-card> tag, we will build the wrapper manually based on variant
            output.TagName = null;

            if (Variant == CardVariant.Icon)
            {
                output.Content.SetHtmlContent($@"
                    <article class=""no-underline d-block bg-gray-50 bg-gray-lightest-hover p-a-md pos-rel{h100}"">
                        <div class=""text-center p-b"">
                            <span class=""{IconClass} color-p2 color-p2-hover text-huge d-block"" aria-hidden=""true""></span>
                            <a href=""{Href}"" class=""h4 m-t-0 m-b color-gray-dark link-before text-left no-underline d-block"">{Title}</a>
                            <p class=""color-gray-dark text-left"">{content}</p>
                        </div>
                    </article>");
            }
            else if (Variant == CardVariant.Image)
            {
                output.Content.SetHtmlContent($@"
                    <div class=""card pos-rel{h100}"">
                        <img class=""card-img"" src=""{ImageSrc}"" alt=""{ImageAlt}"" />
                        <div class=""card-body bg-gray-50 bg-gray-100-hover{flexInner}"">
                            <h3 class=""card-title"">
                                <a href=""{Href}"" class=""link-before"">{Title}</a>
                            </h3>
                            <p>{content}</p>
                        </div>
                    </div>");
            }
            else if (Variant == CardVariant.Legacy)
            {
                // Determine Legacy Header structure
                bool useHeading = LegacyType is LegacyCardType.Default or LegacyCardType.Understated or LegacyCardType.Standout or LegacyCardType.Overstated;
                string headerClass = useHeading ? "card-heading" : "card-header";
                
                string standoutHtml = LegacyType == LegacyCardType.Standout ? "<span class=\"triangle\"></span><span class=\"triangle\"></span>" : "";
                string cardModifier = LegacyType == LegacyCardType.Standout ? "card-standout highlight" : $"card-{LegacyType.ToString().ToLower()}";

                string optionsHtml = string.IsNullOrWhiteSpace(ButtonText) ? "" : $@"<div class=""options""><a href=""{Href}"" class=""btn btn-default"">{ButtonText}</a></div>";

                output.Content.SetHtmlContent($@"
                    <div class=""card {cardModifier}{h100}"">
                        <div class=""{headerClass}"">
                            {standoutHtml}
                            <h3><span class=""{IconClass}"" aria-hidden=""true""></span> {Title}</h3>
                            {optionsHtml}
                        </div>
                        <div class=""card-body"">
                            {content}
                        </div>
                    </div>");
            }
            else // Default Text Card
            {
                string buttonHtml = string.IsNullOrWhiteSpace(ButtonText) 
                    ? "" 
                    : $@"<p class=""{mtAuto}""><a class=""btn btn-primary p-x-md"" href=""{Href}"">{ButtonText}</a></p>";

                output.Content.SetHtmlContent($@"
                    <div class=""card{h100}"">
                        <div class=""card-body bg-gray-50{flexInner}"">
                            <h3 class=""h4 m-y-sm"">{Title}</h3>
                            <p class=""m-b"">{content}</p>
                            {buttonHtml}
                        </div>
                    </div>");
            }
        }
    }
}

# cshtml use
<div class="row">
    <div class="col-md-4 m-b-md">
        <rcl-card variant="Default" title="Card Title" button-text="Learn More" href="/link" is-grid-item="true">
            Use this space to briefly tell your reader what they will find at the card's destination.
        </rcl-card>
    </div>

    <div class="col-md-4 m-b-md">
        <rcl-card variant="Icon" title="Infographic" icon-class="ca-gov-icon-clipboard" href="/link" is-grid-item="true">
            Commonly recognized by visitors and generally reserved for data-rich visualization.
        </rcl-card>
    </div>

    <div class="col-md-4 m-b-md">
        <rcl-card variant="Image" title="Give your card a short title" image-src="/sunflower.jpg" image-alt="Sunflower" href="/link" is-grid-item="true">
            Briefly tell your reader what they will find at the card's destination then link to that location.
        </rcl-card>
    </div>
</div>

<rcl-card variant="Legacy" legacy-type="Standout" title="Card (Standout Highlight)" button-text="button">
    Card Body
</rcl-card>

<rcl-card variant="Legacy" legacy-type="Primary" title="Card (Primary)" button-text="button" icon-class="ca-gov-icon-info">
    Card Body
</rcl-card>

# docs

Card Component (<rcl-card>)

Generates compliant card blocks according to the state template. Automatically handles inner flex properties when utilized inside CSS grids.
Setup

Ensure the Tag Helpers are registered in your _ViewImports.cshtml:
HTML

@addTagHelper *, MyComponentLibrary

Properties
Attribute	Type	Default	Description
variant	CardVariant	Default	Visual structure. Options: Default, Icon, Image, Legacy.
title	string	""	The card's heading text.
href	string	"javascript:;"	Destination for the card's action button or clickable title.
is-grid-item	bool	false	If true, applies h-100 and flex-column to stretch evenly in a Bootstrap row.
button-text	string	""	Generates a primary button on Default and Legacy cards if populated.
icon-class	string	"ca-gov-icon-info"	CSS class for the icon (used by Icon and Legacy variants).
image-src	string	""	URL to the image (Required if variant is Image).
image-alt	string	""	Alt text for the image (Required if variant is Image).
legacy-type	LegacyCardType	Default	Determines color styling if variant is Legacy (e.g., Standout, Primary).

# tests

using Microsoft.VisualStudio.TestTools.UnitTesting;
using Microsoft.AspNetCore.Razor.TagHelpers;
using MyComponentLibrary.TagHelpers;
using System.Collections.Generic;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc.Testing;
using System.Net.Http;
using MyComponentLibrary.TestHost; 

namespace MyComponentLibrary.Tests
{
    [TestClass]
    public class CardTagHelpersTests
    {
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
                    tagHelperContent.SetContent("Card Body Content");
                    return Task.FromResult<TagHelperContent>(tagHelperContent);
                });

            return (context, output);
        }

        [TestMethod]
        public async Task CardTagHelper_DefaultVariant_RendersCorrectly()
        {
            // Arrange
            var helper = new CardTagHelper { Variant = CardVariant.Default, Title = "Test Title", ButtonText = "Click Me" };
            var (context, output) = CreateTagHelperData("rcl-card");

            // Act
            await helper.ProcessAsync(context, output);
            var content = output.Content.GetContent();

            // Assert
            Assert.IsNull(output.TagName); // Ensure wrapper is stripped
            StringAssert.Contains(content, "<div class=\"card\">");
            StringAssert.Contains(content, "<h3 class=\"h4 m-y-sm\">Test Title</h3>");
            StringAssert.Contains(content, "Card Body Content");
            StringAssert.Contains(content, ">Click Me</a>");
        }

        [TestMethod]
        public async Task CardTagHelper_GridItem_AppendsHeightClasses()
        {
            // Arrange
            var helper = new CardTagHelper { Variant = CardVariant.Default, IsGridItem = true };
            var (context, output) = CreateTagHelperData("rcl-card");

            // Act
            await helper.ProcessAsync(context, output);
            var content = output.Content.GetContent();

            // Assert
            StringAssert.Contains(content, "class=\"card h-100\"");
            StringAssert.Contains(content, "class=\"card-body bg-gray-50 h-100 d-flex flex-column\"");
        }

        [TestMethod]
        public async Task CardTagHelper_ImageVariant_RendersImageAndLinkBefore()
        {
            // Arrange
            var helper = new CardTagHelper 
            { 
                Variant = CardVariant.Image, 
                Title = "Img Title", 
                ImageSrc = "/test.jpg",
                ImageAlt = "Test Alt"
            };
            var (context, output) = CreateTagHelperData("rcl-card");

            // Act
            await helper.ProcessAsync(context, output);
            var content = output.Content.GetContent();

            // Assert
            StringAssert.Contains(content, "<img class=\"card-img\" src=\"/test.jpg\" alt=\"Test Alt\"");
            StringAssert.Contains(content, "class=\"link-before\">Img Title</a>");
        }

        [TestMethod]
        public async Task CardTagHelper_LegacyStandout_RendersTriangles()
        {
            // Arrange
            var helper = new CardTagHelper { Variant = CardVariant.Legacy, LegacyType = LegacyCardType.Standout };
            var (context, output) = CreateTagHelperData("rcl-card");

            // Act
            await helper.ProcessAsync(context, output);
            var content = output.Content.GetContent();

            // Assert
            StringAssert.Contains(content, "class=\"card card-standout highlight\"");
            StringAssert.Contains(content, "class=\"card-heading\"");
            StringAssert.Contains(content, "<span class=\"triangle\"></span><span class=\"triangle\"></span>");
        }
    }

    [TestClass]
    public class CardIntegrationTests
    {
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
        public async Task Card_RendersCorrectHtml_OnPage()
        {
            // Act
            // Assume page has: <rcl-card variant="Icon" title="Int Test" icon-class="ca-gov-icon-test">Int Content</rcl-card>
            var response = await _client.GetAsync("/CardTestPage");
            response.EnsureSuccessStatusCode();
            var responseString = await response.Content.ReadAsStringAsync();

            // Assert
            StringAssert.Contains(responseString, "<article class=\"no-underline d-block bg-gray-50");
            StringAssert.Contains(responseString, "ca-gov-icon-test");
            StringAssert.Contains(responseString, "Int Test");
            StringAssert.Contains(responseString, "Int Content");
        }
    }
}



###################

Give them a syntax that uses the fenced block style (:::) with simple key="value" attributes on the opening line. It feels exactly like writing a standard Markdown code block, which most users are already comfortable with.

What they will write:
Markdown

:::rcl-card variant="Icon" title="Online Services" icon="ca-gov-icon-computer" href="/services"
Here is the description of the service they are looking for.
:::

2. The Architectural "Gotcha" (The TagHelper Trap)

There is a massive trap here: TagHelpers only execute on physical .cshtml files during the Razor compile/render pipeline. If you convert a Markdown string to HTML at runtime and use @Html.Raw() to display it, Razor will completely ignore the <rcl-card> tags. The browser will receive <rcl-card>, not know what it is, and fail to render your state design system styles (like those ca-gov classes).

The Solution: You need your Markdown pipeline to output the raw Bootstrap HTML directly, bypassing the TagHelper. To keep your code DRY, we will extract the HTML-generating logic out of your TagHelper and into a shared CardHtmlBuilder that both your TagHelper and your Markdown parser can use.
3. The Implementation
Step 1: Extract the HTML Logic

Create a static builder so you aren't duplicating HTML strings.
C#

public static class CardHtmlBuilder
{
    // Pass in a simple data object or dictionary of your properties
    public static string Build(CardVariant variant, string title, string href, string iconClass, string content, bool isGridItem = false, string buttonText = "")
    {
        string h100 = isGridItem ? " h-100" : "";
        string flexInner = isGridItem ? " h-100 d-flex flex-column" : "";
        string mtAuto = isGridItem ? "mt-auto" : "m-t-md";

        if (variant == CardVariant.Icon)
        {
            return $@"
                <article class=""no-underline d-block bg-gray-50 bg-gray-lightest-hover p-a-md pos-rel{h100}"">
                    <div class=""text-center p-b"">
                        <span class=""{iconClass} color-p2 color-p2-hover text-huge d-block"" aria-hidden=""true""></span>
                        <a href=""{href}"" class=""h4 m-t-0 m-b color-gray-dark link-before text-left no-underline d-block"">{title}</a>
                        <p class=""color-gray-dark text-left"">{content}</p>
                    </div>
                </article>";
        }
        
        // ... (Add your other variant if-statements here exactly as they were) ...
        
        return ""; 
    }
}

(Now, update your CardTagHelper's ProcessAsync method to simply call this builder and set output.Content.SetHtmlContent(...)).
Step 2: The Markdown Pre-Processor

Since we just got your [GeneratedRegex] working in the previous steps, we can use that exact same high-performance pattern to find and replace these blocks before you pass the string to your Markdown-to-HTML converter.
C#

using System.Text.RegularExpressions;

public partial class MarkdownCardParser
{
    // Matches the block: :::rcl-card [attributes] \n [content] \n :::
    // Singleline makes '.' match newlines. Multiline makes '^' match line starts.
    [GeneratedRegex(@"^:::rcl-card[ \t]*(.*?)\r?\n(.*?)\r?\n:::", RegexOptions.Multiline | RegexOptions.Singleline)]
    private static partial Regex RclCardBlockRegex();

    // Matches key="value" pairs
    [GeneratedRegex(@"([a-zA-Z0-9_-]+)=""([^""]+)""")]
    private static partial Regex AttributeRegex();

    public static string ProcessCards(string rawMarkdown)
    {
        return RclCardBlockRegex().Replace(rawMarkdown, match =>
        {
            string attributesString = match.Groups[1].Value;
            string content = match.Groups[2].Value; // The Markdown inside the card

            // 1. Parse the key="value" attributes into a dictionary
            var attributes = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
            foreach (Match attrMatch in AttributeRegex().Matches(attributesString))
            {
                attributes[attrMatch.Groups[1].Value] = attrMatch.Groups[2].Value;
            }

            // 2. Safely extract values with defaults
            string title = attributes.GetValueOrDefault("title", string.Empty);
            string href = attributes.GetValueOrDefault("href", "javascript:;");
            string iconClass = attributes.GetValueOrDefault("icon", "ca-gov-icon-info");
            
            // Parse the enum safely
            CardVariant variant = CardVariant.Default;
            if (attributes.TryGetValue("variant", out string? variantStr))
            {
                Enum.TryParse(variantStr, true, out variant);
            }

            // 3. (Optional) If you want the inner text to support bold/italics, 
            // you might want to run your markdownToHtml Func on the 'content' string here!

            // 4. Generate the raw HTML string
            return CardHtmlBuilder.Build(variant, title, href, iconClass, content);
        });
    }
}

Step 3: Wire it into your Pipeline

Wherever you are calling your Markdown converter, just run this pre-processor first.
C#

string markdownContent = File.ReadAllText(filePath);

// 1. Convert the custom ::: directives directly into Bootstrap HTML
string processedMarkdown = MarkdownCardParser.ProcessCards(markdownContent);

// 2. Pass the result to your standard Markdown pipeline (e.g., Markdig)
string finalHtml = markdownToHtml(processedMarkdown);