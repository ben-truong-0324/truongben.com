### DTO

using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Razor.TagHelpers;
using WTS.RazorComponentLibrary.Models.Helpers; // Assuming RequiredIf lives here

namespace WTS.RazorComponentLibrary.Models.RclComponents
{
    public enum BlockquoteVariant
    {
        Default,
        NoGraphic,
        Prominent,
        Pull,
        WithImage
    }

    public class BlockquoteProperties
    {
        public BlockquoteVariant Variant { get; set; } = BlockquoteVariant.Default;
        
        public string Author { get; set; } = string.Empty;
        
        public string ImageSrc { get; set; } = string.Empty;

        [RequiredIf("Variant", BlockquoteVariant.WithImage, ErrorMessage = "ImageAlt is required for ADA compliance when using the WithImage variant.")]
        public string ImageAlt { get; set; } = string.Empty;

        [HtmlAttributeNotBound]
        [Required(AllowEmptyStrings = false, ErrorMessage = "Blockquote content is required.")]
        public string Content { get; set; } = string.Empty;
    }
}

### TagHelper

using Microsoft.AspNetCore.Razor.TagHelpers;
using System.Threading.Tasks;
using System.ComponentModel.DataAnnotations;
using WTS.RazorComponentLibrary.Models.RclComponents;
using WTS.RazorComponentLibrary.Renderers;

namespace WTS.RazorLibrary.TagHelpers
{
    [HtmlTargetElement("rcl-blockquote")]
    public class BlockquoteHelper : BlockquoteProperties, ITagHelper
    {
        public int Order => 0;
        public void Init(TagHelperContext context) { }

        public async Task ProcessAsync(TagHelperContext context, TagHelperOutput output)
        {
            var childContent = await output.GetChildContentAsync();
            this.Content = childContent.GetContent().Trim();

            // Run validation (this will catch missing Alt Text on images)
            var validationContext = new ValidationContext(this);
            Validator.ValidateObject(this, validationContext, validateAllProperties: true);

            // Strip the <rcl-blockquote> tag as the renderer handles the wrapper
            output.TagName = null;

            var htmlResult = RclBlockquoteRenderer.Render(this);
            output.Content.SetHtmlContent(htmlResult);
        }
    }
}

### Renderer

using WTS.RazorComponentLibrary.Models.RclComponents;

namespace WTS.RazorComponentLibrary.Renderers
{
    public static class RclBlockquoteRenderer
    {
        public static string Render(BlockquoteProperties p)
        {
            string footerHtml = string.IsNullOrWhiteSpace(p.Author) 
                ? string.Empty 
                : $"<footer>{p.Author}</footer>";

            if (p.Variant == BlockquoteVariant.WithImage)
            {
                return $@"
                    <div class=""row"">
                        <div class=""col-md-4 text-right p-r-md p-t-sm"">
                            <img src=""{p.ImageSrc}"" class=""img-fluid img-circle height-150"" alt=""{p.ImageAlt}"" />
                        </div>
                        <div class=""col-md-8"">
                            <blockquote>
                                {p.Content}
                                {footerHtml}
                            </blockquote>
                        </div>
                    </div>";
            }

            string cssClass = p.Variant switch
            {
                BlockquoteVariant.NoGraphic => " class=\"no-quotation-mark\"",
                BlockquoteVariant.Prominent => " class=\"prominent\"",
                BlockquoteVariant.Pull => " class=\"pull-quote\"",
                _ => string.Empty
            };

            return $@"
                <blockquote{cssClass}>
                    {p.Content}
                    {footerHtml}
                </blockquote>";
        }
    }
}

### test

using Microsoft.VisualStudio.TestTools.UnitTesting;
using Microsoft.AspNetCore.Razor.TagHelpers;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Threading.Tasks;
using WTS.RazorComponentLibrary.Models.RclComponents;
using WTS.RazorComponentLibrary.Renderers;
using WTS.RazorLibrary.TagHelpers;

namespace WTS.RazorLibrary.Tests
{
    [TestClass]
    public class BlockquoteTests
    {
        // --- 1. Property Validation Tests ---

