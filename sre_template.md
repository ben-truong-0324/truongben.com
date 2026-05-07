### Template for SRE work flow

## TODO

















using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Razor.TagHelpers;
using WTS.RazorComponentLibrary.Models.Helpers; 

namespace WTS.RazorComponentLibrary.Models.RclComponents
{
    public enum CardVariant
    {
        Default,
        Icon,
        Image,
        Legacy
    }

    public enum LegacyCardType
    {
        Default,
        Understated,
        Standout,
        Overstated,
        Primary,
        Danger,
        Inverted,
        Info,
        Success,
        Warning
    }

    public class CardProperties
    {
        public CardVariant Variant { get; set; } = CardVariant.Default;

        [Required(AllowEmptyStrings = false, ErrorMessage = "A Title is required for the card heading.")]
        public string Title { get; set; } = string.Empty;

        public string Href { get; set; } = "javascript:;";

        public bool IsGridItem { get; set; } 

        public string ButtonText { get; set; } = string.Empty;
        public string ButtonAriaLabel { get; set; } = string.Empty;

        public string IconClass { get; set; } = "ca-gov-icon-info";

        public string ImageSrc { get; set; } = string.Empty;

        [RequiredIf("Variant", CardVariant.Image, ErrorMessage = "Image Alt text is required for ADA compliance on Image cards.")]
        public string ImageAlt { get; set; } = string.Empty;

        public LegacyCardType LegacyType { get; set; } = LegacyCardType.Default;

        [HtmlAttributeNotBound]
        public string Content { get; set; } = string.Empty;
    }
}

###

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

####

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
                CardVariant.Legacy => RenderLegacyVariant(p),
                _ => RenderDefaultVariant(p)
            };
        }

        private static string RenderDefaultVariant(CardProperties p)
        {
            string h100 = p.IsGridItem ? " h-100" : "";
            string flexInner = p.IsGridItem ? " h-100 d-flex flex-column" : "";
            string mtAuto = p.IsGridItem ? "mt-auto" : "m-t-md";

            string srOnlyHtml = string.IsNullOrWhiteSpace(p.ButtonAriaLabel)
                ? string.Empty
                : $" <span class=\"sr-only\">{p.ButtonAriaLabel}</span>";

            string buttonHtml = string.IsNullOrWhiteSpace(p.ButtonText) 
                ? string.Empty 
                : $@"<p class=""{mtAuto} m-b-0""><a class=""btn btn-primary p-x-md"" href=""{p.Href}"">{p.ButtonText}{srOnlyHtml}</a></p>";

            return $@"
                <div class=""card{h100}"">
                  <div class=""card-body bg-gray-50{flexInner}"">
                    <h3 class=""h4 m-y-sm"">{p.Title}</h3>
                    <p class=""m-b"">{p.Content}</p>
                    {buttonHtml}
                  </div>
                </div>";
        }

        private static string RenderIconVariant(CardProperties p)
        {
            string h100 = p.IsGridItem ? " h-100" : "";

            return $@"
                <article class=""no-underline d-block bg-gray-50 bg-gray-lightest-hover p-a-md pos-rel{h100}"">
                  <div class=""text-center p-b"">
                    <span class=""{p.IconClass} color-p2 color-p2-hover text-huge d-block"" aria-hidden=""true""></span>
                    <a href=""{p.Href}"" class=""h4 m-t-0 m-b color-gray-dark link-before text-left no-underline d-block"">{p.Title}</a>
                    <p class=""color-gray-dark text-left"">{p.Content}</p>
                  </div>
                </article>";
        }

        private static string RenderImageVariant(CardProperties p)
        {
            string h100 = p.IsGridItem ? " h-100" : "";
            string flexInner = p.IsGridItem ? " h-100 d-flex flex-column" : "";

            return $@"
                <div class=""card pos-rel{h100}"">
                  <img class=""card-img"" src=""{p.ImageSrc}"" alt=""{p.ImageAlt}"" />
                  <div class=""card-body bg-gray-50 bg-gray-100-hover{flexInner}"">
                    <h3 class=""card-title"">
                      <a href=""{p.Href}"" class=""link-before"">{p.Title}</a>
                    </h3>
                    <p>{p.Content}</p>
                  </div>
                </div>";
        }

        private static string RenderLegacyVariant(CardProperties p)
        {
            string h100 = p.IsGridItem ? " h-100" : "";
            
            bool useHeading = p.LegacyType is LegacyCardType.Default or LegacyCardType.Understated or LegacyCardType.Standout or LegacyCardType.Overstated;
            string headerClass = useHeading ? "card-heading" : "card-header";
            
            string standoutHtml = p.LegacyType == LegacyCardType.Standout ? "<span class=\"triangle\"></span><span class=\"triangle\"></span>\n" : "";
            string cardModifier = p.LegacyType == LegacyCardType.Standout ? "card-standout highlight" : $"card-{p.LegacyType.ToString().ToLowerInvariant()}";

            string optionsHtml = string.IsNullOrWhiteSpace(p.ButtonText) 
                ? string.Empty 
                : $@"<div class=""options""><a href=""{p.Href}"" class=""btn btn-default"">{p.ButtonText}</a></div>";

            return $@"
                <div class=""card {cardModifier}{h100}"">
                  <div class=""{headerClass}"">
                    {standoutHtml}
                    <h3><span class=""{p.IconClass}"" aria-hidden=""true""></span> {p.Title}</h3>
                    {optionsHtml}
                  </div>
                  <div class=""card-body"">
                    {p.Content}
                  </div>
                </div>";
        }
    }
}

