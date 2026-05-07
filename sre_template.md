### dto

using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Razor.TagHelpers;

namespace WTS.RazorComponentLibrary.Models.RclComponents
{
    public enum BannerVariant
    {
        Featured,
        FullSpan
    }

    public class FeaturedBannerProperties
    {
        public BannerVariant Variant { get; set; } = BannerVariant.Featured;

        [Required(AllowEmptyStrings = false, ErrorMessage = "A Title is required for the banner heading.")]
        public string Title { get; set; } = string.Empty;

        [Required(AllowEmptyStrings = false, ErrorMessage = "An ImageSrc is required to render the banner background.")]
        public string ImageSrc { get; set; } = string.Empty;
        
        public string ImageAriaLabel { get; set; } = string.Empty;
        
        public string ImageHref { get; set; } = string.Empty;

        [Required(AllowEmptyStrings = false, ErrorMessage = "Button text is required for UI and ADA compliance.")]
        public string ButtonText { get; set; } = string.Empty;

        public string ButtonHref { get; set; } = "javascript:;";
        
        public string ButtonAriaLabel { get; set; } = string.Empty;

        [HtmlAttributeNotBound]
        public string Content { get; set; } = string.Empty;
    }
}

### tag helper
capturing the child HTML (the paragraph content), validating the properties, stripping the custom tag, and invoking the renderer.


using Microsoft.AspNetCore.Razor.TagHelpers;
using System.Threading.Tasks;
using System.ComponentModel.DataAnnotations;
using WTS.RazorComponentLibrary.Models.RclComponents;
using WTS.RazorComponentLibrary.Renderers;

namespace WTS.RazorLibrary.TagHelpers
{
    [HtmlTargetElement("rcl-featured-banner")]
    public class FeaturedBannerHelper : FeaturedBannerProperties, ITagHelper
    {
        public int Order => 0;
        public void Init(TagHelperContext context) { }

        public async Task ProcessAsync(TagHelperContext context, TagHelperOutput output)
        {
            var childContent = await output.GetChildContentAsync();
            this.Content = childContent.GetContent().Trim();

            var validationContext = new ValidationContext(this);
            Validator.ValidateObject(this, validationContext, validateAllProperties: true);

            // Strip the <rcl-featured-banner> wrapper
            output.TagName = null;

            var htmlResult = RclFeaturedBannerRenderer.Render(this);
            output.Content.SetHtmlContent(htmlResult);
        }
    }
}


### renderer 

using WTS.RazorComponentLibrary.Models.RclComponents;

namespace WTS.RazorComponentLibrary.Renderers
{
    public static class RclFeaturedBannerRenderer
    {
        public static string Render(FeaturedBannerProperties p)
        {
            // Build accessible button label span
            string ariaLabelSpan = string.IsNullOrWhiteSpace(p.ButtonAriaLabel)
                ? string.Empty
                : $" <span class=\"sr-only\">{p.ButtonAriaLabel}</span>";

            if (p.Variant == BannerVariant.FullSpan)
            {
                return RenderFullSpanVariant(p, ariaLabelSpan);
            }

            return RenderFeaturedVariant(p, ariaLabelSpan);
        }

        private static string RenderFeaturedVariant(FeaturedBannerProperties p, string ariaLabelSpan)
        {
            // Resolve Image Link fallback
            string finalImageHref = string.IsNullOrWhiteSpace(p.ImageHref) ? p.ButtonHref : p.ImageHref;
            
            // Resolve Image Aria Label fallback
            string finalImageAria = string.IsNullOrWhiteSpace(p.ImageAriaLabel) ? "Feature banner image" : p.ImageAriaLabel;

            return $@"
                <div class=""container"">
                  <div class=""row bg-gray-100"">
                    <div class=""col-md-6 col-lg-4 p-a-md order-2 order-md-1"">
                      <h2 class=""h3 m-t-0"">{p.Title}</h2>
                      {p.Content}
                      <a href=""{p.ButtonHref}"" class=""btn btn-primary m-y-md"">
                        {p.ButtonText}{ariaLabelSpan}
                      </a>
                    </div>
                    <div class=""col-lg-8 col-md-6 p-0 text-right order-1 order-md-2 d-flex justify-content-center"">
                      <a href=""{finalImageHref}"" class=""feature-img"" style=""background: url('{p.ImageSrc}')"" aria-label=""{finalImageAria}""></a>
                    </div>
                  </div>
                </div>";
        }

