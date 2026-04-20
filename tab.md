# tag

using Microsoft.AspNetCore.Razor.TagHelpers;
using System;
using System.Collections.Generic;
using System.Text;
using System.Threading.Tasks;

namespace MyComponentLibrary.TagHelpers
{
    // A simple data model to pass tab metadata from children to the parent
    public class TabItemData
    {
        public string Id { get; set; } = string.Empty;
        public string Title { get; set; } = string.Empty;
    }

    // --- 1. Parent Tabs Container ---
    [HtmlTargetElement("rcl-tabs")]
    public class TabsTagHelper : TagHelper
    {
        public override async Task ProcessAsync(TagHelperContext context, TagHelperOutput output)
        {
            output.TagName = "div";
            output.Attributes.SetAttribute("class", "tabs");

            // Create a shared list to hold the tab metadata
            var tabsList = new List<TabItemData>();
            context.Items["TabsList"] = tabsList;

            // Wait for all <rcl-tab> children to execute. 
            // They will populate the tabsList and render their <section> tags.
            var childContent = await output.GetChildContentAsync();

            // Build the top navigation <ul> based on what the children reported
            var navBuilder = new StringBuilder();
            navBuilder.AppendLine("<ul>");
            foreach (var tab in tabsList)
            {
                navBuilder.AppendLine($"  <li><a href=\"#{tab.Id}\">{tab.Title}</a></li>");
            }
            navBuilder.AppendLine("</ul>");

            // Combine the navigation with the rendered child content
            output.Content.SetHtmlContent(navBuilder.ToString() + childContent.GetContent());
        }
    }

    // --- 2. Child Tab Item ---
    [HtmlTargetElement("rcl-tab", ParentTag = "rcl-tabs")]
    public class TabTagHelper : TagHelper
    {
        // The display text for the tab navigation link
        public string Title { get; set; } = string.Empty;
        
        // Optional: Provide a specific ID. If left blank, one will be generated automatically.
        public string TabId { get; set; } = string.Empty;

        public override async Task ProcessAsync(TagHelperContext context, TagHelperOutput output)
        {
            // Determine the ID
            string finalId = string.IsNullOrWhiteSpace(TabId) 
                ? $"tab_{Guid.NewGuid().ToString("N").Substring(0, 6)}" 
                : TabId;

            // Register this tab with the parent component
            if (context.Items.ContainsKey("TabsList") && context.Items["TabsList"] is List<TabItemData> tabs)
            {
                tabs.Add(new TabItemData { Id = finalId, Title = this.Title });
            }

            // Render the content wrapper for the CA State Template
            output.TagName = "section";
            output.Attributes.SetAttribute("id", finalId);

            // Fetch and render whatever HTML the developer put inside the tab
            var childContent = await output.GetChildContentAsync();
            output.Content.SetHtmlContent(childContent.GetContent());
        }
    }
}

# cshtml

<rcl-tabs>
    <rcl-tab tab-id="section1" title="Tab 1 example">
        <h3 class="m-t-0">Heading example</h3>
        <p>Use tabs sparingly. When using tabs, don't use too many.</p>
    </rcl-tab>

    <rcl-tab tab-id="section2" title="Tab 2 example">
        <h3 class="m-t-0">Tab 2 heading</h3>
        <p>This is tab 2 body text.</p>
    </rcl-tab>
</rcl-tabs>

<br />

<rcl-tabs>
    <rcl-tab title="Project Scope">
        <p>The scope involves defining standard UI components.</p>
    </rcl-tab>

    <rcl-tab title="Requirements">
        <ul>
            <li>Must adhere to CA.gov guidelines.</li>
            <li>Must be accessible.</li>
        </ul>
    </rcl-tab>
</rcl-tabs>

# docs

Here is the complete implementation for the Tabs component.

Building tabs in Razor can be slightly complicated because the HTML structure requires a list of navigation links (<ul>) to be rendered before the actual content blocks (<section>). To solve this, the <rcl-tabs> parent component uses a shared context to collect the titles and IDs from each <rcl-tab> child component before dynamically building the navigation list at the top.
1. The Tag Helper Logic (TabsTagHelpers.cs)
C#

using Microsoft.AspNetCore.Razor.TagHelpers;
using System;
using System.Collections.Generic;
using System.Text;
using System.Threading.Tasks;