####

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
        // --- Existing Validation Tests omitted for brevity, keeping layout/renderer tests ---

        [TestMethod]
        public void Renderer_DefaultVariant_WithGridItem_OutputsFlexClasses()
        {
            // Arrange
            var props = new CardProperties
            {
                Variant = CardVariant.Default,
                Title = "Grid Card",
                IsGridItem = true,
                ButtonText = "Action"
            };

            // Act
            var result = RclCardRenderer.Render(props);

            // Assert
            Assert.IsTrue(result.Contains("<div class=\"card h-100\">"));
            Assert.IsTrue(result.Contains("card-body bg-gray-50 h-100 d-flex flex-column"));
            Assert.IsTrue(result.Contains("<p class=\"mt-auto m-b-0\">"));
        }

        [TestMethod]
        public void Renderer_LegacyVariant_Standout_OutputsTrianglesAndHighlights()
        {
            // Arrange
            var props = new CardProperties
            {
                Variant = CardVariant.Legacy,
                LegacyType = LegacyCardType.Standout,
                Title = "Important Card",
                IconClass = "ca-gov-icon-warning",
                ButtonText = "Review"
            };

            // Act
            var result = RclCardRenderer.Render(props);

            // Assert
            Assert.IsTrue(result.Contains("card card-standout highlight"));
            Assert.IsTrue(result.Contains("card-heading"));
            Assert.IsTrue(result.Contains("<span class=\"triangle\"></span><span class=\"triangle\"></span>"));
            Assert.IsTrue(result.Contains("ca-gov-icon-warning"));
            Assert.IsTrue(result.Contains("<div class=\"options\">"));
        }

        [TestMethod]
        public void Renderer_LegacyVariant_Danger_OutputsHeaderClass()
        {
            // Arrange
            var props = new CardProperties
            {
                Variant = CardVariant.Legacy,
                LegacyType = LegacyCardType.Danger,
                Title = "Error Alert",
                IsGridItem = false
            };

            // Act
            var result = RclCardRenderer.Render(props);

            // Assert
            Assert.IsTrue(result.Contains("card card-danger"));
            Assert.IsTrue(result.Contains("card-header")); // Danger type uses card-header instead of card-heading
            Assert.IsFalse(result.Contains("triangle"));
        }

        [TestMethod]
        public async Task Helper_ProcessAsync_LegacyVariant_StripsTagAndRenders()
        {
            // Arrange
            var context = new TagHelperContext(
                new TagHelperAttributeList(),
                new Dictionary<object, object>(),
                "test-id");

            var childContent = new DefaultTagHelperContent();
            childContent.SetHtmlContent("<p>Legacy content</p>");

            var output = new TagHelperOutput(
                "rcl-card",
                new TagHelperAttributeList(),
                (useCachedResult, encoder) => Task.FromResult<TagHelperContent>(childContent));

            var helper = new CardHelper
            {
                Variant = CardVariant.Legacy,
                LegacyType = LegacyCardType.Success,
                Title = "Success!"
            };

            // Act
            await helper.ProcessAsync(context, output);

            // Assert
            Assert.IsNull(output.TagName); // <rcl-card> should be stripped
            
            var finalHtml = output.Content.GetContent();
            Assert.IsTrue(finalHtml.Contains("card card-success"));
            Assert.IsTrue(finalHtml.Contains("<p>Legacy content</p>"));
        }
    }
}




