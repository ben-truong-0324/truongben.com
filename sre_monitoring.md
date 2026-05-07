### DTO
using System.ComponentModel.DataAnnotations;
using WTS.RazorComponentLibrary.Models.Helpers; // Assuming RequiredIf lives here if needed later

namespace WTS.RazorComponentLibrary.Models.RclComponents
{
    public enum AccordionVariant
    {
        Default,
        List,
        SideNav
    }

    public class AccordionProperties
    {
        public AccordionVariant Variant { get; set; } = AccordionVariant.Default;

        [HtmlAttributeNotBound]
        public string Content { get; set; } = string.Empty;
    }

    public class AccordionItemProperties
    {
        [Required(ErrorMessage = "A Heading is required for ADA compliance to ensure screen readers can navigate the accordion.")]
        public string Heading { get; set; } = string.Empty;

        public bool IsOpen { get; set; }

        [HtmlAttributeNotBound]
        public AccordionVariant Variant { get; set; } = AccordionVariant.Default;

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
    // Parent Container Tag Helper
    [HtmlTargetElement("rcl-accordion")]
    public class AccordionHelper : AccordionProperties, ITagHelper
    {
        public int Order => 0;
        public void Init(TagHelperContext context) { }

        public async Task ProcessAsync(TagHelperContext context, TagHelperOutput output)
        {
            // Pass variant down to child items
            context.Items["AccordionVariant"] = this.Variant;

            var childContent = await output.GetChildContentAsync();
            this.Content = childContent.GetContent();

            var validationContext = new ValidationContext(this);
            Validator.ValidateObject(this, validationContext, validateAllProperties: true);

            output.TagName = null; 
            
            var htmlResult = RclAccordionRenderer.Render(this);
            output.Content.SetHtmlContent(htmlResult);
        }
    }

    // Child Item Tag Helper
    [HtmlTargetElement("rcl-accordion-item", ParentTag = "rcl-accordion")]
    public class AccordionItemHelper : AccordionItemProperties, ITagHelper
    {
        public int Order => 0;
        public void Init(TagHelperContext context) { }

        public async Task ProcessAsync(TagHelperContext context, TagHelperOutput output)
        {
            // Retrieve variant from parent container
            if (context.Items.TryGetValue("AccordionVariant", out var variantObj) && variantObj is AccordionVariant variant)
            {
                this.Variant = variant;
            }

            var childContent = await output.GetChildContentAsync();
            this.Content = childContent.GetContent();

            var validationContext = new ValidationContext(this);
            Validator.ValidateObject(this, validationContext, validateAllProperties: true);

            output.TagName = null;

            var htmlResult = RclAccordionItemRenderer.Render(this);
            output.Content.SetHtmlContent(htmlResult);
        }
    }
}


### Renderer


namespace WTS.RazorComponentLibrary.Renderers
{
    public static class RclAccordionRenderer
    {
        public static string Render(AccordionProperties p)
        {
            if (p.Variant == AccordionVariant.List)
            {
                return $@"
                    <ol data-aria-accordion data-multi data-transition data-default=""none"">
                        {p.Content}
                    </ol>";
            }

            return p.Content;
        }
    }

    public static class RclAccordionItemRenderer
    {
        public static string Render(AccordionItemProperties p)
        {
            return p.Variant switch
            {
                AccordionVariant.List => RenderListAccordion(p),
                AccordionVariant.SideNav => RenderSideNavAccordion(p),
                _ => RenderDefaultAccordion(p)
            };
        }

        private static string RenderListAccordion(AccordionItemProperties p) =>
            $@"<li>
                <h3 data-aria-accordion-heading>{p.Heading}</h3>
                <div data-aria-accordion-panel>
                    {p.Content}
                </div>
               </li>";

        private static string RenderSideNavAccordion(AccordionItemProperties p)
        {
            string openAttr = p.IsOpen ? " open" : string.Empty;
            string activeClass = p.IsOpen ? " class=\"active\"" : string.Empty;

            return $@"<cagov-accordion class=""sidenav"">
                        <details{openAttr}>
                            <summary{activeClass}>{p.Heading}</summary>
                            <div class=""accordion-body"">
                                {p.Content}
                            </div>
                        </details>
                      </cagov-accordion>";
        }

        private static string RenderDefaultAccordion(AccordionItemProperties p) =>
            $@"<cagov-accordion>
                <details>
                    <summary>{p.Heading}</summary>
                    <div class=""accordion-body"">
                        {p.Content}
                    </div>
                </details>
               </cagov-accordion>";
    }
}


### test

using Microsoft.VisualStudio.TestTools.UnitTesting;
using System.ComponentModel.DataAnnotations;
using WTS.RazorComponentLibrary.Models.RclComponents;

namespace WTS.RazorLibrary.Tests
{
    [TestClass]
    public class AccordionPropertiesTests
    {
        [TestMethod]
        [ExpectedException(typeof(ValidationException))]
        public void AccordionItem_MissingHeading_ThrowsValidationException_ForADACompliance()
        {
            // Arrange
            var itemProperties = new AccordionItemProperties
            {
                Heading = string.Empty, // Invalid: Needs a heading for screen readers
                Variant = AccordionVariant.Default
            };
            var context = new ValidationContext(itemProperties);

            // Act
            Validator.ValidateObject(itemProperties, context, validateAllProperties: true);

            // Assert is handled by ExpectedException
        }

        [TestMethod]
        public void AccordionItem_ValidHeading_PassesValidation()
        {
            // Arrange
            var itemProperties = new AccordionItemProperties
            {
                Heading = "Valid ADA Heading",
                Variant = AccordionVariant.Default
            };
            var context = new ValidationContext(itemProperties);

            // Act & Assert (Should not throw)
            Validator.ValidateObject(itemProperties, context, validateAllProperties: true);
        }
    }
}


### DTO
using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Razor.TagHelpers;

namespace WTS.RazorComponentLibrary.Models.RclComponents
{
    public enum AlertVariant
    {
        Info,
        Warning,
        Danger,
        Resolution
    }

    public class AlertProperties
    {
        public AlertVariant Variant { get; set; } = AlertVariant.Info;

        [HtmlAttributeNotBound]
        [Required(AllowEmptyStrings = false, ErrorMessage = "Alert content is required so screen readers have text to announce.")]
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
    [HtmlTargetElement("rcl-alert")]
    public class AlertHelper : AlertProperties, ITagHelper
    {
        public int Order => 0;
        public void Init(TagHelperContext context) { }

        public async Task ProcessAsync(TagHelperContext context, TagHelperOutput output)
        {
            var childContent = await output.GetChildContentAsync();
            this.Content = childContent.GetContent().Trim();

            var validationContext = new ValidationContext(this);
            Validator.ValidateObject(this, validationContext, validateAllProperties: true);

            // Strip the <rcl-alert> tag and let the renderer build the wrapper
            output.TagName = null;

            var htmlResult = RclAlertRenderer.Render(this);
            output.Content.SetHtmlContent(htmlResult);
        }
    }
}

### Renderer

using WTS.RazorComponentLibrary.Models.RclComponents;

namespace WTS.RazorComponentLibrary.Renderers
{
    public static class RclAlertRenderer
    {
        public static string Render(AlertProperties p)
        {
            string iconHtml = p.Variant switch
            {
                AlertVariant.Warning => @"<span class=""alert-icon ca-gov-icon-warning-triangle text-warning"" aria-hidden=""true""></span>",
                AlertVariant.Danger => @"<img src=""https://template.webstandards.ca.gov/images/alert-warning-diamond.svg"" alt=""alert warning icon"" />",
                AlertVariant.Resolution => @"<img src=""https://template.webstandards.ca.gov/images/alert-success.svg"" alt=""alert success icon"" />",
                _ => @"<img src=""https://template.webstandards.ca.gov/images/alert-info.svg"" alt=""alert info icon"" />" // Default to Info
            };

            return $@"
                <div class=""alert alert-dismissible alert-banner"" role=""alert"">
                    <div class=""container"">
                        {iconHtml}
                        <span class=""alert-text"">
                            {p.Content}
                        </span>
                        <button type=""button"" class=""close ms-lg-auto"" data-bs-dismiss=""alert"" aria-label=""Close"">
                            <span class=""ca-gov-icon-close-mark"" aria-hidden=""true""></span>
                        </button>
                    </div>
                </div>";
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
    public class AlertTests
    {
        // --- 1. Property Validation Tests ---

        [TestMethod]
        [ExpectedException(typeof(ValidationException))]
        public void AlertProperties_EmptyContent_ThrowsValidationException()
        {
            // Arrange
            var props = new AlertProperties
            {
                Variant = AlertVariant.Info,
                Content = string.Empty // Invalid: Content is required
            };
            var context = new ValidationContext(props);

            // Act
            Validator.ValidateObject(props, context, validateAllProperties: true);

            // Assert is handled by ExpectedException
        }

        [TestMethod]
        public void AlertProperties_ValidContent_PassesValidation()
        {
            // Arrange
            var props = new AlertProperties
            {
                Variant = AlertVariant.Danger,
                Content = "System is down."
            };
            var context = new ValidationContext(props);

            // Act & Assert (Should not throw)
            Validator.ValidateObject(props, context, validateAllProperties: true);
        }

        // --- 2. Renderer Tests ---

        [TestMethod]
        public void Renderer_WarningVariant_OutputsSpanIconAndContent()
        {
            // Arrange
            var props = new AlertProperties
            {
                Variant = AlertVariant.Warning,
                Content = "This is a warning."
            };

            // Act
            var result = RclAlertRenderer.Render(props);

            // Assert
            Assert.IsTrue(result.Contains("role=\"alert\""));
            Assert.IsTrue(result.Contains("ca-gov-icon-warning-triangle text-warning")); // Warning specific
            Assert.IsTrue(result.Contains("<span class=\"alert-text\">"));
            Assert.IsTrue(result.Contains("This is a warning."));
            Assert.IsTrue(result.Contains("data-bs-dismiss=\"alert\""));
        }

        [TestMethod]
        public void Renderer_ResolutionVariant_OutputsSvgImage()
        {
            // Arrange
            var props = new AlertProperties
            {
                Variant = AlertVariant.Resolution,
                Content = "Saved successfully."
            };

            // Act
            var result = RclAlertRenderer.Render(props);

            // Assert
            Assert.IsTrue(result.Contains("alert-success.svg")); // Resolution specific
            Assert.IsTrue(result.Contains("Saved successfully."));
        }

        // --- 3. Tag Helper Execution Tests ---

        private (TagHelperContext, TagHelperOutput) CreateTagHelperEssentials(string childContentText)
        {
            var context = new TagHelperContext(
                new TagHelperAttributeList(),
                new Dictionary<object, object>(),
                "test-id");

            var childContent = new DefaultTagHelperContent();
            childContent.SetHtmlContent(childContentText);

            var output = new TagHelperOutput(
                "rcl-alert",
                new TagHelperAttributeList(),
                (useCachedResult, encoder) => Task.FromResult<TagHelperContent>(childContent));

            return (context, output);
        }

        [TestMethod]
        public async Task AlertHelper_ProcessAsync_StripsOriginalTagAndRendersHtml()
        {
            // Arrange
            var (context, output) = CreateTagHelperEssentials("Important information here.");
            var helper = new AlertHelper
            {
                Variant = AlertVariant.Info
            };

            // Act
            await helper.ProcessAsync(context, output);

            // Assert
            Assert.IsNull(output.TagName); // <rcl-alert> should be stripped
            
            var finalHtml = output.Content.GetContent();
            Assert.IsTrue(finalHtml.Contains("<div class=\"alert alert-dismissible alert-banner\""));
            Assert.IsTrue(finalHtml.Contains("Important information here."));
            Assert.IsTrue(finalHtml.Contains("alert-info.svg")); // Default info icon
        }
    }
}


### DTO

using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Razor.TagHelpers;
using WTS.RazorComponentLibrary.Models.Helpers; // Assuming RequiredIf lives here

namespace WTS.RazorComponentLibrary.Models.RclComponents
{
    public enum BlockquoteVariant
    {
        Default,
        NoGraphic,
        Prominent,
        Pull,
        WithImage
    }

    public class BlockquoteProperties
    {
        public BlockquoteVariant Variant { get; set; } = BlockquoteVariant.Default;
        
        public string Author { get; set; } = string.Empty;
        
        public string ImageSrc { get; set; } = string.Empty;

        [RequiredIf("Variant", BlockquoteVariant.WithImage, ErrorMessage = "ImageAlt is required for ADA compliance when using the WithImage variant.")]
        public string ImageAlt { get; set; } = string.Empty;

        [HtmlAttributeNotBound]
        [Required(AllowEmptyStrings = false, ErrorMessage = "Blockquote content is required.")]
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
    [HtmlTargetElement("rcl-blockquote")]
    public class BlockquoteHelper : BlockquoteProperties, ITagHelper
    {
        public int Order => 0;
        public void Init(TagHelperContext context) { }

