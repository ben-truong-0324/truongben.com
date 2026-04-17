# tag

using Microsoft.AspNetCore.Razor.TagHelpers;
using System.Threading.Tasks;

namespace MyComponentLibrary.TagHelpers
{
    // --- 1. Parent Timeline Container ---
    [HtmlTargetElement("rcl-timeline")]
    public class TimelineTagHelper : TagHelper
    {
        public override async Task ProcessAsync(TagHelperContext context, TagHelperOutput output)
        {
            output.TagName = "div";
            output.Attributes.SetAttribute("class", "card overflow-visible");

            var childContent = await output.GetChildContentAsync();

            // Wraps all the generated list items in the required panel and list classes
            output.Content.SetHtmlContent($@"
                <div class=""card-block"">
                    <ul class=""row list-unstyled"">
                        {childContent.GetContent()}
                    </ul>
                </div>
            ");
        }
    }

    // --- 2. Child Timeline Item ---
    [HtmlTargetElement("rcl-timeline-item", ParentTag = "rcl-timeline")]
    public class TimelineItemTagHelper : TagHelper
    {
        // The main title/contributor for the step
        public string Title { get; set; } = string.Empty;

        // The date, year, or timeframe string
        public string Timeframe { get; set; } = string.Empty;

        public override async Task ProcessAsync(TagHelperContext context, TagHelperOutput output)
        {
            output.TagName = "li";
            output.Attributes.SetAttribute("class", "col-md-12");

            var childContent = await output.GetChildContentAsync();
            var content = childContent.GetContent();

            // Using a <div> with the p-tag margins to safely wrap any block-level content the developer passes in
            output.Content.SetHtmlContent($@"
                <article class=""row"">
                  <div class=""col-md-3 text-md-end p-x-md"">
                    <div class=""h5 m-b-0 m-t"">{Title}</div>
                    <div class=""h6 m-y-0"">{Timeframe}</div>
                  </div>
                  <div class=""col-md-9 pos-rel brd-md-left brd-gray-light p-x-md"">
                    <div class=""timeline-dot d-none d-md-block"">
                      <span class=""dot-line-inner bg-white bg-primary-before brd-gray-light""></span>
                    </div>
                    <div class=""m-t m-b-md m-b-0-mobile"">
                      {content}
                    </div>
                  </div>
                  </article>
            ");
        }
    }
}

# cshtml

<rcl-timeline>
    <rcl-timeline-item title="Step 1 Contributor" timeframe="2024 - 2025">
        <p>Briefly discuss the step or identify the milestone.</p>
    </rcl-timeline-item>
    
    <rcl-timeline-item title="Step 2 Contributor" timeframe="2025 - 2026">
        <p>Keep the message clear and concise.</p>
    </rcl-timeline-item>

    <rcl-timeline-item title="Step 3 Contributor" timeframe="2026 - Present">
        <p>Do not link to more information from the tracker.</p>
    </rcl-timeline-item>

    <rcl-timeline-item title="Step 4 Contributor" timeframe="Future">
        <p>Instead, link to additional information in your body content or tracker caption.</p>
    </rcl-timeline-item>
</rcl-timeline>

# docs

Timeline Component

Renders a vertical timeline or experience tracker. It automatically handles the responsive layout changes (like hiding the connecting dots on mobile) required by the state template.
Setup

Ensure the Tag Helpers are registered in your _ViewImports.cshtml:
HTML

@addTagHelper *, MyComponentLibrary

Properties
<rcl-timeline>

The outer wrapper. No configurable properties needed.
<rcl-timeline-item>
Attribute	Type	Default	Description
title	string	""	The primary text in the left column (e.g., Job Title, Phase Name).
timeframe	string	""	The secondary text in the left column (e.g., Date, Year range).

# tests

using Microsoft.VisualStudio.TestTools.UnitTesting;
using Microsoft.AspNetCore.Razor.TagHelpers;
using MyComponentLibrary.TagHelpers;
using System.Collections.Generic;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc.Testing;
using System.Net.Http;
using MyComponentLibrary.TestHost; // Adjust to your test host namespace

namespace MyComponentLibrary.Tests
{
    [TestClass]
    public class TimelineTagHelpersTests
    {
        // --- Unit Tests ---
        private (TagHelperContext, TagHelperOutput) CreateTagHelperData(string tagName, string content = "Timeline Details")
        {
            var context = new TagHelperContext(
                tagName: tagName,
                allAttributes: new TagHelperAttributeList(),
                items: new Dictionary<object, object>(),
                uniqueId: "test");

            var output = new TagHelperOutput(
                tagName,
                new TagHelperAttributeList(),
                (useCachedResult, encoder) =>
                {
                    var tagHelperContent = new DefaultTagHelperContent();
                    tagHelperContent.SetContent(content);
                    return Task.FromResult<TagHelperContent>(tagHelperContent);
                });

            return (context, output);
        }

