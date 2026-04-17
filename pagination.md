# tag

using Microsoft.AspNetCore.Razor.TagHelpers;

namespace MyComponentLibrary.TagHelpers
{
    [HtmlTargetElement("rcl-pagination")]
    public class PaginationTagHelper : TagHelper
    {
        // The current active page
        public int CurrentPage { get; set; } = 1;

        // The total number of pages available
        public int TotalPages { get; set; } = 1;

        public override void Process(TagHelperContext context, TagHelperOutput output)
        {
            // Transform the <rcl-pagination> tag into the <cagov-pagination> web component
            output.TagName = "cagov-pagination";

            // Set the required data attributes
            output.Attributes.SetAttribute("data-current-page", CurrentPage.ToString());
            output.Attributes.SetAttribute("data-total-pages", TotalPages.ToString());

            // Ensure it renders with a closing tag, which web components require
            output.TagMode = TagMode.StartTagAndEndTag; 
        }
    }
}


# cshtml

<rcl-pagination current-page="5" total-pages="99"></rcl-pagination>

<rcl-pagination 
    current-page="@Model.CurrentPageNumber" 
    total-pages="@Model.TotalPageCount">
</rcl-pagination>

# docs

Pagination Component (<rcl-pagination>)

Renders the state template's pagination web component. The styling and interaction logic (like truncating large page ranges with ellipses) is handled automatically by the cagov.core.js library.
Setup

Ensure the Tag Helpers are registered in your _ViewImports.cshtml:
HTML

@addTagHelper *, MyComponentLibrary

Properties
Attribute	Type	Default	Description
current-page	int	1	The currently active page number.
total-pages	int	1	The total number of pages available in the dataset.

<rcl-pagination current-page="2" total-pages="10"></rcl-pagination>

# tests

using Microsoft.VisualStudio.TestTools.UnitTesting;
using Microsoft.AspNetCore.Razor.TagHelpers;
using MyComponentLibrary.TagHelpers;
using System.Collections.Generic;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc.Testing;
using System.Net.Http;
using MyComponentLibrary.TestHost; // Adjust to your test host app namespace

namespace MyComponentLibrary.Tests
{
    [TestClass]
    public class PaginationTagHelpersTests
    {
        // --- Unit Tests ---
        private (TagHelperContext, TagHelperOutput) CreateTagHelperData()
        {
            var context = new TagHelperContext(
                tagName: "rcl-pagination",
                allAttributes: new TagHelperAttributeList(),
                items: new Dictionary<object, object>(),
                uniqueId: "test");

            var output = new TagHelperOutput(
                "rcl-pagination",
                new TagHelperAttributeList(),
                (useCachedResult, encoder) =>
                {
                    return Task.FromResult<TagHelperContent>(new DefaultTagHelperContent());
                });

            return (context, output);
        }

        [TestMethod]
        public void Pagination_DefaultProperties_RendersCorrectly()
        {
            // Arrange
            var helper = new PaginationTagHelper();
            var (context, output) = CreateTagHelperData();

            // Act
            helper.Process(context, output);

            // Assert
            Assert.AreEqual("cagov-pagination", output.TagName);
            Assert.AreEqual("1", output.Attributes["data-current-page"].Value);
            Assert.AreEqual("1", output.Attributes["data-total-pages"].Value);
            Assert.AreEqual(TagMode.StartTagAndEndTag, output.TagMode);
        }

        [TestMethod]
        public void Pagination_CustomProperties_SetsDataAttributes()
        {
            // Arrange
            var helper = new PaginationTagHelper 
            { 
                CurrentPage = 5, 
                TotalPages = 99 
            };
            var (context, output) = CreateTagHelperData();

            // Act
            helper.Process(context, output);

            // Assert
            Assert.AreEqual("cagov-pagination", output.TagName);
            Assert.AreEqual("5", output.Attributes["data-current-page"].Value);
            Assert.AreEqual("99", output.Attributes["data-total-pages"].Value);
        }
    }

    [TestClass]
    public class PaginationIntegrationTests
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
        public async Task Pagination_RendersCorrectHtml_OnPage()
        {
            // Act
            // Assume page has: <rcl-pagination current-page="3" total-pages="10"></rcl-pagination>
            var response = await _client.GetAsync("/PaginationTestPage");
            response.EnsureSuccessStatusCode();

            var responseString = await response.Content.ReadAsStringAsync();

            // Assert
            StringAssert.Contains(responseString, "<cagov-pagination");
            StringAssert.Contains(responseString, "data-current-page=\"3\"");
            StringAssert.Contains(responseString, "data-total-pages=\"10\"");
            StringAssert.Contains(responseString, "</cagov-pagination>");
        }
    }
}