        private static string RenderFullSpanVariant(FeaturedBannerProperties p, string ariaLabelSpan)
        {
            return $@"
                <div class=""header-primary-banner d-flex justify-content-center align-items-center"" style=""background-image: url('{p.ImageSrc}');"">
                  <div class=""container p-y-lg"">
                    <div class=""row"">
                      <div class=""col-sm color-white text-center p-a-lg"">
                        <h2 class=""text-3rem m-t-0 overflow-visible"">{p.Title}</h2>
                        {p.Content}
                        <div class=""btn-row p-b"">
                          <a href=""{p.ButtonHref}"" class=""btn btn-lg btn-highlight m-t"">
                            {p.ButtonText}{ariaLabelSpan}
                          </a>
                        </div>
                      </div>
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
    public class FeaturedBannerTests
    {
        // --- 1. Property Validation Tests ---

        [TestMethod]
        [ExpectedException(typeof(ValidationException))]
        public void Properties_MissingTitle_ThrowsValidationException()
        {
            // Arrange
            var props = new FeaturedBannerProperties
            {
                Title = string.Empty, // Invalid
                ImageSrc = "/img.jpg",
                ButtonText = "Click Here"
            };
            var context = new ValidationContext(props);

            // Act
            Validator.ValidateObject(props, context, validateAllProperties: true);
        }

        [TestMethod]
        [ExpectedException(typeof(ValidationException))]
        public void Properties_MissingImageSrc_ThrowsValidationException()
        {
            // Arrange
            var props = new FeaturedBannerProperties
            {
                Title = "Banner",
                ImageSrc = string.Empty, // Invalid
                ButtonText = "Click Here"
            };
            var context = new ValidationContext(props);

            // Act
            Validator.ValidateObject(props, context, validateAllProperties: true);
        }

        // --- 2. Renderer Tests ---

        [TestMethod]
        public void Renderer_FeaturedVariant_OutputsCorrectHtmlAndFallbacks()
        {
            // Arrange
            var props = new FeaturedBannerProperties
            {
                Variant = BannerVariant.Featured,
                Title = "Featured Title",
                ImageSrc = "/ocean.jpg",
                ButtonText = "Action",
                ButtonHref = "/default-link",
                Content = "<p>Some inner content.</p>"
            };

            // Act
            var result = RclFeaturedBannerRenderer.Render(props);

            // Assert
            Assert.IsTrue(result.Contains("<div class=\"row bg-gray-100\">"));
            Assert.IsTrue(result.Contains("<h2 class=\"h3 m-t-0\">Featured Title</h2>"));
            Assert.IsTrue(result.Contains("<p>Some inner content.</p>"));
            Assert.IsTrue(result.Contains("<a href=\"/default-link\" class=\"btn btn-primary m-y-md\">"));
            
            // Verifying fallbacks
            Assert.IsTrue(result.Contains("href=\"/default-link\" class=\"feature-img\"")); // ImageHref falls back to ButtonHref
            Assert.IsTrue(result.Contains("aria-label=\"Feature banner image\"")); // Aria-label fallback
            Assert.IsTrue(result.Contains("background: url('/ocean.jpg')"));
        }

        [TestMethod]
        public void Renderer_FullSpanVariant_OutputsCorrectHtml()
        {
            // Arrange
            var props = new FeaturedBannerProperties
            {
                Variant = BannerVariant.FullSpan,
                Title = "Full Banner",
                ImageSrc = "/main-banner10.jpg",
                ButtonText = "Learn More",
                ButtonAriaLabel = "(feature)"
            };

            // Act
            var result = RclFeaturedBannerRenderer.Render(props);

            // Assert
            Assert.IsTrue(result.Contains("class=\"header-primary-banner d-flex justify-content-center align-items-center\""));
            Assert.IsTrue(result.Contains("background-image: url('/main-banner10.jpg')"));
            Assert.IsTrue(result.Contains("<h2 class=\"text-3rem m-t-0 overflow-visible\">Full Banner</h2>"));
            Assert.IsTrue(result.Contains("class=\"btn btn-lg btn-highlight m-t\""));
            Assert.IsTrue(result.Contains("<span class=\"sr-only\">(feature)</span>"));
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
                "rcl-featured-banner",
                new TagHelperAttributeList(),
                (useCachedResult, encoder) => Task.FromResult<TagHelperContent>(childContent));

            return (context, output);
        }

        [TestMethod]
        public async Task Helper_ProcessAsync_StripsTagAndRenders()
        {
            // Arrange
            var (context, output) = CreateTagHelperEssentials("<p>Dynamic content</p>");
            var helper = new FeaturedBannerHelper
            {
                Title = "Tag Helper Test",
                ImageSrc = "/test.jpg",
                ButtonText = "Go"
            };

            // Act
            await helper.ProcessAsync(context, output);

            // Assert
            Assert.IsNull(output.TagName); // <rcl-featured-banner> should be stripped
            
            var finalHtml = output.Content.GetContent();
            Assert.IsTrue(finalHtml.Contains("Tag Helper Test"));
            Assert.IsTrue(finalHtml.Contains("<p>Dynamic content</p>"));
            Assert.IsTrue(finalHtml.Contains("url('/test.jpg')"));
        }
    }
}

### DTO
using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Razor.TagHelpers;
using WTS.RazorComponentLibrary.Models.Helpers; // Assuming this is where your RequiredIf lives

namespace WTS.RazorComponentLibrary.Models.RclComponents
{
    public enum CardVariant
    {
        Default,
        Icon,
        Image
    }

    public class CardProperties
    {
        public CardVariant Variant { get; set; } = CardVariant.Default;

        [Required(AllowEmptyStrings = false, ErrorMessage = "A Title is required for the card heading.")]
        public string Title { get; set; } = string.Empty;

        public string Href { get; set; } = "javascript:;";

        // Specific to the Default Variant
        public string ButtonText { get; set; } = string.Empty;
        public string ButtonAriaLabel { get; set; } = string.Empty;

        // Specific to the Icon Variant
        public string IconClass { get; set; } = "ca-gov-icon-clipboard";

        // Specific to the Image Variant
        public string ImageSrc { get; set; } = string.Empty;

        [RequiredIf("Variant", CardVariant.Image, ErrorMessage = "Image Alt text is required for ADA compliance on Image cards.")]
        public string ImageAlt { get; set; } = string.Empty;

        [HtmlAttributeNotBound]
        public string Content { get; set; } = string.Empty;
    }
}


### tag helper
using Microsoft.AspNetCore.Razor.TagHelpers;
using System.Threading.Tasks;
using System.ComponentModel.DataAnnotations;
using WTS.RazorComponentLibrary.Models.RclComponents;
using WTS.RazorComponentLibrary.Renderers;

namespace WTS.RazorLibrary.TagHelpers
{
    [HtmlTargetElement("rcl-card")]
    public class CardHelper : CardProperties, ITagHelper
    {
        public int Order => 0;
        public void Init(TagHelperContext context) { }

        public async Task ProcessAsync(TagHelperContext context, TagHelperOutput output)
        {
            var childContent = await output.GetChildContentAsync();
            this.Content = childContent.GetContent().Trim();

            var validationContext = new ValidationContext(this);
            Validator.ValidateObject(this, validationContext, validateAllProperties: true);

            // Strip the <rcl-card> wrapper
            output.TagName = null;

            var htmlResult = RclCardRenderer.Render(this);
            output.Content.SetHtmlContent(htmlResult);
        }
    }
}

### renderer
using WTS.RazorComponentLibrary.Models.RclComponents;

namespace WTS.RazorComponentLibrary.Renderers
{
    public static class RclCardRenderer
    {
        public static string Render(CardProperties p)
        {
            return p.Variant switch
            {
                CardVariant.Icon => RenderIconVariant(p),
                CardVariant.Image => RenderImageVariant(p),
                _ => RenderDefaultVariant(p)
            };
        }

        private static string RenderDefaultVariant(CardProperties p)
        {
            string srOnlyHtml = string.IsNullOrWhiteSpace(p.ButtonAriaLabel)
                ? string.Empty
                : $" <span class=\"sr-only\">{p.ButtonAriaLabel}</span>";

            return $@"
                <div class=""card h-100"">
                  <div class=""card-body bg-gray-50 h-100"">
                    <h3 class=""h4 m-y-sm"">{p.Title}</h3>
                    <p class=""m-b"">{p.Content}</p>
                    <a class=""btn btn-primary p-x-md"" href=""{p.Href}"">
                      {p.ButtonText}{srOnlyHtml}
                    </a>
                  </div>
                </div>";
        }

