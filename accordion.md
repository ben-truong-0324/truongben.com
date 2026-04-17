### AccordionTagHelpers.cs

using Microsoft.AspNetCore.Razor.TagHelpers;
using System.Threading.Tasks;

namespace MyComponentLibrary.TagHelpers
{
    public enum AccordionVariant
    {
        Default,
        List,
        SideNav
    }

    // Parent Container Tag Helper
    [HtmlTargetElement("rcl-accordion")]
    public class AccordionTagHelper : TagHelper
    {
        public AccordionVariant Variant { get; set; } = AccordionVariant.Default;

        public override void Process(TagHelperContext context, TagHelperOutput output)
        {
            // Share the selected variant with the child items
            context.Items["AccordionVariant"] = Variant;

            if (Variant == AccordionVariant.List)
            {
                output.TagName = "ol";
                output.Attributes.SetAttribute("data-aria-accordion", "");
                output.Attributes.SetAttribute("data-multi", "");
                output.Attributes.SetAttribute("data-transition", "");
                output.Attributes.SetAttribute("data-default", "none");
            }
            else
            {
                // The standard cagov-accordion and sidenav variants don't have a universal 
                // parent wrapper in your provided HTML, so we strip the <rcl-accordion> tag.
                output.TagName = null; 
            }
        }
    }

    // Child Item Tag Helper
    [HtmlTargetElement("rcl-accordion-item", ParentTag = "rcl-accordion")]
    public class AccordionItemTagHelper : TagHelper
    {
        public string Heading { get; set; } = string.Empty;
        
        // Primarily used for the SideNav variant
        public bool IsOpen { get; set; } 

        public override async Task ProcessAsync(TagHelperContext context, TagHelperOutput output)
        {
            var variant = context.Items.ContainsKey("AccordionVariant")
                ? (AccordionVariant)context.Items["AccordionVariant"]
                : AccordionVariant.Default;

            // Grab whatever arbitrary HTML the developer puts inside the item
            var childContent = await output.GetChildContentAsync();
            var content = childContent.GetContent();

            if (variant == AccordionVariant.List)
            {
                output.TagName = "li";
                output.Content.SetHtmlContent($@"
                    <h3 data-aria-accordion-heading>{Heading}</h3>
                    <div data-aria-accordion-panel>
                        {content}
                    </div>");
            }
            else if (variant == AccordionVariant.SideNav)
            {
                output.TagName = "cagov-accordion";
                output.Attributes.SetAttribute("class", "sidenav");

                var openAttr = IsOpen ? "open" : string.Empty;
                var activeClass = IsOpen ? "class=\"active\"" : string.Empty;

                output.Content.SetHtmlContent($@"
                    <details {openAttr}>
                        <summary {activeClass}>{Heading}</summary>
                        <div class=""accordion-body"">
                            {content}
                        </div>
                    </details>");
            }
            else // Default
            {
                output.TagName = "cagov-accordion";
                output.Content.SetHtmlContent($@"
                    <details>
                        <summary>{Heading}</summary>
                        <div class=""accordion-body"">
                            {content}
                        </div>
                    </details>");
            }
        }
    }
}


####
sample use
<rcl-accordion variant="Default">
    <rcl-accordion-item heading="Add a short, descriptive heading for your topic">
        <p>Once open, the content within the accordion should describe the topic in more detail. It should not repeat the heading.</p>
        <p>This part of the accordion is a great place to link to other resources.</p>
    </rcl-accordion-item>
    
    <rcl-accordion-item heading="This heading tells users what's inside the accordion">
        <p>Once open, the content within the accordion should describe the topic in more detail.</p>
    </rcl-accordion-item>
</rcl-accordion>

<rcl-accordion variant="List">
    <rcl-accordion-item heading="List heading number 1">
        <p>Use this space to offer visitors more detail. You can also link to additional resources.</p>
    </rcl-accordion-item>
    
    <rcl-accordion-item heading="List heading number 2">
        <p>Use this space to offer visitors more detail.</p>
    </rcl-accordion-item>
</rcl-accordion>

<nav aria-labelledby="accordion-side-nav">
    <div class="sr-only" id="accordion-side-nav">Accordion side navigation</div>
    <a class="sidenav landing">Landing page</a>

    <rcl-accordion variant="SideNav">
        <rcl-accordion-item heading="Page 2" is-open="true">
            <ul class="side-subnav">
                <li><a href="javascript:;">Subpage 1</a></li>
                <li><a href="javascript:;">Subpage 2</a></li>
                <li><a href="javascript:;">Subpage 3</a></li>
            </ul>
        </rcl-accordion-item>
    </rcl-accordion>

    <a class="sidenav" href="javascript:;">Page 3</a>
</nav>



### docs

The Accordion component renders collapsible content panels. It uses a parent-child Tag Helper structure (<rcl-accordion> and <rcl-accordion-item>) and supports three distinct visual variants: Default, List, and SideNav.

Ensure the Tag Helpers are registered in your _ViewImports.cshtml file:
@addTagHelper *, RCL

Properties
<rcl-accordion> (Parent)
Attribute	Type	Default	Description
variant	AccordionVariant enum	Default	Determines the markup structure. Valid options are Default, List, and SideNav.
<rcl-accordion-item> (Child)
Attribute	Type	Default	Description
heading	string	""	The text displayed on the clickable summary/header.
is-open	bool	false	If true, the accordion item renders in an expanded state (mainly used in the SideNav variant).


Examples
Default Variant

Renders a standard <cagov-accordion> wrapper for each item.
HTML

<rcl-accordion variant="Default">
    <rcl-accordion-item heading="Topic 1">
        <p>Details about topic 1.</p>
    </rcl-accordion-item>
</rcl-accordion>

List Variant

Wraps the items in an <ol> list with ARIA accordion attributes.
HTML

<rcl-accordion variant="List">
    <rcl-accordion-item heading="List Item 1">
        <p>List item details.</p>
    </rcl-accordion-item>
</rcl-accordion>

SideNav Variant

Renders an accordion specifically formatted for side navigation menus.
HTML

<rcl-accordion variant="SideNav">
    <rcl-accordion-item heading="Section 1" is-open="true">
        <ul class="side-subnav">
            <li><a href="#">Sub-link</a></li>
        </ul>
    </rcl-accordion-item>
</rcl-accordion>



### Tests

using Microsoft.VisualStudio.TestTools.UnitTesting;
using Microsoft.AspNetCore.Razor.TagHelpers;
using MyComponentLibrary.TagHelpers; // Adjust to your actual namespace
using System.Collections.Generic;
using System.Threading.Tasks;

namespace MyComponentLibrary.Tests
{
    [TestClass]
    public class AccordionTagHelpersTests
    {
        // --- Helper to generate dummy TagHelper contexts ---
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
                    tagHelperContent.SetContent("Test Child Content");
                    return Task.FromResult<TagHelperContent>(tagHelperContent);
                });

            return (context, output);
        }

