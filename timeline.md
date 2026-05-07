### DTO

using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Razor.TagHelpers;

namespace WTS.RazorComponentLibrary.Models.RclComponents
{
    public class TimelineProperties
    {
        [HtmlAttributeNotBound]
        public string Content { get; set; } = string.Empty;
    }

    public class TimelineItemProperties
    {
        [Required(AllowEmptyStrings = false, ErrorMessage = "A Title is required to establish the subject of the timeline event.")]
        public string Title { get; set; } = string.Empty;

        [Required(AllowEmptyStrings = false, ErrorMessage = "A Timeframe is required to ground the timeline event chronologically.")]
        public string Timeframe { get; set; } = string.Empty;

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
    [HtmlTargetElement("rcl-timeline")]
    public class TimelineHelper : TimelineProperties, ITagHelper
    {
        public int Order => 0;
        public void Init(TagHelperContext context) { }

        public async Task ProcessAsync(TagHelperContext context, TagHelperOutput output)
        {
            var childContent = await output.GetChildContentAsync();
            this.Content = childContent.GetContent().Trim();

            // Strip the <rcl-timeline> tag
            output.TagName = null;

            var htmlResult = RclTimelineRenderer.Render(this);
            output.Content.SetHtmlContent(htmlResult);
        }
    }

    // --- 2. Child Item ---
    [HtmlTargetElement("rcl-timeline-item", ParentTag = "rcl-timeline")]
    public class TimelineItemHelper : TimelineItemProperties, ITagHelper
    {
        public int Order => 0;
        public void Init(TagHelperContext context) { }

        public async Task ProcessAsync(TagHelperContext context, TagHelperOutput output)
        {
            var childContent = await output.GetChildContentAsync();
            this.Content = childContent.GetContent().Trim();

            var validationContext = new ValidationContext(this);
            Validator.ValidateObject(this, validationContext, validateAllProperties: true);

            // Strip the <rcl-timeline-item> tag
            output.TagName = null;

            var htmlResult = RclTimelineItemRenderer.Render(this);
            output.Content.SetHtmlContent(htmlResult);
        }
    }
}

### Renderer

using WTS.RazorComponentLibrary.Models.RclComponents;

namespace WTS.RazorComponentLibrary.Renderers
{
    public static class RclTimelineRenderer
    {
        public static string Render(TimelineProperties p)
        {
            return $@"
                <div class=""card overflow-visible"">
                    <div class=""card-block"">
                        <ul class=""row list-unstyled"">
                            {p.Content}
                        </ul>
                    </div>
                </div>";
        }
    }

    public static class RclTimelineItemRenderer
    {
        public static string Render(TimelineItemProperties p)
        {
            return $@"
                <li class=""col-md-12"">
                    <article class=""row"">
                        <div class=""col-md-3 text-md-end p-x-md"">
                            <div class=""h5 m-b-0 m-t"">{p.Title}</div>
                            <div class=""h6 m-y-0"">{p.Timeframe}</div>
                        </div>
                        <div class=""col-md-9 pos-rel brd-md-left brd-gray-light p-x-md"">
                            <div class=""timeline-dot d-none d-md-block"">
                                <span class=""dot-line-inner bg-white bg-primary-before brd-gray-light""></span>
                            </div>
                            <div class=""m-t m-b-md m-b-0-mobile"">
                                {p.Content}
                            </div>
                        </div>
                    </article>
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
    public class TimelineTests
    {
        // --- 1. Property Validation Tests ---

        [TestMethod]
        [ExpectedException(typeof(ValidationException))]
        public void ChildProperties_MissingTitle_ThrowsValidationException()
        {
            // Arrange
            var props = new TimelineItemProperties
            {
                Title = string.Empty, // Invalid: Timeline events require a title
                Timeframe = "2026",
                Content = "Event details."
            };
            var context = new ValidationContext(props);

            // Act
            Validator.ValidateObject(props, context, validateAllProperties: true);
        }

        [TestMethod]
        [ExpectedException(typeof(ValidationException))]
        public void ChildProperties_MissingTimeframe_ThrowsValidationException()
        {
            // Arrange
            var props = new TimelineItemProperties
            {
                Title = "Graduation",
                Timeframe = string.Empty, // Invalid: Timeline events require a timeframe
                Content = "Event details."
            };
            var context = new ValidationContext(props);

            // Act
            Validator.ValidateObject(props, context, validateAllProperties: true);
        }

        // --- 2. Renderer Tests ---

        [TestMethod]
        public void ParentRenderer_OutputsCardAndListWrapper()
        {
            // Arrange
            var props = new TimelineProperties { Content = "<li>Event</li>" };

            // Act
            var result = RclTimelineRenderer.Render(props);

            // Assert
            Assert.IsTrue(result.Contains("<div class=\"card overflow-visible\">"));
            Assert.IsTrue(result.Contains("<div class=\"card-block\">"));
            Assert.IsTrue(result.Contains("<ul class=\"row list-unstyled\">"));
            Assert.IsTrue(result.Contains("<li>Event</li>"));
            Assert.IsTrue(result.Contains("</ul>"));
        }

        [TestMethod]
        public void ChildRenderer_OutputsCorrectArticleStructure()
        {
            // Arrange
            var props = new TimelineItemProperties
            {
                Title = "Project Kickoff",
                Timeframe = "Q1 2026",
                Content = "<p>Initial planning phase.</p>"
            };

            // Act
            var result = RclTimelineItemRenderer.Render(props);

            // Assert
            Assert.IsTrue(result.StartsWith("<li class=\"col-md-12\">"));
            Assert.IsTrue(result.Contains("<article class=\"row\">"));
            Assert.IsTrue(result.Contains("<div class=\"h5 m-b-0 m-t\">Project Kickoff</div>"));
            Assert.IsTrue(result.Contains("<div class=\"h6 m-y-0\">Q1 2026</div>"));
            Assert.IsTrue(result.Contains("timeline-dot"));
            Assert.IsTrue(result.Contains("<p>Initial planning phase.</p>"));
            Assert.IsTrue(result.EndsWith("</li>"));
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
            var (context, output) = CreateTagHelperEssentials("Items go here", "rcl-timeline");
            var helper = new TimelineHelper();

            // Act
            await helper.ProcessAsync(context, output);

            // Assert
            Assert.IsNull(output.TagName); // <rcl-timeline> should be stripped
            Assert.IsTrue(output.Content.GetContent().Contains("<ul class=\"row list-unstyled\">"));
            Assert.IsTrue(output.Content.GetContent().Contains("Items go here"));
        }

        [TestMethod]
        public async Task ChildHelper_ProcessAsync_StripsOriginalTagAndRendersItem()
        {
            // Arrange
            var (context, output) = CreateTagHelperEssentials("Deployment completed.", "rcl-timeline-item");
            var helper = new TimelineItemHelper
            {
                Title = "Release v1.0",
                Timeframe = "May 2026"
            };

            // Act
            await helper.ProcessAsync(context, output);

            // Assert
            Assert.IsNull(output.TagName); // <rcl-timeline-item> should be stripped
            
            var finalHtml = output.Content.GetContent();
            Assert.IsTrue(finalHtml.Contains("<li class=\"col-md-12\">"));
            Assert.IsTrue(finalHtml.Contains("Release v1.0"));
            Assert.IsTrue(finalHtml.Contains("May 2026"));
            Assert.IsTrue(finalHtml.Contains("Deployment completed."));
        }
    }
}