        public async Task ProcessAsync(TagHelperContext context, TagHelperOutput output)
        {
            var childContent = await output.GetChildContentAsync();
            this.Content = childContent.GetContent().Trim();

            // Run validation (this will catch missing Alt Text on images)
            var validationContext = new ValidationContext(this);
            Validator.ValidateObject(this, validationContext, validateAllProperties: true);

            // Strip the <rcl-blockquote> tag as the renderer handles the wrapper
            output.TagName = null;

            var htmlResult = RclBlockquoteRenderer.Render(this);
            output.Content.SetHtmlContent(htmlResult);
        }
    }
}

### Renderer

using WTS.RazorComponentLibrary.Models.RclComponents;

namespace WTS.RazorComponentLibrary.Renderers
{
    public static class RclBlockquoteRenderer
    {
        public static string Render(BlockquoteProperties p)
        {
            string footerHtml = string.IsNullOrWhiteSpace(p.Author) 
                ? string.Empty 
                : $"<footer>{p.Author}</footer>";

            if (p.Variant == BlockquoteVariant.WithImage)
            {
                return $@"
                    <div class=""row"">
                        <div class=""col-md-4 text-right p-r-md p-t-sm"">
                            <img src=""{p.ImageSrc}"" class=""img-fluid img-circle height-150"" alt=""{p.ImageAlt}"" />
                        </div>
                        <div class=""col-md-8"">
                            <blockquote>
                                {p.Content}
                                {footerHtml}
                            </blockquote>
                        </div>
                    </div>";
            }

            string cssClass = p.Variant switch
            {
                BlockquoteVariant.NoGraphic => " class=\"no-quotation-mark\"",
                BlockquoteVariant.Prominent => " class=\"prominent\"",
                BlockquoteVariant.Pull => " class=\"pull-quote\"",
                _ => string.Empty
            };

            return $@"
                <blockquote{cssClass}>
                    {p.Content}
                    {footerHtml}
                </blockquote>";
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
    public class BlockquoteTests
    {
        // --- 1. Property Validation Tests ---

        [TestMethod]
        [ExpectedException(typeof(ValidationException))]
        public void Properties_WithImageVariant_MissingAltText_ThrowsValidationException()
        {
            // Arrange
            var props = new BlockquoteProperties
            {
                Variant = BlockquoteVariant.WithImage,
                ImageSrc = "/images/portrait.jpg",
                ImageAlt = string.Empty, // Invalid: Alt text required for ADA when using image
                Content = "A great quote."
            };
            var context = new ValidationContext(props);

            // Act
            Validator.ValidateObject(props, context, validateAllProperties: true);
        }

        [TestMethod]
        public void Properties_WithImageVariant_ValidAltText_PassesValidation()
        {
            // Arrange
            var props = new BlockquoteProperties
            {
                Variant = BlockquoteVariant.WithImage,
                ImageSrc = "/images/portrait.jpg",
                ImageAlt = "Portrait of the author",
                Content = "A great quote."
            };
            var context = new ValidationContext(props);

            // Act & Assert (Should not throw)
            Validator.ValidateObject(props, context, validateAllProperties: true);
        }

        // --- 2. Renderer Tests ---

        [TestMethod]
        public void Renderer_WithImageVariant_RendersGridRowAndImage()
        {
            // Arrange
            var props = new BlockquoteProperties
            {
                Variant = BlockquoteVariant.WithImage,
                ImageSrc = "img.png",
                ImageAlt = "alt text",
                Content = "Image quote content"
            };

            // Act
            var result = RclBlockquoteRenderer.Render(props);

            // Assert
            Assert.IsTrue(result.Contains("<div class=\"row\">"));
            Assert.IsTrue(result.Contains("<img src=\"img.png\""));
            Assert.IsTrue(result.Contains("alt=\"alt text\""));
            Assert.IsTrue(result.Contains("<blockquote>"));
            Assert.IsFalse(result.Contains("<footer>")); // No author provided
        }

        [TestMethod]
        public void Renderer_PullVariantWithAuthor_RendersClassAndFooter()
        {
            // Arrange
            var props = new BlockquoteProperties
            {
                Variant = BlockquoteVariant.Pull,
                Content = "Pull quote text.",
                Author = "Jane Doe"
            };

            // Act
            var result = RclBlockquoteRenderer.Render(props);

            // Assert
            Assert.IsTrue(result.Contains("<blockquote class=\"pull-quote\">"));
            Assert.IsTrue(result.Contains("<footer>Jane Doe</footer>"));
            Assert.IsTrue(result.Contains("Pull quote text."));
        }

        // --- 3. Tag Helper Execution Tests ---

        private (TagHelperContext, TagHelperOutput) CreateTagHelperEssentials(string childContentText)
        {
            var context = new TagHelperContext(
                new TagHelperAttributeList(),
                new Dictionary<object, object>(),
                "test-id");

            var childContent = new DefaultTagHelperContent();
            childContent.SetHtmlContent(childContentText);

            var output = new TagHelperOutput(
                "rcl-blockquote",
                new TagHelperAttributeList(),
                (useCachedResult, encoder) => Task.FromResult<TagHelperContent>(childContent));

            return (context, output);
        }

        [TestMethod]
        public async Task Helper_ProcessAsync_StripsOriginalTagAndRendersHtml()
        {
            // Arrange
            var (context, output) = CreateTagHelperEssentials("Standard quote text.");
            var helper = new BlockquoteHelper
            {
                Variant = BlockquoteVariant.Prominent,
                Author = "John Smith"
            };

            // Act
            await helper.ProcessAsync(context, output);

            // Assert
            Assert.IsNull(output.TagName); // <rcl-blockquote> should be stripped
            
            var finalHtml = output.Content.GetContent();
            Assert.IsTrue(finalHtml.Contains("<blockquote class=\"prominent\">"));
            Assert.IsTrue(finalHtml.Contains("Standard quote text."));
            Assert.IsTrue(finalHtml.Contains("<footer>John Smith</footer>"));
        }
    }
}

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


# tag

using Microsoft.AspNetCore.Razor.TagHelpers;
using System;
using System.Threading.Tasks;

namespace MyComponentLibrary.TagHelpers
{
    [HtmlTargetElement("rcl-countdown-timer")]
    public class CountdownTimerTagHelper : TagHelper
    {
        // Accept a native C# DateTime object
        public DateTime TargetDate { get; set; }

        // Optional: Let developers specify an ID, otherwise auto-generate one
        public string TimerId { get; set; }

        public override void Process(TagHelperContext context, TagHelperOutput output)
        {
            // Strip the parent tag
            output.TagName = null;

            // Generate a unique ID if one wasn't provided
            var id = string.IsNullOrWhiteSpace(TimerId) 
                ? Guid.NewGuid().ToString("N").Substring(0, 6) 
                : TimerId;

            // Format date safely for JS parsing
            string jsDateString = TargetDate.ToString("MMM d, yyyy HH:mm:ss");

            string htmlContent = $@"
<div class=""row flex-column flex-md-row countdown p-x"">
  <div class=""col bg-gray-100 text-center p-b-md p-l-0 p-r-0"">
    <span class=""countdown-text""><abbr title=""weeks"" aria-label=""weeks"" class=""text-decoration-none"">wks</abbr><br /></span>
    <span id=""weeks_{id}""></span>
  </div>
  <div class=""col bg-gray-100 text-center p-b-md p-l-0 p-r-0"">
    <span class=""countdown-text"">days<br /></span>
    <span id=""days_{id}""></span>
  </div>
  <div class=""col bg-gray-100 text-center p-b-md p-l-0 p-r-0"">
    <span class=""countdown-text""><abbr title=""hours"" aria-label=""hours"" class=""text-decoration-none"">hrs</abbr><br /></span>
    <span id=""hours_{id}""></span>
  </div>
  <div class=""col bg-gray-100 text-center p-b-md p-l-0 p-r-0"">
    <span class=""countdown-text""><abbr title=""minutes"" aria-label=""minutes"" class=""text-decoration-none"">mins</abbr><br /></span>
    <span id=""minutes_{id}""></span>
  </div>
  <div class=""col bg-gray-100 text-center p-b-md p-l-0 p-r-0"">
    <span class=""countdown-text""><abbr title=""seconds"" aria-label=""seconds"" class=""text-decoration-none"">secs</abbr><br /></span>
    <span id=""seconds_{id}""></span>
  </div>
</div>

<script>
  (function() {{
      var countDownDate = new Date(""{jsDateString}"").getTime();
      var x = setInterval(function () {{
          var now = new Date().getTime();
          var distance = countDownDate - now;

          var weeks = Math.floor(distance / (1000 * 60 * 60 * 24 * 7));
          var days = Math.floor(distance / (1000 * 60 * 60 * 24));
          var hours = Math.floor((distance % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60));
          var minutes = Math.floor((distance % (1000 * 60 * 60)) / (1000 * 60));
          var seconds = Math.floor((distance % (1000 * 60)) / 1000);

          var weeksEl = document.getElementById(""weeks_{id}"");
          var daysEl = document.getElementById(""days_{id}"");
          var hoursEl = document.getElementById(""hours_{id}"");
          var minutesEl = document.getElementById(""minutes_{id}"");
          var secondsEl = document.getElementById(""seconds_{id}"");

          if(weeksEl) weeksEl.innerHTML = weeks;
          if(daysEl) daysEl.innerHTML = days;
          if(hoursEl) hoursEl.innerHTML = hours;
          if(minutesEl) minutesEl.innerHTML = minutes;
          if(secondsEl) secondsEl.innerHTML = seconds;

          if (distance < 0) {{
              clearInterval(x);
              if(daysEl) daysEl.innerHTML = ""EXPIRED"";
          }}
      }}, 1000);
  }})();
</script>";

            output.Content.SetHtmlContent(htmlContent);
        }
    }
}

# cshtml

<rcl-countdown-timer target-date="Jan 1, 2026 00:00:00"></rcl-countdown-timer>

<rcl-countdown-timer target-date="2026-12-31T23:59:59" timer-id="NewYearsEve"></rcl-countdown-timer>

<rcl-countdown-timer target-date="@Model.ProjectLaunchDate"></rcl-countdown-timer>

# docs

Countdown Timer Component (<rcl-countdown-timer>)

Renders a 5-column countdown timer (weeks, days, hours, minutes, seconds) and automatically injects the necessary scoped JavaScript to update it every second.
Setup

Ensure the Tag Helpers are registered in your _ViewImports.cshtml:
HTML

@addTagHelper *, MyComponentLibrary

Here is the implementation for the Countdown Timer.

Because countdown timers rely on element id attributes to update the DOM via JavaScript, I've added a unique ID generation step. This ensures that if you put multiple <rcl-countdown-timer> components on the same page, their scripts won't collide and overwrite each other. I also wrapped the generated JavaScript in an Immediately Invoked Function Expression (IIFE) to prevent polluting the global window scope with variables.
1. The Tag Helper Logic (CountdownTimerTagHelper.cs)
C#

using Microsoft.AspNetCore.Razor.TagHelpers;
using System;
using System.Threading.Tasks;

namespace MyComponentLibrary.TagHelpers
{
    [HtmlTargetElement("rcl-countdown-timer")]
    public class CountdownTimerTagHelper : TagHelper
    {
        // Accept a native C# DateTime object
        public DateTime TargetDate { get; set; }

        // Optional: Let developers specify an ID, otherwise auto-generate one
        public string TimerId { get; set; }

