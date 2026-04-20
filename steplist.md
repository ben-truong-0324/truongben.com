# tag

using Microsoft.AspNetCore.Razor.TagHelpers;
using System.Threading.Tasks;

namespace MyComponentLibrary.TagHelpers
{
    // --- 1. Parent Container ---
    [HtmlTargetElement("rcl-step-list")]
    public class StepListTagHelper : TagHelper
    {
        public override void Process(TagHelperContext context, TagHelperOutput output)
        {
            output.TagName = "ol";
            output.Attributes.SetAttribute("class", "cagov-step-list");
        }
    }

    // --- 2. Child Item ---
    [HtmlTargetElement("rcl-step-list-item", ParentTag = "rcl-step-list")]
    public class StepListItemTagHelper : TagHelper
    {
        // The main text for the step
        public string Heading { get; set; } = string.Empty;

        public override async Task ProcessAsync(TagHelperContext context, TagHelperOutput output)
        {
            output.TagName = "li";

            // Capture the detailed content provided inside the tag
            var childContent = await output.GetChildContentAsync();
            var content = childContent.GetContent();

            // Build the specific structure required by the CA State Template
            output.Content.SetHtmlContent($@"
                {Heading}
                <br />
                <span class=""cagov-step-list-content"">
                    {content}
                </span>
            ");
        }
    }
}

# cshtml

<rcl-step-list>
    <rcl-step-list-item heading="Step one of your list">
        Riveting text to explain the step.
    </rcl-step-list-item>
    
    <rcl-step-list-item heading="Step two of your list">
        Everyone is going to love the simple, visual way you laid out these steps.
        <br /><br />
        Normal list inside the step list
        <ul>
            <li>Item 1</li>
            <li>Item 2</li>
        </ul>
    </rcl-step-list-item>
    
    <rcl-step-list-item heading="Step three of your list">
        This process has never seemed easier.
    </rcl-step-list-item>
</rcl-step-list>

# docs

Step List Component

Renders a stylized, ordered sequence of steps according to the state template visual design.
Setup

Ensure the Tag Helpers are registered in your _ViewImports.cshtml:
HTML

@addTagHelper *, MyComponentLibrary

Properties
<rcl-step-list>

The parent container. Renders an <ol> with the cagov-step-list class. Takes no custom attributes.
<rcl-step-list-item>

The individual step. Renders an <li> element and wraps its inner content in the required formatting spans.
Attribute	Type	Default	Description
heading	string	""	The primary instruction or title for the step. Appears above the detailed body content.

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
    public class StepListTagHelpersTests
    {
        // --- Unit Tests ---
        private (TagHelperContext, TagHelperOutput) CreateTagHelperData(string tagName, string content = "Detailed step description.")
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
        public void StepList_RendersOrderedListWithCorrectClass()
        {
            // Arrange
            var helper = new StepListTagHelper();
            var (context, output) = CreateTagHelperData("rcl-step-list");

            // Act
            helper.Process(context, output);

            // Assert
            Assert.AreEqual("ol", output.TagName);
            Assert.AreEqual("cagov-step-list", output.Attributes["class"].Value);
        }

        [TestMethod]
        public async Task StepListItem_RendersListElementAndSpanFormatting()
        {
            // Arrange
            var helper = new StepListItemTagHelper { Heading = "Test Step" };
            var (context, output) = CreateTagHelperData("rcl-step-list-item", "Inner Details");

            // Act
            await helper.ProcessAsync(context, output);
            var content = output.Content.GetContent();

            // Assert
            Assert.AreEqual("li", output.TagName);
            
            // Check that heading is placed before the span
            StringAssert.Contains(content, "Test Step\n                <br />");
            
            // Check that inner content is wrapped properly
            StringAssert.Contains(content, "<span class=\"cagov-step-list-content\">");
            StringAssert.Contains(content, "Inner Details");
            StringAssert.Contains(content, "</span>");
        }
    }

    [TestClass]
    public class StepListIntegrationTests
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
        public async Task StepList_RendersCorrectHtml_OnPage()
        {
            // Act
            // Assume page has: 
            // <rcl-step-list><rcl-step-list-item heading="Int Test">Int Content</rcl-step-list-item></rcl-step-list>
            var response = await _client.GetAsync("/StepListTestPage");
            response.EnsureSuccessStatusCode();

            var responseString = await response.Content.ReadAsStringAsync();

            // Assert
            StringAssert.Contains(responseString, "<ol class=\"cagov-step-list\">");
            StringAssert.Contains(responseString, "Int Test");
            StringAssert.Contains(responseString, "<br />");
            StringAssert.Contains(responseString, "<span class=\"cagov-step-list-content\">");
            StringAssert.Contains(responseString, "Int Content");
        }
    }
}




###################################


