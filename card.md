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




using Microsoft.VisualStudio.TestTools.UnitTesting;
using MyProject.Rcl.Core.Models;
using MyProject.Rcl.Core.Renderers;

namespace MyComponentLibrary.Tests
{
    [TestClass]
    public class RclCardRendererTests
    {
        [TestMethod]
        public void Render_DefaultVariant_ProducesValidBootstrapHtml()
        {
            // Arrange
            var props = new CardProperties {
                Variant = CardVariant.Default,
                Title = "Test Title",
                Content = "Card Body Content",
                ButtonText = "Click Me"
            };

            // Act
            var html = RclCardRenderer.Render(props);

            // Assert
            StringAssert.Contains(html, "<div class=\"card\">");
            StringAssert.Contains(html, "Test Title");
            StringAssert.Contains(html, "Card Body Content");
            StringAssert.Contains(html, "Click Me");
        }

        [TestMethod]
        public void Render_GridItem_AppendsH100Classes()
        {
            var props = new CardProperties { IsGridItem = true };
            var html = RclCardRenderer.Render(props);

            StringAssert.Contains(html, "class=\"card h-100\"");
            StringAssert.Contains(html, "d-flex flex-column");
        }

        [TestMethod]
        public void Render_LegacyStandout_IncludesTriangles()
        {
            var props = new CardProperties { 
                Variant = CardVariant.Legacy, 
                LegacyType = LegacyCardType.Standout 
            };
            
            var html = RclCardRenderer.Render(props);

            StringAssert.Contains(html, "card-standout highlight");
            StringAssert.Contains(html, "<span class=\"triangle\"></span>");
        }
    }
}

2. The Slimmed TagHelper Tests (CardTagHelperTests.cs)

These ensure that your CardTagHelper properties correctly map to the output. We keep one or two here just to ensure the "glue" is working.
C#

[TestClass]
public class CardTagHelperTests
{
    private (TagHelperContext, TagHelperOutput) CreateTagHelperData()
    {
        var context = new TagHelperContext(new TagHelperAttributeList(), new Dictionary<object, object>(), "test");
        var output = new TagHelperOutput("rcl-card", new TagHelperAttributeList(), (useCachedResult, encoder) => {
            var content = new DefaultTagHelperContent();
            content.SetContent("Inner Content");
            return Task.FromResult<TagHelperContent>(content);
        });
        return (context, output);
    }

    [TestMethod]
    public async Task ProcessAsync_PassesPropertiesToRenderer()
    {
        // Arrange
        var helper = new CardTagHelper { 
            Title = "TagHelper Title", 
            Variant = CardVariant.Icon,
            IconClass = "custom-icon"
        };
        var (context, output) = CreateTagHelperData();

        // Act
        await helper.ProcessAsync(context, output);
        var result = output.Content.GetContent();

        // Assert
        Assert.IsNull(output.TagName); // Wrapper stripped
        StringAssert.Contains(result, "custom-icon");
        StringAssert.Contains(result, "TagHelper Title");
    }
}

3. The New Markdown Tests (MarkdownRclTests.cs)

Since you wanted your non-technical users to use this, we need to test the Markdown Parser → Handler → Renderer flow.
C#

[TestClass]
public class MarkdownRclTests
{
    [TestMethod]
    public void Process_CardComponent_RendersHtmlSuccessfully()
    {
        // Arrange
        var pipeline = new Markdig.MarkdownPipelineBuilder().Build();
        var parser = new MyProject.Markdown.MarkdownRclParser(pipeline);
        
        string markdown = @":::rcl-card title=""MD Card"" variant=""Icon""
This is **bold** content.
:::";

        // Act
        var result = parser.Process(markdown);

        // Assert
        StringAssert.Contains(result, "<article class=\"no-underline"); // Check it chose the Icon variant
        StringAssert.Contains(result, "MD Card");
        StringAssert.Contains(result, "<strong>bold</strong>"); // Check that inner markdown worked!
    }
}