        public override void Process(TagHelperContext context, TagHelperOutput output)
        {
            // Strip the parent tag
            output.TagName = null;

            // Generate a unique ID if one wasn't provided
            var id = string.IsNullOrWhiteSpace(TimerId) 
                ? Guid.NewGuid().ToString("N").Substring(0, 6) 
                : TimerId;

            // Format date safely for JS parsing
            string jsDateString = TargetDate.ToString("MMM d, yyyy HH:mm:ss");

            string htmlContent = $@"
<div class=""row flex-column flex-md-row countdown p-x"">
  <div class=""col bg-gray-100 text-center p-b-md p-l-0 p-r-0"">
    <span class=""countdown-text""><abbr title=""weeks"" aria-label=""weeks"" class=""text-decoration-none"">wks</abbr><br /></span>
    <span id=""weeks_{id}""></span>
  </div>
  <div class=""col bg-gray-100 text-center p-b-md p-l-0 p-r-0"">
    <span class=""countdown-text"">days<br /></span>
    <span id=""days_{id}""></span>
  </div>
  <div class=""col bg-gray-100 text-center p-b-md p-l-0 p-r-0"">
    <span class=""countdown-text""><abbr title=""hours"" aria-label=""hours"" class=""text-decoration-none"">hrs</abbr><br /></span>
    <span id=""hours_{id}""></span>
  </div>
  <div class=""col bg-gray-100 text-center p-b-md p-l-0 p-r-0"">
    <span class=""countdown-text""><abbr title=""minutes"" aria-label=""minutes"" class=""text-decoration-none"">mins</abbr><br /></span>
    <span id=""minutes_{id}""></span>
  </div>
  <div class=""col bg-gray-100 text-center p-b-md p-l-0 p-r-0"">
    <span class=""countdown-text""><abbr title=""seconds"" aria-label=""seconds"" class=""text-decoration-none"">secs</abbr><br /></span>
    <span id=""seconds_{id}""></span>
  </div>
</div>

<script>
  (function() {{
      var countDownDate = new Date(""{jsDateString}"").getTime();
      var x = setInterval(function () {{
          var now = new Date().getTime();
          var distance = countDownDate - now;

          var weeks = Math.floor(distance / (1000 * 60 * 60 * 24 * 7));
          var days = Math.floor(distance / (1000 * 60 * 60 * 24));
          var hours = Math.floor((distance % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60));
          var minutes = Math.floor((distance % (1000 * 60 * 60)) / (1000 * 60));
          var seconds = Math.floor((distance % (1000 * 60)) / 1000);

          var weeksEl = document.getElementById(""weeks_{id}"");
          var daysEl = document.getElementById(""days_{id}"");
          var hoursEl = document.getElementById(""hours_{id}"");
          var minutesEl = document.getElementById(""minutes_{id}"");
          var secondsEl = document.getElementById(""seconds_{id}"");

          if(weeksEl) weeksEl.innerHTML = weeks;
          if(daysEl) daysEl.innerHTML = days;
          if(hoursEl) hoursEl.innerHTML = hours;
          if(minutesEl) minutesEl.innerHTML = minutes;
          if(secondsEl) secondsEl.innerHTML = seconds;

          if (distance < 0) {{
              clearInterval(x);
              if(daysEl) daysEl.innerHTML = ""EXPIRED"";
          }}
      }}, 1000);
  }})();
</script>";

            output.Content.SetHtmlContent(htmlContent);
        }
    }
}

2. Usage in your Views (.cshtml)

You can pass standard strings that C# can implicitly parse into DateTime, or pass explicit DateTime models.
HTML

<rcl-countdown-timer target-date="Jan 1, 2026 00:00:00"></rcl-countdown-timer>

<rcl-countdown-timer target-date="2026-12-31T23:59:59" timer-id="NewYearsEve"></rcl-countdown-timer>

<rcl-countdown-timer target-date="@Model.ProjectLaunchDate"></rcl-countdown-timer>

3. Documentation (README.md)
Countdown Timer Component (<rcl-countdown-timer>)

Renders a 5-column countdown timer (weeks, days, hours, minutes, seconds) and automatically injects the necessary scoped JavaScript to update it every second.
Setup

Ensure the Tag Helpers are registered in your _ViewImports.cshtml:
HTML

@addTagHelper *, MyComponentLibrary

Properties
Attribute	Type	Default	Description
target-date	DateTime	0001-01-01	Required. The future date and time to count down to.
timer-id	string	Random GUID	An optional prefix to use for the inner element IDs. If omitted, the Tag Helper will generate a random string to prevent JavaScript collisions.

Here is the implementation for the Countdown Timer.

Because countdown timers rely on element id attributes to update the DOM via JavaScript, I've added a unique ID generation step. This ensures that if you put multiple <rcl-countdown-timer> components on the same page, their scripts won't collide and overwrite each other. I also wrapped the generated JavaScript in an Immediately Invoked Function Expression (IIFE) to prevent polluting the global window scope with variables.
1. The Tag Helper Logic (CountdownTimerTagHelper.cs)
C#

using Microsoft.AspNetCore.Razor.TagHelpers;
using System;
using System.Threading.Tasks;

namespace MyComponentLibrary.TagHelpers
{
    [HtmlTargetElement("rcl-countdown-timer")]
    public class CountdownTimerTagHelper : TagHelper
    {
        // Accept a native C# DateTime object
        public DateTime TargetDate { get; set; }

        // Optional: Let developers specify an ID, otherwise auto-generate one
        public string TimerId { get; set; }

        public override void Process(TagHelperContext context, TagHelperOutput output)
        {
            // Strip the parent tag
            output.TagName = null;

            // Generate a unique ID if one wasn't provided
            var id = string.IsNullOrWhiteSpace(TimerId) 
                ? Guid.NewGuid().ToString("N").Substring(0, 6) 
                : TimerId;

            // Format date safely for JS parsing
            string jsDateString = TargetDate.ToString("MMM d, yyyy HH:mm:ss");

            string htmlContent = $@"
<div class=""row flex-column flex-md-row countdown p-x"">
  <div class=""col bg-gray-100 text-center p-b-md p-l-0 p-r-0"">
    <span class=""countdown-text""><abbr title=""weeks"" aria-label=""weeks"" class=""text-decoration-none"">wks</abbr><br /></span>
    <span id=""weeks_{id}""></span>
  </div>
  <div class=""col bg-gray-100 text-center p-b-md p-l-0 p-r-0"">
    <span class=""countdown-text"">days<br /></span>
    <span id=""days_{id}""></span>
  </div>
  <div class=""col bg-gray-100 text-center p-b-md p-l-0 p-r-0"">
    <span class=""countdown-text""><abbr title=""hours"" aria-label=""hours"" class=""text-decoration-none"">hrs</abbr><br /></span>
    <span id=""hours_{id}""></span>
  </div>
  <div class=""col bg-gray-100 text-center p-b-md p-l-0 p-r-0"">
    <span class=""countdown-text""><abbr title=""minutes"" aria-label=""minutes"" class=""text-decoration-none"">mins</abbr><br /></span>
    <span id=""minutes_{id}""></span>
  </div>
  <div class=""col bg-gray-100 text-center p-b-md p-l-0 p-r-0"">
    <span class=""countdown-text""><abbr title=""seconds"" aria-label=""seconds"" class=""text-decoration-none"">secs</abbr><br /></span>
    <span id=""seconds_{id}""></span>
  </div>
</div>

<script>
  (function() {{
      var countDownDate = new Date(""{jsDateString}"").getTime();
      var x = setInterval(function () {{
          var now = new Date().getTime();
          var distance = countDownDate - now;

          var weeks = Math.floor(distance / (1000 * 60 * 60 * 24 * 7));
          var days = Math.floor(distance / (1000 * 60 * 60 * 24));
          var hours = Math.floor((distance % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60));
          var minutes = Math.floor((distance % (1000 * 60 * 60)) / (1000 * 60));
          var seconds = Math.floor((distance % (1000 * 60)) / 1000);

          var weeksEl = document.getElementById(""weeks_{id}"");
          var daysEl = document.getElementById(""days_{id}"");
          var hoursEl = document.getElementById(""hours_{id}"");
          var minutesEl = document.getElementById(""minutes_{id}"");
          var secondsEl = document.getElementById(""seconds_{id}"");

          if(weeksEl) weeksEl.innerHTML = weeks;
          if(daysEl) daysEl.innerHTML = days;
          if(hoursEl) hoursEl.innerHTML = hours;
          if(minutesEl) minutesEl.innerHTML = minutes;
          if(secondsEl) secondsEl.innerHTML = seconds;

          if (distance < 0) {{
              clearInterval(x);
              if(daysEl) daysEl.innerHTML = ""EXPIRED"";
          }}
      }}, 1000);
  }})();
</script>";

            output.Content.SetHtmlContent(htmlContent);
        }
    }
}

2. Usage in your Views (.cshtml)

You can pass standard strings that C# can implicitly parse into DateTime, or pass explicit DateTime models.
HTML

<rcl-countdown-timer target-date="Jan 1, 2026 00:00:00"></rcl-countdown-timer>

<rcl-countdown-timer target-date="2026-12-31T23:59:59" timer-id="NewYearsEve"></rcl-countdown-timer>

<rcl-countdown-timer target-date="@Model.ProjectLaunchDate"></rcl-countdown-timer>

3. Documentation (README.md)
Countdown Timer Component (<rcl-countdown-timer>)

Renders a 5-column countdown timer (weeks, days, hours, minutes, seconds) and automatically injects the necessary scoped JavaScript to update it every second.
Setup

Ensure the Tag Helpers are registered in your _ViewImports.cshtml:
HTML

@addTagHelper *, MyComponentLibrary

Properties
Attribute	Type	Default	Description
target-date	DateTime	0001-01-01	Required. The future date and time to count down to.
timer-id	string	Random GUID	An optional prefix to use for the inner element IDs. If omitted, the Tag Helper will generate a random string to prevent JavaScript collisions.
Example
HTML

<rcl-countdown-timer target-date="2026-07-04 12:00:00"></rcl-countdown-timer>


# tests

using Microsoft.VisualStudio.TestTools.UnitTesting;
using Microsoft.AspNetCore.Razor.TagHelpers;
using MyComponentLibrary.TagHelpers;
using System.Collections.Generic;
using System;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc.Testing;
using System.Net.Http;
using MyComponentLibrary.TestHost; // Adjust to your test host app namespace

namespace MyComponentLibrary.Tests
{
    [TestClass]
    public class CountdownTimerTagHelpersTests
    {
        // --- Unit Tests ---

        private (TagHelperContext, TagHelperOutput) CreateTagHelperData()
        {
            var context = new TagHelperContext(
                tagName: "rcl-countdown-timer",
                allAttributes: new TagHelperAttributeList(),
                items: new Dictionary<object, object>(),
                uniqueId: "test");

            var output = new TagHelperOutput(
                "rcl-countdown-timer",
                new TagHelperAttributeList(),
                (useCachedResult, encoder) =>
                {
                    return Task.FromResult<TagHelperContent>(new DefaultTagHelperContent());
                });

            return (context, output);
        }

        [TestMethod]
        public void CountdownTimer_GeneratesRandomId_WhenTimerIdIsNull()
        {
            // Arrange
            var target = new DateTime(2026, 1, 1);
            var helper = new CountdownTimerTagHelper { TargetDate = target };
            var (context, output) = CreateTagHelperData();

            // Act
            helper.Process(context, output);
            var content = output.Content.GetContent();

            // Assert
            Assert.IsNull(output.TagName); // Ensure wrapper stripped
            
            // Check that it generated some kind of id for the spans
            StringAssert.Contains(content, "<span id=\"weeks_");
            
            // Check that the JS script was outputted
            StringAssert.Contains(content, "<script>");
            StringAssert.Contains(content, "(function() {");
        }

        [TestMethod]
        public void CountdownTimer_UsesProvidedId_WhenTimerIdIsSet()
        {
            // Arrange
            var target = new DateTime(2026, 1, 1);
            var helper = new CountdownTimerTagHelper { TargetDate = target, TimerId = "MyCustomTimer" };
            var (context, output) = CreateTagHelperData();

            // Act
            helper.Process(context, output);
            var content = output.Content.GetContent();

            // Assert
            StringAssert.Contains(content, "<span id=\"weeks_MyCustomTimer\"></span>");
            StringAssert.Contains(content, "document.getElementById(\"weeks_MyCustomTimer\")");
        }

        [TestMethod]
        public void CountdownTimer_FormatsDateCorrectlyForJavaScript()
        {
            // Arrange
            var target = new DateTime(2026, 12, 31, 23, 59, 59);
            var helper = new CountdownTimerTagHelper { TargetDate = target };
            var (context, output) = CreateTagHelperData();

            // Act
            helper.Process(context, output);
            var content = output.Content.GetContent();

            // Assert
            // The format JS expects is "Dec 31, 2026 23:59:59"
            StringAssert.Contains(content, "var countDownDate = new Date(\"Dec 31, 2026 23:59:59\").getTime();");
        }
    }