###

using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Razor.TagHelpers;

namespace WTS.RazorComponentLibrary.Models.RclComponents
{
    public enum ProgressVariant
    {
        Default,
        Bold
    }

    public class ProgressStepData
    {
        public string Heading { get; set; } = string.Empty;
        public string Content { get; set; } = string.Empty;
        public bool IsComplete { get; set; }
    }

    public class ProgressBlockProperties
    {
        public ProgressVariant Variant { get; set; } = ProgressVariant.Default;

        [HtmlAttributeNotBound]
        public List<ProgressStepData> Steps { get; set; } = new List<ProgressStepData>();
    }

    public class ProgressStepProperties
    {
        [Required(AllowEmptyStrings = false, ErrorMessage = "A Heading is required for the progress step.")]
        public string Heading { get; set; } = string.Empty;

        public bool IsComplete { get; set; } = false;
    }
}



###

using Microsoft.AspNetCore.Razor.TagHelpers;
using System.Collections.Generic;
using System.Threading.Tasks;
using System.ComponentModel.DataAnnotations;
using WTS.RazorComponentLibrary.Models.RclComponents;
using WTS.RazorComponentLibrary.Renderers;

namespace WTS.RazorLibrary.TagHelpers
{
    // --- 1. Parent Container ---
    [HtmlTargetElement("rcl-progress-block")]
    public class ProgressBlockHelper : ProgressBlockProperties, ITagHelper
    {
        public int Order => 0;
        public void Init(TagHelperContext context) { }

        public async Task ProcessAsync(TagHelperContext context, TagHelperOutput output)
        {
            // Initialize list for children to append their data to
            var steps = new List<ProgressStepData>();
            context.Items["ProgressSteps"] = steps;

            // Execute children so they populate the list
            await output.GetChildContentAsync();

            this.Steps = steps;

            // Strip the <rcl-progress-block> wrapper and defer to Renderer
            output.TagName = null;
            output.Content.SetHtmlContent(RclProgressBlockRenderer.Render(this));
        }
    }

    // --- 2. Child Step ---
    [HtmlTargetElement("rcl-progress-step", ParentTag = "rcl-progress-block")]
    public class ProgressStepHelper : ProgressStepProperties, ITagHelper
    {
        public int Order => 0;
        public void Init(TagHelperContext context) { }

        public async Task ProcessAsync(TagHelperContext context, TagHelperOutput output)
        {
            var childContent = await output.GetChildContentAsync();
            var content = childContent.GetContent().Trim();

            var validationContext = new ValidationContext(this);
            Validator.ValidateObject(this, validationContext, validateAllProperties: true);

            // Feed this step's data back up to the parent container
            if (context.Items.TryGetValue("ProgressSteps", out var listObj) && listObj is List<ProgressStepData> steps)
            {
                steps.Add(new ProgressStepData 
                { 
                    Heading = this.Heading, 
                    Content = content,
                    IsComplete = this.IsComplete
                });
            }

            // Suppress child output completely (the parent block will render the HTML array)
            output.SuppressOutput();
        }
    }
}

##

using System;
using System.Text;
using WTS.RazorComponentLibrary.Models.RclComponents;

