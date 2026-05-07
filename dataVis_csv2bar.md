### DTO

using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Razor.TagHelpers;

namespace WTS.RazorComponentLibrary.Models.RclComponents
{
    public class Csv2BarProperties
    {
        [Required(AllowEmptyStrings = false, ErrorMessage = "A ChartId is required to initialize the canvas element.")]
        public string ChartId { get; set; } = string.Empty;

        [Required(AllowEmptyStrings = false, ErrorMessage = "A CsvSource URL is required to fetch the chart data.")]
        public string CsvSource { get; set; } = string.Empty;

        public string ChartTitle { get; set; } = string.Empty;
        
        public string XAxisLabel { get; set; } = string.Empty;
        
        public string YAxisLabel { get; set; } = string.Empty;

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
    [HtmlTargetElement("rcl-csv2bar")]
    public class Csv2BarHelper : Csv2BarProperties, ITagHelper
    {
        public int Order => 0;
        public void Init(TagHelperContext context) { }

        public async Task ProcessAsync(TagHelperContext context, TagHelperOutput output)
        {
            var childContent = await output.GetChildContentAsync();
            this.Content = childContent.GetContent().Trim();

            var validationContext = new ValidationContext(this);
            Validator.ValidateObject(this, validationContext, validateAllProperties: true);

            // Strip the <rcl-csv2bar> wrapper
            output.TagName = null;

            var htmlResult = RclCsv2BarRenderer.Render(this);
            output.Content.SetHtmlContent(htmlResult);
        }
    }
}

### Renderer

using WTS.RazorComponentLibrary.Models.RclComponents;

namespace WTS.RazorComponentLibrary.Renderers
{
    public static class RclCsv2BarRenderer
    {
        public static string Render(Csv2BarProperties p)
        {
            string ariaLabel = string.IsNullOrWhiteSpace(p.ChartTitle) 
                ? "Bar Chart" 
                : p.ChartTitle;

            return $@"
                <div class=""chart-container"" role=""figure"" aria-label=""{ariaLabel}"">
                    <canvas id=""{p.ChartId}"" 
                            class=""csv2barchart""
                            data-csv-src=""{p.CsvSource}"" 
                            data-title=""{p.ChartTitle}""
                            data-x-axis=""{p.XAxisLabel}"" 
                            data-y-axis=""{p.YAxisLabel}"">
                    </canvas>
                    <div class=""sr-only"">
                        {p.Content}
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
    public class Csv2BarTests
    {
        // --- 1. Property Validation Tests ---

        [TestMethod]
        [ExpectedException(typeof(ValidationException))]
        public void Properties_MissingChartId_ThrowsValidationException()
        {
            // Arrange
            var props = new Csv2BarProperties
            {
                ChartId = string.Empty, // Invalid: Needs ID for canvas
                CsvSource = "/data/sales.csv"
            };
            var context = new ValidationContext(props);

            // Act
            Validator.ValidateObject(props, context, validateAllProperties: true);
        }

        [TestMethod]
        [ExpectedException(typeof(ValidationException))]
        public void Properties_MissingCsvSource_ThrowsValidationException()
        {
            // Arrange
            var props = new Csv2BarProperties
            {
                ChartId = "salesChart",
                CsvSource = string.Empty // Invalid: Needs data source
            };
            var context = new ValidationContext(props);

            // Act
            Validator.ValidateObject(props, context, validateAllProperties: true);
        }

        // --- 2. Renderer Tests ---

        [TestMethod]
        public void Renderer_WithTitle_GeneratesCorrectAriaLabelAndDataAttributes()
        {
            // Arrange
            var props = new Csv2BarProperties
            {
                ChartId = "revenueChart",
                CsvSource = "/api/revenue",
                ChartTitle = "Q1 Revenue",
                XAxisLabel = "Months",
                YAxisLabel = "Dollars"
            };

            // Act
            var result = RclCsv2BarRenderer.Render(props);

            // Assert
            Assert.IsTrue(result.Contains("role=\"figure\""));
            Assert.IsTrue(result.Contains("aria-label=\"Q1 Revenue\""));
            Assert.IsTrue(result.Contains("id=\"revenueChart\""));
            Assert.IsTrue(result.Contains("data-csv-src=\"/api/revenue\""));
            Assert.IsTrue(result.Contains("data-x-axis=\"Months\""));
            Assert.IsTrue(result.Contains("data-y-axis=\"Dollars\""));
        }

        [TestMethod]
        public void Renderer_WithoutTitle_GeneratesFallbackAriaLabel()
        {
            // Arrange
            var props = new Csv2BarProperties
            {
                ChartId = "basicChart",
                CsvSource = "data.csv"
            };

            // Act
            var result = RclCsv2BarRenderer.Render(props);

            // Assert
            Assert.IsTrue(result.Contains("aria-label=\"Bar Chart\""));
        }

        [TestMethod]
        public void Renderer_IncludesInnerContentInSrOnlyDiv()
        {
            // Arrange
            var props = new Csv2BarProperties
            {
                ChartId = "testChart",
                CsvSource = "data.csv",
                Content = "<table><tr><td>Raw Data Fallback</td></tr></table>"
            };

            // Act
            var result = RclCsv2BarRenderer.Render(props);

            // Assert
            Assert.IsTrue(result.Contains("<div class=\"sr-only\">"));
            Assert.IsTrue(result.Contains("Raw Data Fallback"));
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
                "rcl-csv2bar",
                new TagHelperAttributeList(),
                (useCachedResult, encoder) => Task.FromResult<TagHelperContent>(childContent));

            return (context, output);
        }

        [TestMethod]
        public async Task Helper_ProcessAsync_StripsOriginalTagAndRendersChartContainer()
        {
            // Arrange
            var (context, output) = CreateTagHelperEssentials("<p>Screen reader description.</p>");
            var helper = new Csv2BarHelper
            {
                ChartId = "demoChart",
                CsvSource = "/metrics.csv"
            };

            // Act
            await helper.ProcessAsync(context, output);

            // Assert
            Assert.IsNull(output.TagName); // <rcl-csv2bar> should be stripped
            
            var finalHtml = output.Content.GetContent();
            Assert.IsTrue(finalHtml.Contains("<div class=\"chart-container\""));
            Assert.IsTrue(finalHtml.Contains("<canvas id=\"demoChart\""));
            Assert.IsTrue(finalHtml.Contains("data-csv-src=\"/metrics.csv\""));
            Assert.IsTrue(finalHtml.Contains("<p>Screen reader description.</p>"));
        }
    }
}