    [TestClass]
    public class CountdownTimerIntegrationTests
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
        public async Task CountdownTimer_RendersCorrectHtml_OnPage()
        {
            // Act
            // Assume test page has: <rcl-countdown-timer target-date="2026-01-01" timer-id="IntTest"></rcl-countdown-timer>
            var response = await _client.GetAsync("/CountdownTestPage");
            response.EnsureSuccessStatusCode();

            var responseString = await response.Content.ReadAsStringAsync();

            // Assert
            StringAssert.Contains(responseString, "class=\"row flex-column flex-md-row countdown p-x\"");
            StringAssert.Contains(responseString, "id=\"weeks_IntTest\"");
            StringAssert.Contains(responseString, "Math.floor(distance /");
        }
    }
}


###########################################



:::rcl-countdown targetdate="2026-12-31 23:59:00" timerid="launchTimer" :::

2. The Implementation

We will extract the HTML/JS logic into the builder, and add a parser that gracefully handles invalid date formats so the page doesn't crash if a user typos the date.
Step 1: The Countdown Timer HTML Builder

This is a direct port of your TagHelper logic. Note that since we are using C# string interpolation ($@""), the curly braces for the JavaScript functions must be escaped using double braces ({{ and }}).
C#

using System;

public static class CountdownTimerHtmlBuilder
{
    public static string Build(DateTime targetDate, string timerId)
    {
        string id = string.IsNullOrWhiteSpace(timerId) 
            ? Guid.NewGuid().ToString("N").Substring(0, 6) 
            : timerId;

        string jsDateString = targetDate.ToString("MMM d, yyyy HH:mm:ss");

        return $@"
<div class=""row flex-column flex-md-row countdown p-x"">
  <div class=""col bg-gray-100 text-center p-b-md p-l-0 p-r-0"">
    <span class=""countdown-text""><abbr title=""weeks"" aria-label=""weeks"" class=""text-decoration-none"">wks</abbr><br /></span>
    <span id=""weeks_{id}""></span>
  </div>
  <div class=""col bg-gray-100 text-center p-b-md p-l-0 p-r-0"">
    <span class=""countdown-text"">days<br /></span>
    <span id=""days_{id}""></span>
  </div>
  <div class=""col bg-gray-100 text-center p-b-md p-l-0 p-r-0"">
    <span class=""countdown-text""><abbr title=""hours"" aria-label=""hours"" class=""text-decoration-none"">hrs</abbr><br /></span>
    <span id=""hours_{id}""></span>
  </div>
  <div class=""col bg-gray-100 text-center p-b-md p-l-0 p-r-0"">
    <span class=""countdown-text""><abbr title=""minutes"" aria-label=""minutes"" class=""text-decoration-none"">mins</abbr><br /></span>
    <span id=""minutes_{id}""></span>
  </div>
  <div class=""col bg-gray-100 text-center p-b-md p-l-0 p-r-0"">
    <span class=""countdown-text""><abbr title=""seconds"" aria-label=""seconds"" class=""text-decoration-none"">secs</abbr><br /></span>
    <span id=""seconds_{id}""></span>
  </div>
</div>

<script>
  (function() {{
      var countDownDate = new Date(""{jsDateString}"").getTime();
      var x = setInterval(function () {{
          var now = new Date().getTime();
          var distance = countDownDate - now;

          var weeks = Math.floor(distance / (1000 * 60 * 60 * 24 * 7));
          var days = Math.floor(distance / (1000 * 60 * 60 * 24));
          var hours = Math.floor((distance % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60));
          var minutes = Math.floor((distance % (1000 * 60 * 60)) / (1000 * 60));
          var seconds = Math.floor((distance % (1000 * 60)) / 1000);

          var weeksEl = document.getElementById(""weeks_{id}"");
          var daysEl = document.getElementById(""days_{id}"");
          var hoursEl = document.getElementById(""hours_{id}"");
          var minutesEl = document.getElementById(""minutes_{id}"");
          var secondsEl = document.getElementById(""seconds_{id}"");

          if(weeksEl) weeksEl.innerHTML = weeks;
          if(daysEl) daysEl.innerHTML = days;
          if(hoursEl) hoursEl.innerHTML = hours;
          if(minutesEl) minutesEl.innerHTML = minutes;
          if(secondsEl) secondsEl.innerHTML = seconds;

          if (distance < 0) {{
              clearInterval(x);
              if(daysEl) daysEl.innerHTML = ""EXPIRED"";
          }}
      }}, 1000);
  }})();
</script>";
    }
}

Step 2: The Regex Parser

Add this pattern and method to your MarkdownComponentParser. We use DateTime.TryParse here so that if a content editor accidentally types targetdate="next tuesday", it won't crash the .NET server—it will just default to 30 days from now.
C#

using System.Text.RegularExpressions;
using System.Collections.Generic;
using System;

public partial class MarkdownComponentParser
{
    // Match the single-line block: :::rcl-countdown [attributes] :::
    [GeneratedRegex(@":::rcl-countdown[ \t]+(.*?):::", RegexOptions.IgnoreCase)]
    private static partial Regex RclCountdownRegex();

    // Your existing AttributeRegex() is reused here

    public static string ProcessCountdownTimers(string rawMarkdown)
    {
        return RclCountdownRegex().Replace(rawMarkdown, match =>
        {
            string attributesString = match.Groups[1].Value;

            // 1. Parse attributes
            var attributes = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
            foreach (Match attrMatch in AttributeRegex().Matches(attributesString))
            {
                attributes[attrMatch.Groups[1].Value] = attrMatch.Groups[2].Value;
            }

            // 2. Extract values
            string timerId = attributes.GetValueOrDefault("timerid", string.Empty);
            string targetDateStr = attributes.GetValueOrDefault("targetdate", string.Empty);

            // 3. Parse the Date safely
            if (!DateTime.TryParse(targetDateStr, out DateTime targetDate))
            {
                // Fallback: If they mess up the date format, set it 30 days in the future
                // so the component at least renders on the page for debugging.
                targetDate = DateTime.Now.AddDays(30);
            }

            // 4. Build and return the HTML
            return CountdownTimerHtmlBuilder.Build(targetDate, timerId);
        });
    }
}

Step 3: Wire it into the Pipeline

Add the new countdown processor to your chain.
C#

string processedContent = MarkdownComponentParser.ProcessCards(rawMarkdown);
processedContent = MarkdownComponentParser.ProcessButtons(processedContent);
processedContent = MarkdownComponentParser.ProcessTabs(processedContent);
processedContent = MarkdownComponentParser.ProcessBlockquotes(processedContent);
processedContent = MarkdownComponentParser.ProcessModals(processedContent);
processedContent = MarkdownComponentParser.ProcessCountdownTimers(processedContent); // <--- Add Countdown here

string finalHtml = markdownToHtml(processedContent);

### DTO

using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Razor.TagHelpers;

namespace WTS.RazorComponentLibrary.Models.RclComponents
{
    public class Csv2BarProperties
    {
        [Required(AllowEmptyStrings = false, ErrorMessage = "A ChartId is required to initialize the canvas element.")]
        public string ChartId { get; set; } = string.Empty;

        [Required(AllowEmptyStrings = false, ErrorMessage = "A CsvSource URL is required to fetch the chart data.")]
        public string CsvSource { get; set; } = string.Empty;

        public string ChartTitle { get; set; } = string.Empty;
        
        public string XAxisLabel { get; set; } = string.Empty;
        
        public string YAxisLabel { get; set; } = string.Empty;

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
    [HtmlTargetElement("rcl-csv2bar")]
    public class Csv2BarHelper : Csv2BarProperties, ITagHelper
    {
        public int Order => 0;
        public void Init(TagHelperContext context) { }

        public async Task ProcessAsync(TagHelperContext context, TagHelperOutput output)
        {
            var childContent = await output.GetChildContentAsync();
            this.Content = childContent.GetContent().Trim();

            var validationContext = new ValidationContext(this);
            Validator.ValidateObject(this, validationContext, validateAllProperties: true);

            // Strip the <rcl-csv2bar> wrapper
            output.TagName = null;

            var htmlResult = RclCsv2BarRenderer.Render(this);
            output.Content.SetHtmlContent(htmlResult);
        }
    }
}

### Renderer

using WTS.RazorComponentLibrary.Models.RclComponents;

namespace WTS.RazorComponentLibrary.Renderers
{
    public static class RclCsv2BarRenderer
    {
        public static string Render(Csv2BarProperties p)
        {
            string ariaLabel = string.IsNullOrWhiteSpace(p.ChartTitle) 
                ? "Bar Chart" 
                : p.ChartTitle;

            return $@"
                <div class=""chart-container"" role=""figure"" aria-label=""{ariaLabel}"">
                    <canvas id=""{p.ChartId}"" 
                            class=""csv2barchart""
                            data-csv-src=""{p.CsvSource}"" 
                            data-title=""{p.ChartTitle}""
                            data-x-axis=""{p.XAxisLabel}"" 
                            data-y-axis=""{p.YAxisLabel}"">
                    </canvas>
                    <div class=""sr-only"">
                        {p.Content}
                    </div>
                </div>";
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
    public class Csv2BarTests
    {
        // --- 1. Property Validation Tests ---

        [TestMethod]
        [ExpectedException(typeof(ValidationException))]
        public void Properties_MissingChartId_ThrowsValidationException()
        {
            // Arrange
            var props = new Csv2BarProperties
            {
                ChartId = string.Empty, // Invalid: Needs ID for canvas
                CsvSource = "/data/sales.csv"
            };
            var context = new ValidationContext(props);

            // Act
            Validator.ValidateObject(props, context, validateAllProperties: true);
        }

        [TestMethod]
        [ExpectedException(typeof(ValidationException))]
        public void Properties_MissingCsvSource_ThrowsValidationException()
        {
            // Arrange
            var props = new Csv2BarProperties
            {
                ChartId = "salesChart",
                CsvSource = string.Empty // Invalid: Needs data source
            };
            var context = new ValidationContext(props);

            // Act
            Validator.ValidateObject(props, context, validateAllProperties: true);
        }

        // --- 2. Renderer Tests ---

        [TestMethod]
        public void Renderer_WithTitle_GeneratesCorrectAriaLabelAndDataAttributes()
        {
            // Arrange
            var props = new Csv2BarProperties
            {
                ChartId = "revenueChart",
                CsvSource = "/api/revenue",
                ChartTitle = "Q1 Revenue",
                XAxisLabel = "Months",
                YAxisLabel = "Dollars"
            };

            // Act
            var result = RclCsv2BarRenderer.Render(props);

            // Assert
            Assert.IsTrue(result.Contains("role=\"figure\""));
            Assert.IsTrue(result.Contains("aria-label=\"Q1 Revenue\""));
            Assert.IsTrue(result.Contains("id=\"revenueChart\""));
            Assert.IsTrue(result.Contains("data-csv-src=\"/api/revenue\""));
            Assert.IsTrue(result.Contains("data-x-axis=\"Months\""));
            Assert.IsTrue(result.Contains("data-y-axis=\"Dollars\""));
        }

        [TestMethod]
        public void Renderer_WithoutTitle_GeneratesFallbackAriaLabel()
        {
            // Arrange
            var props = new Csv2BarProperties
            {
                ChartId = "basicChart",
                CsvSource = "data.csv"
            };

            // Act
            var result = RclCsv2BarRenderer.Render(props);

            // Assert
            Assert.IsTrue(result.Contains("aria-label=\"Bar Chart\""));
        }

        [TestMethod]
        public void Renderer_IncludesInnerContentInSrOnlyDiv()
        {
            // Arrange
            var props = new Csv2BarProperties
            {
                ChartId = "testChart",
                CsvSource = "data.csv",
                Content = "<table><tr><td>Raw Data Fallback</td></tr></table>"
            };

            // Act
            var result = RclCsv2BarRenderer.Render(props);

            // Assert
            Assert.IsTrue(result.Contains("<div class=\"sr-only\">"));
            Assert.IsTrue(result.Contains("Raw Data Fallback"));
        }

        // --- 3. Tag Helper Execution Tests ---

        private (TagHelperContext, TagHelperOutput) CreateTagHelperEssentials(string childContentText)
        {
            var context = new TagHelperContext(
                new TagHelperAttributeList(),
                new Dictionary<object, object>(),
                "test-id");

            var childContent = new DefaultTagHelperContent();
            childContent.SetHtmlContent(childContentText);

            var output = new TagHelperOutput(
                "rcl-csv2bar",
                new TagHelperAttributeList(),
                (useCachedResult, encoder) => Task.FromResult<TagHelperContent>(childContent));

            return (context, output);
        }

        [TestMethod]
        public async Task Helper_ProcessAsync_StripsOriginalTagAndRendersChartContainer()
        {
            // Arrange
            var (context, output) = CreateTagHelperEssentials("<p>Screen reader description.</p>");
            var helper = new Csv2BarHelper
            {
                ChartId = "demoChart",
                CsvSource = "/metrics.csv"
            };

            // Act
            await helper.ProcessAsync(context, output);

            // Assert
            Assert.IsNull(output.TagName); // <rcl-csv2bar> should be stripped
            
            var finalHtml = output.Content.GetContent();
            Assert.IsTrue(finalHtml.Contains("<div class=\"chart-container\""));
            Assert.IsTrue(finalHtml.Contains("<canvas id=\"demoChart\""));
            Assert.IsTrue(finalHtml.Contains("data-csv-src=\"/metrics.csv\""));
            Assert.IsTrue(finalHtml.Contains("<p>Screen reader description.</p>"));
        }
    }
}


### DTO

using System.ComponentModel.DataAnnotations;

namespace WTS.RazorComponentLibrary.Models.RclComponents
{
    public enum ExecutiveProfileVariant
    {
        Default,
        Transparent,
        Dark
    }

    public class ExecutiveProfileProperties
    {
        public ExecutiveProfileVariant Variant { get; set; } = ExecutiveProfileVariant.Default;

        public string ImageSrc { get; set; } = string.Empty;

        [Required(AllowEmptyStrings = false, ErrorMessage = "Image Alt text is required for ADA compliance.")]
        public string ImageAlt { get; set; } = string.Empty;

        public string OfficialTitle { get; set; } = string.Empty;

        [Required(AllowEmptyStrings = false, ErrorMessage = "Name is required for the profile heading and fallback aria-label.")]
        public string Name { get; set; } = string.Empty;

        public string Agency { get; set; } = string.Empty;

        public string LinkHref { get; set; } = "javascript:;";
        public string LinkText { get; set; } = string.Empty;
        public string LinkAriaLabel { get; set; } = string.Empty;
    }
}

### TagHelper

using Microsoft.AspNetCore.Razor.TagHelpers;
using System.ComponentModel.DataAnnotations;
using WTS.RazorComponentLibrary.Models.RclComponents;
using WTS.RazorComponentLibrary.Renderers;

namespace WTS.RazorLibrary.TagHelpers
{
    [HtmlTargetElement("rcl-executive-profile")]
    public class ExecutiveProfileHelper : ExecutiveProfileProperties, ITagHelper
    {
        public int Order => 0;
        public void Init(TagHelperContext context) { }