namespace WTS.RazorComponentLibrary.Renderers
{
    public static class RclProgressBlockRenderer
    {
        public static string Render(ProgressBlockProperties p)
        {
            if (p.Steps == null || p.Steps.Count == 0) return string.Empty;

            var sb = new StringBuilder();
            sb.AppendLine("<div class=\"row\">");

            // Calculate dynamic Bootstrap column width (e.g., 4 steps = col-sm-3, 3 steps = col-sm-4)
            // Caps at 12 to prevent divide-by-zero on empty lists
            int colWidth = Math.Max(1, 12 / p.Steps.Count);

            for (int i = 0; i < p.Steps.Count; i++)
            {
                var step = p.Steps[i];
                
                bool isFirst = i == 0;
                bool isLast = i == p.Steps.Count - 1;
                
                // Track adjacent completion to determine connecting line colors
                bool prevComplete = i > 0 && p.Steps[i - 1].IsComplete;
                bool nextComplete = i < p.Steps.Count - 1 && p.Steps[i + 1].IsComplete;

                string beforeClass = "";
                string afterClass = "";
                string innerClass = "";
                string pMargin = p.Variant == ProgressVariant.Bold ? "m-b-0" : "mb-4";
                string dotLineModifier = p.Variant == ProgressVariant.Bold ? " progress-bold" : "";

                if (p.Variant == ProgressVariant.Bold)
                {
                    // Bold Variant Line Styling
                    beforeClass = isFirst ? "brd-transparent-before" 
                                : (step.IsComplete && prevComplete ? "brd-primary-light-before" : "brd-gray-light-before");
                    
                    afterClass = isLast ? "brd-transparent-after" 
                               : (step.IsComplete && nextComplete ? "brd-primary-light-after" : "brd-gray-light-after");

                    // Bold Variant Inner Dot
                    innerClass = step.IsComplete 
                        ? "bg-primary-light bg-primary-before brd-primary-light" 
                        : "bg-gray-light brd-gray-light";
                }
                else
                {
                    // Default Variant Line Styling (always gray unless edge)
                    beforeClass = isFirst ? "brd-transparent-before" : "brd-gray-light-before";
                    afterClass = isLast ? "brd-transparent-after" : "brd-gray-light-after";

                    // Default Variant Inner Dot
                    innerClass = step.IsComplete 
                        ? "bg-white bg-primary-before brd-gray-light" 
                        : "bg-white brd-gray-light";
                }

                sb.AppendLine($@"
                    <div class=""col-sm-{colWidth} text-sm-center d-flex d-sm-block"">
                        <div class=""dot-line{dotLineModifier} {beforeClass} {afterClass}"">
                            <span class=""dot-line-inner {innerClass}""></span>
                        </div>
                        <div class=""dot-text"">
                            <h3 class=""h5 m-b"">{step.Heading}</h3>
                            <p class=""{pMargin}"">{step.Content}</p>
                        </div>
                    </div>");
            }

            sb.AppendLine("</div>");
            return sb.ToString();
        }
    }
}


####

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
    public class ProgressBlockTests
    {
        [TestMethod]
        public void Renderer_DefaultVariant_OutputsCorrectClasses()
        {
            // Arrange
            var props = new ProgressBlockProperties
            {
                Variant = ProgressVariant.Default,
                Steps = new List<ProgressStepData>
                {
                    new ProgressStepData { Heading = "Step 1", Content = "C1", IsComplete = true },
                    new ProgressStepData { Heading = "Step 2", Content = "C2", IsComplete = false }
                }
            };

            // Act
            var result = RclProgressBlockRenderer.Render(props);

            // Assert
            Assert.IsTrue(result.Contains("col-sm-6")); // 12 / 2 steps calculates correctly
            Assert.IsTrue(result.Contains("brd-transparent-before")); // Step 1 edge
            Assert.IsTrue(result.Contains("bg-white bg-primary-before brd-gray-light")); // Step 1 inner (complete)
            Assert.IsTrue(result.Contains("bg-white brd-gray-light")); // Step 2 inner (incomplete)
            Assert.IsTrue(result.Contains("brd-transparent-after")); // Step 2 edge
        }

