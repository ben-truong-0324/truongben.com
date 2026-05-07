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