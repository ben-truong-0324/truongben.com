# tag

using Microsoft.AspNetCore.Razor.TagHelpers;

namespace MyComponentLibrary.TagHelpers
{
    public enum SocialPlatform
    {
        Facebook,
        GitHub,
        Twitter,
        YouTube,
        LinkedIn,
        Instagram,
        Email
    }

    // --- 1. Container ---
    [HtmlTargetElement("rcl-social-container")]
    public class SocialContainerTagHelper : TagHelper
    {
        public override void Process(TagHelperContext context, TagHelperOutput output)
        {
            output.TagName = "div";
            output.Attributes.SetAttribute("class", "socialsharer-container");
        }
    }

    // --- 2. Icon Item ---
    [HtmlTargetElement("rcl-social-icon", ParentTag = "rcl-social-container")]
    public class SocialIconTagHelper : TagHelper
    {
        public SocialPlatform Platform { get; set; } = SocialPlatform.Facebook;
        
        // The URL the icon points to
        public string Href { get; set; } = "javascript:;";
        
        // Optional override for the accessibility title
        public string Title { get; set; } = string.Empty;

        public override void Process(TagHelperContext context, TagHelperOutput output)
        {
            output.TagName = "a";
            output.TagMode = TagMode.StartTagAndEndTag; // Ensures <a></a> instead of self-closing <a />

            // Resolve proper CA state template icon class
            string iconClass = Platform switch
            {
                SocialPlatform.Facebook => "ca-gov-icon-facebook",
                SocialPlatform.GitHub => "ca-gov-icon-github",
                SocialPlatform.Twitter => "ca-gov-icon-share-twitter",
                SocialPlatform.YouTube => "ca-gov-icon-share-youtube",
                SocialPlatform.LinkedIn => "ca-gov-icon-share-linkedin",
                SocialPlatform.Instagram => "ca-gov-icon-instagram",
                SocialPlatform.Email => "ca-gov-icon-share-email",
                _ => "ca-gov-icon-share"
            };

            output.Attributes.SetAttribute("class", iconClass);
            output.Attributes.SetAttribute("href", Href);

            // Generate a default title if the developer omits it
            string finalTitle = string.IsNullOrWhiteSpace(Title) ? $"{Platform} Link" : Title;
            output.Attributes.SetAttribute("title", finalTitle);
        }
    }
}

# cshtml

<rcl-social-container>
    <rcl-social-icon platform="Facebook" href="https://www.facebook.com/index.html"></rcl-social-icon>
    <rcl-social-icon platform="GitHub" href="https://github.com/index.html"></rcl-social-icon>
    <rcl-social-icon platform="Twitter" href="https://twitter.com/index.html"></rcl-social-icon>
    <rcl-social-icon platform="YouTube" href="https://www.youtube.com/index.html"></rcl-social-icon>
    <rcl-social-icon platform="LinkedIn" href="https://www.linkedin.com/index.html"></rcl-social-icon>
    <rcl-social-icon platform="Instagram" href="https://www.instagram.com/index.html"></rcl-social-icon>
    <rcl-social-icon platform="Email" href="mailto:your_email@ca.gov"></rcl-social-icon>
</rcl-social-container>

# docs

Social Media Icons Component

Renders a uniform block of sharing/social link icons mapped directly to the state template's custom font library.
Setup

Ensure the Tag Helpers are registered in your _ViewImports.cshtml:
HTML

@addTagHelper *, MyComponentLibrary

Properties
<rcl-social-container>

Acts as a wrapper. It renders a <div class="socialsharer-container"> and requires no additional attributes.
<rcl-social-icon>
Attribute	Type	Default	Description
platform	SocialPlatform	Facebook	Resolves the specific icon. Options: Facebook, GitHub, Twitter, YouTube, LinkedIn, Instagram, Email.
href	string	"javascript:;"	Destination URL.
title	string	""	The HTML title attribute (used by screen readers and tooltips). If left blank, it generates {Platform} Link.

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
    public class SocialMediaTagHelpersTests
    {
        // --- Unit Tests ---
        private (TagHelperContext, TagHelperOutput) CreateTagHelperData(string tagName)
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
                    return Task.FromResult<TagHelperContent>(new DefaultTagHelperContent());
                });

            return (context, output);
        }

        [TestMethod]
        public void SocialContainer_RendersCorrectWrapperDiv()
        {
            // Arrange
            var helper = new SocialContainerTagHelper();
            var (context, output) = CreateTagHelperData("rcl-social-container");

            // Act
            helper.Process(context, output);

            // Assert
            Assert.AreEqual("div", output.TagName);
            Assert.AreEqual("socialsharer-container", output.Attributes["class"].Value);
        }

        [TestMethod]
        public void SocialIcon_DefaultsToFacebookAndGeneratesTitle()
        {
            // Arrange
            var helper = new SocialIconTagHelper { Href = "https://facebook.com" };
            var (context, output) = CreateTagHelperData("rcl-social-icon");

            // Act
            helper.Process(context, output);

            // Assert
            Assert.AreEqual("a", output.TagName);
            Assert.AreEqual("ca-gov-icon-facebook", output.Attributes["class"].Value);
            Assert.AreEqual("https://facebook.com", output.Attributes["href"].Value);
            Assert.AreEqual("Facebook Link", output.Attributes["title"].Value); // Auto-generated
        }

        [TestMethod]
        public void SocialIcon_TwitterVariant_RendersCorrectClassAndCustomTitle()
        {
            // Arrange
            var helper = new SocialIconTagHelper 
            { 
                Platform = SocialPlatform.Twitter, 
                Title = "Follow us on Twitter",
                Href = "/twitter"
            };
            var (context, output) = CreateTagHelperData("rcl-social-icon");

            // Act
            helper.Process(context, output);

            // Assert
            Assert.AreEqual("ca-gov-icon-share-twitter", output.Attributes["class"].Value);
            Assert.AreEqual("Follow us on Twitter", output.Attributes["title"].Value);
        }
    }

    [TestClass]
    public class SocialMediaIntegrationTests
    {
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
        public async Task SocialMedia_RendersCorrectHtml_OnPage()
        {
            // Act
            // Assume page has: 
            // <rcl-social-container>
            //   <rcl-social-icon platform="GitHub" href="/git"></rcl-social-icon>
            // </rcl-social-container>
            var response = await _client.GetAsync("/SocialMediaTestPage");
            response.EnsureSuccessStatusCode();

            var responseString = await response.Content.ReadAsStringAsync();

            // Assert
            StringAssert.Contains(responseString, "<div class=\"socialsharer-container\">");
            StringAssert.Contains(responseString, "class=\"ca-gov-icon-github\"");
            StringAssert.Contains(responseString, "href=\"/git\"");
            StringAssert.Contains(responseString, "title=\"GitHub Link\"");
        }
    }
}