        [TestMethod]
        public async Task Timeline_RendersContainerAndList()
        {
            // Arrange
            var helper = new TimelineTagHelper();
            var (context, output) = CreateTagHelperData("rcl-timeline", "<li>Child Content</li>");

            // Act
            await helper.ProcessAsync(context, output);
            var content = output.Content.GetContent();

            // Assert
            Assert.AreEqual("div", output.TagName);
            Assert.AreEqual("card overflow-visible", output.Attributes["class"].Value);
            StringAssert.Contains(content, "<div class=\"card-block\">");
            StringAssert.Contains(content, "<ul class=\"row list-unstyled\">");
            StringAssert.Contains(content, "<li>Child Content</li>");
        }

        [TestMethod]
        public async Task TimelineItem_RendersCorrectStructureAndData()
        {
            // Arrange
            var helper = new TimelineItemTagHelper 
            { 
                Title = "Test Phase",
                Timeframe = "2026 - 2027"
            };
            var (context, output) = CreateTagHelperData("rcl-timeline-item", "Task completed.");

            // Act
            await helper.ProcessAsync(context, output);
            var content = output.Content.GetContent();

            // Assert
            Assert.AreEqual("li", output.TagName);
            Assert.AreEqual("col-md-12", output.Attributes["class"].Value);
            
            // Left column (Metadata)
            StringAssert.Contains(content, "<article class=\"row\">");
            StringAssert.Contains(content, "<div class=\"h5 m-b-0 m-t\">Test Phase</div>");
            StringAssert.Contains(content, "<div class=\"h6 m-y-0\">2026 - 2027</div>");
            
            // Right column (Body & Dot)
            StringAssert.Contains(content, "class=\"col-md-9 pos-rel brd-md-left brd-gray-light p-x-md\"");
            StringAssert.Contains(content, "class=\"timeline-dot d-none d-md-block\"");
            StringAssert.Contains(content, "Task completed.");
        }
    }

    [TestClass]
    public class TimelineIntegrationTests
    {
        // --- Integration Tests ---
        private WebApplicationFactory<Program> _factory;
        private HttpClient _client;

        [TestInitialize]
        public void Setup()
        {
            _factory = new WebApplicationFactory<Program>();
            _client = _factory.CreateClient();
        }

        [TestCleanup]
        public void Cleanup()
        {
            _client?.Dispose();
            _factory?.Dispose();
        }

        [TestMethod]
        public async Task Timeline_RendersCorrectHtml_OnPage()
        {
            // Act
            // Assume page has: 
            // <rcl-timeline><rcl-timeline-item title="Int Title" timeframe="Int Time">Int Content</rcl-timeline-item></rcl-timeline>
            var response = await _client.GetAsync("/TimelineTestPage");
            response.EnsureSuccessStatusCode();

            var responseString = await response.Content.ReadAsStringAsync();

            // Assert
            StringAssert.Contains(responseString, "<div class=\"card overflow-visible\">");
            StringAssert.Contains(responseString, "<div class=\"h5 m-b-0 m-t\">Int Title</div>");
            StringAssert.Contains(responseString, "<div class=\"h6 m-y-0\">Int Time</div>");
            StringAssert.Contains(responseString, "Int Content");
            StringAssert.Contains(responseString, "timeline-dot d-none d-md-block");
        }
    }
}