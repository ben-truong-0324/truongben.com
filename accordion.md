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