        [TestMethod]
        [ExpectedException(typeof(ValidationException))]
        public void Properties_WithImageVariant_MissingAltText_ThrowsValidationException()
        {
            // Arrange
            var props = new BlockquoteProperties
            {
                Variant = BlockquoteVariant.WithImage,
                ImageSrc = "/images/portrait.jpg",
                ImageAlt = string.Empty, // Invalid: Alt text required for ADA when using image
                Content = "A great quote."
            };
            var context = new ValidationContext(props);

            // Act
            Validator.ValidateObject(props, context, validateAllProperties: true);
        }

        [TestMethod]
        public void Properties_WithImageVariant_ValidAltText_PassesValidation()
        {
            // Arrange
            var props = new BlockquoteProperties
            {
                Variant = BlockquoteVariant.WithImage,
                ImageSrc = "/images/portrait.jpg",
                ImageAlt = "Portrait of the author",
                Content = "A great quote."
            };
            var context = new ValidationContext(props);

            // Act & Assert (Should not throw)
            Validator.ValidateObject(props, context, validateAllProperties: true);
        }

        // --- 2. Renderer Tests ---

        [TestMethod]
        public void Renderer_WithImageVariant_RendersGridRowAndImage()
        {
            // Arrange
            var props = new BlockquoteProperties
            {
                Variant = BlockquoteVariant.WithImage,
                ImageSrc = "img.png",
                ImageAlt = "alt text",
                Content = "Image quote content"
            };

            // Act
            var result = RclBlockquoteRenderer.Render(props);

            // Assert
            Assert.IsTrue(result.Contains("<div class=\"row\">"));
            Assert.IsTrue(result.Contains("<img src=\"img.png\""));
            Assert.IsTrue(result.Contains("alt=\"alt text\""));
            Assert.IsTrue(result.Contains("<blockquote>"));
            Assert.IsFalse(result.Contains("<footer>")); // No author provided
        }

        [TestMethod]
        public void Renderer_PullVariantWithAuthor_RendersClassAndFooter()
        {
            // Arrange
            var props = new BlockquoteProperties
            {
                Variant = BlockquoteVariant.Pull,
                Content = "Pull quote text.",
                Author = "Jane Doe"
            };

            // Act
            var result = RclBlockquoteRenderer.Render(props);

            // Assert
            Assert.IsTrue(result.Contains("<blockquote class=\"pull-quote\">"));
            Assert.IsTrue(result.Contains("<footer>Jane Doe</footer>"));
            Assert.IsTrue(result.Contains("Pull quote text."));
        }

        // --- 3. Tag Helper Execution Tests ---

        private (TagHelperContext, TagHelperOutput) CreateTagHelperEssentials(string childContentText)
        {
            var context = new TagHelperContext(
                new TagHelperAttributeList(),
                new Dictionary<object, object>(),
                "test-id");

            var childContent = new DefaultTagHelperContent();
            childContent.SetHtmlContent(childContentText);

            var output = new TagHelperOutput(
                "rcl-blockquote",
                new TagHelperAttributeList(),
                (useCachedResult, encoder) => Task.FromResult<TagHelperContent>(childContent));

            return (context, output);
        }

        [TestMethod]
        public async Task Helper_ProcessAsync_StripsOriginalTagAndRendersHtml()
        {
            // Arrange
            var (context, output) = CreateTagHelperEssentials("Standard quote text.");
            var helper = new BlockquoteHelper
            {
                Variant = BlockquoteVariant.Prominent,
                Author = "John Smith"
            };

            // Act
            await helper.ProcessAsync(context, output);

            // Assert
            Assert.IsNull(output.TagName); // <rcl-blockquote> should be stripped
            
            var finalHtml = output.Content.GetContent();
            Assert.IsTrue(finalHtml.Contains("<blockquote class=\"prominent\">"));
            Assert.IsTrue(finalHtml.Contains("Standard quote text."));
            Assert.IsTrue(finalHtml.Contains("<footer>John Smith</footer>"));
        }
    }
}