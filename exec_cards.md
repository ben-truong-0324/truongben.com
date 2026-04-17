# tag
 using Microsoft.AspNetCore.Razor.TagHelpers;
using System.Collections.Generic;

namespace MyComponentLibrary.TagHelpers
{
    public enum ExecutiveProfileVariant
    {
        Default,
        Transparent,
        Dark
    }

    [HtmlTargetElement("rcl-executive-profile")]
    public class ExecutiveProfileTagHelper : TagHelper
    {
        public ExecutiveProfileVariant Variant { get; set; } = ExecutiveProfileVariant.Default;

        // Image Properties
        public string ImageSrc { get; set; } = string.Empty;
        public string ImageAlt { get; set; } = string.Empty;

        // Profile Details
        public string OfficialTitle { get; set; } = string.Empty;
        public string Name { get; set; } = string.Empty;
        public string Agency { get; set; } = string.Empty;

        // Link Properties
        public string LinkHref { get; set; } = "javascript:;";
        public string LinkText { get; set; } = string.Empty;
        public string LinkAriaLabel { get; set; } = string.Empty;

        public override void Process(TagHelperContext context, TagHelperOutput output)
        {
            output.TagName = "figure";
            
            // Resolve CSS classes based on variant
            var classes = new List<string> { "executive-profile" };
            if (Variant == ExecutiveProfileVariant.Transparent)
            {
                classes.Add("bg-transparent");
            }
            else if (Variant == ExecutiveProfileVariant.Dark)
            {
                classes.Add("bg-transparent");
                classes.Add("dark");
            }

            output.Attributes.SetAttribute("class", string.Join(" ", classes));

            // Default Aria Label if not explicitly provided
            string ariaLabel = string.IsNullOrWhiteSpace(LinkAriaLabel) 
                ? $"Link to {Name}'s Website" 
                : LinkAriaLabel;

            // Build inner HTML
            output.Content.SetHtmlContent($@"
                <img src=""{ImageSrc}"" alt=""{ImageAlt}"" />
                <div class=""executive-profile-body"">
                    <p>{OfficialTitle}</p>
                    <h3 class=""executive-name"">{Name}</h3>
                    <p>{Agency}</p>
                    <p>
                        <a href=""{LinkHref}"" aria-label=""{ariaLabel}"">
                            {LinkText}
                        </a>
                    </p>
                </div>
            ");
        }
    }
} 


# cshtml

<rcl-executive-profile 
    variant="Default"
    image-src="/images/profile.jpg"
    image-alt="Photo of Jane Doe"
    official-title="Director"
    name="Jane Doe"
    agency="Department of Technology"
    link-href="/jane-doe-bio"
    link-text="Read Jane's Bio">
</rcl-executive-profile>

<rcl-executive-profile 
    variant="Transparent"
    image-src="/images/profile.jpg"
    image-alt="Photo of Jane Doe"
    official-title="Director"
    name="Jane Doe"
    agency="Department of Technology"
    link-href="/jane-doe-bio"
    link-text="Read Jane's Bio">
</rcl-executive-profile>

<div class="section-standout p-a-md">
    <rcl-executive-profile 
        variant="Dark"
        image-src="/images/profile.jpg"
        image-alt="Photo of Jane Doe"
        official-title="Director"
        name="Jane Doe"
        agency="Department of Technology"
        link-href="/jane-doe-bio"
        link-text="Read Jane's Bio">
    </rcl-executive-profile>
</div>


# docs

Executive Profile Component (<rcl-executive-profile>)

Generates a stylized figure element for displaying official personnel details.
Setup

Ensure the Tag Helpers are registered in your _ViewImports.cshtml:
HTML

@addTagHelper *, MyComponentLibrary

Properties
Attribute	Type	Default	Description
variant	ExecutiveProfileVariant	Default	Options: Default, Transparent, Dark. Note: The Dark variant text is white and requires a dark parent container.
image-src	string	""	Source URL for the headshot image.
image-alt	string	""	Accessibility text for the image.
official-title	string	""	The person's job title.
name	string	""	The person's full name.
agency	string	""	The government agency or department.
link-href	string	"javascript:;"	Destination URL for the bio.
link-text	string	""	Clickable text for the bio link.
link-aria-label	string	"Link to {Name}'s Website"	Screen reader text for the bio link.

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
    public class ExecutiveProfileTagHelpersTests
    {
        // --- Unit Tests ---