        public void Process(TagHelperContext context, TagHelperOutput output)
        {
            var validationContext = new ValidationContext(this);
            Validator.ValidateObject(this, validationContext, validateAllProperties: true);

            // Strip the <rcl-executive-profile> tag; the renderer will output the <figure> wrapper
            output.TagName = null;

            var htmlResult = RclExecutiveProfileRenderer.Render(this);
            output.Content.SetHtmlContent(htmlResult);
        }
    }
}


### Renderer

using System.Collections.Generic;
using WTS.RazorComponentLibrary.Models.RclComponents;

namespace WTS.RazorComponentLibrary.Renderers
{
    public static class RclExecutiveProfileRenderer
    {
        public static string Render(ExecutiveProfileProperties p)
        {
            var classes = new List<string> { "executive-profile" };

            if (p.Variant == ExecutiveProfileVariant.Transparent)
            {
                classes.Add("bg-transparent");
            }
            else if (p.Variant == ExecutiveProfileVariant.Dark)
            {
                classes.Add("bg-transparent");
                classes.Add("dark");
            }

            string classString = string.Join(" ", classes);

            string ariaLabel = string.IsNullOrWhiteSpace(p.LinkAriaLabel) 
                ? $"Link to {p.Name}'s Website" 
                : p.LinkAriaLabel;

            return $@"
                <figure class=""{classString}"">
                    <img src=""{p.ImageSrc}"" alt=""{p.ImageAlt}"" />
                    <div class=""executive-profile-body"">
                        <p>{p.OfficialTitle}</p>
                        <h3 class=""executive-name"">{p.Name}</h3>
                        <p>{p.Agency}</p>
                        <p>
                            <a href=""{p.LinkHref}"" aria-label=""{ariaLabel}"">
                                {p.LinkText}
                            </a>
                        </p>
                    </div>
                </figure>";
        }
    }
}


### test

using Microsoft.VisualStudio.TestTools.UnitTesting;
using Microsoft.AspNetCore.Razor.TagHelpers;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using WTS.RazorComponentLibrary.Models.RclComponents;
using WTS.RazorComponentLibrary.Renderers;
using WTS.RazorLibrary.TagHelpers;

namespace WTS.RazorLibrary.Tests
{
    [TestClass]
    public class ExecutiveProfileTests
    {
        // --- 1. Property Validation Tests ---

        [TestMethod]
        [ExpectedException(typeof(ValidationException))]
        public void Properties_MissingImageAlt_ThrowsValidationException()
        {
            // Arrange
            var props = new ExecutiveProfileProperties
            {
                Name = "John Doe",
                ImageAlt = string.Empty // Invalid: Requires Alt Text
            };
            var context = new ValidationContext(props);

            // Act
            Validator.ValidateObject(props, context, validateAllProperties: true);
        }

        [TestMethod]
        [ExpectedException(typeof(ValidationException))]
        public void Properties_MissingName_ThrowsValidationException()
        {
            // Arrange
            var props = new ExecutiveProfileProperties
            {
                ImageAlt = "Headshot of John Doe",
                Name = string.Empty // Invalid: Requires Name for fallback aria-label
            };
            var context = new ValidationContext(props);

            // Act
            Validator.ValidateObject(props, context, validateAllProperties: true);
        }

        // --- 2. Renderer Tests ---

        [TestMethod]
        public void Renderer_DarkVariant_OutputsCorrectClasses()
        {
            // Arrange
            var props = new ExecutiveProfileProperties
            {
                Variant = ExecutiveProfileVariant.Dark,
                Name = "Jane Doe",
                ImageAlt = "Jane Doe Headshot"
            };

            // Act
            var result = RclExecutiveProfileRenderer.Render(props);

            // Assert
            Assert.IsTrue(result.Contains("class=\"executive-profile bg-transparent dark\""));
        }

        [TestMethod]
        public void Renderer_MissingAriaLabel_GeneratesFallbackFromName()
        {
            // Arrange
            var props = new ExecutiveProfileProperties
            {
                Name = "Director Smith",
                ImageAlt = "Director Smith",
                LinkAriaLabel = string.Empty // Deliberately empty
            };

            // Act
            var result = RclExecutiveProfileRenderer.Render(props);

            // Assert
            Assert.IsTrue(result.Contains("aria-label=\"Link to Director Smith's Website\""));
        }

        [TestMethod]
        public void Renderer_ProvidedAriaLabel_OverridesFallback()
        {
            // Arrange
            var props = new ExecutiveProfileProperties
            {
                Name = "Director Smith",
                ImageAlt = "Director Smith",
                LinkAriaLabel = "Custom Agency Link"
            };

            // Act
            var result = RclExecutiveProfileRenderer.Render(props);

            // Assert
            Assert.IsTrue(result.Contains("aria-label=\"Custom Agency Link\""));
            Assert.IsFalse(result.Contains("Link to Director Smith's Website"));
        }

        // --- 3. Tag Helper Execution Tests ---

        [TestMethod]
        public void Helper_Process_StripsOriginalTagAndRendersFigure()
        {
            // Arrange
            var context = new TagHelperContext(
                new TagHelperAttributeList(),
                new Dictionary<object, object>(),
                "test-id");

            var output = new TagHelperOutput(
                "rcl-executive-profile",
                new TagHelperAttributeList(),
                (useCachedResult, encoder) => null); // No async child content fetching needed here

            var helper = new ExecutiveProfileHelper
            {
                Variant = ExecutiveProfileVariant.Transparent,
                Name = "Test Name",
                ImageAlt = "Test Alt",
                OfficialTitle = "Chief Executive"
            };

            // Act
            helper.Process(context, output);

            // Assert
            Assert.IsNull(output.TagName); // <rcl-executive-profile> should be stripped
            
            var finalHtml = output.Content.GetContent();
            Assert.IsTrue(finalHtml.Contains("<figure class=\"executive-profile bg-transparent\">"));
            Assert.IsTrue(finalHtml.Contains("<h3 class=\"executive-name\">Test Name</h3>"));
            Assert.IsTrue(finalHtml.Contains("<p>Chief Executive</p>"));
        }
    }
}


### DTO

using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Razor.TagHelpers;

namespace WTS.RazorComponentLibrary.Models.RclComponents
{
    public class FeaturedCardProperties
    {
        [Required(AllowEmptyStrings = false, ErrorMessage = "Button text is required for screen readers and UI.")]
        public string ButtonText { get; set; } = string.Empty;
        
        public string ButtonHref { get; set; } = "javascript:;";
        
        public string ButtonAriaLabel { get; set; } = string.Empty;

        public string ImageSrc { get; set; } = string.Empty;

        [Required(AllowEmptyStrings = false, ErrorMessage = "Image Alt text is required for ADA compliance.")]
        public string ImageAlt { get; set; } = string.Empty;

        public string ImageHref { get; set; } = string.Empty;

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
    [HtmlTargetElement("rcl-featured-card")]
    public class FeaturedCardHelper : FeaturedCardProperties, ITagHelper
    {
        public int Order => 0;
        public void Init(TagHelperContext context) { }

        public async Task ProcessAsync(TagHelperContext context, TagHelperOutput output)
        {
            var childContent = await output.GetChildContentAsync();
            this.Content = childContent.GetContent().Trim();

            var validationContext = new ValidationContext(this);
            Validator.ValidateObject(this, validationContext, validateAllProperties: true);

            // Strip the <rcl-featured-card> wrapper
            output.TagName = null;

            var htmlResult = RclFeaturedCardRenderer.Render(this);
            output.Content.SetHtmlContent(htmlResult);
        }
    }
}

### Renderer

using WTS.RazorComponentLibrary.Models.RclComponents;

namespace WTS.RazorComponentLibrary.Renderers
{
    public static class RclFeaturedCardRenderer
    {
        public static string Render(FeaturedCardProperties p)
        {
            // Resolve Image Link fallback
            string finalImageHref = string.IsNullOrWhiteSpace(p.ImageHref) ? p.ButtonHref : p.ImageHref;

            // Build accessible button label span
            string ariaLabelHtml = string.IsNullOrWhiteSpace(p.ButtonAriaLabel)
                ? string.Empty
                : $" <span class=\"sr-only\">{p.ButtonAriaLabel}</span>";

            return $@"
                <div class=""card featured-card"">
                    <a href=""{finalImageHref}"" tabindex=""-1"" aria-hidden=""true"">
                        <img class=""card-img-top"" src=""{p.ImageSrc}"" alt=""{p.ImageAlt}"" />
                    </a>
                    <div class=""card-body"">
                        <div class=""card-text"">
                            {p.Content}
                        </div>
                        <a href=""{p.ButtonHref}"" class=""btn btn-primary"">
                            {p.ButtonText}{ariaLabelHtml}
                        </a>
                    </div>
                </div>";
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
    public class FeaturedCardTests
    {
        // --- 1. Property Validation Tests ---

        [TestMethod]
        [ExpectedException(typeof(ValidationException))]
        public void Properties_MissingImageAlt_ThrowsValidationException()
        {
            // Arrange
            var props = new FeaturedCardProperties
            {
                ButtonText = "Read More",
                ImageAlt = string.Empty // Invalid: Requires Alt Text
            };
            var context = new ValidationContext(props);

            // Act
            Validator.ValidateObject(props, context, validateAllProperties: true);
        }

        [TestMethod]
        [ExpectedException(typeof(ValidationException))]
        public void Properties_MissingButtonText_ThrowsValidationException()
        {
            // Arrange
            var props = new FeaturedCardProperties
            {
                ImageAlt = "A descriptive image",
                ButtonText = string.Empty // Invalid: Requires Button Text
            };
            var context = new ValidationContext(props);

            // Act
            Validator.ValidateObject(props, context, validateAllProperties: true);
        }

        // --- 2. Renderer Tests ---

        [TestMethod]
        public void Renderer_EmptyImageHref_FallsBackToButtonHref()
        {
            // Arrange
            var props = new FeaturedCardProperties
            {
                ButtonText = "Action",
                ImageAlt = "Alt",
                ButtonHref = "/default-link",
                ImageHref = string.Empty // Deliberately empty
            };

            // Act
            var result = RclFeaturedCardRenderer.Render(props);

            // Assert
            Assert.IsTrue(result.Contains("<a href=\"/default-link\" tabindex=\"-1\""));
        }

        [TestMethod]
        public void Renderer_ProvidedImageHref_OverridesButtonHrefForImage()
        {
            // Arrange
            var props = new FeaturedCardProperties
            {
                ButtonText = "Action",
                ImageAlt = "Alt",
                ButtonHref = "/button-link",
                ImageHref = "/custom-image-link"
            };

            // Act
            var result = RclFeaturedCardRenderer.Render(props);

            // Assert
            Assert.IsTrue(result.Contains("<a href=\"/custom-image-link\" tabindex=\"-1\""));
            Assert.IsTrue(result.Contains("<a href=\"/button-link\" class=\"btn")); // Button retains its own link
        }

        [TestMethod]
        public void Renderer_WithAriaLabel_AppendsSrOnlySpan()
        {
            // Arrange
            var props = new FeaturedCardProperties
            {
                ButtonText = "Learn",
                ImageAlt = "Alt",
                ButtonAriaLabel = "Learn more about the program"
            };

            // Act
            var result = RclFeaturedCardRenderer.Render(props);

            // Assert
            Assert.IsTrue(result.Contains("<span class=\"sr-only\">Learn more about the program</span>"));
        }

        [TestMethod]
        public void Renderer_NoAriaLabel_OmitsSrOnlySpan()
        {
            // Arrange
            var props = new FeaturedCardProperties
            {
                ButtonText = "Learn",
                ImageAlt = "Alt",
                ButtonAriaLabel = string.Empty
            };

            // Act
            var result = RclFeaturedCardRenderer.Render(props);

            // Assert
            Assert.IsFalse(result.Contains("sr-only"));
        }

        // --- 3. Tag Helper Execution Tests ---

        private (TagHelperContext, TagHelperOutput) CreateTagHelperEssentials(string childContentText)
        {
            var context = new TagHelperContext(
                new TagHelperAttributeList(),
                new Dictionary<object, object>(),
                "test-id");

            var childContent = new DefaultTagHelperContent();
            childContent.SetHtmlContent(childContentText);

            var output = new TagHelperOutput(
                "rcl-featured-card",
                new TagHelperAttributeList(),
                (useCachedResult, encoder) => Task.FromResult<TagHelperContent>(childContent));

            return (context, output);
        }

        [TestMethod]
        public async Task Helper_ProcessAsync_StripsOriginalTagAndRendersCard()
        {
            // Arrange
            var (context, output) = CreateTagHelperEssentials("<p>Inner paragraph text.</p>");
            var helper = new FeaturedCardHelper
            {
                ButtonText = "Apply Now",
                ButtonHref = "/apply",
                ImageAlt = "Scenic view",
                ImageSrc = "scenic.jpg"
            };

            // Act
            await helper.ProcessAsync(context, output);

            // Assert
            Assert.IsNull(output.TagName); // <rcl-featured-card> should be stripped
            
            var finalHtml = output.Content.GetContent();
            Assert.IsTrue(finalHtml.Contains("<div class=\"card featured-card\">"));
            Assert.IsTrue(finalHtml.Contains("<p>Inner paragraph text.</p>"));
            Assert.IsTrue(finalHtml.Contains("Apply Now"));
            Assert.IsTrue(finalHtml.Contains("src=\"scenic.jpg\""));
        }
    }
}


### DTO

using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Razor.TagHelpers;

namespace WTS.RazorComponentLibrary.Models.RclComponents
{
    public class LinkGridProperties
    {
        [HtmlAttributeNotBound]
        public string Content { get; set; } = string.Empty;
    }