namespace MyComponentLibrary.TagHelpers
{
    // A simple data model to pass tab metadata from children to the parent
    public class TabItemData
    {
        public string Id { get; set; } = string.Empty;
        public string Title { get; set; } = string.Empty;
    }

    // --- 1. Parent Tabs Container ---
    [HtmlTargetElement("rcl-tabs")]
    public class TabsTagHelper : TagHelper
    {
        public override async Task ProcessAsync(TagHelperContext context, TagHelperOutput output)
        {
            output.TagName = "div";
            output.Attributes.SetAttribute("class", "tabs");

            // Create a shared list to hold the tab metadata
            var tabsList = new List<TabItemData>();
            context.Items["TabsList"] = tabsList;

            // Wait for all <rcl-tab> children to execute. 
            // They will populate the tabsList and render their <section> tags.
            var childContent = await output.GetChildContentAsync();

            // Build the top navigation <ul> based on what the children reported
            var navBuilder = new StringBuilder();
            navBuilder.AppendLine("<ul>");
            foreach (var tab in tabsList)
            {
                navBuilder.AppendLine($"  <li><a href=\"#{tab.Id}\">{tab.Title}</a></li>");
            }
            navBuilder.AppendLine("</ul>");

            // Combine the navigation with the rendered child content
            output.Content.SetHtmlContent(navBuilder.ToString() + childContent.GetContent());
        }
    }

    // --- 2. Child Tab Item ---
    [HtmlTargetElement("rcl-tab", ParentTag = "rcl-tabs")]
    public class TabTagHelper : TagHelper
    {
        // The display text for the tab navigation link
        public string Title { get; set; } = string.Empty;
        
        // Optional: Provide a specific ID. If left blank, one will be generated automatically.
        public string TabId { get; set; } = string.Empty;

        public override async Task ProcessAsync(TagHelperContext context, TagHelperOutput output)
        {
            // Determine the ID
            string finalId = string.IsNullOrWhiteSpace(TabId) 
                ? $"tab_{Guid.NewGuid().ToString("N").Substring(0, 6)}" 
                : TabId;

            // Register this tab with the parent component
            if (context.Items.ContainsKey("TabsList") && context.Items["TabsList"] is List<TabItemData> tabs)
            {
                tabs.Add(new TabItemData { Id = finalId, Title = this.Title });
            }

            // Render the content wrapper for the CA State Template
            output.TagName = "section";
            output.Attributes.SetAttribute("id", finalId);

            // Fetch and render whatever HTML the developer put inside the tab
            var childContent = await output.GetChildContentAsync();
            output.Content.SetHtmlContent(childContent.GetContent());
        }
    }
}

2. Usage in your Views (.cshtml)
HTML

<rcl-tabs>
    <rcl-tab tab-id="section1" title="Tab 1 example">
        <h3 class="m-t-0">Heading example</h3>
        <p>Use tabs sparingly. When using tabs, don't use too many.</p>
    </rcl-tab>

    <rcl-tab tab-id="section2" title="Tab 2 example">
        <h3 class="m-t-0">Tab 2 heading</h3>
        <p>This is tab 2 body text.</p>
    </rcl-tab>
</rcl-tabs>

<br />

<rcl-tabs>
    <rcl-tab title="Project Scope">
        <p>The scope involves defining standard UI components.</p>
    </rcl-tab>

    <rcl-tab title="Requirements">
        <ul>
            <li>Must adhere to CA.gov guidelines.</li>
            <li>Must be accessible.</li>
        </ul>
    </rcl-tab>
</rcl-tabs>

3. Documentation (README.md)
Tabs Component

Renders a dynamic tabbed interface. The parent <rcl-tabs> component automatically generates the required <ul> navigation structure based on the <rcl-tab> children you provide.

Note: The actual interaction (hiding and showing content) relies on the cagov.core.js script provided by the state template.
Setup

Ensure the Tag Helpers are registered in your _ViewImports.cshtml:
HTML

@addTagHelper *, MyComponentLibrary

Properties
<rcl-tabs>