        [TestMethod]
        public void Renderer_BoldVariant_OutputsDynamicLineColors()
        {
            // Arrange
            var props = new ProgressBlockProperties
            {
                Variant = ProgressVariant.Bold,
                Steps = new List<ProgressStepData>
                {
                    new ProgressStepData { Heading = "S1", IsComplete = true },
                    new ProgressStepData { Heading = "S2", IsComplete = true },
                    new ProgressStepData { Heading = "S3", IsComplete = false }
                }
            };

            // Act
            var result = RclProgressBlockRenderer.Render(props);

            // Assert
            Assert.IsTrue(result.Contains("col-sm-4")); // 12 / 3 steps
            
            // Step 1 to Step 2 connection (both complete) should be primary colored
            Assert.IsTrue(result.Contains("brd-primary-light-after"));
            Assert.IsTrue(result.Contains("brd-primary-light-before"));

            // Step 2 to Step 3 connection (S3 is incomplete) should fall back to gray colored
            Assert.IsTrue(result.Contains("brd-gray-light-after"));
            Assert.IsTrue(result.Contains("brd-gray-light-before"));
            
            // Step 3 inner dot should be gray because it's incomplete
            Assert.IsTrue(result.Contains("bg-gray-light brd-gray-light")); 
        }

        [TestMethod]
        public async Task Helper_ProcessAsync_GeneratesCorrectStructure()
        {
            // Arrange
            var blockContext = new TagHelperContext(new TagHelperAttributeList(), new Dictionary<object, object>(), "test");
            var blockOutput = new TagHelperOutput("rcl-progress-block", new TagHelperAttributeList(), (u, e) => Task.FromResult<TagHelperContent>(new DefaultTagHelperContent()));
            var blockHelper = new ProgressBlockHelper();

            // Simulate the children filling the context
            blockContext.Items["ProgressSteps"] = new List<ProgressStepData>
            {
                new ProgressStepData { Heading = "Child Step", Content = "Text", IsComplete = true }
            };

            // Act
            await blockHelper.ProcessAsync(blockContext, blockOutput);

            // Assert
            Assert.IsNull(blockOutput.TagName);
            var html = blockOutput.Content.GetContent();
            Assert.IsTrue(html.Contains("Child Step"));
            Assert.IsTrue(html.Contains("Text"));
            Assert.IsTrue(html.Contains("col-sm-12"));
        }
    }
}

@model MyAgency.Models.ApplicationViewModel

<rcl-progress-block variant="Bold">
    
    <rcl-progress-step heading="Step 1: Apply" is-complete="true">
        Application Submitted.
    </rcl-progress-step>
    
    <rcl-progress-step heading="Step 2: Review" is-complete="true">
        Under Internal Review.
    </rcl-progress-step>
    
    <rcl-progress-step heading="Step 3: Interview" is-complete="@(Model.Status == "Interview")">
        Pending Interview Scheduling.
    </rcl-progress-step>
    
    <rcl-progress-step heading="Step 4: Decision" is-complete="false">
        Final Decision Provided.
    </rcl-progress-step>

</rcl-progress-block>



####


using System;
using System.Collections.Generic;
using System.Text.RegularExpressions;

namespace WTS.RazorComponentLibrary.MarkdownRclParser
{
    public static partial class RclAttributeParser
    {
        // Matches: Key="Value" or key="value"
        [GeneratedRegex(@"([a-zA-Z0-9_\-]+)\s*=\s*""([^""]*)""")]
        private static partial Regex AttributeRegex();

        public static Dictionary<string, string> Parse(string attributeString)
        {
            var attributes = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
            
            if (string.IsNullOrWhiteSpace(attributeString)) 
                return attributes;

            foreach (Match match in AttributeRegex().Matches(attributeString))
            {
                attributes[match.Groups[1].Value] = match.Groups[2].Value;
            }
            
            return attributes;
        }
    }
}


####


using System;
using System.Collections.Generic;
using System.Reflection;

