### DTO
using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Razor.TagHelpers;

namespace WTS.RazorComponentLibrary.Models.RclComponents
{
    public enum TableVariant
    {
        Basic,
        Default,
        Striped
    }

    public class TableProperties
    {
        public TableVariant Variant { get; set; } = TableVariant.Basic;

        [HtmlAttributeNotBound]
        [Required(AllowEmptyStrings = false, ErrorMessage = "A table must contain inner content (rows and cells) for data presentation and ADA compliance.")]
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
    [HtmlTargetElement("rcl-table")]
    public class TableHelper : TableProperties, ITagHelper
    {
        public int Order => 0;
        public void Init(TagHelperContext context) { }

        public async Task ProcessAsync(TagHelperContext context, TagHelperOutput output)
        {
            var childContent = await output.GetChildContentAsync();
            this.Content = childContent.GetContent().Trim();

            var validationContext = new ValidationContext(this);
            Validator.ValidateObject(this, validationContext, validateAllProperties: true);

            // Strip the <rcl-table> wrapper
            output.TagName = null;

            var htmlResult = RclTableRenderer.Render(this);
            output.Content.SetHtmlContent(htmlResult);
        }
    }
}


### Renderer

using WTS.RazorComponentLibrary.Models.RclComponents;

namespace WTS.RazorComponentLibrary.Renderers
{
    public static class RclTableRenderer
    {
        public static string Render(TableProperties p)
        {
            string cssClass = p.Variant switch
            {
                TableVariant.Default => "table table-default",
                TableVariant.Striped => "table table-striped",
                _ => "table" // Basic variant
            };

            return $@"
                <table class=""{cssClass}"">
                    {p.Content}
                </table>";
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
    public class TableTests
    {
        // --- 1. Property Validation Tests ---

        [TestMethod]
        [ExpectedException(typeof(ValidationException))]
        public void Properties_MissingContent_ThrowsValidationException()
        {
            // Arrange
            var props = new TableProperties
            {
                Variant = TableVariant.Striped,
                Content = string.Empty // Invalid: Needs rows/cells
            };
            var context = new ValidationContext(props);

            // Act
            Validator.ValidateObject(props, context, validateAllProperties: true);
        }

        // --- 2. Renderer Tests ---

        [TestMethod]
        public void Renderer_BasicVariant_OutputsBaseTableClassOnly()
        {
            // Arrange
            var props = new TableProperties
            {
                Variant = TableVariant.Basic,
                Content = "<tbody><tr><td>Data</td></tr></tbody>"
            };

            // Act
            var result = RclTableRenderer.Render(props);

            // Assert
            Assert.IsTrue(result.Contains("<table class=\"table\">"));
            Assert.IsTrue(result.Contains("<td>Data</td>"));
        }

        [TestMethod]
        public void Renderer_StripedVariant_OutputsStripedTableClass()
        {
            // Arrange
            var props = new TableProperties
            {
                Variant = TableVariant.Striped,
                Content = "<tbody><tr><td>Data</td></tr></tbody>"
            };

            // Act
            var result = RclTableRenderer.Render(props);

            // Assert
            Assert.IsTrue(result.Contains("<table class=\"table table-striped\">"));
        }

        [TestMethod]
        public void Renderer_DefaultVariant_OutputsDefaultTableClass()
        {
            // Arrange
            var props = new TableProperties
            {
                Variant = TableVariant.Default,
                Content = "<tbody><tr><td>Data</td></tr></tbody>"
            };

            // Act
            var result = RclTableRenderer.Render(props);

            // Assert
            Assert.IsTrue(result.Contains("<table class=\"table table-default\">"));
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
                "rcl-table",
                new TagHelperAttributeList(),
                (useCachedResult, encoder) => Task.FromResult<TagHelperContent>(childContent));

            return (context, output);
        }

        [TestMethod]
        public async Task Helper_ProcessAsync_StripsOriginalTagAndRendersTable()
        {
            // Arrange
            var innerHtml = "<thead><tr><th>Header</th></tr></thead>";
            var (context, output) = CreateTagHelperEssentials(innerHtml);
            
            var helper = new TableHelper
            {
                Variant = TableVariant.Striped
            };

            // Act
            await helper.ProcessAsync(context, output);

            // Assert
            Assert.IsNull(output.TagName); // <rcl-table> should be stripped
            
            var finalHtml = output.Content.GetContent();
            Assert.IsTrue(finalHtml.Contains("<table class=\"table table-striped\">"));
            Assert.IsTrue(finalHtml.Contains(innerHtml));
            Assert.IsTrue(finalHtml.Contains("</table>"));
        }
    }
}