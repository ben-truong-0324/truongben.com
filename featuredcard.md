# tag

using Microsoft.AspNetCore.Razor.TagHelpers;
using System.Threading.Tasks;

namespace MyComponentLibrary.TagHelpers
{
    [HtmlTargetElement("rcl-feature-card")]
    public class FeatureCardTagHelper : TagHelper
    {
        // Text Content Properties
        public string Title { get; set; } = string.Empty;
        
        // Button Link Properties
        public string ButtonText { get; set; } = string.Empty;
        public string ButtonHref { get; set; } = "javascript:;";
        public string ButtonAriaLabel { get; set; } = string.Empty;

        // Image Properties
        public string ImageSrc { get; set; } = string.Empty;
        public string ImageAlt { get; set; } = string.Empty;
        // Allows the image to link somewhere else; defaults to the ButtonHref if left empty
        public string ImageHref { get; set; } = string.Empty;

        public override async Task ProcessAsync(TagHelperContext context, TagHelperOutput output)
        {
            // Strip the parent wrapper tag
            output.TagName = null;

            // Capture inner content for the paragraph
            var childContent = await output.GetChildContentAsync();
            var content = childContent.GetContent();

            // Resolve Image Link
            string finalImageHref = string.IsNullOrWhiteSpace(ImageHref) ? ButtonHref : ImageHref;

            // Build accessible button label
            string ariaLabelHtml = string.IsNullOrWhiteSpace(ButtonAriaLabel)
                ? ""
                : $" <span class=\"sr-only\">{ButtonAriaLabel}</span>";

            output.Content.SetHtmlContent($@"
<div class=""container"">
  <div class=""row bg-gray-100"">
    <div class=""col-md-6 col-lg-4 p-a-md order-2 order-md-1"">
      <h2 class=""h3 m-t-0"">{Title}</h2>
      <p>{content}</p>
      <a href=""{ButtonHref}"" class=""btn btn-primary m-y-md"">
        {ButtonText}
        {ariaLabelHtml}
      </a>
    </div>
    <div class=""col-lg-8 col-md-6 p-0 text-right order-1 order-md-2 d-flex justify-content-center"">
      <a
        href=""{finalImageHref}""
        class=""feature-img""
        style=""background: url('{ImageSrc}')""
        aria-label=""{ImageAlt}""></a>
    </div>
  </div>
</div>");
        }
    }
}

# cshtml

<rcl-feature-card 
    title="California Oceans"
    button-text="Learn More"
    button-href="/ocean-conservation"
    button-aria-label="(feature)"
    image-src="https://template.webstandards.ca.gov/images/ocean.jpg"
    image-alt="Feature card example image">
    Highlight an action you want people to take or important information on the homepage.
</rcl-feature-card>

<rcl-feature-card 
    title="Parks & Recreation"
    button-text="Find a Park"
    button-href="/find-park"
    image-src="/images/park.jpg"
    image-alt="Family enjoying a state park"
    image-href="/park-gallery">
    Explore the thousands of miles of hiking trails available in the state park system.
</rcl-feature-card>

# docs

Feature Card Component (<rcl-feature-card>)

Renders a wide layout card typically used on homepages to highlight a primary call to action. It handles complex Bootstrap grid order classes to ensure proper stacking behavior on mobile devices.
Setup

Ensure the Tag Helpers are registered in your _ViewImports.cshtml:
HTML

@addTagHelper *, MyComponentLibrary

Properties
Attribute	Type	Default	Description
title	string	""	The primary heading for the feature block.
button-text	string	""	Text displayed inside the primary action button.
button-href	string	"javascript:;"	Destination URL for the button.
button-aria-label	string	""	Screen reader-only text appended to the button text for context.
image-src	string	""	URL to the background image.
image-alt	string	""	The aria-label applied to the image link wrapper for accessibility.
image-href	string	ButtonHref	Optional. Provide if the image click should go somewhere different than the button.


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
    public class FeatureCardTagHelpersTests
    {
        // --- Unit Tests ---
        private (TagHelperContext, TagHelperOutput) CreateTagHelperData(string tagName, string content = "")
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
        public async Task FeatureCard_RendersCorrectStructureAndData()
        {
            // Arrange
            var helper = new FeatureCardTagHelper 
            { 
                Title = "Test Feature",
                ButtonText = "Click",
                ButtonHref = "/action",
                ButtonAriaLabel = "Action Details",
                ImageSrc = "/bg.jpg",
                ImageAlt = "Background"
            };
            var (context, output) = CreateTagHelperData("rcl-feature-card", "Feature Content");

            // Act
            await helper.ProcessAsync(context, output);
            var content = output.Content.GetContent();

            // Assert
            Assert.IsNull(output.TagName); // Ensure wrapper stripped
            StringAssert.Contains(content, "<h2 class=\"h3 m-t-0\">Test Feature</h2>");
            StringAssert.Contains(content, "<p>Feature Content</p>");
            StringAssert.Contains(content, "href=\"/action\"");
            StringAssert.Contains(content, "Click");
            StringAssert.Contains(content, "<span class=\"sr-only\">Action Details</span>");
            
            // Check image properties
            StringAssert.Contains(content, "style=\"background: url('/bg.jpg')\"");
            StringAssert.Contains(content, "aria-label=\"Background\"");
        }

        [TestMethod]
        public async Task FeatureCard_ImageHref_DefaultsToButtonHref_WhenEmpty()
        {
            // Arrange
            var helper = new FeatureCardTagHelper 
            { 
                ButtonHref = "/default-link"
            };
            var (context, output) = CreateTagHelperData("rcl-feature-card");

            // Act
            await helper.ProcessAsync(context, output);
            var content = output.Content.GetContent();

            // Assert
            // Find the anchor tag for the feature image
            StringAssert.Contains(content, "href=\"/default-link\"\n        class=\"feature-img\"");
        }

        [TestMethod]
        public async Task FeatureCard_ImageHref_UsesExplicitLink_WhenProvided()
        {
            // Arrange
            var helper = new FeatureCardTagHelper 
            { 
                ButtonHref = "/button-link",
                ImageHref = "/image-specific-link"
            };
            var (context, output) = CreateTagHelperData("rcl-feature-card");

            // Act
            await helper.ProcessAsync(context, output);
            var content = output.Content.GetContent();

            // Assert
            StringAssert.Contains(content, "href=\"/image-specific-link\"\n        class=\"feature-img\"");
            StringAssert.Contains(content, "href=\"/button-link\" class=\"btn");
        }
    }

    [TestClass]
    public class FeatureCardIntegrationTests
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
        public async Task FeatureCard_RendersCorrectHtml_OnPage()
        {
            // Act
            // Assume page has: <rcl-feature-card title="Int Test" image-src="/test.jpg">Int Content</rcl-feature-card>
            var response = await _client.GetAsync("/FeatureCardTestPage");
            response.EnsureSuccessStatusCode();

            var responseString = await response.Content.ReadAsStringAsync();

            // Assert
            StringAssert.Contains(responseString, "<div class=\"row bg-gray-100\">");
            StringAssert.Contains(responseString, "<h2 class=\"h3 m-t-0\">Int Test</h2>");
            StringAssert.Contains(responseString, "Int Content");
            StringAssert.Contains(responseString, "url('/test.jpg')");
        }
    }
}