namespace WTS.RazorComponentLibrary.MarkdownRclParser
{
    public static class ComponentMapper
    {
        public static T Map<T>(Dictionary<string, string> attrs, string content) where T : new()
        {
            var props = new T();

            // 1. Set the Inner Content
            var contentProp = typeof(T).GetProperty("Content", BindingFlags.Public | BindingFlags.Instance | BindingFlags.IgnoreCase);
            if (contentProp != null && contentProp.CanWrite)
            {
                contentProp.SetValue(props, content);
            }

            // 2. Auto-Map Attributes to Properties
            foreach (var prop in typeof(T).GetProperties(BindingFlags.Public | BindingFlags.Instance))
            {
                if (attrs.TryGetValue(prop.Name, out string stringValue))
                {
                    if (prop.PropertyType == typeof(string))
                    {
                        prop.SetValue(props, stringValue);
                    }
                    else if (prop.PropertyType == typeof(bool) && bool.TryParse(stringValue, out bool bVal))
                    {
                        prop.SetValue(props, bVal);
                    }
                    else if (prop.PropertyType == typeof(int) && int.TryParse(stringValue, out int iVal))
                    {
                        prop.SetValue(props, iVal);
                    }
                    else if (prop.PropertyType == typeof(double) && double.TryParse(stringValue, out double dVal))
                    {
                        prop.SetValue(props, dVal);
                    }
                    else if (prop.PropertyType == typeof(DateTime) && DateTime.TryParse(stringValue, out DateTime dateVal))
                    {
                        prop.SetValue(props, dateVal);
                    }
                    else if (prop.PropertyType.IsEnum)
                    {
                        if (Enum.TryParse(prop.PropertyType, stringValue, true, out var enumVal))
                        {
                            prop.SetValue(props, enumVal);
                        }
                    }
                }
            }

            return props;
        }
    }
}



####

using System;
using System.Collections.Generic;
using System.Text.RegularExpressions;
using Markdown; // Assuming Markdig
using WTS.RazorComponentLibrary.Models.RclComponents;
using WTS.RazorComponentLibrary.Renderers;

namespace WTS.RazorComponentLibrary.MarkdownRclParser
{
    public partial class MarkdownRcParser
    {
        private readonly MarkdownPipeline _pipeline;
        
        // Maps the Markdown TagName to a generic function that handles the Mapping and Rendering
        private readonly Dictionary<string, Func<Dictionary<string, string>, string, string>> _handlers;

        // MATCHES: :::component-name {Key="Value"} \n Content \n :::
        // CRITICAL: Uses (?!:::) to ensure it only grabs INNERMOST blocks first to support nesting
        [GeneratedRegex(@":::([a-zA-Z0-9_\-]+)(?:\s*\{([^}]*)\})?\s*\n((?:(?!:::).)*?)\n:::", RegexOptions.Singleline | RegexOptions.Compiled)]
        private static partial Regex InnermostComponentRegex();

