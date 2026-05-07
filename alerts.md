### DTO
using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Razor.TagHelpers;

namespace WTS.RazorComponentLibrary.Models.RclComponents
{
    public enum AlertVariant
    {
        Info,
        Warning,
        Danger,
        Resolution
    }

    public class AlertProperties
    {
        public AlertVariant Variant { get; set; } = AlertVariant.Info;

        [HtmlAttributeNotBound]
        [Required(AllowEmptyStrings = false, ErrorMessage = "Alert content is required so screen readers have text to announce.")]
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
    [HtmlTargetElement("rcl-alert")]
    public class AlertHelper : AlertProperties, ITagHelper
    {
        public int Order => 0;
        public void Init(TagHelperContext context) { }

        public async Task ProcessAsync(TagHelperContext context, TagHelperOutput output)
        {
            var childContent = await output.GetChildContentAsync();
            this.Content = childContent.GetContent().Trim();

            var validationContext = new ValidationContext(this);
            Validator.ValidateObject(this, validationContext, validateAllProperties: true);

            // Strip the <rcl-alert> tag and let the renderer build the wrapper
            output.TagName = null;

            var htmlResult = RclAlertRenderer.Render(this);
            output.Content.SetHtmlContent(htmlResult);
        }
    }
}

### Renderer

using WTS.RazorComponentLibrary.Models.RclComponents;

namespace WTS.RazorComponentLibrary.Renderers
{
    public static class RclAlertRenderer
    {
        public static string Render(AlertProperties p)
        {
            string iconHtml = p.Variant switch
            {
                AlertVariant.Warning => @"<span class=""alert-icon ca-gov-icon-warning-triangle text-warning"" aria-hidden=""true""></span>",
                AlertVariant.Danger => @"<img src=""https://template.webstandards.ca.gov/images/alert-warning-diamond.svg"" alt=""alert warning icon"" />",
                AlertVariant.Resolution => @"<img src=""https://template.webstandards.ca.gov/images/alert-success.svg"" alt=""alert success icon"" />",
                _ => @"<img src=""https://template.webstandards.ca.gov/images/alert-info.svg"" alt=""alert info icon"" />" // Default to Info
            };

            return $@"
                <div class=""alert alert-dismissible alert-banner"" role=""alert"">
                    <div class=""container"">
                        {iconHtml}
                        <span class=""alert-text"">
                            {p.Content}
                        </span>
                        <button type=""button"" class=""close ms-lg-auto"" data-bs-dismiss=""alert"" aria-label=""Close"">
                            <span class=""ca-gov-icon-close-mark"" aria-hidden=""true""></span>
                        </button>
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
    public class AlertTests
    {
        // --- 1. Property Validation Tests ---

        [TestMethod]
        [ExpectedException(typeof(ValidationException))]
        public void AlertProperties_EmptyContent_ThrowsValidationException()
        {
            // Arrange
            var props = new AlertProperties
            {
                Variant = AlertVariant.Info,
                Content = string.Empty // Invalid: Content is required
            };
            var context = new ValidationContext(props);

            // Act
            Validator.ValidateObject(props, context, validateAllProperties: true);

            // Assert is handled by ExpectedException
        }

        [TestMethod]
        public void AlertProperties_ValidContent_PassesValidation()
        {
            // Arrange
            var props = new AlertProperties
            {
                Variant = AlertVariant.Danger,
                Content = "System is down."
            };
            var context = new ValidationContext(props);

            // Act & Assert (Should not throw)
            Validator.ValidateObject(props, context, validateAllProperties: true);
        }

        // --- 2. Renderer Tests ---

        [TestMethod]
        public void Renderer_WarningVariant_OutputsSpanIconAndContent()
        {
            // Arrange
            var props = new AlertProperties
            {
                Variant = AlertVariant.Warning,
                Content = "This is a warning."
            };

            // Act
            var result = RclAlertRenderer.Render(props);

            // Assert
            Assert.IsTrue(result.Contains("role=\"alert\""));
            Assert.IsTrue(result.Contains("ca-gov-icon-warning-triangle text-warning")); // Warning specific
            Assert.IsTrue(result.Contains("<span class=\"alert-text\">"));
            Assert.IsTrue(result.Contains("This is a warning."));
            Assert.IsTrue(result.Contains("data-bs-dismiss=\"alert\""));
        }

        [TestMethod]
        public void Renderer_ResolutionVariant_OutputsSvgImage()
        {
            // Arrange
            var props = new AlertProperties
            {
                Variant = AlertVariant.Resolution,
                Content = "Saved successfully."
            };

            // Act
            var result = RclAlertRenderer.Render(props);

            // Assert
            Assert.IsTrue(result.Contains("alert-success.svg")); // Resolution specific
            Assert.IsTrue(result.Contains("Saved successfully."));
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
                "rcl-alert",
                new TagHelperAttributeList(),
                (useCachedResult, encoder) => Task.FromResult<TagHelperContent>(childContent));

            return (context, output);
        }

        [TestMethod]
        public async Task AlertHelper_ProcessAsync_StripsOriginalTagAndRendersHtml()
        {
            // Arrange
            var (context, output) = CreateTagHelperEssentials("Important information here.");
            var helper = new AlertHelper
            {
                Variant = AlertVariant.Info
            };

            // Act
            await helper.ProcessAsync(context, output);

            // Assert
            Assert.IsNull(output.TagName); // <rcl-alert> should be stripped
            
            var finalHtml = output.Content.GetContent();
            Assert.IsTrue(finalHtml.Contains("<div class=\"alert alert-dismissible alert-banner\""));
            Assert.IsTrue(finalHtml.Contains("Important information here."));
            Assert.IsTrue(finalHtml.Contains("alert-info.svg")); // Default info icon
        }
    }
}