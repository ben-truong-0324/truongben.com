### taghelpre

using Microsoft.AspNetCore.Razor.TagHelpers;
using System.Threading.Tasks;

namespace MyComponentLibrary.TagHelpers
{
    public enum BlockquoteVariant
    {
        Default,
        NoGraphic,
        Prominent,
        Pull,
        WithImage
    }

    [HtmlTargetElement("rcl-blockquote")]
    public class BlockquoteTagHelper : TagHelper
    {
        public BlockquoteVariant Variant { get; set; } = BlockquoteVariant.Default;
        
        // The author/footer text
        public string Author { get; set; } = string.Empty;
        
        // Used only for the WithImage variant
        public string ImageSrc { get; set; } = string.Empty;
        public string ImageAlt { get; set; } = string.Empty;

        public override async Task ProcessAsync(TagHelperContext context, TagHelperOutput output)
        {
            var childContent = await output.GetChildContentAsync();
            var content = childContent.GetContent();

            // Only generate the footer if an author was provided
            string footerHtml = string.IsNullOrWhiteSpace(Author) 
                ? string.Empty 
                : $"<footer>{Author}</footer>";

            if (Variant == BlockquoteVariant.WithImage)
            {
                // The WithImage variant needs to be wrapped in a grid row
                output.TagName = "div";
                output.Attributes.SetAttribute("class", "row");
                
                output.Content.SetHtmlContent($@"
                    <div class=""col-md-4 text-right p-r-md p-t-sm"">
                        <img src=""{ImageSrc}"" class=""img-fluid img-circle height-150"" alt=""{ImageAlt}"" />
                    </div>
                    <div class=""col-md-8"">
                        <blockquote>
                            {content}
                            {footerHtml}
                        </blockquote>
                    </div>");
            }
            else
            {
                // All other variants are standard blockquotes with different classes
                output.TagName = "blockquote";
                
                switch (Variant)
                {
                    case BlockquoteVariant.NoGraphic:
                        output.Attributes.SetAttribute("class", "no-quotation-mark");
                        break;
                    case BlockquoteVariant.Prominent:
                        output.Attributes.SetAttribute("class", "prominent");
                        break;
                    case BlockquoteVariant.Pull:
                        output.Attributes.SetAttribute("class", "pull-quote");
                        break;
                }

                output.Content.SetHtmlContent($@"
                    {content}
                    {footerHtml}
                ");
            }
        }
    }
}

### cshtml use

<rcl-blockquote author="Holly Zuluaga">
    <p>Good quotes help to tell a story and enhance the credibility of a press release, news story, or speech. Words that are crafted well can leave a lasting impact on the world.</p>
</rcl-blockquote>

<rcl-blockquote variant="NoGraphic" author="Holly Zuluaga">
    <p>Good quotes help to tell a story and enhance the credibility...</p>
</rcl-blockquote>

<rcl-blockquote variant="Prominent" author="Holly Zuluaga">
    <p>Good quotes help to tell a story and enhance the credibility...</p>
</rcl-blockquote>

<rcl-blockquote variant="Pull" author="Holly Zuluaga">
    <p>Good quotes help to tell a story and enhance the credibility...</p>
</rcl-blockquote>

<rcl-blockquote 
    variant="WithImage" 
    author="Author" 
    image-src="https://template.webstandards.ca.gov/images/blockquote-with-image.jpg" 
    image-alt="Person's face">
    <p>You can pair a block quote with the image of related content or the author of the quote.</p>
</rcl-blockquote>

### docs

Blockquote Component (<rcl-blockquote>)

Renders stylized blockquotes adhering to the state template standards. It supports five variants, including an image-paired layout.
Properties
Attribute	Type	Default	Description
variant	BlockquoteVariant enum	Default	Visual style. Options: Default, NoGraphic, Prominent, Pull, WithImage.
author	string	""	The text to display inside the <footer> element. Optional.
image-src	string	""	The URL of the image. Required if variant is WithImage.
image-alt	string	""	The alt text for the image. Required if variant is WithImage.
Example
HTML

<rcl-blockquote variant="Prominent" author="Jane Doe">
    <p>This is a highly visible quote.</p>
</rcl-blockquote>


### tests

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
    public class BlockquoteTagHelpersTests
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
                    tagHelperContent.SetContent("<p>Test Quote</p>");
                    return Task.FromResult<TagHelperContent>(tagHelperContent);
                });

            return (context, output);
        }

        [TestMethod]
        public async Task BlockquoteTagHelper_DefaultVariant_RendersCorrectly()
        {
            // Arrange
            var helper = new BlockquoteTagHelper { Author = "Test Author" };
            var (context, output) = CreateTagHelperData("rcl-blockquote");

            // Act
            await helper.ProcessAsync(context, output);
            var content = output.Content.GetContent();

            // Assert
            Assert.AreEqual("blockquote", output.TagName);
            Assert.IsFalse(output.Attributes.ContainsName("class")); // Default has no class
            StringAssert.Contains(content, "<p>Test Quote</p>");
            StringAssert.Contains(content, "<footer>Test Author</footer>");
        }

        [TestMethod]
        public async Task BlockquoteTagHelper_ProminentVariant_AddsClass()
        {
            // Arrange
            var helper = new BlockquoteTagHelper { Variant = BlockquoteVariant.Prominent };
            var (context, output) = CreateTagHelperData("rcl-blockquote");

            // Act
            await helper.ProcessAsync(context, output);

            // Assert
            Assert.AreEqual("blockquote", output.TagName);
            Assert.AreEqual("prominent", output.Attributes["class"].Value);
        }

        [TestMethod]
        public async Task BlockquoteTagHelper_WithImageVariant_RendersGridStructure()
        {
            // Arrange
            var helper = new BlockquoteTagHelper 
            { 
                Variant = BlockquoteVariant.WithImage,
                Author = "Image Author",
                ImageSrc = "/test-img.jpg",
                ImageAlt = "Test Alt"
            };
            var (context, output) = CreateTagHelperData("rcl-blockquote");

            // Act
            await helper.ProcessAsync(context, output);
            var content = output.Content.GetContent();

            // Assert
            Assert.AreEqual("div", output.TagName);
            Assert.AreEqual("row", output.Attributes["class"].Value);
            
            // Check image setup
            StringAssert.Contains(content, "<div class=\"col-md-4 text-right p-r-md p-t-sm\">");
            StringAssert.Contains(content, "src=\"/test-img.jpg\"");
            StringAssert.Contains(content, "alt=\"Test Alt\"");
            
            // Check blockquote setup
            StringAssert.Contains(content, "<div class=\"col-md-8\">");
            StringAssert.Contains(content, "<blockquote>");
            StringAssert.Contains(content, "<p>Test Quote</p>");
            StringAssert.Contains(content, "<footer>Image Author</footer>");
        }

        [TestMethod]
        public async Task BlockquoteTagHelper_NoAuthor_OmitsFooter()
        {
            // Arrange
            var helper = new BlockquoteTagHelper { Variant = BlockquoteVariant.Default, Author = "" };
            var (context, output) = CreateTagHelperData("rcl-blockquote");

            // Act
            await helper.ProcessAsync(context, output);
            var content = output.Content.GetContent();

            // Assert
            Assert.AreEqual("blockquote", output.TagName);
            StringAssert.Contains(content, "<p>Test Quote</p>");
            Assert.IsFalse(content.Contains("<footer>"));
        }
    }

    [TestClass]
    public class BlockquoteIntegrationTests
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
        public async Task Blockquote_RendersCorrectHtml_OnPage()
        {
            // Act
            // Assume test page has: <rcl-blockquote variant="Pull" author="Int Test"><p>Integration</p></rcl-blockquote>
            var response = await _client.GetAsync("/BlockquoteTestPage");
            response.EnsureSuccessStatusCode();

            var responseString = await response.Content.ReadAsStringAsync();

            // Assert
            StringAssert.Contains(responseString, "<blockquote class=\"pull-quote\">");
            StringAssert.Contains(responseString, "<p>Integration</p>");
            StringAssert.Contains(responseString, "<footer>Int Test</footer>");
        }
    }
}



