### DTO
using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Razor.TagHelpers;

namespace WTS.RazorComponentLibrary.Models.RclComponents
{
    public class StepListProperties
    {
        [HtmlAttributeNotBound]
        public string Content { get; set; } = string.Empty;
    }

    public class StepListItemProperties
    {
        [Required(AllowEmptyStrings = false, ErrorMessage = "A Heading is required to define the step's primary instruction.")]
        public string Heading { get; set; } = string.Empty;

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
    // --- 1. Parent Container ---
    [HtmlTargetElement("rcl-step-list")]
    public class StepListHelper : StepListProperties, ITagHelper
    {
        public int Order => 0;
        public void Init(TagHelperContext context) { }

        public async Task ProcessAsync(TagHelperContext context, TagHelperOutput output)
        {
            var childContent = await output.GetChildContentAsync();
            this.Content = childContent.GetContent().Trim();

            // Strip the <rcl-step-list> tag
            output.TagName = null;

            var htmlResult = RclStepListRenderer.Render(this);
            output.Content.SetHtmlContent(htmlResult);
        }
    }

    // --- 2. Child Item ---
    [HtmlTargetElement("rcl-step-list-item", ParentTag = "rcl-step-list")]
    public class StepListItemHelper : StepListItemProperties, ITagHelper
    {
        public int Order => 0;
        public void Init(TagHelperContext context) { }

        public async Task ProcessAsync(TagHelperContext context, TagHelperOutput output)
        {
            var childContent = await output.GetChildContentAsync();
            this.Content = childContent.GetContent().Trim();

            var validationContext = new ValidationContext(this);
            Validator.ValidateObject(this, validationContext, validateAllProperties: true);

            // Strip the <rcl-step-list-item> tag
            output.TagName = null;

            var htmlResult = RclStepListItemRenderer.Render(this);
            output.Content.SetHtmlContent(htmlResult);
        }
    }
}

### Renderer

using WTS.RazorComponentLibrary.Models.RclComponents;

namespace WTS.RazorComponentLibrary.Renderers
{
    public static class RclStepListRenderer
    {
        public static string Render(StepListProperties p)
        {
            return $@"
                <ol class=""cagov-step-list"">
                    {p.Content}
                </ol>";
        }
    }

    public static class RclStepListItemRenderer
    {
        public static string Render(StepListItemProperties p)
        {
            return $@"
                <li>
                    {p.Heading}
                    <br />
                    <span class=""cagov-step-list-content"">
                        {p.Content}
                    </span>
                </li>";
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
    public class StepListTests
    {
        // --- 1. Property Validation Tests ---

        [TestMethod]
        [ExpectedException(typeof(ValidationException))]
        public void ChildProperties_MissingHeading_ThrowsValidationException()
        {
            // Arrange
            var props = new StepListItemProperties
            {
                Heading = string.Empty, // Invalid: Needs a heading
                Content = "More details."
            };
            var context = new ValidationContext(props);

            // Act
            Validator.ValidateObject(props, context, validateAllProperties: true);
        }

        // --- 2. Renderer Tests ---

        [TestMethod]
        public void ParentRenderer_OutputsOrderedListWrapper()
        {
            // Arrange
            var props = new StepListProperties { Content = "<li>Step 1</li>" };

            // Act
            var result = RclStepListRenderer.Render(props);

            // Assert
            Assert.IsTrue(result.Contains("<ol class=\"cagov-step-list\">"));
            Assert.IsTrue(result.Contains("<li>Step 1</li>"));
            Assert.IsTrue(result.Contains("</ol>"));
        }

        [TestMethod]
        public void ChildRenderer_OutputsHeadingAndContentSpan()
        {
            // Arrange
            var props = new StepListItemProperties
            {
                Heading = "Review Application",
                Content = "Check for errors."
            };

            // Act
            var result = RclStepListItemRenderer.Render(props);

            // Assert
            Assert.IsTrue(result.StartsWith("<li>"));
            Assert.IsTrue(result.Contains("Review Application"));
            Assert.IsTrue(result.Contains("<br />"));
            Assert.IsTrue(result.Contains("<span class=\"cagov-step-list-content\">"));
            Assert.IsTrue(result.Contains("Check for errors."));
            Assert.IsTrue(result.Contains("</span>"));
            Assert.IsTrue(result.Contains("</li>"));
        }

        // --- 3. Tag Helper Execution Tests ---

        private (TagHelperContext, TagHelperOutput) CreateTagHelperEssentials(string childContentText, string tagName)
        {
            var context = new TagHelperContext(
                new TagHelperAttributeList(),
                new Dictionary<object, object>(),
                "test-id");

            var childContent = new DefaultTagHelperContent();
            childContent.SetHtmlContent(childContentText);

            var output = new TagHelperOutput(
                tagName,
                new TagHelperAttributeList(),
                (useCachedResult, encoder) => Task.FromResult<TagHelperContent>(childContent));

            return (context, output);
        }

        [TestMethod]
        public async Task ParentHelper_ProcessAsync_StripsOriginalTagAndRenders()
        {
            // Arrange
            var (context, output) = CreateTagHelperEssentials("Items go here", "rcl-step-list");
            var helper = new StepListHelper();

            // Act
            await helper.ProcessAsync(context, output);

            // Assert
            Assert.IsNull(output.TagName); // <rcl-step-list> should be stripped
            Assert.IsTrue(output.Content.GetContent().Contains("<ol class=\"cagov-step-list\">"));
            Assert.IsTrue(output.Content.GetContent().Contains("Items go here"));
        }

        [TestMethod]
        public async Task ChildHelper_ProcessAsync_StripsOriginalTagAndRendersItem()
        {
            // Arrange
            var (context, output) = CreateTagHelperEssentials("Fill out form online.", "rcl-step-list-item");
            var helper = new StepListItemHelper
            {
                Heading = "Step 1: Apply"
            };

            // Act
            await helper.ProcessAsync(context, output);

            // Assert
            Assert.IsNull(output.TagName); // <rcl-step-list-item> should be stripped
            
            var finalHtml = output.Content.GetContent();
            Assert.IsTrue(finalHtml.Contains("<li>"));
            Assert.IsTrue(finalHtml.Contains("Step 1: Apply"));
            Assert.IsTrue(finalHtml.Contains("<span class=\"cagov-step-list-content\">"));
            Assert.IsTrue(finalHtml.Contains("Fill out form online."));
        }
    }
}