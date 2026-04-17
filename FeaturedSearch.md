# tag

using Microsoft.AspNetCore.Razor.TagHelpers;

namespace MyComponentLibrary.TagHelpers
{
    [HtmlTargetElement("rcl-featured-search")]
    public class FeaturedSearchTagHelper : TagHelper
    {
        // Allow developers to point the search to their specific search engine results page (SERP)
        public string Action { get; set; } = "../serp.html";
        
        // Placeholder text for the input
        public string Placeholder { get; set; } = "Search";
        
        // Accessibility (Screen Reader) text
        public string SrLabel { get; set; } = "Custom Google Search";
        
        // Input ID, useful if you have multiple search bars on the same page
        public string InputId { get; set; } = "SearchInput";

        public override void Process(TagHelperContext context, TagHelperOutput output)
        {
            output.TagName = "form";
            output.Attributes.SetAttribute("class", "pos-rel d-flex");
            output.Attributes.SetAttribute("action", Action);

            output.Content.SetHtmlContent($@"
                <span class=""sr-only"" id=""{InputId}"">{SrLabel}</span>
                <input
                    type=""search""
                    name=""q""
                    aria-labelledby=""{InputId}""
                    placeholder=""{Placeholder}""
                    class=""font-size-20 pt-3 pb-3 ps-3 w-100 border-end-0 rounded-start brd-primary border border-2 outline-offset-5"" />
                <button
                    type=""submit""
                    class=""bg-white border-start-0 rounded-end brd-primary border border-2 outline-offset-5 font-size-30 ps-3 pe-3 bg-gray-50-hover gray-900 color-black-hover"">
                    <span class=""ca-gov-icon-search"" aria-hidden=""true""></span>
                    <span class=""sr-only"">Submit</span>
                </button>");
        }
    }
}

# cshtml

<rcl-featured-search></rcl-featured-search>

<rcl-featured-search 
    action="/Search" 
    placeholder="Search the agency database..." 
    sr-label="Agency Search" 
    input-id="MainAgencySearch">
</rcl-featured-search>

# docs

Featured Search Component (<rcl-featured-search>)

Renders a prominent, stylized search bar form designed to meet the state template visual and accessibility guidelines. It automatically wires up the input aria-labelledby attribute to the hidden screen reader text.
Setup

Ensure the Tag Helpers are registered in your _ViewImports.cshtml:
HTML

@addTagHelper *, MyComponentLibrary

Properties
Attribute	Type	Default	Description
action	string	"../serp.html"	The destination URL where the form submits the search query q.
placeholder	string	"Search"	The placeholder text inside the input field.
sr-label	string	"Custom Google Search"	Screen reader-only text to describe the purpose of the search input.
input-id	string	"SearchInput"	The id for the screen reader span, used by the input's aria-labelledby property. Change this if placing multiple searches on one page to avoid ID collisions.

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
    public class FeaturedSearchTagHelpersTests
    {
        // --- Unit Tests ---
        private (TagHelperContext, TagHelperOutput) CreateTagHelperData()
        {
            var context = new TagHelperContext(
                tagName: "rcl-featured-search",
                allAttributes: new TagHelperAttributeList(),
                items: new Dictionary<object, object>(),
                uniqueId: "test");

            var output = new TagHelperOutput(
                "rcl-featured-search",
                new TagHelperAttributeList(),
                (useCachedResult, encoder) =>
                {
                    return Task.FromResult<TagHelperContent>(new DefaultTagHelperContent());
                });

            return (context, output);
        }

        [TestMethod]
        public void FeaturedSearch_DefaultProperties_RendersCorrectly()
        {
            // Arrange
            var helper = new FeaturedSearchTagHelper();
            var (context, output) = CreateTagHelperData();

            // Act
            helper.Process(context, output);
            var content = output.Content.GetContent();

            // Assert
            Assert.AreEqual("form", output.TagName);
            Assert.AreEqual("pos-rel d-flex", output.Attributes["class"].Value);
            Assert.AreEqual("../serp.html", output.Attributes["action"].Value);
            
            StringAssert.Contains(content, "id=\"SearchInput\"");
            StringAssert.Contains(content, "Custom Google Search");
            StringAssert.Contains(content, "placeholder=\"Search\"");
            StringAssert.Contains(content, "aria-labelledby=\"SearchInput\"");
            StringAssert.Contains(content, "ca-gov-icon-search");
        }

        [TestMethod]
        public void FeaturedSearch_CustomProperties_OverridesDefaults()
        {
            // Arrange
            var helper = new FeaturedSearchTagHelper 
            { 
                Action = "/custom-search",
                Placeholder = "Find a document",
                SrLabel = "Document Search",
                InputId = "DocSearchId"
            };
            var (context, output) = CreateTagHelperData();

            // Act
            helper.Process(context, output);
            var content = output.Content.GetContent();

            // Assert
            Assert.AreEqual("/custom-search", output.Attributes["action"].Value);
            
            StringAssert.Contains(content, "id=\"DocSearchId\"");
            StringAssert.Contains(content, "Document Search");
            StringAssert.Contains(content, "placeholder=\"Find a document\"");
            StringAssert.Contains(content, "aria-labelledby=\"DocSearchId\"");
        }
    }

    [TestClass]
    public class FeaturedSearchIntegrationTests
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
        public async Task FeaturedSearch_RendersCorrectHtml_OnPage()
        {
            // Act
            // Assume page has: <rcl-featured-search action="/IntSearch" placeholder="Int Place"></rcl-featured-search>
            var response = await _client.GetAsync("/SearchTestPage");
            response.EnsureSuccessStatusCode();

            var responseString = await response.Content.ReadAsStringAsync();

            // Assert
            StringAssert.Contains(responseString, "<form class=\"pos-rel d-flex\" action=\"/IntSearch\">");
            StringAssert.Contains(responseString, "placeholder=\"Int Place\"");
            StringAssert.Contains(responseString, "type=\"search\"");
            StringAssert.Contains(responseString, "class=\"ca-gov-icon-search\"");
        }
    }
}