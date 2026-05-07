### DTO

using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Razor.TagHelpers;

namespace WTS.RazorComponentLibrary.Models.RclComponents
{
    public enum ButtonSize
    {
        Default,
        Lg,
        Sm,
        Xs
    }

    public enum ButtonColor
    {
        Primary,
        Secondary,
        Success,
        Danger,
        Warning,
        Info,
        Light,
        Dark
    }

    public class ButtonProperties
    {
        public ButtonColor Color { get; set; } = ButtonColor.Primary;
        public ButtonSize Size { get; set; } = ButtonSize.Default;
        public bool IsOutline { get; set; }
        public bool IsDisabled { get; set; }
        public bool IsHover { get; set; }
        public string Href { get; set; } = string.Empty;

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
    [HtmlTargetElement("rcl-button")]
    public class ButtonHelper : ButtonProperties, ITagHelper
    {
        public int Order => 0;
        public void Init(TagHelperContext context) { }

        public async Task ProcessAsync(TagHelperContext context, TagHelperOutput output)
        {
            var childContent = await output.GetChildContentAsync();
            this.Content = childContent.GetContent().Trim();

            var validationContext = new ValidationContext(this);
            Validator.ValidateObject(this, validationContext, validateAllProperties: true);

            // Strip the <rcl-button> tag; the renderer will output the <a> or <button>
            output.TagName = null;

            var htmlResult = RclButtonRenderer.Render(this);
            output.Content.SetHtmlContent(htmlResult);
        }
    }
}


### Renderer

using System.Collections.Generic;
using WTS.RazorComponentLibrary.Models.RclComponents;

namespace WTS.RazorComponentLibrary.Renderers
{
    public static class RclButtonRenderer
    {
        public static string Render(ButtonProperties p)
        {
            var classes = new List<string> { "btn" };

            // 1. Resolve Color and Outline
            string outlineModifier = p.IsOutline ? "-outline" : "";
            string colorString = p.Color.ToString().ToLowerInvariant();
            classes.Add($"btn{outlineModifier}-{colorString}");

            // 2. Resolve Size
            switch (p.Size)
            {
                case ButtonSize.Lg: classes.Add("btn-lg"); break;
                case ButtonSize.Sm: classes.Add("btn-sm"); break;
                case ButtonSize.Xs: classes.Add("btn-xs"); break;
            }

            // 3. Resolve States
            if (p.IsDisabled) classes.Add("disabled");
            if (p.IsHover) classes.Add("btn-hover");

            string classString = string.Join(" ", classes);

            // 4. Resolve Tag Type
            if (!string.IsNullOrWhiteSpace(p.Href))
            {
                // Anchor tag needs aria-disabled and negative tabindex if disabled
                string disabledAttr = p.IsDisabled ? " aria-disabled=\"true\" tabindex=\"-1\"" : string.Empty;
                return $"<a href=\"{p.Href}\" class=\"{classString}\" role=\"button\"{disabledAttr}>{p.Content}</a>";
            }
            else
            {
                // Button tag gets the standard disabled attribute
                string disabledAttr = p.IsDisabled ? " disabled=\"disabled\"" : string.Empty;
                return $"<button class=\"{classString}\"{disabledAttr}>{p.Content}</button>";
            }
        }
    }
}


### test

using Microsoft.VisualStudio.TestTools.UnitTesting;
using Microsoft.AspNetCore.Razor.TagHelpers;
using System.Collections.Generic;
using System.Threading.Tasks;
using WTS.RazorComponentLibrary.Models.RclComponents;
using WTS.RazorComponentLibrary.Renderers;
using WTS.RazorLibrary.TagHelpers;

namespace WTS.RazorLibrary.Tests
{
    [TestClass]
    public class ButtonTests
    {
        // --- 1. Renderer Tests ---