##############################


:::rcl-blockquote variant="WithImage" author="Jane Doe, Director" imagesrc="/assets/jane.jpg" imagealt="Headshot of Jane Doe"
Our commitment to accessible digital services ensures that every resident can get the help they need, when they need it.
:::

2. The Implementation

Just like the previous components, we will extract the HTML logic into a shared builder and then add a new Regex to your parser.
Step 1: The Blockquote HTML Builder

This mirrors your TagHelper logic exactly, separating the WithImage grid layout from the standard variants.
C#

public static class BlockquoteHtmlBuilder
{
    public static string Build(BlockquoteVariant variant, string author, string imageSrc, string imageAlt, string content)
    {
        string footerHtml = string.IsNullOrWhiteSpace(author) 
            ? string.Empty 
            : $"<footer>{author}</footer>";

        if (variant == BlockquoteVariant.WithImage)
        {
            // The WithImage variant uses a grid row instead of a base blockquote tag
            return $@"
                <div class=""row"" markdown=""1"">
                    <div class=""col-md-4 text-right p-r-md p-t-sm"">
                        <img src=""{imageSrc}"" class=""img-fluid img-circle height-150"" alt=""{imageAlt}"" />
                    </div>
                    <div class=""col-md-8"">
                        <blockquote>
                            {content}
                            {footerHtml}
                        </blockquote>
                    </div>
                </div>";
        }
        else
        {
            string cssClass = variant switch
            {
                BlockquoteVariant.NoGraphic => " class=\"no-quotation-mark\"",
                BlockquoteVariant.Prominent => " class=\"prominent\"",
                BlockquoteVariant.Pull => " class=\"pull-quote\"",
                _ => "" // Default
            };

            return $@"
                <blockquote{cssClass} markdown=""1"">
                    {content}
                    {footerHtml}
                </blockquote>";
        }
    }
}

