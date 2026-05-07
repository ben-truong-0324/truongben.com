### DTO

using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Razor.TagHelpers;

namespace WTS.RazorComponentLibrary.Models.RclComponents
{
    public enum SocialPlatform
    {
        Facebook,
        GitHub,
        Twitter,
        YouTube,
        LinkedIn,
        Instagram,
        Email,
        Default
    }

    public class SocialContainerProperties
    {
        [HtmlAttributeNotBound]
        public string Content { get; set; } = string.Empty;
    }

    public class SocialIconProperties
    {
        public SocialPlatform Platform { get; set; } = SocialPlatform.Facebook;

        [Required(AllowEmptyStrings = false, ErrorMessage = "An Href destination is required for the social icon link.")]
        public string Href { get; set; } = "javascript:;";

        public string Title { get; set; } = string.Empty;
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
    // --- 1. Container ---
    [HtmlTargetElement("rcl-social-container")]
    public class SocialContainerHelper : SocialContainerProperties, ITagHelper
    {
        public int Order => 0;
        public void Init(TagHelperContext context) { }

        public async Task ProcessAsync(TagHelperContext context, TagHelperOutput output)
        {
            var childContent = await output.GetChildContentAsync();
            this.Content = childContent.GetContent().Trim();

            // Strip the <rcl-social-container> tag
            output.TagName = null;

            var htmlResult = RclSocialContainerRenderer.Render(this);
            output.Content.SetHtmlContent(htmlResult);
        }
    }

    // --- 2. Icon Item ---
    [HtmlTargetElement("rcl-social-icon", ParentTag = "rcl-social-container")]
    public class SocialIconHelper : SocialIconProperties, ITagHelper
    {
        public int Order => 0;
        public void Init(TagHelperContext context) { }

        public void Process(TagHelperContext context, TagHelperOutput output)
        {
            var validationContext = new ValidationContext(this);
            Validator.ValidateObject(this, validationContext, validateAllProperties: true);

            // Strip the <rcl-social-icon> tag
            output.TagName = null;

            var htmlResult = RclSocialIconRenderer.Render(this);
            output.Content.SetHtmlContent(htmlResult);
        }
    }
}

### Renderer

using WTS.RazorComponentLibrary.Models.RclComponents;

namespace WTS.RazorComponentLibrary.Renderers
{
    public static class RclSocialContainerRenderer
    {
        public static string Render(SocialContainerProperties p)
        {
            return $@"
                <div class=""socialsharer-container"">
                    {p.Content}
                </div>";
        }
    }

    public static class RclSocialIconRenderer
    {
        public static string Render(SocialIconProperties p)
        {
            string iconClass = p.Platform switch
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

            string finalTitle = string.IsNullOrWhiteSpace(p.Title) 
                ? $"{p.Platform} Link" 
                : p.Title;

            // Empty <a> tags need explicit closing for HTML compliance, and aria-label for ADA
            return $"<a href=\"{p.Href}\" class=\"{iconClass}\" title=\"{finalTitle}\" aria-label=\"{finalTitle}\"></a>";
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
    public class SocialShareTests
    {
        // --- 1. Property Validation Tests ---

        [TestMethod]
        [ExpectedException(typeof(ValidationException))]
        public void IconProperties_EmptyHref_ThrowsValidationException()
        {
            // Arrange
            var props = new SocialIconProperties
            {
                Platform = SocialPlatform.Facebook,
                Href = string.Empty // Invalid: Link needs a destination
            };
            var context = new ValidationContext(props);

            // Act
            Validator.ValidateObject(props, context, validateAllProperties: true);
        }

        // --- 2. Renderer Tests ---

        [TestMethod]
        public void ContainerRenderer_OutputsWrapperDiv()
        {
            // Arrange
            var props = new SocialContainerProperties { Content = "<a href=\"#\">Icon</a>" };

            // Act
            var result = RclSocialContainerRenderer.Render(props);

            // Assert
            Assert.IsTrue(result.Contains("<div class=\"socialsharer-container\">"));
            Assert.IsTrue(result.Contains("<a href=\"#\">Icon</a>"));
        }

        [TestMethod]
        public void IconRenderer_MissingTitle_GeneratesFallbackTitleAndAriaLabel()
        {
            // Arrange
            var props = new SocialIconProperties
            {
                Platform = SocialPlatform.GitHub,
                Href = "https://github.com",
                Title = string.Empty // Intentionally blank
            };

            // Act
            var result = RclSocialIconRenderer.Render(props);

            // Assert
            Assert.IsTrue(result.Contains("class=\"ca-gov-icon-github\""));
            Assert.IsTrue(result.Contains("title=\"GitHub Link\""));
            Assert.IsTrue(result.Contains("aria-label=\"GitHub Link\""));
        }

        [TestMethod]
        public void IconRenderer_ProvidedTitle_OverridesFallback()
        {
            // Arrange
            var props = new SocialIconProperties
            {
                Platform = SocialPlatform.Twitter,
                Href = "https://twitter.com",
                Title = "Follow us on X"
            };

            // Act
            var result = RclSocialIconRenderer.Render(props);

            // Assert
            Assert.IsTrue(result.Contains("class=\"ca-gov-icon-share-twitter\""));
            Assert.IsTrue(result.Contains("title=\"Follow us on X\""));
            Assert.IsTrue(result.Contains("aria-label=\"Follow us on X\""));
            Assert.IsFalse(result.Contains("Twitter Link"));
        }

        [TestMethod]
        public void IconRenderer_EnsuresExplicitClosingAnchorTag()
        {
            // Arrange
            var props = new SocialIconProperties { Platform = SocialPlatform.Email };

            // Act
            var result = RclSocialIconRenderer.Render(props);

            // Assert
            Assert.IsTrue(result.EndsWith("></a>"));
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
        public async Task ContainerHelper_ProcessAsync_StripsOriginalTagAndRenders()
        {
            // Arrange
            var (context, output) = CreateTagHelperEssentials("Inner HTML", "rcl-social-container");
            var helper = new SocialContainerHelper();

            // Act
            await helper.ProcessAsync(context, output);

            // Assert
            Assert.IsNull(output.TagName); // <rcl-social-container> should be stripped
            Assert.IsTrue(output.Content.GetContent().Contains("socialsharer-container"));
            Assert.IsTrue(output.Content.GetContent().Contains("Inner HTML"));
        }

        [TestMethod]
        public void IconHelper_Process_StripsOriginalTagAndRendersIcon()
        {
            // Arrange
            var context = new TagHelperContext(
                new TagHelperAttributeList(),
                new Dictionary<object, object>(),
                "test-id");

            // No child content needed for the icon itself
            var output = new TagHelperOutput(
                "rcl-social-icon",
                new TagHelperAttributeList(),
                (useCachedResult, encoder) => Task.FromResult<TagHelperContent>(new DefaultTagHelperContent()));

            var helper = new SocialIconHelper
            {
                Platform = SocialPlatform.LinkedIn,
                Href = "/linkedin"
            };

            // Act
            helper.Process(context, output);

            // Assert
            Assert.IsNull(output.TagName); // <rcl-social-icon> should be stripped
            
            var finalHtml = output.Content.GetContent();
            Assert.IsTrue(finalHtml.Contains("href=\"/linkedin\""));
            Assert.IsTrue(finalHtml.Contains("class=\"ca-gov-icon-share-linkedin\""));
            Assert.IsTrue(finalHtml.Contains("title=\"LinkedIn Link\""));
        }
    }
}