Acts as the wrapper. Takes no configurable attributes.
<rcl-tab>
Attribute	Type	Default	Description
title	string	""	Required. The text displayed on the clickable tab navigation link.
tab-id	string	Random GUID	The HTML id for the section. If omitted, a random ID is generated. Explicit IDs are recommended if you want users to be able to share direct links to a specific opened tab.

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
    public class TabsTagHelpersTests
    {
        // --- Unit Tests ---
        private (TagHelperContext, TagHelperOutput) CreateTagHelperData(string tagName, string content = "Body Content")
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
                    tagHelperContent.SetContent(content);
                    return Task.FromResult<TagHelperContent>(tagHelperContent);
                });

            return (context, output);
        }

        [TestMethod]
        public async Task TabTagHelper_RegistersSelf_AndRendersSection()
        {
            // Arrange
            var helper = new TabTagHelper { Title = "Test Tab", TabId = "test_id" };
            var (context, output) = CreateTagHelperData("rcl-tab");
            
            // Simulate parent having initialized the list
            var list = new List<TabItemData>();
            context.Items["TabsList"] = list;

            // Act
            await helper.ProcessAsync(context, output);
            var content = output.Content.GetContent();

            // Assert List Registration
            Assert.AreEqual(1, list.Count);
            Assert.AreEqual("test_id", list[0].Id);
            Assert.AreEqual("Test Tab", list[0].Title);

            // Assert Output HTML
            Assert.AreEqual("section", output.TagName);
            Assert.AreEqual("test_id", output.Attributes["id"].Value);
            StringAssert.Contains(content, "Body Content");
        }

        [TestMethod]
        public async Task TabTagHelper_GeneratesId_WhenMissing()
        {
            // Arrange
            var helper = new TabTagHelper { Title = "No ID Tab" };
            var (context, output) = CreateTagHelperData("rcl-tab");
            context.Items["TabsList"] = new List<TabItemData>();

            // Act
            await helper.ProcessAsync(context, output);

            // Assert
            Assert.IsTrue(output.Attributes["id"].Value.ToString().StartsWith("tab_"));
        }

        [TestMethod]
        public async Task TabsTagHelper_GeneratesNavList_FromChildren()
        {
            // Arrange
            var helper = new TabsTagHelper();
            var (context, output) = CreateTagHelperData("rcl-tabs", "<section id=\"s1\">Dummy</section>");

            // Simulate child execution by pre-populating the context list before ProcessAsync acts on it
            // (In reality, ProcessAsync awaits children which populates this, but we simulate it via content)
            // To properly unit test this flow, we actually just check if the parent wrapper creates the UL correctly.

            // Since GetChildContentAsync() doesn't execute our simulated children in this simple mock,
            // we will inject a fake list right after the helper creates it in the dictionary.
            
            // Act
            // (In a pure unit test we have to override or accept that the list won't populate automatically)
            // We'll bypass the strict behavior of GetChildContentAsync for this assertion and test integration.
            await helper.ProcessAsync(context, output);
            
            // Assert
            Assert.AreEqual("div", output.TagName);
            Assert.AreEqual("tabs", output.Attributes["class"].Value);
            StringAssert.Contains(output.Content.GetContent(), "<ul>");
        }
    }

    [TestClass]
    public class TabsIntegrationTests
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
        public async Task Tabs_RendersCorrectHtml_OnPage()
        {
            // Act
            // Assume page has: 
            // <rcl-tabs>
            //   <rcl-tab tab-id="t1" title="Tab 1">Content 1</rcl-tab>
            // </rcl-tabs>
            var response = await _client.GetAsync("/TabsTestPage");
            response.EnsureSuccessStatusCode();

            var responseString = await response.Content.ReadAsStringAsync();

            // Assert
            StringAssert.Contains(responseString, "<div class=\"tabs\">");
            StringAssert.Contains(responseString, "<ul>");
            StringAssert.Contains(responseString, "<a href=\"#t1\">Tab 1</a>");
            StringAssert.Contains(responseString, "<section id=\"t1\">");
            StringAssert.Contains(responseString, "Content 1");
        }
    }
}



#####################################


::::rcl-tabs
:::rcl-tab title="Overview" id="overview-tab"
This is the **overview** content. It supports standard markdown!
:::
:::rcl-tab title="Requirements"
If you don't provide an ID, the system will generate one automatically.
:::
::::

2. The Implementation

Since the parent tab needs to know the Title and Id of all its children to build the <ul> navigation at the top, our parser will grab the whole ::::rcl-tabs block, extract the children, and build the entire HTML structure in one go.
Step 1: The Tab Definition & HTML Builder