#########################################

namespace Publish.Models
{
    public class SocialMediaConfig
    {
        public string? DepartmentFacebookUrl { get; set; }
        public string? DepartmentTwitterUrl { get; set; }
        public string? DepartmentLinkedInUrl { get; set; }
        public string? DepartmentYouTubeUrl { get; set; }
        public string? DepartmentInstagramUrl { get; set; }
    }
}

Step 2: The YAML Parsing Helper

Assuming you have YamlDotNet installed (which is standard for .NET Markdown pipelines), you can create a quick parser. The key here is .IgnoreUnmatchedProperties(), which prevents the app from crashing if a user accidentally adds a YAML key that doesn't exist in your C# class.
C#

using YamlDotNet.Serialization;
using YamlDotNet.Serialization.NamingConventions;
using System.IO;

public static class SocialMediaParser
{
    public static SocialMediaConfig GetConfig(string filePath)
    {
        // 1. If the file doesn't exist, return an empty config (all nulls)
        if (!File.Exists(filePath))
        {
            return new SocialMediaConfig(); 
        }

        string yamlContent = File.ReadAllText(filePath);

        // 2. If the file is completely blank, return an empty config
        if (string.IsNullOrWhiteSpace(yamlContent))
        {
            return new SocialMediaConfig();
        }

        // 3. Deserialize the YAML into our C# object
        var deserializer = new DeserializerBuilder()
            .WithNamingConvention(PascalCaseNamingConvention.Instance)
            .IgnoreUnmatchedProperties() 
            .Build();

        // Parse and return (using ?? to guarantee we never return null)
        return deserializer.Deserialize<SocialMediaConfig>(yamlContent) ?? new SocialMediaConfig();
    }
}

Step 3: Attach it to your PageModel

Wherever you load your page data (like TryMarkdownFileModelYaml or TemplateBaseModel), you can now load this config and pass it down to the View.

In your TemplateBaseModel (or ViewModel):
C#

// Use an initializer to satisfy CS8618
public SocialMediaConfig Socials { get; set; } = new SocialMediaConfig(); 

In your OnGet() or pipeline logic:
C#

// Path to where the user dropped the file (e.g., wwwroot/config/socials.yml)
string socialsFilePath = Path.Combine(_env.WebRootPath, "config", "socials.yml");

// Load the data into your model
baseModel.Socials = SocialMediaParser.GetConfig(socialsFilePath);

Step 4: Render in the Razor View (With CA State Icons)

Now, in your .cshtml layout or footer partial, you just check if the property has a value before rendering the link. Because I know you're using the State Template's ca-gov-icon-* fonts based on your earlier Card component, this will wire right up to them.
Razor CSHTML

<div class="social-media-links">
    
    @* Only renders if the YAML had a valid URL *@
    @if (!string.IsNullOrWhiteSpace(baseModel.Socials?.DepartmentFacebookUrl))
    {
        <a href="@baseModel.Socials.DepartmentFacebookUrl" 
           class="ca-gov-icon-facebook" 
           title="Facebook" 
           target="_blank" 
           rel="noopener noreferrer">
           <span class="sr-only">Facebook</span>
        </a>
    }

    @if (!string.IsNullOrWhiteSpace(baseModel.Socials?.DepartmentTwitterUrl))
    {
        <a href="@baseModel.Socials.DepartmentTwitterUrl" 
           class="ca-gov-icon-twitter" 
           title="Twitter" 
           target="_blank" 
           rel="noopener noreferrer">
           <span class="sr-only">Twitter</span>
        </a>
    }
    
    @* Repeat for LinkedIn, YouTube, etc... *@

</div>

How this experience looks for your users

Now, your content editors simply maintain a file named socials.yml that looks exactly like you suggested:
YAML

---
DepartmentFacebookUrl: "https://www.facebook.com/YourDepartment"
DepartmentTwitterUrl: "https://twitter.com/YourDepartment"
DepartmentLinkedInUrl: 
DepartmentYouTubeUrl: ""
---