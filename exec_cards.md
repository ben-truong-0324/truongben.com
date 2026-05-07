### DTO

using System.ComponentModel.DataAnnotations;

namespace WTS.RazorComponentLibrary.Models.RclComponents
{
    public enum ExecutiveProfileVariant
    {
        Default,
        Transparent,
        Dark
    }

    public class ExecutiveProfileProperties
    {
        public ExecutiveProfileVariant Variant { get; set; } = ExecutiveProfileVariant.Default;

        public string ImageSrc { get; set; } = string.Empty;

        [Required(AllowEmptyStrings = false, ErrorMessage = "Image Alt text is required for ADA compliance.")]
        public string ImageAlt { get; set; } = string.Empty;

        public string OfficialTitle { get; set; } = string.Empty;

        [Required(AllowEmptyStrings = false, ErrorMessage = "Name is required for the profile heading and fallback aria-label.")]
        public string Name { get; set; } = string.Empty;

        public string Agency { get; set; } = string.Empty;

        public string LinkHref { get; set; } = "javascript:;";
        public string LinkText { get; set; } = string.Empty;
        public string LinkAriaLabel { get; set; } = string.Empty;
    }
}

### TagHelper

using Microsoft.AspNetCore.Razor.TagHelpers;
using System.ComponentModel.DataAnnotations;
using WTS.RazorComponentLibrary.Models.RclComponents;
using WTS.RazorComponentLibrary.Renderers;

namespace WTS.RazorLibrary.TagHelpers
{
    [HtmlTargetElement("rcl-executive-profile")]
    public class ExecutiveProfileHelper : ExecutiveProfileProperties, ITagHelper
    {
        public int Order => 0;
        public void Init(TagHelperContext context) { }

        public void Process(TagHelperContext context, TagHelperOutput output)
        {
            var validationContext = new ValidationContext(this);
            Validator.ValidateObject(this, validationContext, validateAllProperties: true);

            // Strip the <rcl-executive-profile> tag; the renderer will output the <figure> wrapper
            output.TagName = null;

            var htmlResult = RclExecutiveProfileRenderer.Render(this);
            output.Content.SetHtmlContent(htmlResult);
        }
    }
}


### Renderer

using System.Collections.Generic;
using WTS.RazorComponentLibrary.Models.RclComponents;

namespace WTS.RazorComponentLibrary.Renderers
{
    public static class RclExecutiveProfileRenderer
    {
        public static string Render(ExecutiveProfileProperties p)
        {
            var classes = new List<string> { "executive-profile" };

            if (p.Variant == ExecutiveProfileVariant.Transparent)
            {
                classes.Add("bg-transparent");
            }
            else if (p.Variant == ExecutiveProfileVariant.Dark)
            {
                classes.Add("bg-transparent");
                classes.Add("dark");
            }

            string classString = string.Join(" ", classes);

            string ariaLabel = string.IsNullOrWhiteSpace(p.LinkAriaLabel) 
                ? $"Link to {p.Name}'s Website" 
                : p.LinkAriaLabel;

            return $@"
                <figure class=""{classString}"">
                    <img src=""{p.ImageSrc}"" alt=""{p.ImageAlt}"" />
                    <div class=""executive-profile-body"">
                        <p>{p.OfficialTitle}</p>
                        <h3 class=""executive-name"">{p.Name}</h3>
                        <p>{p.Agency}</p>
                        <p>
                            <a href=""{p.LinkHref}"" aria-label=""{ariaLabel}"">
                                {p.LinkText}
                            </a>
                        </p>
                    </div>
                </figure>";
        }
    }
}


### test

using Microsoft.VisualStudio.TestTools.UnitTesting;
using Microsoft.AspNetCore.Razor.TagHelpers;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using WTS.RazorComponentLibrary.Models.RclComponents;
using WTS.RazorComponentLibrary.Renderers;
using WTS.RazorLibrary.TagHelpers;