        private static string RenderIconVariant(CardProperties p)
        {
            return $@"
                <article class=""no-underline d-block bg-gray-50 bg-grey-lightest-hover p-a-md pos-rel h-100"">
                  <div class=""text-center p-b"">
                    <span class=""{p.IconClass} color-p2 color-p2-hover text-huge d-block"" aria-hidden=""true""></span>
                    <a href=""{p.Href}"" class=""h4 m-t-0 m-b color-gray-dark link-before text-left no-underline d-block"">{p.Title}</a>
                    <p class=""color-gray-dark text-left"">{p.Content}</p>
                  </div>
                </article>";
        }

        private static string RenderImageVariant(CardProperties p)
        {
            return $@"
                <div class=""card pos-rel"">
                  <img class=""card-img"" src=""{p.ImageSrc}"" alt=""{p.ImageAlt}"">
                  <div class=""card-body bg-gray-50 bg-gray-100-hover"">
                    <h3 class=""card-title"">
                      <a href=""{p.Href}"" class=""link-before"">
                        {p.Title}
                      </a>
                    </h3>
                    <p>{p.Content}</p>
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
    public class CardTests
    {
        // --- 1. Property Validation Tests ---

        [TestMethod]
        [ExpectedException(typeof(ValidationException))]
        public void Properties_MissingTitle_ThrowsValidationException()
        {
            // Arrange
            var props = new CardProperties
            {
                Title = string.Empty, // Invalid: Needs Title
                Variant = CardVariant.Default
            };
            var context = new ValidationContext(props);

            // Act
            Validator.ValidateObject(props, context, validateAllProperties: true);
        }

        // Note: The RequiredIf attribute testing usually requires a specific setup depending 
        // on your custom implementation of RequiredIf in the WTS.RazorComponentLibrary.Models.Helpers namespace.
        // Assuming it hooks into standard ValidationContext execution, it would be tested like this:
        [TestMethod]
        [ExpectedException(typeof(ValidationException))]
        public void Properties_ImageVariantMissingAltText_ThrowsValidationException()
        {
            // Arrange
            var props = new CardProperties
            {
                Variant = CardVariant.Image,
                Title = "Test",
                ImageSrc = "/img.jpg",
                ImageAlt = string.Empty // Invalid due to RequiredIf
            };
            var context = new ValidationContext(props);

            // Act
            Validator.ValidateObject(props, context, validateAllProperties: true);
        }

        // --- 2. Renderer Tests ---

        [TestMethod]
        public void Renderer_DefaultVariant_OutputsCorrectHtmlAndSrOnlySpan()
        {
            // Arrange
            var props = new CardProperties
            {
                Variant = CardVariant.Default,
                Title = "Basic Card",
                Content = "Inner text",
                ButtonText = "Submit",
                ButtonAriaLabel = "Submit the form"
            };

            // Act
            var result = RclCardRenderer.Render(props);

            // Assert
            Assert.IsTrue(result.Contains("<div class=\"card h-100\">"));
            Assert.IsTrue(result.Contains("<h3 class=\"h4 m-y-sm\">Basic Card</h3>"));
            Assert.IsTrue(result.Contains("<p class=\"m-b\">Inner text</p>"));
            Assert.IsTrue(result.Contains("<a class=\"btn btn-primary p-x-md\""));
            Assert.IsTrue(result.Contains("<span class=\"sr-only\">Submit the form</span>"));
        }

        [TestMethod]
        public void Renderer_IconVariant_OutputsArticleTag()
        {
            // Arrange
            var props = new CardProperties
            {
                Variant = CardVariant.Icon,
                Title = "Icon Card",
                IconClass = "ca-gov-icon-info",
                Href = "/info",
                Content = "Icon description."
            };

            // Act
            var result = RclCardRenderer.Render(props);

            // Assert
            Assert.IsTrue(result.Contains("<article class=\"no-underline d-block"));
            Assert.IsTrue(result.Contains("<span class=\"ca-gov-icon-info"));
            Assert.IsTrue(result.Contains("aria-hidden=\"true\""));
            Assert.IsTrue(result.Contains("<a href=\"/info\" class=\"h4 m-t-0 m-b color-gray-dark link-before"));
        }

        [TestMethod]
        public void Renderer_ImageVariant_OutputsImageTag()
        {
            // Arrange
            var props = new CardProperties
            {
                Variant = CardVariant.Image,
                Title = "Image Card",
                ImageSrc = "/test.jpg",
                ImageAlt = "Test Alt"
            };

            // Act
            var result = RclCardRenderer.Render(props);

            // Assert
            Assert.IsTrue(result.Contains("<div class=\"card pos-rel\">"));
            Assert.IsTrue(result.Contains("<img class=\"card-img\" src=\"/test.jpg\" alt=\"Test Alt\">"));
            Assert.IsTrue(result.Contains("class=\"card-body bg-gray-50 bg-gray-100-hover\""));
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
                "rcl-card",
                new TagHelperAttributeList(),
                (useCachedResult, encoder) => Task.FromResult<TagHelperContent>(childContent));

            return (context, output);
        }

        [TestMethod]
        public async Task Helper_ProcessAsync_StripsOriginalTagAndRenders()
        {
            // Arrange
            var (context, output) = CreateTagHelperEssentials("This is dynamic content.");
            var helper = new CardHelper
            {
                Variant = CardVariant.Image,
                Title = "Execute Test",
                ImageSrc = "img.png",
                ImageAlt = "alt"
            };

            // Act
            await helper.ProcessAsync(context, output);

            // Assert
            Assert.IsNull(output.TagName); // <rcl-card> should be stripped
            
            var finalHtml = output.Content.GetContent();
            Assert.IsTrue(finalHtml.Contains("Execute Test"));
            Assert.IsTrue(finalHtml.Contains("<p>This is dynamic content.</p>"));
            Assert.IsTrue(finalHtml.Contains("<img class=\"card-img\""));
        }
    }
}


###  DTO
using System;
using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Razor.TagHelpers;

namespace WTS.RazorComponentLibrary.Models.RclComponents
{
    public class ProgressBarProperties
    {
        [Required(ErrorMessage = "A current Value is required for the progress bar.")]
        public double Value { get; set; } = 0;