(Note: I added markdown="1" to the wrappers here just like we did for Tabs, ensuring that if your users put bold or links inside their quotes, the Markdown engine still processes them!)
Step 2: The Blockquote Regex Parser

Add this alongside your other parsers in the MarkdownComponentParser class.
C#

using System.Text.RegularExpressions;
using System.Collections.Generic;
using System;

public partial class MarkdownComponentParser
{
    // Match the multi-line block: :::rcl-blockquote [attributes] \n [content] \n :::
    [GeneratedRegex(@"^:::rcl-blockquote[ \t]*(.*?)\r?\n(.*?)\r?\n:::", RegexOptions.Multiline | RegexOptions.Singleline)]
    private static partial Regex RclBlockquoteRegex();

    // Your existing AttributeRegex() handles the key="value" pairs

    public static string ProcessBlockquotes(string rawMarkdown)
    {
        return RclBlockquoteRegex().Replace(rawMarkdown, match =>
        {
            string attributesString = match.Groups[1].Value;
            string content = match.Groups[2].Value;

            // 1. Parse attributes
            var attributes = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
            foreach (Match attrMatch in AttributeRegex().Matches(attributesString))
            {
                attributes[attrMatch.Groups[1].Value] = attrMatch.Groups[2].Value;
            }

            // 2. Extract values
            string author = attributes.GetValueOrDefault("author", string.Empty);
            string imageSrc = attributes.GetValueOrDefault("imagesrc", string.Empty);
            string imageAlt = attributes.GetValueOrDefault("imagealt", string.Empty);

            // 3. Parse the Enum
            BlockquoteVariant variant = BlockquoteVariant.Default;
            if (attributes.TryGetValue("variant", out string? variantStr))
            {
                Enum.TryParse(variantStr, true, out variant);
            }

            // 4. Build and return the HTML
            return BlockquoteHtmlBuilder.Build(variant, author, imageSrc, imageAlt, content);
        });
    }
}

Step 3: Wire it into the Pipeline

Add the new processor to your Markdown processing chain. The order doesn't strictly matter as long as they all run before the final Markdown-to-HTML conversion.
C#

string processedContent = MarkdownComponentParser.ProcessCards(rawMarkdown);
processedContent = MarkdownComponentParser.ProcessButtons(processedContent);
processedContent = MarkdownComponentParser.ProcessTabs(processedContent);
processedContent = MarkdownComponentParser.ProcessBlockquotes(processedContent); // <--- Added here

string finalHtml = markdownToHtml(processedContent);