    public class LinkGridItemProperties
    {
        public string Href { get; set; } = "javascript:;";
        
        public string ColumnClass { get; set; } = "col-md-4 mb-4";

        [HtmlAttributeNotBound]
        [Required(AllowEmptyStrings = false, ErrorMessage = "Link grid items must contain text or content so screen readers can announce the link destination.")]
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
    // Parent Container
    [HtmlTargetElement("rcl-link-grid")]
    public class LinkGridHelper : LinkGridProperties, ITagHelper
    {
        public int Order => 0;
        public void Init(TagHelperContext context) { }

        public async Task ProcessAsync(TagHelperContext context, TagHelperOutput output)
        {
            var childContent = await output.GetChildContentAsync();
            this.Content = childContent.GetContent().Trim();

            // Strip the parent <rcl-link-grid> tag
            output.TagName = null;

            var htmlResult = RclLinkGridRenderer.Render(this);
            output.Content.SetHtmlContent(htmlResult);
        }
    }

    // Child Item
    [HtmlTargetElement("rcl-link-grid-item", ParentTag = "rcl-link-grid")]
    public class LinkGridItemHelper : LinkGridItemProperties, ITagHelper
    {
        public int Order => 0;
        public void Init(TagHelperContext context) { }

        public async Task ProcessAsync(TagHelperContext context, TagHelperOutput output)
        {
            var childContent = await output.GetChildContentAsync();
            this.Content = childContent.GetContent().Trim();

            var validationContext = new ValidationContext(this);
            Validator.ValidateObject(this, validationContext, validateAllProperties: true);

            // Strip the <rcl-link-grid-item> tag
            output.TagName = null;

            var htmlResult = RclLinkGridItemRenderer.Render(this);
            output.Content.SetHtmlContent(htmlResult);
        }
    }
}

### Renderer

using WTS.RazorComponentLibrary.Models.RclComponents;

namespace WTS.RazorComponentLibrary.Renderers
{
    public static class RclLinkGridRenderer
    {
        public static string Render(LinkGridProperties p)
        {
            return $@"
                <div class=""row"">
                    {p.Content}
                </div>";
        }
    }