        public double Min { get; set; } = 0;
        
        public double Max { get; set; } = 100;

        public string ColorClass { get; set; } = "bg-highlight";

        public bool ShowLabel { get; set; } = true;

        [HtmlAttributeNotBound]
        public string Content { get; set; } = string.Empty;
    }
}

### tag helprer
using Microsoft.AspNetCore.Razor.TagHelpers;
using System.Threading.Tasks;
using System.ComponentModel.DataAnnotations;
using WTS.RazorComponentLibrary.Models.RclComponents;
using WTS.RazorComponentLibrary.Renderers;

namespace WTS.RazorLibrary.TagHelpers
{
    [HtmlTargetElement("rcl-progress-bar")]
    public class ProgressBarHelper : ProgressBarProperties, ITagHelper
    {
        public int Order => 0;
        public void Init(TagHelperContext context) { }

        public async Task ProcessAsync(TagHelperContext context, TagHelperOutput output)
        {
            var childContent = await output.GetChildContentAsync();
            this.Content = childContent.GetContent().Trim();

            var validationContext = new ValidationContext(this);
            Validator.ValidateObject(this, validationContext, validateAllProperties: true);

            // Strip the <rcl-progress-bar> wrapper
            output.TagName = null;

            var htmlResult = RclProgressBarRenderer.Render(this);
            output.Content.SetHtmlContent(htmlResult);
        }
    }
}

### rendere 
using System;
using WTS.RazorComponentLibrary.Models.RclComponents;

namespace WTS.RazorComponentLibrary.Renderers
{
    public static class RclProgressBarRenderer
    {
        public static string Render(ProgressBarProperties p)
        {
            // Safeguard against divide-by-zero if a developer accidentally sets Min and Max to the same value
            double range = p.Max - p.Min;
            if (range <= 0) range = 1; 

            // Calculate the percentage for the CSS width (clamped between 0 and 100)
            double percentage = Math.Clamp(((p.Value - p.Min) / range) * 100, 0, 100);
            
            // Format percentage to a clean integer string (e.g., "60%")
            string formattedPercentage = $"{Math.Round(percentage)}%";

            // Determine what text to show inside the bar (prioritize developer's custom inner HTML, fallback to the percentage)
            string innerText = string.Empty;
            if (p.ShowLabel)
            {
                innerText = string.IsNullOrWhiteSpace(p.Content) ? formattedPercentage : p.Content;
            }

            return $@"
                <div class=""progress"">
                  <div class=""progress-bar {p.ColorClass} overflow-auto"" 
                       role=""progressbar"" 
                       aria-valuenow=""{p.Value}"" 
                       aria-valuemin=""{p.Min}"" 
                       aria-valuemax=""{p.Max}"" 
                       style=""width: {formattedPercentage}; color:#000;"" 
                       tabindex=""0"">
                    {innerText}
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
    public class ProgressBarTests
    {
        // --- 1. Renderer Tests ---

        [TestMethod]
        public void Renderer_StandardValues_CalculatesCorrectPercentage()
        {
            // Arrange
            var props = new ProgressBarProperties
            {
                Value = 60,
                Min = 0,
                Max = 100,
                ColorClass = "bg-highlight"
            };

            // Act
            var result = RclProgressBarRenderer.Render(props);

            // Assert
            Assert.IsTrue(result.Contains("aria-valuenow=\"60\""));
            Assert.IsTrue(result.Contains("style=\"width: 60%; color:#000;\""));
            Assert.IsTrue(result.Contains("60%"));
            Assert.IsTrue(result.Contains("bg-highlight"));
        }

        [TestMethod]
        public void Renderer_CustomMinMax_CalculatesCorrectRelativePercentage()
        {
            // Arrange
            var props = new ProgressBarProperties
            {
                Value = 150,
                Min = 100,
                Max = 200
            };

            // Act
            var result = RclProgressBarRenderer.Render(props);

            // Assert
            Assert.IsTrue(result.Contains("aria-valuenow=\"150\""));
            Assert.IsTrue(result.Contains("aria-valuemin=\"100\""));
            Assert.IsTrue(result.Contains("aria-valuemax=\"200\""));
            // 150 is exactly 50% between 100 and 200
            Assert.IsTrue(result.Contains("style=\"width: 50%; color:#000;\"")); 
            Assert.IsTrue(result.Contains("50%"));
        }

        [TestMethod]
        public void Renderer_ShowLabelFalse_OmitsInnerPercentageText()
        {
            // Arrange
            var props = new ProgressBarProperties
            {
                Value = 75,
                ShowLabel = false
            };

            // Act
            var result = RclProgressBarRenderer.Render(props);

            // Assert
            Assert.IsTrue(result.Contains("width: 75%;"));
            // Because ShowLabel is false, "75%" should NOT be rendered as text inside the div
            Assert.IsFalse(result.Contains(">75%<")); 
            Assert.IsFalse(result.Contains(">\r\n                    75%\r\n                  </div>"));
        }

        [TestMethod]
        public void Renderer_CustomContent_OverridesPercentageLabel()
        {
            // Arrange
            var props = new ProgressBarProperties
            {
                Value = 42,
                Content = "Processing..."
            };

            // Act
            var result = RclProgressBarRenderer.Render(props);

            // Assert
            Assert.IsTrue(result.Contains("width: 42%;"));
            Assert.IsTrue(result.Contains("Processing..."));
            Assert.IsFalse(result.Contains("42%")); // Replaced by custom text
        }

        // --- 2. Tag Helper Execution Tests ---

        [TestMethod]
        public async Task Helper_ProcessAsync_StripsTagAndRendersCorrectly()
        {
            // Arrange
            var context = new TagHelperContext(
                new TagHelperAttributeList(),
                new Dictionary<object, object>(),
                "test-id");

            var childContent = new DefaultTagHelperContent();
            childContent.SetHtmlContent("");

            var output = new TagHelperOutput(
                "rcl-progress-bar",
                new TagHelperAttributeList(),
                (useCachedResult, encoder) => Task.FromResult<TagHelperContent>(childContent));

            var helper = new ProgressBarHelper
            {
                Value = 88,
                ColorClass = "bg-success"
            };

            // Act
            await helper.ProcessAsync(context, output);

            // Assert
            Assert.IsNull(output.TagName); // <rcl-progress-bar> stripped
            
            var finalHtml = output.Content.GetContent();
            Assert.IsTrue(finalHtml.Contains("class=\"progress-bar bg-success overflow-auto\""));
            Assert.IsTrue(finalHtml.Contains("width: 88%"));
            Assert.IsTrue(finalHtml.Contains("88%"));
        }
    }
}


### dto

using System.ComponentModel.DataAnnotations;

namespace WTS.RazorComponentLibrary.Models.RclComponents
{
    public class PaginationProperties
    {
        [Range(1, int.MaxValue, ErrorMessage = "CurrentPage must be 1 or greater.")]
        public int CurrentPage { get; set; } = 1;

