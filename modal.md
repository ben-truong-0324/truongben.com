# tag

using Microsoft.AspNetCore.Razor.TagHelpers;
using System.Threading.Tasks;

namespace MyComponentLibrary.TagHelpers
{
    public enum ModalSize
    {
        Default,
        Lg,
        Sm,
        Xl
    }

    [HtmlTargetElement("rcl-modal")]
    public class ModalTagHelper : TagHelper
    {
        // The ID is required so a button can target it (e.g., data-bs-target="#myModal")
        public string ModalId { get; set; } = string.Empty;
        
        public string Title { get; set; } = string.Empty;
        public ModalSize Size { get; set; } = ModalSize.Lg; // CA Gov defaults to modal-lg in the sample
        
        public bool ShowFooter { get; set; } = true;
        public string FooterCloseText { get; set; } = "Close";

        public override async Task ProcessAsync(TagHelperContext context, TagHelperOutput output)
        {
            output.TagName = null; // Strip the parent wrapper

            var childContent = await output.GetChildContentAsync();
            var content = childContent.GetContent();

            string sizeClass = Size switch
            {
                ModalSize.Lg => " modal-lg",
                ModalSize.Sm => " modal-sm",
                ModalSize.Xl => " modal-xl",
                _ => ""
            };

            string footerHtml = string.Empty;
            if (ShowFooter)
            {
                footerHtml = $@"
                    <div class=""modal-footer"">
                        <button type=""button"" class=""btn btn-default"" data-bs-dismiss=""modal"">
                            {FooterCloseText}
                        </button>
                    </div>";
            }

            output.Content.SetHtmlContent($@"
<div class=""modal fade"" id=""{ModalId}"" role=""dialog"" tabindex=""-1"">
  <div class=""modal-dialog{sizeClass}"">
    <div class=""modal-content"">
      <div class=""modal-header"">
        <h4 class=""modal-title"">{Title}</h4>
        <button type=""button"" class=""close btn btn-secondary"" data-bs-dismiss=""modal"">
          <span class=""sr-only"">Close modal</span>
          <span class=""ca-gov-icon-close-mark"" aria-hidden=""true""></span>
        </button>
      </div>
      <div class=""modal-body"">
        {content}
      </div>
      {footerHtml}
    </div>
  </div>
</div>
");
        }
    }
}


# cshtml

<button
  type="button"
  class="btn btn-default btn-lg m-t-lg"
  data-bs-toggle="modal"
  data-bs-target="#news-headlines">
  Open modal
</button>

<rcl-modal modal-id="news-headlines" title="This is the modal container's heading.">
    <p>This is the modal container's body. You can put forms, text, or images in here.</p>
</rcl-modal>


<button class="btn btn-primary" data-bs-toggle="modal" data-bs-target="#quick-alert">
  Show Alert Modal
</button>

<rcl-modal modal-id="quick-alert" title="Warning" size="Sm" show-footer="false">
    <p>Are you sure you want to delete this record?</p>
</rcl-modal>

# docs

Modal Component (<rcl-modal>)

Renders a hidden Bootstrap-compliant modal dialog adhering to CA state template standards.
Setup

Ensure the Tag Helpers are registered in your _ViewImports.cshtml:
HTML

@addTagHelper *, MyComponentLibrary

Properties
Attribute	Type	Default	Description
modal-id	string	""	Required. Sets the HTML id of the modal. Your trigger button must use data-bs-target="#your-id".
title	string	""	The heading text displayed at the top of the modal.
size	ModalSize	Lg	Controls the maximum width. Options: Default, Lg, Sm, Xl.
show-footer	bool	true	If true, renders the footer section with a generic close button.
footer-close-text	string	"Close"	Text displayed on the footer close button.

# tests

using Microsoft.VisualStudio.TestTools.UnitTesting;
using Microsoft.AspNetCore.Razor.TagHelpers;
using MyComponentLibrary.TagHelpers;
using System.Collections.Generic;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc.Testing;
using System.Net.Http;
using MyComponentLibrary.TestHost; // Adjust to your test host app namespace

namespace MyComponentLibrary.Tests
{
    [TestClass]
    public class ModalTagHelpersTests
    {
        // --- Unit Tests ---
        private (TagHelperContext, TagHelperOutput) CreateTagHelperData(string content = "Modal Body Content")
        {
            var context = new TagHelperContext(
                tagName: "rcl-modal",
                allAttributes: new TagHelperAttributeList(),
                items: new Dictionary<object, object>(),
                uniqueId: "test");

            var output = new TagHelperOutput(
                "rcl-modal",
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
        public async Task Modal_DefaultProperties_RendersCorrectStructure()
        {
            // Arrange
            var helper = new ModalTagHelper { ModalId = "testModal", Title = "Test Heading" };
            var (context, output) = CreateTagHelperData();

            // Act
            await helper.ProcessAsync(context, output);
            var content = output.Content.GetContent();

            // Assert
            Assert.IsNull(output.TagName); // Ensure wrapper stripped
            
            // Check structural classes
            StringAssert.Contains(content, "<div class=\"modal fade\" id=\"testModal\" role=\"dialog\" tabindex=\"-1\">");
            StringAssert.Contains(content, "<div class=\"modal-dialog modal-lg\">"); // Default size is Lg
            
            // Check Header
            StringAssert.Contains(content, "<h4 class=\"modal-title\">Test Heading</h4>");
            StringAssert.Contains(content, "ca-gov-icon-close-mark");
            StringAssert.Contains(content, "data-bs-dismiss=\"modal\"");
            
            // Check Body
            StringAssert.Contains(content, "<div class=\"modal-body\">");
            StringAssert.Contains(content, "Modal Body Content");
            
            // Check Footer
            StringAssert.Contains(content, "<div class=\"modal-footer\">");
            StringAssert.Contains(content, ">Close\n"); // Default footer text
        }

        [TestMethod]
        public async Task Modal_Sizes_AppliesCorrectClass()
        {
            // Arrange
            var helper = new ModalTagHelper { ModalId = "smModal", Size = ModalSize.Sm };
            var (context, output) = CreateTagHelperData();

            // Act
            await helper.ProcessAsync(context, output);
            var content = output.Content.GetContent();

            // Assert
            StringAssert.Contains(content, "<div class=\"modal-dialog modal-sm\">");
        }

        [TestMethod]
        public async Task Modal_HideFooter_RemovesFooterElement()
        {
            // Arrange
            var helper = new ModalTagHelper { ModalId = "noFooter", ShowFooter = false };
            var (context, output) = CreateTagHelperData();

            // Act
            await helper.ProcessAsync(context, output);
            var content = output.Content.GetContent();

            // Assert
            Assert.IsFalse(content.Contains("<div class=\"modal-footer\">"));
            Assert.IsFalse(content.Contains(">Close\n")); // Generic close button should not exist
        }
    }

    [TestClass]
    public class ModalIntegrationTests
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
        public async Task Modal_RendersCorrectHtml_OnPage()
        {
            // Act
            // Assume page has: <rcl-modal modal-id="intModal" title="Int Test">Int Content</rcl-modal>
            var response = await _client.GetAsync("/ModalTestPage");
            response.EnsureSuccessStatusCode();

            var responseString = await response.Content.ReadAsStringAsync();

            // Assert
            StringAssert.Contains(responseString, "id=\"intModal\"");
            StringAssert.Contains(responseString, "Int Test");
            StringAssert.Contains(responseString, "Int Content");
            StringAssert.Contains(responseString, "ca-gov-icon-close-mark");
        }
    }
}


########################################


For a modal, you definitely want the multi-line ::: syntax, as modals often contain paragraphs, lists, or even other components inside their body.

Because a modal is invisible until triggered, the most important thing to communicate to your non-technical users is that they need an ID so they can actually open it with a button or a link.
1. The Recommendation for Non-Technical Users

Have them define the modal block anywhere on the page (usually at the bottom is best practice), and then use the button component we built earlier to target it.

What they will write:
Markdown

Click the button below to view the requirements.

:::rcl-button text="View Requirements" isOutline="true" href="#" data-bs-toggle="modal" data-bs-target="#reqModal" :::

:::rcl-modal modalId="reqModal" title="Eligibility Requirements" size="Lg" showFooter="true"
Here is a list of what you need:
* Valid ID
* Proof of residence
* Completed application form
:::

(Note: To make that button work, you might need to quickly update your ButtonHtmlBuilder to pass through data- attributes, or they can just use a standard Markdown link like <a href="#" data-bs-toggle="modal" data-bs-target="#reqModal">Open</a>).
2. The Implementation

Here is the extraction of your TagHelper logic into the HTML builder and the parser.
Step 1: The Modal HTML Builder

This handles the Bootstrap modal structure. Notice I added markdown="1" to the <div class="modal-body"> so your users' bulleted lists and bold text render correctly inside the popup!
C#

public static class ModalHtmlBuilder
{
    public static string Build(string modalId, string title, ModalSize size, bool showFooter, string footerCloseText, string content)
    {
        string sizeClass = size switch
        {
            ModalSize.Lg => " modal-lg",
            ModalSize.Sm => " modal-sm",
            ModalSize.Xl => " modal-xl",
            _ => ""
        };

        string footerHtml = string.Empty;
        if (showFooter)
        {
            footerHtml = $@"
                <div class=""modal-footer"">
                    <button type=""button"" class=""btn btn-default"" data-bs-dismiss=""modal"">
                        {footerCloseText}
                    </button>
                </div>";
        }

        return $@"
<div class=""modal fade"" id=""{modalId}"" role=""dialog"" tabindex=""-1"">
  <div class=""modal-dialog{sizeClass}"">
    <div class=""modal-content"">
      <div class=""modal-header"">
        <h4 class=""modal-title"">{title}</h4>
        <button type=""button"" class=""close btn btn-secondary"" data-bs-dismiss=""modal"">
          <span class=""sr-only"">Close modal</span>
          <span class=""ca-gov-icon-close-mark"" aria-hidden=""true""></span>
        </button>
      </div>
      <div class=""modal-body"" markdown=""1"">
        {content}
      </div>
      {footerHtml}
    </div>
  </div>
</div>";
    }
}

Step 2: The Modal Regex Parser

Add this pattern to your MarkdownComponentParser. We will automatically generate an ID for them if they forget to provide one, though it means they won't be able to easily link a button to it.
C#

using System.Text.RegularExpressions;
using System.Collections.Generic;
using System;

public partial class MarkdownComponentParser
{
    // Match the multi-line block: :::rcl-modal [attributes] \n [content] \n :::
    [GeneratedRegex(@"^:::rcl-modal[ \t]*(.*?)\r?\n(.*?)\r?\n:::", RegexOptions.Multiline | RegexOptions.Singleline)]
    private static partial Regex RclModalRegex();