        [TestMethod]
        public void AccordionTagHelper_ListVariant_SetsOrderedListOutput()
        {
            // Arrange
            var helper = new AccordionTagHelper { Variant = AccordionVariant.List };
            var (context, output) = CreateTagHelperData("rcl-accordion");

            // Act
            helper.Process(context, output);

            // Assert
            Assert.AreEqual("ol", output.TagName);
            Assert.IsTrue(output.Attributes.ContainsName("data-aria-accordion"));
            Assert.AreEqual(AccordionVariant.List, context.Items["AccordionVariant"]);
        }

        [TestMethod]
        public void AccordionTagHelper_DefaultVariant_StripsWrapperTag()
        {
            // Arrange
            var helper = new AccordionTagHelper { Variant = AccordionVariant.Default };
            var (context, output) = CreateTagHelperData("rcl-accordion");

            // Act
            helper.Process(context, output);

            // Assert
            Assert.IsNull(output.TagName); // Ensure the parent wrapper is stripped
            Assert.AreEqual(AccordionVariant.Default, context.Items["AccordionVariant"]);
        }

        [TestMethod]
        public async Task AccordionItemTagHelper_DefaultVariant_OutputsCagovAccordion()
        {
            // Arrange
            var helper = new AccordionItemTagHelper { Heading = "Test Heading" };
            var (context, output) = CreateTagHelperData("rcl-accordion-item");
            
            // Simulate the parent passing down the variant context
            context.Items["AccordionVariant"] = AccordionVariant.Default;

            // Act
            await helper.ProcessAsync(context, output);
            var content = output.Content.GetContent();

            // Assert
            Assert.AreEqual("cagov-accordion", output.TagName);
            StringAssert.Contains(content, "<summary>Test Heading</summary>");
            StringAssert.Contains(content, "Test Child Content");
        }

        [TestMethod]
        public async Task AccordionItemTagHelper_ListVariant_OutputsListItem()
        {
            // Arrange
            var helper = new AccordionItemTagHelper { Heading = "List Heading" };
            var (context, output) = CreateTagHelperData("rcl-accordion-item");
            context.Items["AccordionVariant"] = AccordionVariant.List;

            // Act
            await helper.ProcessAsync(context, output);
            var content = output.Content.GetContent();

            // Assert
            Assert.AreEqual("li", output.TagName);
            StringAssert.Contains(content, "<h3 data-aria-accordion-heading>List Heading</h3>");
            StringAssert.Contains(content, "Test Child Content");
        }

        [TestMethod]
        public async Task AccordionItemTagHelper_SideNavVariant_OutputsOpenDetails()
        {
            // Arrange
            var helper = new AccordionItemTagHelper { Heading = "Nav Heading", IsOpen = true };
            var (context, output) = CreateTagHelperData("rcl-accordion-item");
            context.Items["AccordionVariant"] = AccordionVariant.SideNav;

            // Act
            await helper.ProcessAsync(context, output);
            var content = output.Content.GetContent();

            // Assert
            Assert.AreEqual("cagov-accordion", output.TagName);
            Assert.AreEqual("sidenav", output.Attributes["class"].Value);
            StringAssert.Contains(content, "<details open>");
            StringAssert.Contains(content, "<summary class=\"active\">Nav Heading</summary>");
        }
    }
}