    public static class RclLinkGridItemRenderer
    {
        public static string Render(LinkGridItemProperties p)
        {
            return $@"
                <div class=""{p.ColumnClass}"">
                    <a href=""{p.Href}"" class=""link-grid"">
                        {p.Content}
                    </a>
                </div>";
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
    public class LinkGridTests
    {
        // --- 1. Property Validation Tests ---

        [TestMethod]
        [ExpectedException(typeof(ValidationException))]
        public void ItemProperties_EmptyContent_ThrowsValidationException()
        {
            // Arrange
            var props = new LinkGridItemProperties
            {
                Href = "/about",
                Content = string.Empty // Invalid: Link needs content for UI and ADA
            };
            var context = new ValidationContext(props);

            // Act
            Validator.ValidateObject(props, context, validateAllProperties: true);
        }

        [TestMethod]
        public void ItemProperties_ValidContent_PassesValidation()
        {
            // Arrange
            var props = new LinkGridItemProperties
            {
                Href = "/about",
                Content = "About Us"
            };
            var context = new ValidationContext(props);

            // Act & Assert (Should not throw)
            Validator.ValidateObject(props, context, validateAllProperties: true);
        }

        // --- 2. Renderer Tests ---

        [TestMethod]
        public void ParentRenderer_OutputsRowWrapper()
        {
            // Arrange
            var props = new LinkGridProperties { Content = "Inner Grid Items" };

            // Act
            var result = RclLinkGridRenderer.Render(props);

            // Assert
            Assert.IsTrue(result.Contains("<div class=\"row\">"));
            Assert.IsTrue(result.Contains("Inner Grid Items"));
        }

        [TestMethod]
        public void ItemRenderer_DefaultProperties_OutputsCorrectHtml()
        {
            // Arrange
            var props = new LinkGridItemProperties
            {
                Content = "Default Link" // Uses default ColumnClass and Href
            };

            // Act
            var result = RclLinkGridItemRenderer.Render(props);

            // Assert
            Assert.IsTrue(result.Contains("<div class=\"col-md-4 mb-4\">"));
            Assert.IsTrue(result.Contains("<a href=\"javascript:;\" class=\"link-grid\">"));
            Assert.IsTrue(result.Contains("Default Link"));
        }

        [TestMethod]
        public void ItemRenderer_CustomProperties_OverridesDefaults()
        {
            // Arrange
            var props = new LinkGridItemProperties
            {
                Href = "https://ca.gov",
                ColumnClass = "col-sm-6 mb-2",
                Content = "External Site"
            };

            // Act
            var result = RclLinkGridItemRenderer.Render(props);

            // Assert
            Assert.IsTrue(result.Contains("<div class=\"col-sm-6 mb-2\">"));
            Assert.IsTrue(result.Contains("<a href=\"https://ca.gov\" class=\"link-grid\">"));
            Assert.IsTrue(result.Contains("External Site"));
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
        public async Task ParentHelper_ProcessAsync_StripsTagAndRenders()
        {
            // Arrange
            var (context, output) = CreateTagHelperEssentials("Child items here", "rcl-link-grid");
            var helper = new LinkGridHelper();

            // Act
            await helper.ProcessAsync(context, output);

            // Assert
            Assert.IsNull(output.TagName); // Tag should be stripped
            Assert.IsTrue(output.Content.GetContent().Contains("<div class=\"row\">"));
            Assert.IsTrue(output.Content.GetContent().Contains("Child items here"));
        }

        [TestMethod]
        public async Task ChildHelper_ProcessAsync_StripsTagAndRenders()
        {
            // Arrange
            var (context, output) = CreateTagHelperEssentials("Settings", "rcl-link-grid-item");
            var helper = new LinkGridItemHelper
            {
                Href = "/settings"
            };

            // Act
            await helper.ProcessAsync(context, output);

            // Assert
            Assert.IsNull(output.TagName); // Tag should be stripped
            var finalHtml = output.Content.GetContent();
            Assert.IsTrue(finalHtml.Contains("<div class=\"col-md-4 mb-4\">"));
            Assert.IsTrue(finalHtml.Contains("<a href=\"/settings\""));
            Assert.IsTrue(finalHtml.Contains("Settings"));
        }
    }
}


### DTO
using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Razor.TagHelpers;

namespace WTS.RazorComponentLibrary.Models.RclComponents
{
    public enum ModalSize
    {
        Default,
        Sm,
        Lg,
        Xl
    }

    public class ModalProperties
    {
        [Required(AllowEmptyStrings = false, ErrorMessage = "A ModalId is required so trigger buttons can target it.")]
        public string ModalId { get; set; } = string.Empty;

        [Required(AllowEmptyStrings = false, ErrorMessage = "A Title is required for screen readers (aria-labelledby).")]
        public string Title { get; set; } = string.Empty;

        public ModalSize Size { get; set; } = ModalSize.Lg; 

        public bool ShowFooter { get; set; } = true;
        
        public string FooterCloseText { get; set; } = "Close";

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
    [HtmlTargetElement("rcl-modal")]
    public class ModalHelper : ModalProperties, ITagHelper
    {
        public int Order => 0;
        public void Init(TagHelperContext context) { }

        public async Task ProcessAsync(TagHelperContext context, TagHelperOutput output)
        {
            var childContent = await output.GetChildContentAsync();
            this.Content = childContent.GetContent().Trim();

            var validationContext = new ValidationContext(this);
            Validator.ValidateObject(this, validationContext, validateAllProperties: true);

            // Strip the <rcl-modal> wrapper; the renderer outputs the actual modal structure
            output.TagName = null;

            var htmlResult = RclModalRenderer.Render(this);
            output.Content.SetHtmlContent(htmlResult);
        }
    }
}

### Renderer
using WTS.RazorComponentLibrary.Models.RclComponents;

namespace WTS.RazorComponentLibrary.Renderers
{
    public static class RclModalRenderer
    {
        public static string Render(ModalProperties p)
        {
            string sizeClass = p.Size switch
            {
                ModalSize.Lg => " modal-lg",
                ModalSize.Sm => " modal-sm",
                ModalSize.Xl => " modal-xl",
                _ => string.Empty
            };

            string footerHtml = string.Empty;
            if (p.ShowFooter)
            {
                footerHtml = $@"
                    <div class=""modal-footer"">
                        <button type=""button"" class=""btn btn-default"" data-bs-dismiss=""modal"">
                            {p.FooterCloseText}
                        </button>
                    </div>";
            }

            return $@"
                <div class=""modal fade"" id=""{p.ModalId}"" tabindex=""-1"" aria-labelledby=""{p.ModalId}Label"" aria-hidden=""true"">
                    <div class=""modal-dialog{sizeClass}"">
                        <div class=""modal-content"">
                            <div class=""modal-header"">
                                <h5 class=""modal-title"" id=""{p.ModalId}Label"">{p.Title}</h5>
                                <button type=""button"" class=""btn-close"" data-bs-dismiss=""modal"" aria-label=""Close""></button>
                            </div>
                            <div class=""modal-body"">
                                {p.Content}
                            </div>
                            {footerHtml}
                        </div>
                    </div>
                </div>";
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
    public class ModalTests
    {
        // --- 1. Property Validation Tests ---

        [TestMethod]
        [ExpectedException(typeof(ValidationException))]
        public void Properties_MissingModalId_ThrowsValidationException()
        {
            // Arrange
            var props = new ModalProperties
            {
                ModalId = string.Empty, // Invalid: Needs ID to be triggered
                Title = "Alert"
            };
            var context = new ValidationContext(props);

            // Act
            Validator.ValidateObject(props, context, validateAllProperties: true);
        }

        [TestMethod]
        [ExpectedException(typeof(ValidationException))]
        public void Properties_MissingTitle_ThrowsValidationException()
        {
            // Arrange
            var props = new ModalProperties
            {
                ModalId = "myModal",
                Title = string.Empty // Invalid: Needs title for aria-labelledby
            };
            var context = new ValidationContext(props);

            // Act
            Validator.ValidateObject(props, context, validateAllProperties: true);
        }

        // --- 2. Renderer Tests ---

        [TestMethod]
        public void Renderer_LgSize_AddsModalLgClass()
        {
            // Arrange
            var props = new ModalProperties
            {
                ModalId = "lgModal",
                Title = "Large Modal",
                Size = ModalSize.Lg
            };

            // Act
            var result = RclModalRenderer.Render(props);

            // Assert
            Assert.IsTrue(result.Contains("modal-dialog modal-lg"));
        }

        [TestMethod]
        public void Renderer_ShowFooterFalse_OmitsFooterHtml()
        {
            // Arrange
            var props = new ModalProperties
            {
                ModalId = "noFooterModal",
                Title = "No Footer",
                ShowFooter = false
            };

            // Act
            var result = RclModalRenderer.Render(props);

            // Assert
            Assert.IsFalse(result.Contains("<div class=\"modal-footer\">"));
            Assert.IsFalse(result.Contains("Close"));
        }

        [TestMethod]
        public void Renderer_ShowFooterTrue_IncludesCustomCloseText()
        {
            // Arrange
            var props = new ModalProperties
            {
                ModalId = "footerModal",
                Title = "Footer",
                ShowFooter = true,
                FooterCloseText = "Dismiss"
            };

            // Act
            var result = RclModalRenderer.Render(props);

            // Assert
            Assert.IsTrue(result.Contains("<div class=\"modal-footer\">"));
            Assert.IsTrue(result.Contains("Dismiss"));
        }

        [TestMethod]
        public void Renderer_GeneratesCorrectAriaLabelledBy()
        {
            // Arrange
            var props = new ModalProperties
            {
                ModalId = "testModal",
                Title = "Accessibility Test"
            };

            // Act
            var result = RclModalRenderer.Render(props);

            // Assert
            Assert.IsTrue(result.Contains("aria-labelledby=\"testModalLabel\""));
            Assert.IsTrue(result.Contains("id=\"testModalLabel\">Accessibility Test</h5>"));
        }

        // --- 3. Tag Helper Execution Tests ---

        private (TagHelperContext, TagHelperOutput) CreateTagHelperEssentials(string childContentText)
        {
            var context = new TagHelperContext(
                new TagHelperAttributeList(),
                new Dictionary<object, object>(),
                "test-id");

            var childContent = new DefaultTagHelperContent();
            childContent.SetHtmlContent(childContentText);

            var output = new TagHelperOutput(
                "rcl-modal",
                new TagHelperAttributeList(),
                (useCachedResult, encoder) => Task.FromResult<TagHelperContent>(childContent));

            return (context, output);
        }

        [TestMethod]
        public async Task Helper_ProcessAsync_StripsOriginalTagAndRendersModal()
        {
            // Arrange
            var (context, output) = CreateTagHelperEssentials("<p>Modal body content.</p>");
            var helper = new ModalHelper
            {
                ModalId = "execModal",
                Title = "Executive Summary",
                Size = ModalSize.Xl
            };

            // Act
            await helper.ProcessAsync(context, output);

            // Assert
            Assert.IsNull(output.TagName); // <rcl-modal> should be stripped
            
            var finalHtml = output.Content.GetContent();
            Assert.IsTrue(finalHtml.Contains("id=\"execModal\""));
            Assert.IsTrue(finalHtml.Contains("modal-dialog modal-xl"));
            Assert.IsTrue(finalHtml.Contains("Executive Summary"));
            Assert.IsTrue(finalHtml.Contains("<p>Modal body content.</p>"));
        }
    }
}


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


### DTO
using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Razor.TagHelpers;

namespace WTS.RazorComponentLibrary.Models.RclComponents
{
    public class StepListProperties
    {
        [HtmlAttributeNotBound]
        public string Content { get; set; } = string.Empty;
    }

    public class StepListItemProperties
    {
        [Required(AllowEmptyStrings = false, ErrorMessage = "A Heading is required to define the step's primary instruction.")]
        public string Heading { get; set; } = string.Empty;

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
    [HtmlTargetElement("rcl-step-list")]
    public class StepListHelper : StepListProperties, ITagHelper
    {
        public int Order => 0;
        public void Init(TagHelperContext context) { }

        public async Task ProcessAsync(TagHelperContext context, TagHelperOutput output)
        {
            var childContent = await output.GetChildContentAsync();
            this.Content = childContent.GetContent().Trim();

            // Strip the <rcl-step-list> tag
            output.TagName = null;

            var htmlResult = RclStepListRenderer.Render(this);
            output.Content.SetHtmlContent(htmlResult);
        }
    }

    // --- 2. Child Item ---
    [HtmlTargetElement("rcl-step-list-item", ParentTag = "rcl-step-list")]
    public class StepListItemHelper : StepListItemProperties, ITagHelper
    {
        public int Order => 0;
        public void Init(TagHelperContext context) { }

        public async Task ProcessAsync(TagHelperContext context, TagHelperOutput output)
        {
            var childContent = await output.GetChildContentAsync();
            this.Content = childContent.GetContent().Trim();

            var validationContext = new ValidationContext(this);
            Validator.ValidateObject(this, validationContext, validateAllProperties: true);

            // Strip the <rcl-step-list-item> tag
            output.TagName = null;

            var htmlResult = RclStepListItemRenderer.Render(this);
            output.Content.SetHtmlContent(htmlResult);
        }
    }
}

### Renderer

using WTS.RazorComponentLibrary.Models.RclComponents;

namespace WTS.RazorComponentLibrary.Renderers
{
    public static class RclStepListRenderer
    {
        public static string Render(StepListProperties p)
        {
            return $@"
                <ol class=""cagov-step-list"">
                    {p.Content}
                </ol>";
        }
    }

    public static class RclStepListItemRenderer
    {
        public static string Render(StepListItemProperties p)
        {
            return $@"
                <li>
                    {p.Heading}
                    <br />
                    <span class=""cagov-step-list-content"">
                        {p.Content}
                    </span>
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
    public class StepListTests
    {
        // --- 1. Property Validation Tests ---

        [TestMethod]
        [ExpectedException(typeof(ValidationException))]
        public void ChildProperties_MissingHeading_ThrowsValidationException()
        {
            // Arrange
            var props = new StepListItemProperties
            {
                Heading = string.Empty, // Invalid: Needs a heading
                Content = "More details."
            };
            var context = new ValidationContext(props);

            // Act
            Validator.ValidateObject(props, context, validateAllProperties: true);
        }

        // --- 2. Renderer Tests ---

        [TestMethod]
        public void ParentRenderer_OutputsOrderedListWrapper()
        {
            // Arrange
            var props = new StepListProperties { Content = "<li>Step 1</li>" };

            // Act
            var result = RclStepListRenderer.Render(props);

            // Assert
            Assert.IsTrue(result.Contains("<ol class=\"cagov-step-list\">"));
            Assert.IsTrue(result.Contains("<li>Step 1</li>"));
            Assert.IsTrue(result.Contains("</ol>"));
        }

        [TestMethod]
        public void ChildRenderer_OutputsHeadingAndContentSpan()
        {
            // Arrange
            var props = new StepListItemProperties
            {
                Heading = "Review Application",
                Content = "Check for errors."
            };

            // Act
            var result = RclStepListItemRenderer.Render(props);

            // Assert
            Assert.IsTrue(result.StartsWith("<li>"));
            Assert.IsTrue(result.Contains("Review Application"));
            Assert.IsTrue(result.Contains("<br />"));
            Assert.IsTrue(result.Contains("<span class=\"cagov-step-list-content\">"));
            Assert.IsTrue(result.Contains("Check for errors."));
            Assert.IsTrue(result.Contains("</span>"));
            Assert.IsTrue(result.Contains("</li>"));
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
            var (context, output) = CreateTagHelperEssentials("Items go here", "rcl-step-list");
            var helper = new StepListHelper();

            // Act
            await helper.ProcessAsync(context, output);

            // Assert
            Assert.IsNull(output.TagName); // <rcl-step-list> should be stripped
            Assert.IsTrue(output.Content.GetContent().Contains("<ol class=\"cagov-step-list\">"));
            Assert.IsTrue(output.Content.GetContent().Contains("Items go here"));
        }

        [TestMethod]
        public async Task ChildHelper_ProcessAsync_StripsOriginalTagAndRendersItem()
        {
            // Arrange
            var (context, output) = CreateTagHelperEssentials("Fill out form online.", "rcl-step-list-item");
            var helper = new StepListItemHelper
            {
                Heading = "Step 1: Apply"
            };

            // Act
            await helper.ProcessAsync(context, output);

            // Assert
            Assert.IsNull(output.TagName); // <rcl-step-list-item> should be stripped
            
            var finalHtml = output.Content.GetContent();
            Assert.IsTrue(finalHtml.Contains("<li>"));
            Assert.IsTrue(finalHtml.Contains("Step 1: Apply"));
            Assert.IsTrue(finalHtml.Contains("<span class=\"cagov-step-list-content\">"));
            Assert.IsTrue(finalHtml.Contains("Fill out form online."));
        }
    }
}


### DTO
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Razor.TagHelpers;

namespace WTS.RazorComponentLibrary.Models.RclComponents
{
    public class TabItemData
    {
        public string Id { get; set; } = string.Empty;
        public string Title { get; set; } = string.Empty;
    }

    public class TabsProperties
    {
        [HtmlAttributeNotBound]
        public List<TabItemData> TabsList { get; set; } = new List<TabItemData>();

        [HtmlAttributeNotBound]
        public string Content { get; set; } = string.Empty;
    }

    public class TabItemProperties
    {
        [Required(AllowEmptyStrings = false, ErrorMessage = "A Title is required to generate the tab navigation link.")]
        public string Title { get; set; } = string.Empty;
        
        public string TabId { get; set; } = string.Empty;

        [HtmlAttributeNotBound]
        public string Content { get; set; } = string.Empty;
    }
}

### TagHelper

using Microsoft.AspNetCore.Razor.TagHelpers;
using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using System.ComponentModel.DataAnnotations;
using WTS.RazorComponentLibrary.Models.RclComponents;
using WTS.RazorComponentLibrary.Renderers;

namespace WTS.RazorLibrary.TagHelpers
{
    // --- 1. Parent Tabs Container ---
    [HtmlTargetElement("rcl-tabs")]
    public class TabsHelper : TabsProperties, ITagHelper
    {
        public int Order => 0;
        public void Init(TagHelperContext context) { }

        public async Task ProcessAsync(TagHelperContext context, TagHelperOutput output)
        {
            // Share the list so children can append their metadata
            context.Items["TabsList"] = this.TabsList;

            // Wait for children to process
            var childContent = await output.GetChildContentAsync();
            this.Content = childContent.GetContent().Trim();

            // Strip the <rcl-tabs> wrapper
            output.TagName = null;

            var htmlResult = RclTabsRenderer.Render(this);
            output.Content.SetHtmlContent(htmlResult);
        }
    }

    // --- 2. Child Tab Item ---
    [HtmlTargetElement("rcl-tab", ParentTag = "rcl-tabs")]
    public class TabItemHelper : TabItemProperties, ITagHelper
    {
        public int Order => 0;
        public void Init(TagHelperContext context) { }

        public async Task ProcessAsync(TagHelperContext context, TagHelperOutput output)
        {
            var childContent = await output.GetChildContentAsync();
            this.Content = childContent.GetContent().Trim();

            var validationContext = new ValidationContext(this);
            Validator.ValidateObject(this, validationContext, validateAllProperties: true);

            // Determine the ID
            this.TabId = string.IsNullOrWhiteSpace(this.TabId) 
                ? $"tab_{Guid.NewGuid().ToString("N").Substring(0, 6)}" 
                : this.TabId;

            // Register this tab with the parent component
            if (context.Items.TryGetValue("TabsList", out var listObj) && listObj is List<TabItemData> tabs)
            {
                tabs.Add(new TabItemData { Id = this.TabId, Title = this.Title });
            }

            // Strip the <rcl-tab> wrapper
            output.TagName = null;

            var htmlResult = RclTabItemRenderer.Render(this);
            output.Content.SetHtmlContent(htmlResult);
        }
    }
}

### Renderer

using System.Text;
using WTS.RazorComponentLibrary.Models.RclComponents;

namespace WTS.RazorComponentLibrary.Renderers
{
    public static class RclTabsRenderer
    {
        public static string Render(TabsProperties p)
        {
            var navBuilder = new StringBuilder();
            navBuilder.AppendLine("<ul>");
            
            foreach (var tab in p.TabsList)
            {
                navBuilder.AppendLine($"  <li><a href=\"#{tab.Id}\">{tab.Title}</a></li>");
            }
            
            navBuilder.AppendLine("</ul>");

            return $@"
                <div class=""tabs"">
                    {navBuilder.ToString()}
                    {p.Content}
                </div>";
        }
    }

    public static class RclTabItemRenderer
    {
        public static string Render(TabItemProperties p)
        {
            return $@"
                <section id=""{p.TabId}"">
                    {p.Content}
                </section>";
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
    public class TabsTests
    {
        // --- 1. Property Validation Tests ---

        [TestMethod]
        [ExpectedException(typeof(ValidationException))]
        public void ChildProperties_MissingTitle_ThrowsValidationException()
        {
            // Arrange
            var props = new TabItemProperties
            {
                Title = string.Empty, // Invalid: Needs a title for the nav
                Content = "Tab content"
            };
            var context = new ValidationContext(props);

            // Act
            Validator.ValidateObject(props, context, validateAllProperties: true);
        }

        // --- 2. Renderer Tests ---

        [TestMethod]
        public void ParentRenderer_WithTabsList_OutputsNavAndContent()
        {
            // Arrange
            var props = new TabsProperties 
            { 
                Content = "<section>Internal Content</section>" 
            };
            props.TabsList.Add(new TabItemData { Id = "tab1", Title = "First Tab" });

            // Act
            var result = RclTabsRenderer.Render(props);

            // Assert
            Assert.IsTrue(result.Contains("<div class=\"tabs\">"));
            Assert.IsTrue(result.Contains("<ul>"));
            Assert.IsTrue(result.Contains("<a href=\"#tab1\">First Tab</a>"));
            Assert.IsTrue(result.Contains("</ul>"));
            Assert.IsTrue(result.Contains("<section>Internal Content</section>"));
        }

        [TestMethod]
        public void ChildRenderer_OutputsSectionWithId()
        {
            // Arrange
            var props = new TabItemProperties
            {
                TabId = "customId",
                Content = "Panel details."
            };

            // Act
            var result = RclTabItemRenderer.Render(props);

            // Assert
            Assert.IsTrue(result.Contains("<section id=\"customId\">"));
            Assert.IsTrue(result.Contains("Panel details."));
            Assert.IsTrue(result.Contains("</section>"));
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
        public async Task ChildHelper_ProcessAsync_GeneratesGuidAndAddsToContextList()
        {
            // Arrange
            var (context, output) = CreateTagHelperEssentials("Tab Info", "rcl-tab");
            
            // Simulate the parent having already initialized the list in context
            var sharedList = new List<TabItemData>();
            context.Items["TabsList"] = sharedList;

            var helper = new TabItemHelper
            {
                Title = "Dynamic Tab"
                // Deliberately leaving TabId empty to test Guid generation
            };

            // Act
            await helper.ProcessAsync(context, output);

            // Assert
            Assert.IsNull(output.TagName); // <rcl-tab> should be stripped
            
            // Verify child appended itself to parent list
            Assert.AreEqual(1, sharedList.Count);
            Assert.AreEqual("Dynamic Tab", sharedList[0].Title);
            Assert.IsTrue(sharedList[0].Id.StartsWith("tab_")); // Verify Guid fallback ran
            
            // Verify generated HTML output
            var finalHtml = output.Content.GetContent();
            Assert.IsTrue(finalHtml.Contains($"<section id=\"{sharedList[0].Id}\">"));
        }

        [TestMethod]
        public async Task ParentHelper_ProcessAsync_InitializesContextAndRenders()
        {
            // Arrange
            var (context, output) = CreateTagHelperEssentials("<section>Pre-rendered child</section>", "rcl-tabs");
            var helper = new TabsHelper();

            // Act
            await helper.ProcessAsync(context, output);

            // Assert
            Assert.IsNull(output.TagName);
            
            // Context should contain the list
            Assert.IsTrue(context.Items.ContainsKey("TabsList"));
            
            var finalHtml = output.Content.GetContent();
            Assert.IsTrue(finalHtml.Contains("<div class=\"tabs\">"));
            Assert.IsTrue(finalHtml.Contains("<ul>")); // Empty ul since we didn't mock children actually running during process
            Assert.IsTrue(finalHtml.Contains("<section>Pre-rendered child</section>"));
        }
    }
}

### DTO
using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Razor.TagHelpers;

namespace WTS.RazorComponentLibrary.Models.RclComponents
{
    public enum TableVariant
    {
        Basic,
        Default,
        Striped
    }

    public class TableProperties
    {
        public TableVariant Variant { get; set; } = TableVariant.Basic;

        [HtmlAttributeNotBound]
        [Required(AllowEmptyStrings = false, ErrorMessage = "A table must contain inner content (rows and cells) for data presentation and ADA compliance.")]
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
    [HtmlTargetElement("rcl-table")]
    public class TableHelper : TableProperties, ITagHelper
    {
        public int Order => 0;
        public void Init(TagHelperContext context) { }

        public async Task ProcessAsync(TagHelperContext context, TagHelperOutput output)
        {
            var childContent = await output.GetChildContentAsync();
            this.Content = childContent.GetContent().Trim();

            var validationContext = new ValidationContext(this);
            Validator.ValidateObject(this, validationContext, validateAllProperties: true);

            // Strip the <rcl-table> wrapper
            output.TagName = null;

            var htmlResult = RclTableRenderer.Render(this);
            output.Content.SetHtmlContent(htmlResult);
        }
    }
}


### Renderer

using WTS.RazorComponentLibrary.Models.RclComponents;

namespace WTS.RazorComponentLibrary.Renderers
{
    public static class RclTableRenderer
    {
        public static string Render(TableProperties p)
        {
            string cssClass = p.Variant switch
            {
                TableVariant.Default => "table table-default",
                TableVariant.Striped => "table table-striped",
                _ => "table" // Basic variant
            };

            return $@"
                <table class=""{cssClass}"">
                    {p.Content}
                </table>";
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
    public class TableTests
    {
        // --- 1. Property Validation Tests ---

        [TestMethod]
        [ExpectedException(typeof(ValidationException))]
        public void Properties_MissingContent_ThrowsValidationException()
        {
            // Arrange
            var props = new TableProperties
            {
                Variant = TableVariant.Striped,
                Content = string.Empty // Invalid: Needs rows/cells
            };
            var context = new ValidationContext(props);

            // Act
            Validator.ValidateObject(props, context, validateAllProperties: true);
        }

        // --- 2. Renderer Tests ---

        [TestMethod]
        public void Renderer_BasicVariant_OutputsBaseTableClassOnly()
        {
            // Arrange
            var props = new TableProperties
            {
                Variant = TableVariant.Basic,
                Content = "<tbody><tr><td>Data</td></tr></tbody>"
            };

            // Act
            var result = RclTableRenderer.Render(props);

            // Assert
            Assert.IsTrue(result.Contains("<table class=\"table\">"));
            Assert.IsTrue(result.Contains("<td>Data</td>"));
        }

        [TestMethod]
        public void Renderer_StripedVariant_OutputsStripedTableClass()
        {
            // Arrange
            var props = new TableProperties
            {
                Variant = TableVariant.Striped,
                Content = "<tbody><tr><td>Data</td></tr></tbody>"
            };

            // Act
            var result = RclTableRenderer.Render(props);

            // Assert
            Assert.IsTrue(result.Contains("<table class=\"table table-striped\">"));
        }

        [TestMethod]
        public void Renderer_DefaultVariant_OutputsDefaultTableClass()
        {
            // Arrange
            var props = new TableProperties
            {
                Variant = TableVariant.Default,
                Content = "<tbody><tr><td>Data</td></tr></tbody>"
            };

            // Act
            var result = RclTableRenderer.Render(props);

            // Assert
            Assert.IsTrue(result.Contains("<table class=\"table table-default\">"));
        }

        // --- 3. Tag Helper Execution Tests ---

        private (TagHelperContext, TagHelperOutput) CreateTagHelperEssentials(string childContentText)
        {
            var context = new TagHelperContext(
                new TagHelperAttributeList(),
                new Dictionary<object, object>(),
                "test-id");

            var childContent = new DefaultTagHelperContent();
            childContent.SetHtmlContent(childContentText);

            var output = new TagHelperOutput(
                "rcl-table",
                new TagHelperAttributeList(),
                (useCachedResult, encoder) => Task.FromResult<TagHelperContent>(childContent));

            return (context, output);
        }

        [TestMethod]
        public async Task Helper_ProcessAsync_StripsOriginalTagAndRendersTable()
        {
            // Arrange
            var innerHtml = "<thead><tr><th>Header</th></tr></thead>";
            var (context, output) = CreateTagHelperEssentials(innerHtml);
            
            var helper = new TableHelper
            {
                Variant = TableVariant.Striped
            };

            // Act
            await helper.ProcessAsync(context, output);

            // Assert
            Assert.IsNull(output.TagName); // <rcl-table> should be stripped
            
            var finalHtml = output.Content.GetContent();
            Assert.IsTrue(finalHtml.Contains("<table class=\"table table-striped\">"));
            Assert.IsTrue(finalHtml.Contains(innerHtml));
            Assert.IsTrue(finalHtml.Contains("</table>"));
        }
    }
}


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


### DTO

using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Razor.TagHelpers;

namespace WTS.RazorComponentLibrary.Models.RclComponents
{
    public class Csv2BarProperties
    {
        [Required(AllowEmptyStrings = false, ErrorMessage = "A ChartId is required to initialize the canvas element.")]
        public string ChartId { get; set; } = string.Empty;

        [Required(AllowEmptyStrings = false, ErrorMessage = "A CsvSource URL is required to fetch the chart data.")]
        public string CsvSource { get; set; } = string.Empty;

        public string ChartTitle { get; set; } = string.Empty;
        
        public string XAxisLabel { get; set; } = string.Empty;
        
        public string YAxisLabel { get; set; } = string.Empty;

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
    [HtmlTargetElement("rcl-csv2bar")]
    public class Csv2BarHelper : Csv2BarProperties, ITagHelper
    {
        public int Order => 0;
        public void Init(TagHelperContext context) { }

        public async Task ProcessAsync(TagHelperContext context, TagHelperOutput output)
        {
            var childContent = await output.GetChildContentAsync();
            this.Content = childContent.GetContent().Trim();

            var validationContext = new ValidationContext(this);
            Validator.ValidateObject(this, validationContext, validateAllProperties: true);

            // Strip the <rcl-csv2bar> wrapper
            output.TagName = null;

            var htmlResult = RclCsv2BarRenderer.Render(this);
            output.Content.SetHtmlContent(htmlResult);
        }
    }
}

### Renderer

using WTS.RazorComponentLibrary.Models.RclComponents;

namespace WTS.RazorComponentLibrary.Renderers
{
    public static class RclCsv2BarRenderer
    {
        public static string Render(Csv2BarProperties p)
        {
            string ariaLabel = string.IsNullOrWhiteSpace(p.ChartTitle) 
                ? "Bar Chart" 
                : p.ChartTitle;

            return $@"
                <div class=""chart-container"" role=""figure"" aria-label=""{ariaLabel}"">
                    <canvas id=""{p.ChartId}"" 
                            class=""csv2barchart""
                            data-csv-src=""{p.CsvSource}"" 
                            data-title=""{p.ChartTitle}""
                            data-x-axis=""{p.XAxisLabel}"" 
                            data-y-axis=""{p.YAxisLabel}"">
                    </canvas>
                    <div class=""sr-only"">
                        {p.Content}
                    </div>
                </div>";
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
    public class Csv2BarTests
    {
        // --- 1. Property Validation Tests ---

        [TestMethod]
        [ExpectedException(typeof(ValidationException))]
        public void Properties_MissingChartId_ThrowsValidationException()
        {
            // Arrange
            var props = new Csv2BarProperties
            {
                ChartId = string.Empty, // Invalid: Needs ID for canvas
                CsvSource = "/data/sales.csv"
            };
            var context = new ValidationContext(props);

            // Act
            Validator.ValidateObject(props, context, validateAllProperties: true);
        }

        [TestMethod]
        [ExpectedException(typeof(ValidationException))]
        public void Properties_MissingCsvSource_ThrowsValidationException()
        {
            // Arrange
            var props = new Csv2BarProperties
            {
                ChartId = "salesChart",
                CsvSource = string.Empty // Invalid: Needs data source
            };
            var context = new ValidationContext(props);

            // Act
            Validator.ValidateObject(props, context, validateAllProperties: true);
        }

        // --- 2. Renderer Tests ---

        [TestMethod]
        public void Renderer_WithTitle_GeneratesCorrectAriaLabelAndDataAttributes()
        {
            // Arrange
            var props = new Csv2BarProperties
            {
                ChartId = "revenueChart",
                CsvSource = "/api/revenue",
                ChartTitle = "Q1 Revenue",
                XAxisLabel = "Months",
                YAxisLabel = "Dollars"
            };

            // Act
            var result = RclCsv2BarRenderer.Render(props);

            // Assert
            Assert.IsTrue(result.Contains("role=\"figure\""));
            Assert.IsTrue(result.Contains("aria-label=\"Q1 Revenue\""));
            Assert.IsTrue(result.Contains("id=\"revenueChart\""));
            Assert.IsTrue(result.Contains("data-csv-src=\"/api/revenue\""));
            Assert.IsTrue(result.Contains("data-x-axis=\"Months\""));
            Assert.IsTrue(result.Contains("data-y-axis=\"Dollars\""));
        }

        [TestMethod]
        public void Renderer_WithoutTitle_GeneratesFallbackAriaLabel()
        {
            // Arrange
            var props = new Csv2BarProperties
            {
                ChartId = "basicChart",
                CsvSource = "data.csv"
            };

            // Act
            var result = RclCsv2BarRenderer.Render(props);

            // Assert
            Assert.IsTrue(result.Contains("aria-label=\"Bar Chart\""));
        }

        [TestMethod]
        public void Renderer_IncludesInnerContentInSrOnlyDiv()
        {
            // Arrange
            var props = new Csv2BarProperties
            {
                ChartId = "testChart",
                CsvSource = "data.csv",
                Content = "<table><tr><td>Raw Data Fallback</td></tr></table>"
            };

            // Act
            var result = RclCsv2BarRenderer.Render(props);

            // Assert
            Assert.IsTrue(result.Contains("<div class=\"sr-only\">"));
            Assert.IsTrue(result.Contains("Raw Data Fallback"));
        }

        // --- 3. Tag Helper Execution Tests ---

        private (TagHelperContext, TagHelperOutput) CreateTagHelperEssentials(string childContentText)
        {
            var context = new TagHelperContext(
                new TagHelperAttributeList(),
                new Dictionary<object, object>(),
                "test-id");

            var childContent = new DefaultTagHelperContent();
            childContent.SetHtmlContent(childContentText);

            var output = new TagHelperOutput(
                "rcl-csv2bar",
                new TagHelperAttributeList(),
                (useCachedResult, encoder) => Task.FromResult<TagHelperContent>(childContent));

            return (context, output);
        }

        [TestMethod]
        public async Task Helper_ProcessAsync_StripsOriginalTagAndRendersChartContainer()
        {
            // Arrange
            var (context, output) = CreateTagHelperEssentials("<p>Screen reader description.</p>");
            var helper = new Csv2BarHelper
            {
                ChartId = "demoChart",
                CsvSource = "/metrics.csv"
            };

            // Act
            await helper.ProcessAsync(context, output);

            // Assert
            Assert.IsNull(output.TagName); // <rcl-csv2bar> should be stripped
            
            var finalHtml = output.Content.GetContent();
            Assert.IsTrue(finalHtml.Contains("<div class=\"chart-container\""));
            Assert.IsTrue(finalHtml.Contains("<canvas id=\"demoChart\""));
            Assert.IsTrue(finalHtml.Contains("data-csv-src=\"/metrics.csv\""));
            Assert.IsTrue(finalHtml.Contains("<p>Screen reader description.</p>"));
        }
    }
}