::::rcl-steplist
:::rcl-step heading="Step 1: Check your eligibility"
Before applying, ensure you meet all the requirements outlined in our eligibility guidelines.
:::
:::rcl-step heading="Step 2: Gather your documents"
You will need your **W-2**, **Proof of Identity**, and **Application Form**.
:::
::::

2. The Implementation

We need a quick data object to hold the steps, the HTML builder to generate the specific State Template markup, and the regex parser.
Step 1: The Step List Definition & HTML Builder

Just like the tag helper, this will output the <ol> and <li> elements, along with the specific cagov-step-list-content span.
C#

using System.Collections.Generic;
using System.Text;

// A simple model to hold the data during parsing
public class StepDefinition
{
    public string Heading { get; set; } = string.Empty;
    public string Content { get; set; } = string.Empty;
}

public static class StepListHtmlBuilder
{
    public static string Build(List<StepDefinition> steps)
    {
        var sb = new StringBuilder();
        
        sb.AppendLine("<ol class=\"cagov-step-list\">");
        
        foreach (var step in steps)
        {
            // The markdown="1" attribute allows the inner text to render bolding/links!
            sb.AppendLine("  <li markdown=\"1\">");
            sb.AppendLine($"    {step.Heading}");
            sb.AppendLine("    <br />");
            sb.AppendLine("    <span class=\"cagov-step-list-content\" markdown=\"1\">");
            sb.AppendLine($"      {step.Content}");
            sb.AppendLine("    </span>");
            sb.AppendLine("  </li>");
        }
        
        sb.AppendLine("</ol>");
        
        return sb.ToString();
    }
}

Step 2: The Nested Regex Parser

Add these to your MarkdownComponentParser class. This works exactly like your Tabs parser: it grabs the parent block, extracts the children, and builds the HTML in one pass.
C#

using System.Text.RegularExpressions;
using System.Collections.Generic;
using System;

public partial class MarkdownComponentParser
{
    // Match the PARENT block using 4 colons (::::)
    [GeneratedRegex(@"^::::rcl-steplist[ \t]*(.*?)\r?\n(.*?)\r?\n::::", RegexOptions.Multiline | RegexOptions.Singleline)]
    private static partial Regex RclStepListBlockRegex();

    // Match the CHILD blocks using 3 colons (:::)
    [GeneratedRegex(@"^:::rcl-step[ \t]+(.*?)\r?\n(.*?)\r?\n:::", RegexOptions.Multiline | RegexOptions.Singleline)]
    private static partial Regex RclStepBlockRegex();

    // Your existing AttributeRegex() is reused here again!

    public static string ProcessStepLists(string rawMarkdown)
    {
        // 1. Find all outer ::::rcl-steplist blocks
        return RclStepListBlockRegex().Replace(rawMarkdown, listMatch =>
        {
            string innerListContent = listMatch.Groups[2].Value;
            var stepsList = new List<StepDefinition>();

            // 2. Scan INSIDE the parent block for the :::rcl-step children
            RclStepBlockRegex().Replace(innerListContent, stepMatch =>
            {
                string attributesString = stepMatch.Groups[1].Value;
                string stepContent = stepMatch.Groups[2].Value;

                // Parse the attributes
                var attributes = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
                foreach (Match attrMatch in AttributeRegex().Matches(attributesString))
                {
                    attributes[attrMatch.Groups[1].Value] = attrMatch.Groups[2].Value;
                }

                // Extract the heading
                string heading = attributes.GetValueOrDefault("heading", "Next Step");

                // Add to our list
                stepsList.Add(new StepDefinition { Heading = heading, Content = stepContent });

                return string.Empty; 
            });

            // 3. Send the collected data to the HTML Builder
            if (stepsList.Count > 0)
            {
                return StepListHtmlBuilder.Build(stepsList);
            }

            // Return empty string if the block was blank
            return string.Empty; 
        });
    }
}

Step 3: Wire it into the Pipeline

Add the new processor to your Markdown rendering chain.
C#

string processedContent = MarkdownComponentParser.ProcessCards(rawMarkdown);
processedContent = MarkdownComponentParser.ProcessButtons(processedContent);
processedContent = MarkdownComponentParser.ProcessTabs(processedContent);
processedContent = MarkdownComponentParser.ProcessBlockquotes(processedContent);
processedContent = MarkdownComponentParser.ProcessModals(processedContent);
processedContent = MarkdownComponentParser.ProcessCountdownTimers(processedContent);
processedContent = MarkdownComponentParser.ProcessStepLists(processedContent); // <--- Add StepLists here

string finalHtml = markdownToHtml(processedContent);

By adding that markdown="1" directly into the StepListHtmlBuilder, you ensure that when the final HTML hits your Markdown converter, it won't ignore standard Markdown lists or bold text tucked inside that .cagov-step-list-content span!