        [Range(-1, int.MaxValue, ErrorMessage = "TotalPages must be -1 (unbound) or 1 or greater.")]
        public int TotalPages { get; set; } = 1;

        public string PreviousText { get; set; } = "Previous";
        
        public string NextText { get; set; } = "Next";
    }
}


### th

using Microsoft.AspNetCore.Razor.TagHelpers;
using System.Threading.Tasks;
using System.ComponentModel.DataAnnotations;
using WTS.RazorComponentLibrary.Models.RclComponents;
using WTS.RazorComponentLibrary.Renderers;

namespace WTS.RazorLibrary.TagHelpers
{
    [HtmlTargetElement("rcl-pagination")]
    public class PaginationHelper : PaginationProperties, ITagHelper
    {
        public int Order => 0;
        public void Init(TagHelperContext context) { }

        public Task ProcessAsync(TagHelperContext context, TagHelperOutput output)
        {
            var validationContext = new ValidationContext(this);
            Validator.ValidateObject(this, validationContext, validateAllProperties: true);

            // Strip the <rcl-pagination> wrapper
            output.TagName = null;

            var htmlResult = RclPaginationRenderer.Render(this);
            output.Content.SetHtmlContent(htmlResult);

            return Task.CompletedTask;
        }
    }
}



## rendere
using WTS.RazorComponentLibrary.Models.RclComponents;

namespace WTS.RazorComponentLibrary.Renderers
{
    public static class RclPaginationRenderer
    {
        public static string Render(PaginationProperties p)
        {
            return $@"<cagov-pagination data-current-page=""{p.CurrentPage}"" data-total-pages=""{p.TotalPages}"" data-previous=""{p.PreviousText}"" data-next=""{p.NextText}""></cagov-pagination>";
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
    public class PaginationTests
    {
        // --- 1. Property Validation Tests ---

        [TestMethod]
        [ExpectedException(typeof(ValidationException))]
        public void Properties_CurrentPageZero_ThrowsValidationException()
        {
            // Arrange
            var props = new PaginationProperties
            {
                CurrentPage = 0, // Invalid: Must be >= 1
                TotalPages = 10
            };
            var context = new ValidationContext(props);

            // Act
            Validator.ValidateObject(props, context, validateAllProperties: true);
        }

        [TestMethod]
        [ExpectedException(typeof(ValidationException))]
        public void Properties_TotalPagesNegativeTwo_ThrowsValidationException()
        {
            // Arrange
            var props = new PaginationProperties
            {
                CurrentPage = 1,
                TotalPages = -2 // Invalid: Must be >= -1
            };
            var context = new ValidationContext(props);

            // Act
            Validator.ValidateObject(props, context, validateAllProperties: true);
        }

        // --- 2. Renderer Tests ---

        [TestMethod]
        public void Renderer_StandardValues_OutputsCorrectWebComponent()
        {
            // Arrange
            var props = new PaginationProperties
            {
                CurrentPage = 5,
                TotalPages = 99
            };

            // Act
            var result = RclPaginationRenderer.Render(props);

            // Assert
            Assert.IsTrue(result.Contains("<cagov-pagination"));
            Assert.IsTrue(result.Contains("data-current-page=\"5\""));
            Assert.IsTrue(result.Contains("data-total-pages=\"99\""));
            Assert.IsTrue(result.Contains("data-previous=\"Previous\""));
            Assert.IsTrue(result.Contains("data-next=\"Next\""));
        }

        [TestMethod]
        public void Renderer_CustomText_OutputsInternationalizedText()
        {
            // Arrange
            var props = new PaginationProperties
            {
                CurrentPage = 2,
                TotalPages = 5,
                PreviousText = "Atrás",
                NextText = "Siguiente"
            };

            // Act
            var result = RclPaginationRenderer.Render(props);

            // Assert
            Assert.IsTrue(result.Contains("data-previous=\"Atrás\""));
            Assert.IsTrue(result.Contains("data-next=\"Siguiente\""));
        }

        // --- 3. Tag Helper Execution Tests ---

        [TestMethod]
        public async Task Helper_ProcessAsync_StripsTagAndRenders()
        {
            // Arrange
            var context = new TagHelperContext(
                new TagHelperAttributeList(),
                new Dictionary<object, object>(),
                "test-id");

            var output = new TagHelperOutput(
                "rcl-pagination",
                new TagHelperAttributeList(),
                (useCachedResult, encoder) => Task.FromResult<TagHelperContent>(new DefaultTagHelperContent()));

            var helper = new PaginationHelper
            {
                CurrentPage = 3,
                TotalPages = -1
            };

            // Act
            await helper.ProcessAsync(context, output);

            // Assert
            Assert.IsNull(output.TagName); // <rcl-pagination> stripped
            
            var finalHtml = output.Content.GetContent();
            Assert.IsTrue(finalHtml.Contains("<cagov-pagination"));
            Assert.IsTrue(finalHtml.Contains("data-current-page=\"3\""));
            Assert.IsTrue(finalHtml.Contains("data-total-pages=\"-1\""));
        }
    }
}



### dto

using System;
using System.ComponentModel.DataAnnotations;

namespace WTS.RazorComponentLibrary.Models.RclComponents
{
    public enum CountdownVariant
    {
        Default,
        Primary
    }

    public class CountdownProperties
    {
        [Required(ErrorMessage = "A TargetDate is required to calculate the countdown distance.")]
        public DateTime TargetDate { get; set; }

        public CountdownVariant Variant { get; set; } = CountdownVariant.Default;

        public string ExpiredText { get; set; } = "EXPIRED";