    // Your existing AttributeRegex() is used again here

    public static string ProcessModals(string rawMarkdown)
    {
        return RclModalRegex().Replace(rawMarkdown, match =>
        {
            string attributesString = match.Groups[1].Value;
            string content = match.Groups[2].Value;

            // 1. Parse attributes
            var attributes = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
            foreach (Match attrMatch in AttributeRegex().Matches(attributesString))
            {
                attributes[attrMatch.Groups[1].Value] = attrMatch.Groups[2].Value;
            }

            // 2. Extract string values
            string title = attributes.GetValueOrDefault("title", string.Empty);
            string footerCloseText = attributes.GetValueOrDefault("footerclosetext", "Close");
            
            // Generate a random ID if they forgot one, so the HTML is at least valid
            string modalId = attributes.GetValueOrDefault("modalid", $"modal_{Guid.NewGuid().ToString("N").Substring(0, 6)}");

            // 3. Parse Enums safely (Default is Lg per your TagHelper)
            ModalSize size = ModalSize.Lg; 
            if (attributes.TryGetValue("size", out string? sizeStr))
            {
                Enum.TryParse(sizeStr, true, out size);
            }

            // 4. Parse Booleans safely (Default is true per your TagHelper)
            bool showFooter = true;
            if (attributes.TryGetValue("showfooter", out string? showFooterStr))
            {
                bool.TryParse(showFooterStr, out showFooter);
            }

            // 5. Build and return the HTML
            return ModalHtmlBuilder.Build(modalId, title, size, showFooter, footerCloseText, content);
        });
    }
}

Step 3: Wire it into the Pipeline

Add the new modal processor to your chain.
C#

string processedContent = MarkdownComponentParser.ProcessCards(rawMarkdown);
processedContent = MarkdownComponentParser.ProcessButtons(processedContent);
processedContent = MarkdownComponentParser.ProcessTabs(processedContent);
processedContent = MarkdownComponentParser.ProcessBlockquotes(processedContent);
processedContent = MarkdownComponentParser.ProcessModals(processedContent); // <--- Add Modals here

string finalHtml = markdownToHtml(processedContent);

A Quick CSS/JS Note

Since this is generating Bootstrap HTML (which the CA State Template uses heavily), ensure that the .cshtml page rendering this markdown has the Bootstrap JavaScript loaded at the bottom of the page (e.g., <script src="...bootstrap.bundle.min.js"></script>). I