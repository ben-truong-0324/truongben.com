### DTO

using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Razor.TagHelpers;

namespace WTS.RazorComponentLibrary.Models.RclComponents
{
    public class FeaturedCardProperties
    {
        [Required(AllowEmptyStrings = false, ErrorMessage = "Button text is required for screen readers and UI.")]
        public string ButtonText { get; set; } = string.Empty;
        
        public string ButtonHref { get; set; } = "javascript:;";
        
        public string ButtonAriaLabel { get; set; } = string.Empty;

        public string ImageSrc { get; set; } = string.Empty;

        [Required(AllowEmptyStrings = false, ErrorMessage = "Image Alt text is required for ADA compliance.")]
        public string ImageAlt { get; set; } = string.Empty;

        public string ImageHref { get; set; } = string.Empty;

        [HtmlAttributeNotBound]
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
    [HtmlTargetElement("rcl-featured-card")]
    public class FeaturedCardHelper : FeaturedCardProperties, ITagHelper
    {
        public int Order => 0;
        public void Init(TagHelperContext context) { }

        public async Task ProcessAsync(TagHelperContext context, TagHelperOutput output)
        {
            var childContent = await output.GetChildContentAsync();
            this.Content = childContent.GetContent().Trim();

            var validationContext = new ValidationContext(this);
            Validator.ValidateObject(this, validationContext, validateAllProperties: true);

            // Strip the <rcl-featured-card> wrapper
            output.TagName = null;

            var htmlResult = RclFeaturedCardRenderer.Render(this);
            output.Content.SetHtmlContent(htmlResult);
        }
    }
}

### Renderer

using WTS.RazorComponentLibrary.Models.RclComponents;

namespace WTS.RazorComponentLibrary.Renderers
{
    public static class RclFeaturedCardRenderer
    {
        public static string Render(FeaturedCardProperties p)
        {
            // Resolve Image Link fallback
            string finalImageHref = string.IsNullOrWhiteSpace(p.ImageHref) ? p.ButtonHref : p.ImageHref;

            // Build accessible button label span
            string ariaLabelHtml = string.IsNullOrWhiteSpace(p.ButtonAriaLabel)
                ? string.Empty
                : $" <span class=\"sr-only\">{p.ButtonAriaLabel}</span>";

            return $@"
                <div class=""card featured-card"">
                    <a href=""{finalImageHref}"" tabindex=""-1"" aria-hidden=""true"">
                        <img class=""card-img-top"" src=""{p.ImageSrc}"" alt=""{p.ImageAlt}"" />
                    </a>
                    <div class=""card-body"">
                        <div class=""card-text"">
                            {p.Content}
                        </div>
                        <a href=""{p.ButtonHref}"" class=""btn btn-primary"">
                            {p.ButtonText}{ariaLabelHtml}
                        </a>
                    </div>
                </div>";
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
    public class FeaturedCardTests
    {
        // --- 1. Property Validation Tests ---

        [TestMethod]
        [ExpectedException(typeof(ValidationException))]
        public void Properties_MissingImageAlt_ThrowsValidationException()
        {
            // Arrange
            var props = new FeaturedCardProperties
            {
                ButtonText = "Read More",
                ImageAlt = string.Empty // Invalid: Requires Alt Text
            };
            var context = new ValidationContext(props);

            // Act
            Validator.ValidateObject(props, context, validateAllProperties: true);
        }

        [TestMethod]
        [ExpectedException(typeof(ValidationException))]
        public void Properties_MissingButtonText_ThrowsValidationException()
        {
            // Arrange
            var props = new FeaturedCardProperties
            {
                ImageAlt = "A descriptive image",
                ButtonText = string.Empty // Invalid: Requires Button Text
            };
            var context = new ValidationContext(props);

            // Act
            Validator.ValidateObject(props, context, validateAllProperties: true);
        }

        // --- 2. Renderer Tests ---

        [TestMethod]
        public void Renderer_EmptyImageHref_FallsBackToButtonHref()
        {
            // Arrange
            var props = new FeaturedCardProperties
            {
                ButtonText = "Action",
                ImageAlt = "Alt",
                ButtonHref = "/default-link",
                ImageHref = string.Empty // Deliberately empty
            };

            // Act
            var result = RclFeaturedCardRenderer.Render(props);

            // Assert
            Assert.IsTrue(result.Contains("<a href=\"/default-link\" tabindex=\"-1\""));
        }

        [TestMethod]
        public void Renderer_ProvidedImageHref_OverridesButtonHrefForImage()
        {
            // Arrange
            var props = new FeaturedCardProperties
            {
                ButtonText = "Action",
                ImageAlt = "Alt",
                ButtonHref = "/button-link",
                ImageHref = "/custom-image-link"
            };

            // Act
            var result = RclFeaturedCardRenderer.Render(props);

            // Assert
            Assert.IsTrue(result.Contains("<a href=\"/custom-image-link\" tabindex=\"-1\""));
            Assert.IsTrue(result.Contains("<a href=\"/button-link\" class=\"btn")); // Button retains its own link
        }

        [TestMethod]
        public void Renderer_WithAriaLabel_AppendsSrOnlySpan()
        {
            // Arrange
            var props = new FeaturedCardProperties
            {
                ButtonText = "Learn",
                ImageAlt = "Alt",
                ButtonAriaLabel = "Learn more about the program"
            };

            // Act
            var result = RclFeaturedCardRenderer.Render(props);

            // Assert
            Assert.IsTrue(result.Contains("<span class=\"sr-only\">Learn more about the program</span>"));
        }

        [TestMethod]
        public void Renderer_NoAriaLabel_OmitsSrOnlySpan()
        {
            // Arrange
            var props = new FeaturedCardProperties
            {
                ButtonText = "Learn",
                ImageAlt = "Alt",
                ButtonAriaLabel = string.Empty
            };

            // Act
            var result = RclFeaturedCardRenderer.Render(props);

            // Assert
            Assert.IsFalse(result.Contains("sr-only"));
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
                "rcl-featured-card",
                new TagHelperAttributeList(),
                (useCachedResult, encoder) => Task.FromResult<TagHelperContent>(childContent));

            return (context, output);
        }

        [TestMethod]
        public async Task Helper_ProcessAsync_StripsOriginalTagAndRendersCard()
        {
            // Arrange
            var (context, output) = CreateTagHelperEssentials("<p>Inner paragraph text.</p>");
            var helper = new FeaturedCardHelper
            {
                ButtonText = "Apply Now",
                ButtonHref = "/apply",
                ImageAlt = "Scenic view",
                ImageSrc = "scenic.jpg"
            };

            // Act
            await helper.ProcessAsync(context, output);

            // Assert
            Assert.IsNull(output.TagName); // <rcl-featured-card> should be stripped
            
            var finalHtml = output.Content.GetContent();
            Assert.IsTrue(finalHtml.Contains("<div class=\"card featured-card\">"));
            Assert.IsTrue(finalHtml.Contains("<p>Inner paragraph text.</p>"));
            Assert.IsTrue(finalHtml.Contains("Apply Now"));
            Assert.IsTrue(finalHtml.Contains("src=\"scenic.jpg\""));
        }
    }
}