        // Allows developers to explicitly set an ID, otherwise the Tag Helper generates one
        public string ComponentId { get; set; } = string.Empty;
    }
}


## th

using Microsoft.AspNetCore.Razor.TagHelpers;
using System;
using System.Threading.Tasks;
using System.ComponentModel.DataAnnotations;
using WTS.RazorComponentLibrary.Models.RclComponents;
using WTS.RazorComponentLibrary.Renderers;

namespace WTS.RazorLibrary.TagHelpers
{
    [HtmlTargetElement("rcl-countdown")]
    public class CountdownHelper : CountdownProperties, ITagHelper
    {
        public int Order => 0;
        public void Init(TagHelperContext context) { }

        public Task ProcessAsync(TagHelperContext context, TagHelperOutput output)
        {
            var validationContext = new ValidationContext(this);
            Validator.ValidateObject(this, validationContext, validateAllProperties: true);

            // Generate a unique ID if the developer didn't provide one to prevent JS DOM collisions
            if (string.IsNullOrWhiteSpace(this.ComponentId))
            {
                this.ComponentId = $"timer_{Guid.NewGuid().ToString("N").Substring(0, 8)}";
            }

            // Strip the <rcl-countdown> wrapper
            output.TagName = null;

            var htmlResult = RclCountdownRenderer.Render(this);
            output.Content.SetHtmlContent(htmlResult);

            return Task.CompletedTask;
        }
    }
}

## renderer
using WTS.RazorComponentLibrary.Models.RclComponents;

namespace WTS.RazorComponentLibrary.Renderers
{
    public static class RclCountdownRenderer
    {
        public static string Render(CountdownProperties p)
        {
            string bgClass = p.Variant == CountdownVariant.Primary ? "section-primary" : "bg-gray-100";
            string targetDateStr = p.TargetDate.ToString("MMM d, yyyy HH:mm:ss");
            string prefix = p.ComponentId;

            return $@"
                <div class=""row flex-column flex-md-row countdown p-x"">
                   <div class=""col {bgClass} text-center p-b-md p-l-0 p-r-0"">
                    <span class=""countdown-text""><abbr title=""weeks"" aria-label=""weeks"" class=""text-decoration-none"">wks</abbr><br></span>
                    <span id=""{prefix}_weeks""></span>
                   </div>
                   <div class=""col {bgClass} text-center p-b-md p-l-0 p-r-0"">
                    <span class=""countdown-text"">days<br></span>
                    <span id=""{prefix}_days""></span>
                   </div>
                   <div class=""col {bgClass} text-center p-b-md p-l-0 p-r-0"">
                    <span class=""countdown-text""><abbr title=""hours"" aria-label=""hours"" class=""text-decoration-none"">hrs</abbr> <br></span>
                    <span id=""{prefix}_hours""></span>
                   </div>
                   <div class=""col {bgClass} text-center p-b-md p-l-0 p-r-0"">
                    <span class=""countdown-text""><abbr title=""minutes"" aria-label=""minutes"" class=""text-decoration-none"">mins</abbr><br></span>
                    <span id=""{prefix}_minutes""></span>
                   </div>
                   <div class=""col {bgClass} text-center p-b-md p-l-0 p-r-0"">
                    <span class=""countdown-text""><abbr title=""seconds"" aria-label=""seconds"" class=""text-decoration-none"">secs</abbr><br></span>
                    <span id=""{prefix}_seconds""></span>
                   </div>
                </div>

                <script>
                (function() {{
                    var countDownDate = new Date(""{targetDateStr}"").getTime();
                    var x = setInterval(function () {{
                        var now = new Date().getTime();
                        var distance = countDownDate - now;

                        var weeks = Math.floor(distance / (1000 * 60 * 60 * 24 * 7));
                        var days = Math.floor(distance / (1000 * 60 * 60 * 24));
                        var hours = Math.floor((distance % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60));
                        var minutes = Math.floor((distance % (1000 * 60 * 60)) / (1000 * 60));
                        var seconds = Math.floor((distance % (1000 * 60)) / 1000);

                        var elWeeks = document.getElementById(""{prefix}_weeks"");
                        if (!elWeeks) {{
                            clearInterval(x); // Stop if element is removed from DOM
                            return;
                        }}

                        if (distance < 0) {{
                            clearInterval(x);
                            elWeeks.innerHTML = ""0"";
                            document.getElementById(""{prefix}_days"").innerHTML = ""{p.ExpiredText}"";
                            document.getElementById(""{prefix}_hours"").innerHTML = ""0"";
                            document.getElementById(""{prefix}_minutes"").innerHTML = ""0"";
                            document.getElementById(""{prefix}_seconds"").innerHTML = ""0"";
                        }} else {{
                            elWeeks.innerHTML = weeks;
                            document.getElementById(""{prefix}_days"").innerHTML = days;
                            document.getElementById(""{prefix}_hours"").innerHTML = hours;
                            document.getElementById(""{prefix}_minutes"").innerHTML = minutes;
                            document.getElementById(""{prefix}_seconds"").innerHTML = seconds;
                        }}
                    }}, 1000);
                }})();
                </script>";
        }
    }
}

### test
using Microsoft.VisualStudio.TestTools.UnitTesting;
using Microsoft.AspNetCore.Razor.TagHelpers;
using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Threading.Tasks;
using WTS.RazorComponentLibrary.Models.RclComponents;
using WTS.RazorComponentLibrary.Renderers;
using WTS.RazorLibrary.TagHelpers;

namespace WTS.RazorLibrary.Tests
{
    [TestClass]
    public class CountdownTests
    {
        // --- 1. Property Validation Tests ---

        [TestMethod]
        public void Properties_ValidDate_PassesValidation()
        {
            var props = new CountdownProperties
            {
                TargetDate = new DateTime(2027, 1, 1)
            };
            var context = new ValidationContext(props);
            
            // Should not throw
            Validator.ValidateObject(props, context, validateAllProperties: true);
        }

        // --- 2. Renderer Tests ---

        [TestMethod]
        public void Renderer_DefaultVariant_OutputsGrayBackgroundAndCorrectJS()
        {
            // Arrange
            var props = new CountdownProperties
            {
                TargetDate = new DateTime(2030, 12, 31, 23, 59, 59),
                Variant = CountdownVariant.Default,
                ComponentId = "customTimer",
                ExpiredText = "DONE"
            };

            // Act
            var result = RclCountdownRenderer.Render(props);

            // Assert - HTML Structure
            Assert.IsTrue(result.Contains("bg-gray-100"));
            Assert.IsFalse(result.Contains("section-primary"));
            Assert.IsTrue(result.Contains("id=\"customTimer_weeks\""));
            
            // Assert - JS Injection
            Assert.IsTrue(result.Contains("new Date(\"Dec 31, 2030 23:59:59\")"));
            Assert.IsTrue(result.Contains("getElementById(\"customTimer_days\")"));
            Assert.IsTrue(result.Contains(".innerHTML = \"DONE\""));
        }