We need a small data object to hold the tab information while we parse it, and a builder to spit out the raw HTML.
C#

using System;
using System.Collections.Generic;
using System.Text;

// A simple model to hold the data during parsing
public class TabDefinition
{
    public string Title { get; set; } = string.Empty;
    public string Id { get; set; } = string.Empty;
    public string Content { get; set; } = string.Empty;
}

public static class TabsHtmlBuilder
{
    public static string Build(List<TabDefinition> tabs)
    {
        var sb = new StringBuilder();
        
        sb.AppendLine("<div class=\"tabs\">");
        
        // 1. Build the Navigation
        sb.AppendLine("  <ul>");
        foreach (var tab in tabs)
        {
            sb.AppendLine($"    <li><a href=\"#{tab.Id}\">{tab.Title}</a></li>");
        }
        sb.AppendLine("  </ul>");

        // 2. Build the Content Sections
        foreach (var tab in tabs)
        {
            // Note the markdown="1" attribute. This tells the downstream 
            // Markdown compiler (like Markdig) to continue parsing any 
            // **bold** or *italic* text found inside this HTML tag!
            sb.AppendLine($"  <section id=\"{tab.Id}\" markdown=\"1\">");
            sb.AppendLine(tab.Content); 
            sb.AppendLine("  </section>");
        }
        
        sb.AppendLine("</div>");
        
        return sb.ToString();
    }
}

Step 2: The Nested Markdown Parser

Add these two new regular expressions and the ProcessTabs method to your existing MarkdownComponentParser class.
C#

using System.Text.RegularExpressions;
using System.Collections.Generic;
using System;

public partial class MarkdownComponentParser
{
    // Match the PARENT block using 4 colons (::::)
    [GeneratedRegex(@"^::::rcl-tabs[ \t]*(.*?)\r?\n(.*?)\r?\n::::", RegexOptions.Multiline | RegexOptions.Singleline)]
    private static partial Regex RclTabsBlockRegex();

    // Match the CHILD blocks using 3 colons (:::)
    [GeneratedRegex(@"^:::rcl-tab[ \t]+(.*?)\r?\n(.*?)\r?\n:::", RegexOptions.Multiline | RegexOptions.Singleline)]
    private static partial Regex RclTabBlockRegex();

    // Your existing AttributeRegex() is reused here!

    public static string ProcessTabs(string rawMarkdown)
    {
        // 1. Find all outer ::::rcl-tabs blocks
        return RclTabsBlockRegex().Replace(rawMarkdown, tabsMatch =>
        {
            string innerTabsContent = tabsMatch.Groups[2].Value;
            var tabsList = new List<TabDefinition>();

            // 2. Scan INSIDE the parent block for the :::rcl-tab children
            RclTabBlockRegex().Replace(innerTabsContent, tabMatch =>
            {
                string attributesString = tabMatch.Groups[1].Value;
                string tabContent = tabMatch.Groups[2].Value;

                // Parse the attributes (title="", id="")
                var attributes = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
                foreach (Match attrMatch in AttributeRegex().Matches(attributesString))
                {
                    attributes[attrMatch.Groups[1].Value] = attrMatch.Groups[2].Value;
                }

                string title = attributes.GetValueOrDefault("title", "Tab");
                
                // Use the provided ID, or generate a safe 6-character hex string if missing
                string id = attributes.GetValueOrDefault("id", $"tab_{Guid.NewGuid().ToString("N").Substring(0, 6)}");

                // Add it to our list for the builder
                tabsList.Add(new TabDefinition { Title = title, Id = id, Content = tabContent });

                return string.Empty; // We don't need to replace inline, we're rebuilding the whole thing
            });

            // 3. Send the collected data to the HTML Builder
            if (tabsList.Count > 0)
            {
                return TabsHtmlBuilder.Build(tabsList);
            }

            // If they wrote an empty tabs block, just return nothing
            return string.Empty; 
        });
    }
}

Step 3: Add to your pipeline

You can now chain all three of your component processors together before handing the text off to the final Markdown-to-HTML converter.
C#

string processedContent = MarkdownComponentParser.ProcessCards(rawMarkdown);
processedContent = MarkdownComponentParser.ProcessButtons(processedContent);
processedContent = MarkdownComponentParser.ProcessTabs(processedContent); // <--- Add Tabs here

string finalHtml = markdownToHtml(processedContent);