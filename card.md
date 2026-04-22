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





The Shared Models: The Enums and a Data Class.

    The Static Renderer: The pure logic that spits out HTML strings.

    The Consumers: Your TagHelper and your MarkdownRclParser will both call that renderer.

1. The Shared Definitions (RclCardModels.cs)

Move these out of the TagHelper file so they are accessible everywhere in your project.
C#

namespace MyComponentLibrary.Models
{
    public enum CardVariant { Default, Icon, Image, Legacy }

    public enum LegacyCardType
    {
        Default, Understated, Standout, Overstated, 
        Primary, Danger, Inverted, Info, Success, Warning
    }

    // A simple DTO to pass data between the parser/taghelper and the renderer
    public class CardProperties
    {
        public CardVariant Variant { get; set; } = CardVariant.Default;
        public string Title { get; set; } = string.Empty;
        public string Href { get; set; } = "javascript:;";
        public bool IsGridItem { get; set; }
        public string ButtonText { get; set; } = string.Empty;
        public string IconClass { get; set; } = "ca-gov-icon-info";
        public string ImageSrc { get; set; } = string.Empty;
        public string ImageAlt { get; set; } = string.Empty;
        public LegacyCardType LegacyType { get; set; } = LegacyCardType.Default;
        public string Content { get; set; } = string.Empty;
    }
}

2. The Portable Renderer (RclCardRenderer.cs)

This class has no dependencies on Razor or Regex. It just takes a CardProperties object and returns a string.
C#

using MyComponentLibrary.Models;

namespace MyComponentLibrary.Renderers;

public static class RclCardRenderer
{
    public static string Render(CardProperties p)
    {
        string h100 = p.IsGridItem ? " h-100" : "";
        string flexInner = p.IsGridItem ? " h-100 d-flex flex-column" : "";
        string mtAuto = p.IsGridItem ? "mt-auto" : "m-t-md";

        return p.Variant switch
        {
            CardVariant.Icon => RenderIconCard(p, h100),
            CardVariant.Image => RenderImageCard(p, h100, flexInner),
            CardVariant.Legacy => RenderLegacyCard(p, h100),
            _ => RenderDefaultCard(p, h100, flexInner, mtAuto)
        };
    }

    private static string RenderIconCard(CardProperties p, string h100) => $@"
        <article class=""no-underline d-block bg-gray-50 bg-gray-lightest-hover p-a-md pos-rel{h100}"">
            <div class=""text-center p-b"">
                <span class=""{p.IconClass} color-p2 color-p2-hover text-huge d-block"" aria-hidden=""true""></span>
                <a href=""{p.Href}"" class=""h4 m-t-0 m-b color-gray-dark link-before text-left no-underline d-block"">{p.Title}</a>
                <div class=""color-gray-dark text-left"">{p.Content}</div>
            </div>
        </article>";

    private static string RenderImageCard(CardProperties p, string h100, string flexInner) => $@"
        <div class=""card pos-rel{h100}"">
            <img class=""card-img"" src=""{p.ImageSrc}"" alt=""{p.ImageAlt}"" />
            <div class=""card-body bg-gray-50 bg-gray-100-hover{flexInner}"">
                <h3 class=""card-title""><a href=""{p.Href}"" class=""link-before"">{p.Title}</a></h3>
                <div>{p.Content}</div>
            </div>
        </div>";

    private static string RenderLegacyCard(CardProperties p, string h100)
    {
        bool useHeading = p.LegacyType is LegacyCardType.Default or LegacyCardType.Understated or LegacyCardType.Standout or LegacyCardType.Overstated;
        string headerClass = useHeading ? "card-heading" : "card-header";
        string standoutHtml = p.LegacyType == LegacyCardType.Standout ? "<span class=\"triangle\"></span><span class=\"triangle\"></span>" : "";
        string cardModifier = p.LegacyType == LegacyCardType.Standout ? "card-standout highlight" : $"card-{p.LegacyType.ToString().ToLower()}";
        string optionsHtml = string.IsNullOrWhiteSpace(p.ButtonText) ? "" : $@"<div class=""options""><a href=""{p.Href}"" class=""btn btn-default"">{p.ButtonText}</a></div>";

        return $@"
            <div class=""card {cardModifier}{h100}"">
                <div class=""{headerClass}"">
                    {standoutHtml}
                    <h3><span class=""{p.IconClass}"" aria-hidden=""true""></span> {p.Title}</h3>
                    {optionsHtml}
                </div>
                <div class=""card-body"">{p.Content}</div>
            </div>";
    }