        public MarkdownRcParser(MarkdownPipeline pipeline)
        {
            _pipeline = pipeline;

            _handlers = new Dictionary<string, Func<Dictionary<string, string>, string, string>>(StringComparer.OrdinalIgnoreCase)
            {
                // Layout & Containers
                { "rcl-card", (a, c) => RclCardRenderer.Render(ComponentMapper.Map<CardProperties>(a, c)) },
                { "rcl-accordion", (a, c) => RclAccordionRenderer.Render(ComponentMapper.Map<AccordionProperties>(a, c)) },
                { "rcl-accordion-item", (a, c) => RclAccordionItemRenderer.Render(ComponentMapper.Map<AccordionItemProperties>(a, c)) },
                { "rcl-tabs", (a, c) => RclTabsRenderer.Render(ComponentMapper.Map<TabsProperties>(a, c)) },
                { "rcl-tab", (a, c) => RclTabItemRenderer.Render(ComponentMapper.Map<TabItemProperties>(a, c)) },
                
                // Typography & Elements
                { "rcl-alert", (a, c) => RclAlertRenderer.Render(ComponentMapper.Map<AlertProperties>(a, c)) },
                { "rcl-blockquote", (a, c) => RclBlockquoteRenderer.Render(ComponentMapper.Map<BlockquoteProperties>(a, c)) },
                { "rcl-button", (a, c) => RclButtonRenderer.Render(ComponentMapper.Map<ButtonProperties>(a, c)) },
                { "rcl-table", (a, c) => RclTableRenderer.Render(ComponentMapper.Map<TableProperties>(a, c)) },
                
                // Specialized Components
                { "rcl-executive-profile", (a, c) => RclExecutiveProfileRenderer.Render(ComponentMapper.Map<ExecutiveProfileProperties>(a, c)) },
                { "rcl-featured-banner", (a, c) => RclFeaturedBannerRenderer.Render(ComponentMapper.Map<FeaturedBannerProperties>(a, c)) },
                { "rcl-countdown", (a, c) => RclCountdownRenderer.Render(ComponentMapper.Map<CountdownProperties>(a, c)) },
                { "rcl-modal", (a, c) => RclModalRenderer.Render(ComponentMapper.Map<ModalProperties>(a, c)) },
                { "rcl-csv2bar", (a, c) => RclCsv2BarRenderer.Render(ComponentMapper.Map<Csv2BarProperties>(a, c)) },
                
                // Trackers & Lists
                { "rcl-progress-bar", (a, c) => RclProgressBarRenderer.Render(ComponentMapper.Map<ProgressBarProperties>(a, c)) },
                { "rcl-progress-block", (a, c) => RclProgressBlockRenderer.Render(ComponentMapper.Map<ProgressBlockProperties>(a, c)) },
                { "rcl-progress-step", (a, c) => RclProgressBlockRenderer.RenderStep(ComponentMapper.Map<ProgressStepProperties>(a, c)) }, // Note: You may need a specific static method for rendering isolated steps outside of TagHelpers
                { "rcl-timeline", (a, c) => RclTimelineRenderer.Render(ComponentMapper.Map<TimelineProperties>(a, c)) },
                { "rcl-timeline-item", (a, c) => RclTimelineItemRenderer.Render(ComponentMapper.Map<TimelineItemProperties>(a, c)) },
                { "rcl-step-list", (a, c) => RclStepListRenderer.Render(ComponentMapper.Map<StepListProperties>(a, c)) },
                { "rcl-step-list-item", (a, c) => RclStepListItemRenderer.Render(ComponentMapper.Map<StepListItemProperties>(a, c)) },
                { "rcl-pagination", (a, c) => RclPaginationRenderer.Render(ComponentMapper.Map<PaginationProperties>(a, c)) },
                
                // Grids & Social
                { "rcl-link-grid", (a, c) => RclLinkGridRenderer.Render(ComponentMapper.Map<LinkGridProperties>(a, c)) },
                { "rcl-link-grid-item", (a, c) => RclLinkGridItemRenderer.Render(ComponentMapper.Map<LinkGridItemProperties>(a, c)) },
                { "rcl-social-container", (a, c) => RclSocialContainerRenderer.Render(ComponentMapper.Map<SocialContainerProperties>(a, c)) },
                { "rcl-social-icon", (a, c) => RclSocialIconRenderer.Render(ComponentMapper.Map<SocialIconProperties>(a, c)) },

                // Forms
                { "rcl-input", (a, c) => RclFormInputRenderer.Render(ComponentMapper.Map<FormInputProperties>(a, c)) },
                { "rcl-check", (a, c) => RclFormCheckRenderer.Render(ComponentMapper.Map<FormCheckProperties>(a, c)) },
                { "rcl-select", (a, c) => RclFormSelectRenderer.Render(ComponentMapper.Map<FormSelectProperties>(a, c)) }
            };
        }

        public string Process(string rawMarkdown)
        {
            string result = rawMarkdown;
            var regex = InnermostComponentRegex();

            // Keep looping until no more ::: blocks exist
            while (regex.IsMatch(result))
            {
                result = regex.Replace(result, match =>
                {
                    string tagName = match.Groups[1].Value;
                    string attrString = match.Groups[2].Success ? match.Groups[2].Value : "";
                    
                    // Convert the inner markdown text into HTML before passing it to the component
                    string bodyHtml = Markdown.ToHtml(match.Groups[3].Value.Trim(), _pipeline);

                    if (_handlers.TryGetValue(tagName, out var handlerFunc))
                    {
                        var attrs = RclAttributeParser.Parse(attrString);
                        return handlerFunc(attrs, bodyHtml);
                    }

                    // If a developer typed :::unknown-component, strip it but keep the text to prevent infinite loops
                    return $"\n{bodyHtml}"; 
                });
            }

            // Once all RCL blocks are converted to HTML, convert any remaining standard Markdown
            return Markdown.ToHtml(result, _pipeline); 
        }
    }
}