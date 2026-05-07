### DTO
using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Razor.TagHelpers;

namespace WTS.RazorComponentLibrary.Models.RclComponents
{
    public enum ModalSize
    {
        Default,
        Sm,
        Lg,
        Xl
    }

    public class ModalProperties
    {
        [Required(AllowEmptyStrings = false, ErrorMessage = "A ModalId is required so trigger buttons can target it.")]
        public string ModalId { get; set; } = string.Empty;

        [Required(AllowEmptyStrings = false, ErrorMessage = "A Title is required for screen readers (aria-labelledby).")]
        public string Title { get; set; } = string.Empty;

        public ModalSize Size { get; set; } = ModalSize.Lg; 

        public bool ShowFooter { get; set; } = true;
        
        public string FooterCloseText { get; set; } = "Close";

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
    [HtmlTargetElement("rcl-modal")]
    public class ModalHelper : ModalProperties, ITagHelper
    {
        public int Order => 0;
        public void Init(TagHelperContext context) { }

        public async Task ProcessAsync(TagHelperContext context, TagHelperOutput output)
        {
            var childContent = await output.GetChildContentAsync();
            this.Content = childContent.GetContent().Trim();

            var validationContext = new ValidationContext(this);
            Validator.ValidateObject(this, validationContext, validateAllProperties: true);

            // Strip the <rcl-modal> wrapper; the renderer outputs the actual modal structure
            output.TagName = null;

            var htmlResult = RclModalRenderer.Render(this);
            output.Content.SetHtmlContent(htmlResult);
        }
    }
}

### Renderer
using WTS.RazorComponentLibrary.Models.RclComponents;

namespace WTS.RazorComponentLibrary.Renderers
{
    public static class RclModalRenderer
    {
        public static string Render(ModalProperties p)
        {
            string sizeClass = p.Size switch
            {
                ModalSize.Lg => " modal-lg",
                ModalSize.Sm => " modal-sm",
                ModalSize.Xl => " modal-xl",
                _ => string.Empty
            };

            string footerHtml = string.Empty;
            if (p.ShowFooter)
            {
                footerHtml = $@"
                    <div class=""modal-footer"">
                        <button type=""button"" class=""btn btn-default"" data-bs-dismiss=""modal"">
                            {p.FooterCloseText}
                        </button>
                    </div>";
            }

            return $@"
                <div class=""modal fade"" id=""{p.ModalId}"" tabindex=""-1"" aria-labelledby=""{p.ModalId}Label"" aria-hidden=""true"">
                    <div class=""modal-dialog{sizeClass}"">
                        <div class=""modal-content"">
                            <div class=""modal-header"">
                                <h5 class=""modal-title"" id=""{p.ModalId}Label"">{p.Title}</h5>
                                <button type=""button"" class=""btn-close"" data-bs-dismiss=""modal"" aria-label=""Close""></button>
                            </div>
                            <div class=""modal-body"">
                                {p.Content}
                            </div>
                            {footerHtml}
                        </div>
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
    public class ModalTests
    {
        // --- 1. Property Validation Tests ---

        [TestMethod]
        [ExpectedException(typeof(ValidationException))]
        public void Properties_MissingModalId_ThrowsValidationException()
        {
            // Arrange
            var props = new ModalProperties
            {
                ModalId = string.Empty, // Invalid: Needs ID to be triggered
                Title = "Alert"
            };
            var context = new ValidationContext(props);

            // Act
            Validator.ValidateObject(props, context, validateAllProperties: true);
        }

        [TestMethod]
        [ExpectedException(typeof(ValidationException))]
        public void Properties_MissingTitle_ThrowsValidationException()
        {
            // Arrange
            var props = new ModalProperties
            {
                ModalId = "myModal",
                Title = string.Empty // Invalid: Needs title for aria-labelledby
            };
            var context = new ValidationContext(props);

            // Act
            Validator.ValidateObject(props, context, validateAllProperties: true);
        }

        // --- 2. Renderer Tests ---

        [TestMethod]
        public void Renderer_LgSize_AddsModalLgClass()
        {
            // Arrange
            var props = new ModalProperties
            {
                ModalId = "lgModal",
                Title = "Large Modal",
                Size = ModalSize.Lg
            };

            // Act
            var result = RclModalRenderer.Render(props);

            // Assert
            Assert.IsTrue(result.Contains("modal-dialog modal-lg"));
        }

        [TestMethod]
        public void Renderer_ShowFooterFalse_OmitsFooterHtml()
        {
            // Arrange
            var props = new ModalProperties
            {
                ModalId = "noFooterModal",
                Title = "No Footer",
                ShowFooter = false
            };

            // Act
            var result = RclModalRenderer.Render(props);

            // Assert
            Assert.IsFalse(result.Contains("<div class=\"modal-footer\">"));
            Assert.IsFalse(result.Contains("Close"));
        }

        [TestMethod]
        public void Renderer_ShowFooterTrue_IncludesCustomCloseText()
        {
            // Arrange
            var props = new ModalProperties
            {
                ModalId = "footerModal",
                Title = "Footer",
                ShowFooter = true,
                FooterCloseText = "Dismiss"
            };

            // Act
            var result = RclModalRenderer.Render(props);

            // Assert
            Assert.IsTrue(result.Contains("<div class=\"modal-footer\">"));
            Assert.IsTrue(result.Contains("Dismiss"));
        }

        [TestMethod]
        public void Renderer_GeneratesCorrectAriaLabelledBy()
        {
            // Arrange
            var props = new ModalProperties
            {
                ModalId = "testModal",
                Title = "Accessibility Test"
            };

            // Act
            var result = RclModalRenderer.Render(props);

            // Assert
            Assert.IsTrue(result.Contains("aria-labelledby=\"testModalLabel\""));
            Assert.IsTrue(result.Contains("id=\"testModalLabel\">Accessibility Test</h5>"));
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
                "rcl-modal",
                new TagHelperAttributeList(),
                (useCachedResult, encoder) => Task.FromResult<TagHelperContent>(childContent));

            return (context, output);
        }

        [TestMethod]
        public async Task Helper_ProcessAsync_StripsOriginalTagAndRendersModal()
        {
            // Arrange
            var (context, output) = CreateTagHelperEssentials("<p>Modal body content.</p>");
            var helper = new ModalHelper
            {
                ModalId = "execModal",
                Title = "Executive Summary",
                Size = ModalSize.Xl
            };

            // Act
            await helper.ProcessAsync(context, output);

            // Assert
            Assert.IsNull(output.TagName); // <rcl-modal> should be stripped
            
            var finalHtml = output.Content.GetContent();
            Assert.IsTrue(finalHtml.Contains("id=\"execModal\""));
            Assert.IsTrue(finalHtml.Contains("modal-dialog modal-xl"));
            Assert.IsTrue(finalHtml.Contains("Executive Summary"));
            Assert.IsTrue(finalHtml.Contains("<p>Modal body content.</p>"));
        }
    }
}