        [TestMethod]
        public void Renderer_PrimaryVariant_OutputsPrimaryBackground()
        {
            // Arrange
            var props = new CountdownProperties
            {
                TargetDate = new DateTime(2027, 1, 1),
                Variant = CountdownVariant.Primary,
                ComponentId = "t1"
            };

            // Act
            var result = RclCountdownRenderer.Render(props);

            // Assert
            Assert.IsTrue(result.Contains("section-primary"));
            Assert.IsFalse(result.Contains("bg-gray-100"));
        }

        // --- 3. Tag Helper Execution Tests ---

        [TestMethod]
        public async Task Helper_ProcessAsync_GeneratesIdIfMissingAndStripsTag()
        {
            // Arrange
            var context = new TagHelperContext(
                new TagHelperAttributeList(),
                new Dictionary<object, object>(),
                "test-id");

            var output = new TagHelperOutput(
                "rcl-countdown",
                new TagHelperAttributeList(),
                (useCachedResult, encoder) => Task.FromResult<TagHelperContent>(new DefaultTagHelperContent()));

            var helper = new CountdownHelper
            {
                TargetDate = new DateTime(2028, 1, 1)
                // Leaving ComponentId empty to test auto-generation
            };

            // Act
            await helper.ProcessAsync(context, output);

            // Assert
            Assert.IsNull(output.TagName); // <rcl-countdown> stripped
            
            var finalHtml = output.Content.GetContent();
            
            // It should have generated a GUID-based ID starting with "timer_"
            Assert.IsTrue(finalHtml.Contains("id=\"timer_"));
            Assert.IsTrue(finalHtml.Contains("_weeks\""));
        }
    }
}

<rcl-countdown target-date="@new DateTime(2027, 1, 1)"></rcl-countdown>

<rcl-countdown 
    target-date="@new DateTime(2026, 12, 25)" 
    variant="Primary" 
    expired-text="MERRY CHRISTMAS!">
</rcl-countdown>







####################

# State Template Component Library Showcase

This document demonstrates the Markdown directive syntax for all custom Razor components in your library. It assumes you are using a Markdown processor (like Markdig) configured to map `:::` directives to your Tag Helpers via custom attributes.

---

## 1. Accordion
Use the accordion to stack collapsible content panels.

:::rcl-accordion {Variant="Default"}
  :::rcl-accordion-item {Heading="Panel 1: Introduction"}
  This is the content inside the first panel. You can use standard markdown like **bold text** here.
  :::
  :::rcl-accordion-item {Heading="Panel 2: Details"}
  Here are more details hidden inside the second panel.
  :::
:::

---

## 2. Alert
Use alerts to display important messages to the user.

:::rcl-alert {Variant="Warning"}
**Attention:** Please review the updated policy changes before continuing with your application.
:::

---

## 3. Blockquote
Highlight prominent quotes or pull-text.

:::rcl-blockquote {Variant="Prominent" Author="Jane Doe"}
Innovation distinguishes between a leader and a follower.
:::

---

## 4. Button
Standardized buttons for actions and links.

:::rcl-button {Color="Primary" Size="Lg" Href="/apply" IsOutline="false"}
Apply Now
:::

---

## 5. Executive Profile
Display leadership headshots and titles.

:::rcl-executive-profile {Variant="Default" Name="John Smith" OfficialTitle="Director of Technology" Agency="Department of Innovation" ImageSrc="/images/john-smith.jpg" ImageAlt="Headshot of John Smith" LinkText="View Director's Bio" LinkHref="/about/director"}
:::

---

## 6. Featured Banner
Use banners for page headers and hero sections.

:::rcl-featured-banner {Variant="Featured" Title="Welcome to the State Portal" ImageSrc="/images/hero-ocean.jpg" ButtonText="Get Started" ButtonHref="/start"}
Discover tools, resources, and services designed to help you succeed.
:::

---

## 7. Link Grid
Create a grid of uniformly sized navigation blocks.

:::rcl-link-grid
  :::rcl-link-grid-item {Href="/services" ColumnClass="col-md-4 mb-4"}
  **Online Services**
  Access forms and applications.
  :::
  :::rcl-link-grid-item {Href="/contact" ColumnClass="col-md-4 mb-4"}
  **Contact Us**
  Get in touch with our team.
  :::
:::

---

## 8. Modal
Define popup modals. (Note: A separate button is required to trigger the `data-bs-target`).

:::rcl-modal {ModalId="termsModal" Title="Terms of Service" Size="Lg" ShowFooter="true" FooterCloseText="I Agree"}
Please read these terms carefully. By using this service, you agree to comply with all state regulations.
:::

---

## 9. Social Media
Generate a standardized row of social sharing icons.

:::rcl-social-container
  :::rcl-social-icon {Platform="Twitter" Href="https://twitter.com/state"}
  :::
  :::rcl-social-icon {Platform="LinkedIn" Href="https://linkedin.com/company/state"}
  :::
  :::rcl-social-icon {Platform="Email" Href="mailto:contact@state.gov"}
  :::
:::

---

## 10. Step List
Guide users through sequential processes.

:::rcl-step-list
  :::rcl-step-list-item {Heading="Step 1: Register"}
  Create an account using your primary email address.
  :::
  :::rcl-step-list-item {Heading="Step 2: Verify"}
  Click the verification link sent to your inbox.
  :::
  :::rcl-step-list-item {Heading="Step 3: Apply"}
  Fill out the application form completely.
  :::
:::

---

## 11. Tabs
Organize dense content into horizontal tabbed views.

:::rcl-tabs
  :::rcl-tab {Title="Overview"}
  This is the overview content.
  :::
  :::rcl-tab {Title="Specifications"}
  Technical specifications and requirements go here.
  :::
:::

---

## 12. Table
Render styled data tables.

:::rcl-table {Variant="Striped"}
<thead>
  <tr>
    <th scope="col">ID</th>
    <th scope="col">Department</th>
    <th scope="col">Status</th>
  </tr>
</thead>
<tbody>
  <tr>
    <td>001</td>
    <td>Technology</td>
    <td>Active</td>
  </tr>
  <tr>
    <td>002</td>
    <td>Human Resources</td>
    <td>Pending</td>
  </tr>
</tbody>
:::

---

## 13. Timeline
Display events in chronological order.

:::rcl-timeline
  :::rcl-timeline-item {Title="Project Kickoff" Timeframe="Q1 2026"}
  Initial planning and requirements gathering phase.
  :::
  :::rcl-timeline-item {Title="Beta Release" Timeframe="Q3 2026"}
  First round of user testing and feedback collection.
  :::
:::

---



## 1. Accordion
Use the accordion to stack collapsible content panels.

:::rcl-accordion {Variant="Default"}
  :::rcl-accordion-item {Heading="Panel 1: Introduction"}
  This is the content inside the first panel. You can use standard markdown like **bold text** here.
  :::
  :::rcl-accordion-item {Heading="Panel 2: Details"}
  Here are more details hidden inside the second panel.
  :::
:::

---

## 2. Alert
Use alerts to display important messages to the user.

:::rcl-alert {Variant="Warning"}
**Attention:** Please review the updated policy changes before continuing with your application.
:::

---

## 3. Blockquote
Highlight prominent quotes or pull-text.

:::rcl-blockquote {Variant="Prominent" Author="Jane Doe"}
Innovation distinguishes between a leader and a follower.
:::

---

## 4. Button
Standardized buttons for actions and links.

:::rcl-button {Color="Primary" Size="Lg" Href="/apply" IsOutline="false"}
Apply Now
:::

---

## 5. Cards
Cards group related information in a flexible container.

:::rcl-card {Variant="Default" Title="Default Card" ButtonText="Learn More" Href="/info"}
This is the standard card layout. It requires a title and button text.
:::

:::rcl-card {Variant="Icon" Title="Icon Card" IconClass="ca-gov-icon-clipboard" Href="/docs"}
Icon cards are great for dashboards and quick links.
:::

:::rcl-card {Variant="Image" Title="Image Card" ImageSrc="/images/sample.jpg" ImageAlt="Descriptive alt text" Href="/gallery"}
Image cards provide a strong visual entry point.
:::

---

## 6. Countdown Timer
Build anticipation for a future event.

:::rcl-countdown {TargetDate="2027-01-01T00:00:00" Variant="Primary" ExpiredText="LAUNCHED"}
:::

---

## 7. Executive Profile
Display leadership headshots and titles.

:::rcl-executive-profile {Variant="Default" Name="John Smith" OfficialTitle="Director of Technology" Agency="Department of Innovation" ImageSrc="/images/john-smith.jpg" ImageAlt="Headshot of John Smith" LinkText="View Director's Bio" LinkHref="/about/director"}
:::

---

## 8. Featured Banner
Use banners for page headers and hero sections.

:::rcl-featured-banner {Variant="Featured" Title="Welcome to the State Portal" ImageSrc="/images/hero-ocean.jpg" ButtonText="Get Started" ButtonHref="/start"}
Discover tools, resources, and services designed to help you succeed.
:::

---

## 9. Forms
Standardized, ADA-compliant form elements.

:::rcl-input {Type="Text" InputId="fName" Name="FirstName" Label="First Name" IsRequired="true" Placeholder="Enter your first name"}
:::

:::rcl-check {Type="Radio" InputId="radio1" Name="Options" Value="A" Label="Option A" IsChecked="true"}
:::

:::rcl-select {SelectId="stateSelect" Name="State" Label="Select your State"}
<option value="CA">California</option>
<option value="NV">Nevada</option>
:::

---

## 10. Link Grid
Create a grid of uniformly sized navigation blocks.

:::rcl-link-grid
  :::rcl-link-grid-item {Href="/services" ColumnClass="col-md-4 mb-4"}
  **Online Services**
  Access forms and applications.
  :::
  :::rcl-link-grid-item {Href="/contact" ColumnClass="col-md-4 mb-4"}
  **Contact Us**
  Get in touch with our team.
  :::
:::

---

## 11. Modal
Define popup modals. (Note: A separate button is required to trigger the `data-bs-target`).

:::rcl-modal {ModalId="termsModal" Title="Terms of Service" Size="Lg" ShowFooter="true" FooterCloseText="I Agree"}
Please read these terms carefully. By using this service, you agree to comply with all state regulations.
:::

---

## 12. Pagination
Provide navigation for paginated data sets.

:::rcl-pagination {CurrentPage="5" TotalPages="99" PreviousText="Previous" NextText="Next"}
:::

---

## 13. Progress Bar
Show completion status for a process or goal.

:::rcl-progress-bar {Value="60" Min="0" Max="100" ColorClass="bg-highlight" ShowLabel="true"}
:::

---

## 14. Social Media
Generate a standardized row of social sharing icons.

:::rcl-social-container
  :::rcl-social-icon {Platform="Twitter" Href="https://twitter.com/state"}
  :::
  :::rcl-social-icon {Platform="LinkedIn" Href="https://linkedin.com/company/state"}
  :::
  :::rcl-social-icon {Platform="Email" Href="mailto:contact@state.gov"}
  :::
:::

---

## 15. Step List
Guide users through sequential processes.

:::rcl-step-list
  :::rcl-step-list-item {Heading="Step 1: Register"}
  Create an account using your primary email address.
  :::
  :::rcl-step-list-item {Heading="Step 2: Verify"}
  Click the verification link sent to your inbox.
  :::
:::

---

## 16. Tabs
Organize dense content into horizontal tabbed views.

:::rcl-tabs
  :::rcl-tab {Title="Overview"}
  This is the overview content.
  :::
  :::rcl-tab {Title="Specifications"}
  Technical specifications and requirements go here.
  :::
:::

---

## 17. Table
Render styled data tables.

:::rcl-table {Variant="Striped"}
<thead>
  <tr>
    <th scope="col">ID</th>
    <th scope="col">Department</th>
    <th scope="col">Status</th>
  </tr>
</thead>
<tbody>
  <tr>
    <td>001</td>
    <td>Technology</td>
    <td>Active</td>
  </tr>
</tbody>
:::

---

## 18. Timeline
Display events in chronological order.

:::rcl-timeline
  :::rcl-timeline-item {Title="Project Kickoff" Timeframe="Q1 2026"}
  Initial planning and requirements gathering phase.
  :::
  :::rcl-timeline-item {Title="Beta Release" Timeframe="Q3 2026"}
  First round of user testing and feedback collection.
  :::
:::

---


#####################