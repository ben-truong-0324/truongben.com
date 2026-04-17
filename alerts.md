#### taghelper

using Microsoft.AspNetCore.Razor.TagHelpers;
using System.Threading.Tasks;

namespace MyComponentLibrary.TagHelpers
{
    public enum AlertVariant
    {
        Info,
        Warning,
        Danger,
        Resolution
    }

    [HtmlTargetElement("rcl-alert")]
    public class AlertTagHelper : TagHelper
    {
        public AlertVariant Variant { get; set; } = AlertVariant.Info;

        public override async Task ProcessAsync(TagHelperContext context, TagHelperOutput output)
        {
            // Set the outer wrapper
            output.TagName = "div";
            output.Attributes.SetAttribute("class", "alert alert-dismissible alert-banner");
            output.Attributes.SetAttribute("role", "alert");

            // Capture the content inside the tag
            var childContent = await output.GetChildContentAsync();
            var content = childContent.GetContent();

            // Determine the correct icon based on the variant
            string iconHtml = Variant switch
            {
                AlertVariant.Warning => @"<span class=""alert-icon ca-gov-icon-warning-triangle text-warning"" aria-hidden=""true""></span>",
                AlertVariant.Danger => @"<img src=""https://template.webstandards.ca.gov/images/alert-warning-diamond.svg"" alt=""alert warning icon"" />",
                AlertVariant.Resolution => @"<img src=""https://template.webstandards.ca.gov/images/alert-success.svg"" alt=""alert success icon"" />",
                _ => @"<img src=""https://template.webstandards.ca.gov/images/alert-info.svg"" alt=""alert info icon"" />" // Default to Info
            };

            // Build the inner HTML structure
            output.Content.SetHtmlContent($@"
                <div class=""container"">
                    {iconHtml}
                    <span class=""alert-text"">
                        {content}
                    </span>
                    <button type=""button"" class=""close ms-lg-auto"" data-bs-dismiss=""alert"" aria-label=""Close"">
                        <span class=""ca-gov-icon-close-mark"" aria-hidden=""true""></span>
                    </button>
                </div>
            ");
        }
    }
}


## cshtml use
<rcl-alert variant="Info">
    <span class="text-bold">New!</span> A new version of the State Web Template has launched.
    <span class="ca-gov-icon-pipe" aria-hidden="true"></span>
    <a href="javascript:;">Upgrade now</a>
</rcl-alert>

<rcl-alert variant="Warning">
    <span class="text-bold">Warning:</span> Our website may be impacted during upgrade.
    <span class="ca-gov-icon-pipe" aria-hidden="true"></span>
    <a href="javascript:;">Learn more <span class="sr-only">about the impact</span></a>
</rcl-alert>

<rcl-alert variant="Danger">
    <span class="text-bold">Alert:</span> Our systems are currently down.
    <span class="ca-gov-icon-pipe" aria-hidden="true"></span>
    <a href="javascript:;">Learn more <span class="sr-only">about the incident</span></a>
</rcl-alert>

<rcl-alert variant="Resolution">
    <span class="text-bold">Fixed.</span> Our systems are back up again.
    <span class="ca-gov-icon-pipe" aria-hidden="true"></span>
    <a href="javascript:;">Learn more <span class="sr-only">about the resolution</span></a>
</rcl-alert>


## docs
Alert Component (<rcl-alert>)

The Alert component renders a dismissible banner, typically used to communicate important, time-sensitive information. It supports four visual variants, each rendering a specific state icon.
Setup

Ensure the Tag Helpers are registered in your _ViewImports.cshtml:
HTML

@addTagHelper *, MyComponentLibrary

Properties
<rcl-alert>
Attribute	Type	Default	Description
variant	AlertVariant enum	Info	Determines the alert icon. Valid options are Info, Warning, Danger, and Resolution.
Example
HTML

<rcl-alert variant="Warning">
    <span class="text-bold">Warning:</span> System maintenance scheduled for tonight.
</rcl-alert>


## test

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
    public class AlertTagHelpersTests
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
                    var tagHelperContent = new DefaultTagHelperContent();
                    tagHelperContent.SetContent("Test Alert Content");
                    return Task.FromResult<TagHelperContent>(tagHelperContent);
                });

            return (context, output);
        }

        [TestMethod]
        public async Task AlertTagHelper_RendersWrapperAndDismissButton()
        {
            // Arrange
            var helper = new AlertTagHelper();
            var (context, output) = CreateTagHelperData("rcl-alert");

            // Act
            await helper.ProcessAsync(context, output);
            var content = output.Content.GetContent();

            // Assert
            Assert.AreEqual("div", output.TagName);
            Assert.AreEqual("alert alert-dismissible alert-banner", output.Attributes["class"].Value);
            Assert.AreEqual("alert", output.Attributes["role"].Value);
            StringAssert.Contains(content, "<div class=\"container\">");
            StringAssert.Contains(content, "<span class=\"alert-text\">");
            StringAssert.Contains(content, "Test Alert Content");
            StringAssert.Contains(content, "data-bs-dismiss=\"alert\"");
            StringAssert.Contains(content, "ca-gov-icon-close-mark");
        }

        [TestMethod]
        public async Task AlertTagHelper_WarningVariant_RendersWarningIcon()
        {
            // Arrange
            var helper = new AlertTagHelper { Variant = AlertVariant.Warning };
            var (context, output) = CreateTagHelperData("rcl-alert");

            // Act
            await helper.ProcessAsync(context, output);
            var content = output.Content.GetContent();

            // Assert
            StringAssert.Contains(content, "ca-gov-icon-warning-triangle text-warning");
        }

        [TestMethod]
        public async Task AlertTagHelper_DangerVariant_RendersDangerImage()
        {
            // Arrange
            var helper = new AlertTagHelper { Variant = AlertVariant.Danger };
            var (context, output) = CreateTagHelperData("rcl-alert");

            // Act
            await helper.ProcessAsync(context, output);
            var content = output.Content.GetContent();

            // Assert
            StringAssert.Contains(content, "alert-warning-diamond.svg");
        }
    }

    [TestClass]
    public class AlertIntegrationTests
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
        public async Task Alert_RendersCorrectHtml_OnPage()
        {
            // Act
            // Assume the test page has: <rcl-alert variant="Resolution">System Fixed</rcl-alert>
            var response = await _client.GetAsync("/AlertTestPage");
            response.EnsureSuccessStatusCode();

            var responseString = await response.Content.ReadAsStringAsync();

            // Assert
            StringAssert.Contains(responseString, "class=\"alert alert-dismissible alert-banner\"");
            StringAssert.Contains(responseString, "alert-success.svg");
            StringAssert.Contains(responseString, "System Fixed");
        }
    }
}