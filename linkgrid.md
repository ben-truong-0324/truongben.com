using Microsoft.AspNetCore.Razor.TagHelpers;
using Microsoft.AspNetCore.Mvc.TagHelpers;
using System.Text.Encodings.Web;
using System.Threading.Tasks;

namespace WebTemplateLibrary.TagHelpers;

// Generates: <div class="row">...</div>
[HtmlTargetElement("link-grid")]
public class LinkGridTagHelper : TagHelper
{
    public override void Process(TagHelperContext context, TagHelperOutput output)
    {
        output.TagName = "div";
        output.AddClass("row", HtmlEncoder.Default);
    }
}

// Generates: <div class="col-md-4 mb-4"><a href="..." class="link-grid">...</a></div>
[HtmlTargetElement("link-grid-item")]
public class LinkGridItemTagHelper : TagHelper
{
    public string Href { get; set; } = "javascript:;";
    public string ColumnClass { get; set; } = "col-md-4 mb-4";

    public override async Task ProcessAsync(TagHelperContext context, TagHelperOutput output)
    {
        // 1. Transform the main tag into the anchor
        output.TagName = "a";
        output.Attributes.SetAttribute("href", Href);
        output.AddClass("link-grid", HtmlEncoder.Default);

        // 2. We must call this to ensure any inner text/HTML is processed
        await output.GetChildContentAsync();

        // 3. Wrap the anchor in the column div
        output.PreElement.SetHtmlContent($"<div class=\"{ColumnClass}\">");
        output.PostElement.SetHtmlContent("</div>");
    }
}

2. The CSHTML Usage Example

Your frontend code drops all the noisy div wrappers and becomes purely declarative.
HTML

<h1 class="mt-lg-0">Link Grid</h1>

<link-grid>
    <link-grid-item href="/dashboard">Short link 1</link-grid-item>
    <link-grid-item href="/settings">Short link 2</link-grid-item>
    
    <link-grid-item href="/profile" column-class="col-md-12 mb-4">
        Short link 3 (Full Width)
    </link-grid-item>
</link-grid>

3. Documentation (LinkGrid.md)
Markdown

---
sidenav_title: "Components"
sidenav_items:
  - label: "Link Grid"
    sublinks: []
---

# Link Grid

The Link Grid component provides a clean, responsive layout for rendering a series of action links. It automatically applies Bootstrap grid sizing and formatting.

## Usage

Use the `<link-grid>` wrapper to establish the row, and `<link-grid-item>` for each link.

```html
<link-grid>
    <link-grid-item href="/example">My Link</link-grid-item>
</link-grid>

Properties: <link-grid-item>
Attribute	Type	Default	Description
href	string	javascript:;	The destination URL for the link.
column-class	string	col-md-4 mb-4	The responsive wrapper classes applied outside the link.
Generated Output

The example above renders the following HTML:
HTML

<div class="row">
    <div class="col-md-4 mb-4">
        <a href="/example" class="link-grid">My Link</a>
    </div>
</div>


---

### 4. The MSTests (No Mocking Frameworks)

Keeping with the dependency-free native testing setup, we manually spin up the `TagHelperContext` and `TagHelperOutput`. I have also included the strict null-checks we covered earlier to avoid any `CS8602` compiler warnings.

```csharp
using Microsoft.AspNetCore.Razor.TagHelpers;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using WebTemplateLibrary.TagHelpers;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace WebTemplateTests;

[TestClass]
public class LinkGridTests
{
    [TestMethod]
    public void LinkGrid_Renders_RowDiv()
    {
        // Arrange
        var tagHelper = new LinkGridTagHelper();
        var context = new TagHelperContext(new TagHelperAttributeList(), new Dictionary<object, object>(), "test-id");
        var output = new TagHelperOutput("link-grid", new TagHelperAttributeList(), 
            (useCachedResult, encoder) => Task.FromResult<TagHelperContent>(new DefaultTagHelperContent()));

        // Act
        tagHelper.Process(context, output);

        // Assert
        Assert.AreEqual("div", output.TagName);
        
        var classAttr = output.Attributes["class"];
        Assert.IsNotNull(classAttr, "Class attribute is missing on the parent grid.");
        Assert.IsTrue(classAttr.Value.ToString()!.Contains("row"));
    }

    [TestMethod]
    public async Task LinkGridItem_Renders_WrappedAnchor()
    {
        // Arrange
        var tagHelper = new LinkGridItemTagHelper { Href = "/my-target" };
        var context = new TagHelperContext(new TagHelperAttributeList(), new Dictionary<object, object>(), "test-id");
        var output = new TagHelperOutput("link-grid-item", new TagHelperAttributeList(), 
            (useCachedResult, encoder) => Task.FromResult<TagHelperContent>(new DefaultTagHelperContent()));

        // Act
        await tagHelper.ProcessAsync(context, output);

        // Assert the Anchor
        Assert.AreEqual("a", output.TagName);
        
        var hrefAttr = output.Attributes["href"];
        Assert.IsNotNull(hrefAttr, "Href attribute is missing.");
        Assert.AreEqual("/my-target", hrefAttr.Value);

        var classAttr = output.Attributes["class"];
        Assert.IsNotNull(classAttr, "Class attribute is missing on the anchor.");
        Assert.IsTrue(classAttr.Value.ToString()!.Contains("link-grid"));

        // Assert the Wrapper Div (Pre/Post elements)
        var preHtml = output.PreElement.GetContent();
        var postHtml = output.PostElement.GetContent();
        
        Assert.AreEqual("<div class=\"col-md-4 mb-4\">", preHtml);
        Assert.AreEqual("</div>", postHtml);
    }
}