        [TestMethod]
        public void Renderer_WithHref_OutputsAnchorTag()
        {
            // Arrange
            var props = new ButtonProperties
            {
                Href = "/home",
                Color = ButtonColor.Primary,
                Content = "Go Home"
            };

            // Act
            var result = RclButtonRenderer.Render(props);

            // Assert
            Assert.IsTrue(result.StartsWith("<a href=\"/home\""));
            Assert.IsTrue(result.Contains("role=\"button\""));
            Assert.IsTrue(result.Contains("class=\"btn btn-primary\""));
            Assert.IsTrue(result.Contains(">Go Home</a>"));
        }

        [TestMethod]
        public void Renderer_WithoutHref_OutputsButtonTag()
        {
            // Arrange
            var props = new ButtonProperties
            {
                Href = string.Empty,
                Color = ButtonColor.Success,
                Size = ButtonSize.Lg,
                Content = "Submit"
            };

            // Act
            var result = RclButtonRenderer.Render(props);

            // Assert
            Assert.IsTrue(result.StartsWith("<button"));
            Assert.IsTrue(result.Contains("class=\"btn btn-success btn-lg\""));
            Assert.IsTrue(result.Contains(">Submit</button>"));
        }

        [TestMethod]
        public void Renderer_OutlineAndHover_GeneratesCorrectClasses()
        {
            // Arrange
            var props = new ButtonProperties
            {
                Color = ButtonColor.Danger,
                IsOutline = true,
                IsHover = true
            };

            // Act
            var result = RclButtonRenderer.Render(props);

            // Assert
            Assert.IsTrue(result.Contains("btn btn-outline-danger btn-hover"));
        }

        [TestMethod]
        public void Renderer_DisabledAnchor_GeneratesAriaDisabled()
        {
            // Arrange
            var props = new ButtonProperties
            {
                Href = "/disabled-link",
                IsDisabled = true
            };

            // Act
            var result = RclButtonRenderer.Render(props);

            // Assert
            Assert.IsTrue(result.Contains("class=\"btn btn-primary disabled\""));
            Assert.IsTrue(result.Contains("aria-disabled=\"true\""));
            Assert.IsTrue(result.Contains("tabindex=\"-1\""));
        }

        [TestMethod]
        public void Renderer_DisabledButton_GeneratesDisabledAttribute()
        {
            // Arrange
            var props = new ButtonProperties
            {
                IsDisabled = true
            };

            // Act
            var result = RclButtonRenderer.Render(props);

            // Assert
            Assert.IsTrue(result.Contains("class=\"btn btn-primary disabled\""));
            Assert.IsTrue(result.Contains("disabled=\"disabled\""));
        }

        // --- 2. Tag Helper Execution Tests ---

        private (TagHelperContext, TagHelperOutput) CreateTagHelperEssentials(string childContentText)
        {
            var context = new TagHelperContext(
                new TagHelperAttributeList(),
                new Dictionary<object, object>(),
                "test-id");

            var childContent = new DefaultTagHelperContent();
            childContent.SetHtmlContent(childContentText);

            var output = new TagHelperOutput(
                "rcl-button",
                new TagHelperAttributeList(),
                (useCachedResult, encoder) => Task.FromResult<TagHelperContent>(childContent));

            return (context, output);
        }

        [TestMethod]
        public async Task Helper_ProcessAsync_StripsOriginalTagAndRendersHtml()
        {
            // Arrange
            var (context, output) = CreateTagHelperEssentials("Click Me");
            var helper = new ButtonHelper
            {
                Color = ButtonColor.Warning,
                Size = ButtonSize.Sm
            };

            // Act
            await helper.ProcessAsync(context, output);

            // Assert
            Assert.IsNull(output.TagName); // <rcl-button> should be stripped
            
            var finalHtml = output.Content.GetContent();
            Assert.IsTrue(finalHtml.Contains("<button class=\"btn btn-warning btn-sm\">"));
            Assert.IsTrue(finalHtml.Contains("Click Me</button>"));
        }
    }
}