        private (TagHelperContext, TagHelperOutput) CreateTagHelperData()
        {
            var context = new TagHelperContext(
                tagName: "rcl-executive-profile",
                allAttributes: new TagHelperAttributeList(),
                items: new Dictionary<object, object>(),
                uniqueId: "test");

            var output = new TagHelperOutput(
                "rcl-executive-profile",
                new TagHelperAttributeList(),
                (useCachedResult, encoder) =>
                {
                    return Task.FromResult<TagHelperContent>(new DefaultTagHelperContent());
                });

            return (context, output);
        }

        [TestMethod]
        public void ExecutiveProfile_DefaultVariant_RendersCorrectStructure()
        {
            // Arrange
            var helper = new ExecutiveProfileTagHelper 
            { 
                Name = "John Smith",
                OfficialTitle = "Chief Executive",
                Agency = "Dept of Testing",
                ImageSrc = "/img.jpg",
                ImageAlt = "John Photo",
                LinkText = "Bio Link",
                LinkHref = "/bio"
            };
            var (context, output) = CreateTagHelperData();

            // Act
            helper.Process(context, output);
            var content = output.Content.GetContent();

            // Assert
            Assert.AreEqual("figure", output.TagName);
            Assert.AreEqual("executive-profile", output.Attributes["class"].Value);
            
            StringAssert.Contains(content, "<img src=\"/img.jpg\" alt=\"John Photo\"");
            StringAssert.Contains(content, "<p>Chief Executive</p>");
            StringAssert.Contains(content, "<h3 class=\"executive-name\">John Smith</h3>");
            StringAssert.Contains(content, "<p>Dept of Testing</p>");
            StringAssert.Contains(content, "href=\"/bio\"");
            StringAssert.Contains(content, "Bio Link");
            
            // Check Auto-generated Aria Label
            StringAssert.Contains(content, "aria-label=\"Link to John Smith's Website\"");
        }

        [TestMethod]
        public void ExecutiveProfile_TransparentVariant_AddsClass()
        {
            // Arrange
            var helper = new ExecutiveProfileTagHelper { Variant = ExecutiveProfileVariant.Transparent };
            var (context, output) = CreateTagHelperData();

            // Act
            helper.Process(context, output);

            // Assert
            Assert.AreEqual("executive-profile bg-transparent", output.Attributes["class"].Value);
        }

        [TestMethod]
        public void ExecutiveProfile_DarkVariant_AddsClasses()
        {
            // Arrange
            var helper = new ExecutiveProfileTagHelper { Variant = ExecutiveProfileVariant.Dark };
            var (context, output) = CreateTagHelperData();

            // Act
            helper.Process(context, output);

            // Assert
            Assert.AreEqual("executive-profile bg-transparent dark", output.Attributes["class"].Value);
        }

        [TestMethod]
        public void ExecutiveProfile_CustomAriaLabel_OverridesDefault()
        {
            // Arrange
            var helper = new ExecutiveProfileTagHelper 
            { 
                Name = "John Smith",
                LinkAriaLabel = "Custom Screen Reader Text"
            };
            var (context, output) = CreateTagHelperData();

            // Act
            helper.Process(context, output);
            var content = output.Content.GetContent();

            // Assert
            StringAssert.Contains(content, "aria-label=\"Custom Screen Reader Text\"");
        }
    }

    [TestClass]
    public class ExecutiveProfileIntegrationTests
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
        public async Task ExecutiveProfile_RendersCorrectHtml_OnPage()
        {
            // Act
            // Assume test page has: <rcl-executive-profile variant="Dark" name="Int Test Name" official-title="Int Title"></rcl-executive-profile>
            var response = await _client.GetAsync("/ExecutiveProfileTestPage");
            response.EnsureSuccessStatusCode();

            var responseString = await response.Content.ReadAsStringAsync();

            // Assert
            StringAssert.Contains(responseString, "<figure class=\"executive-profile bg-transparent dark\">");
            StringAssert.Contains(responseString, "<h3 class=\"executive-name\">Int Test Name</h3>");
            StringAssert.Contains(responseString, "<p>Int Title</p>");
        }
    }
}