namespace WTS.RazorLibrary.Tests
{
    [TestClass]
    public class ExecutiveProfileTests
    {
        // --- 1. Property Validation Tests ---

        [TestMethod]
        [ExpectedException(typeof(ValidationException))]
        public void Properties_MissingImageAlt_ThrowsValidationException()
        {
            // Arrange
            var props = new ExecutiveProfileProperties
            {
                Name = "John Doe",
                ImageAlt = string.Empty // Invalid: Requires Alt Text
            };
            var context = new ValidationContext(props);

            // Act
            Validator.ValidateObject(props, context, validateAllProperties: true);
        }

        [TestMethod]
        [ExpectedException(typeof(ValidationException))]
        public void Properties_MissingName_ThrowsValidationException()
        {
            // Arrange
            var props = new ExecutiveProfileProperties
            {
                ImageAlt = "Headshot of John Doe",
                Name = string.Empty // Invalid: Requires Name for fallback aria-label
            };
            var context = new ValidationContext(props);

            // Act
            Validator.ValidateObject(props, context, validateAllProperties: true);
        }

        // --- 2. Renderer Tests ---

        [TestMethod]
        public void Renderer_DarkVariant_OutputsCorrectClasses()
        {
            // Arrange
            var props = new ExecutiveProfileProperties
            {
                Variant = ExecutiveProfileVariant.Dark,
                Name = "Jane Doe",
                ImageAlt = "Jane Doe Headshot"
            };

            // Act
            var result = RclExecutiveProfileRenderer.Render(props);

            // Assert
            Assert.IsTrue(result.Contains("class=\"executive-profile bg-transparent dark\""));
        }

        [TestMethod]
        public void Renderer_MissingAriaLabel_GeneratesFallbackFromName()
        {
            // Arrange
            var props = new ExecutiveProfileProperties
            {
                Name = "Director Smith",
                ImageAlt = "Director Smith",
                LinkAriaLabel = string.Empty // Deliberately empty
            };

            // Act
            var result = RclExecutiveProfileRenderer.Render(props);

            // Assert
            Assert.IsTrue(result.Contains("aria-label=\"Link to Director Smith's Website\""));
        }

        [TestMethod]
        public void Renderer_ProvidedAriaLabel_OverridesFallback()
        {
            // Arrange
            var props = new ExecutiveProfileProperties
            {
                Name = "Director Smith",
                ImageAlt = "Director Smith",
                LinkAriaLabel = "Custom Agency Link"
            };

            // Act
            var result = RclExecutiveProfileRenderer.Render(props);

            // Assert
            Assert.IsTrue(result.Contains("aria-label=\"Custom Agency Link\""));
            Assert.IsFalse(result.Contains("Link to Director Smith's Website"));
        }

        // --- 3. Tag Helper Execution Tests ---

        [TestMethod]
        public void Helper_Process_StripsOriginalTagAndRendersFigure()
        {
            // Arrange
            var context = new TagHelperContext(
                new TagHelperAttributeList(),
                new Dictionary<object, object>(),
                "test-id");

            var output = new TagHelperOutput(
                "rcl-executive-profile",
                new TagHelperAttributeList(),
                (useCachedResult, encoder) => null); // No async child content fetching needed here

            var helper = new ExecutiveProfileHelper
            {
                Variant = ExecutiveProfileVariant.Transparent,
                Name = "Test Name",
                ImageAlt = "Test Alt",
                OfficialTitle = "Chief Executive"
            };

            // Act
            helper.Process(context, output);

            // Assert
            Assert.IsNull(output.TagName); // <rcl-executive-profile> should be stripped
            
            var finalHtml = output.Content.GetContent();
            Assert.IsTrue(finalHtml.Contains("<figure class=\"executive-profile bg-transparent\">"));
            Assert.IsTrue(finalHtml.Contains("<h3 class=\"executive-name\">Test Name</h3>"));
            Assert.IsTrue(finalHtml.Contains("<p>Chief Executive</p>"));
        }
    }
}