    private static string RenderDefaultCard(CardProperties p, string h100, string flexInner, string mtAuto)
    {
        string buttonHtml = string.IsNullOrWhiteSpace(p.ButtonText) ? "" : $@"<p class=""{mtAuto}""><a class=""btn btn-primary p-x-md"" href=""{p.Href}"">{p.ButtonText}</a></p>";
        return $@"
            <div class=""card{h100}"">
                <div class=""card-body bg-gray-50{flexInner}"">
                    <h3 class=""h4 m-y-sm"">{p.Title}</h3>
                    <div class=""m-b"">{p.Content}</div>
                    {buttonHtml}
                </div>
            </div>";
    }
}

3. The Lean TagHelper (CardTagHelper.cs)

Now your TagHelper is just a wrapper that collects properties and passes them to the renderer.
C#

using Microsoft.AspNetCore.Razor.TagHelpers;
using MyComponentLibrary.Models;
using MyComponentLibrary.Renderers;

namespace MyComponentLibrary.TagHelpers;

[HtmlTargetElement("rcl-card")]
public class CardTagHelper : TagHelper
{
    public CardVariant Variant { get; set; } = CardVariant.Default;
    public string Title { get; set; } = string.Empty;
    public string Href { get; set; } = "javascript:;";
    public bool IsGridItem { get; set; } 
    public string ButtonText { get; set; } = string.Empty;
    public string IconClass { get; set; } = "ca-gov-icon-info";
    public string ImageSrc { get; set; } = string.Empty;
    public string ImageAlt { get; set; } = string.Empty;
    public LegacyCardType LegacyType { get; set; } = LegacyCardType.Default;

    public override async Task ProcessAsync(TagHelperContext context, TagHelperOutput output)
    {
        var childContent = await output.GetChildContentAsync();
        output.TagName = null; // Remove <rcl-card>

        var props = new CardProperties {
            Variant = this.Variant,
            Title = this.Title,
            Href = this.Href,
            IsGridItem = this.IsGridItem,
            ButtonText = this.ButtonText,
            IconClass = this.IconClass,
            ImageSrc = this.ImageSrc,
            ImageAlt = this.ImageAlt,
            LegacyType = this.LegacyType,
            Content = childContent.GetContent()
        };

        output.Content.SetHtmlContent(RclCardRenderer.Render(props));
    }
}

4. The Markdown Handler (CardHandler.cs)

This lives in your Markdown folder and uses the exact same logic.
C#

using MyComponentLibrary.Models;
using MyComponentLibrary.Renderers;

public class CardHandler : IRclComponentHandler
{
    public string Render(Dictionary<string, string> attrs, string htmlContent)
    {
        Enum.TryParse(attrs.GetValueOrDefault("variant", "Default"), true, out CardVariant variant);
        Enum.TryParse(attrs.GetValueOrDefault("legacytype", "Default"), true, out LegacyCardType legacy);

        var props = new CardProperties
        {
            Variant = variant,
            LegacyType = legacy,
            Title = attrs.GetValueOrDefault("title", ""),
            Href = attrs.GetValueOrDefault("href", "#"),
            IconClass = attrs.GetValueOrDefault("icon", "ca-gov-icon-info"),
            ButtonText = attrs.GetValueOrDefault("buttontext", ""),
            ImageSrc = attrs.GetValueOrDefault("src", ""),
            ImageAlt = attrs.GetValueOrDefault("alt", ""),
            IsGridItem = attrs.ContainsKey("griditem"), // check if key exists for bools
            Content = htmlContent
        };

        return RclCardRenderer.Render(props);
    }
}