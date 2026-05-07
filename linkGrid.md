### DTO

using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Razor.TagHelpers;

namespace WTS.RazorComponentLibrary.Models.RclComponents
{
    public class LinkGridProperties
    {
        [HtmlAttributeNotBound]
        public string Content { get; set; } = string.Empty;
    }

    public class LinkGridItemProperties
    {
        public string Href { get; set; } = "javascript:;";
        
        public string ColumnClass { get; set; } = "col-md-4 mb-4";

        [HtmlAttributeNotBound]
        [Required(AllowEmptyStrings = false, ErrorMessage = "Link grid items must contain text or content so screen readers can announce the link destination.")]
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
    // Parent Container
    [HtmlTargetElement("rcl-link-grid")]
    public class LinkGridHelper : LinkGridProperties, ITagHelper
    {
        public int Order => 0;
        public void Init(TagHelperContext context) { }

        public async Task ProcessAsync(TagHelperContext context, TagHelperOutput output)
        {
            var childContent = await output.GetChildContentAsync();
            this.Content = childContent.GetContent().Trim();

            // Strip the parent <rcl-link-grid> tag
            output.TagName = null;

            var htmlResult = RclLinkGridRenderer.Render(this);
            output.Content.SetHtmlContent(htmlResult);
        }
    }

    // Child Item
    [HtmlTargetElement("rcl-link-grid-item", ParentTag = "rcl-link-grid")]
    public class LinkGridItemHelper : LinkGridItemProperties, ITagHelper
    {
        public int Order => 0;
        public void Init(TagHelperContext context) { }

        public async Task ProcessAsync(TagHelperContext context, TagHelperOutput output)
        {
            var childContent = await output.GetChildContentAsync();
            this.Content = childContent.GetContent().Trim();

            var validationContext = new ValidationContext(this);
            Validator.ValidateObject(this, validationContext, validateAllProperties: true);

            // Strip the <rcl-link-grid-item> tag
            output.TagName = null;

            var htmlResult = RclLinkGridItemRenderer.Render(this);
            output.Content.SetHtmlContent(htmlResult);
        }
    }
}

### Renderer

using WTS.RazorComponentLibrary.Models.RclComponents;

namespace WTS.RazorComponentLibrary.Renderers
{
    public static class RclLinkGridRenderer
    {
        public static string Render(LinkGridProperties p)
        {
            return $@"
                <div class=""row"">
                    {p.Content}
                </div>";
        }
    }

    public static class RclLinkGridItemRenderer
    {
        public static string Render(LinkGridItemProperties p)
        {
            return $@"
                <div class=""{p.ColumnClass}"">
                    <a href=""{p.Href}"" class=""link-grid"">
                        {p.Content}
                    </a>
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
    public class LinkGridTests
    {
        // --- 1. Property Validation Tests ---

        [TestMethod]
        [ExpectedException(typeof(ValidationException))]
        public void ItemProperties_EmptyContent_ThrowsValidationException()
        {
            // Arrange
            var props = new LinkGridItemProperties
            {
                Href = "/about",
                Content = string.Empty // Invalid: Link needs content for UI and ADA
            };
            var context = new ValidationContext(props);

            // Act
            Validator.ValidateObject(props, context, validateAllProperties: true);
        }

        [TestMethod]
        public void ItemProperties_ValidContent_PassesValidation()
        {
            // Arrange
            var props = new LinkGridItemProperties
            {
                Href = "/about",
                Content = "About Us"
            };
            var context = new ValidationContext(props);

            // Act & Assert (Should not throw)
            Validator.ValidateObject(props, context, validateAllProperties: true);
        }

        // --- 2. Renderer Tests ---

        [TestMethod]
        public void ParentRenderer_OutputsRowWrapper()
        {
            // Arrange
            var props = new LinkGridProperties { Content = "Inner Grid Items" };

            // Act
            var result = RclLinkGridRenderer.Render(props);

            // Assert
            Assert.IsTrue(result.Contains("<div class=\"row\">"));
            Assert.IsTrue(result.Contains("Inner Grid Items"));
        }

        [TestMethod]
        public void ItemRenderer_DefaultProperties_OutputsCorrectHtml()
        {
            // Arrange
            var props = new LinkGridItemProperties
            {
                Content = "Default Link" // Uses default ColumnClass and Href
            };

            // Act
            var result = RclLinkGridItemRenderer.Render(props);

            // Assert
            Assert.IsTrue(result.Contains("<div class=\"col-md-4 mb-4\">"));
            Assert.IsTrue(result.Contains("<a href=\"javascript:;\" class=\"link-grid\">"));
            Assert.IsTrue(result.Contains("Default Link"));
        }

        [TestMethod]
        public void ItemRenderer_CustomProperties_OverridesDefaults()
        {
            // Arrange
            var props = new LinkGridItemProperties
            {
                Href = "https://ca.gov",
                ColumnClass = "col-sm-6 mb-2",
                Content = "External Site"
            };

            // Act
            var result = RclLinkGridItemRenderer.Render(props);

            // Assert
            Assert.IsTrue(result.Contains("<div class=\"col-sm-6 mb-2\">"));
            Assert.IsTrue(result.Contains("<a href=\"https://ca.gov\" class=\"link-grid\">"));
            Assert.IsTrue(result.Contains("External Site"));
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
        public async Task ParentHelper_ProcessAsync_StripsTagAndRenders()
        {
            // Arrange
            var (context, output) = CreateTagHelperEssentials("Child items here", "rcl-link-grid");
            var helper = new LinkGridHelper();

            // Act
            await helper.ProcessAsync(context, output);

            // Assert
            Assert.IsNull(output.TagName); // Tag should be stripped
            Assert.IsTrue(output.Content.GetContent().Contains("<div class=\"row\">"));
            Assert.IsTrue(output.Content.GetContent().Contains("Child items here"));
        }

        [TestMethod]
        public async Task ChildHelper_ProcessAsync_StripsTagAndRenders()
        {
            // Arrange
            var (context, output) = CreateTagHelperEssentials("Settings", "rcl-link-grid-item");
            var helper = new LinkGridItemHelper
            {
                Href = "/settings"
            };

            // Act
            await helper.ProcessAsync(context, output);

            // Assert
            Assert.IsNull(output.TagName); // Tag should be stripped
            var finalHtml = output.Content.GetContent();
            Assert.IsTrue(finalHtml.Contains("<div class=\"col-md-4 mb-4\">"));
            Assert.IsTrue(finalHtml.Contains("<a href=\"/settings\""));
            Assert.IsTrue(finalHtml.Contains("Settings"));
        }
    }
}