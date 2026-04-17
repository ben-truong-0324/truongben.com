# tag

using Microsoft.AspNetCore.Razor.TagHelpers;
using System.Threading.Tasks;

namespace MyComponentLibrary.TagHelpers
{
    public enum InputType
    {
        Text,
        Textarea,
        File
    }

    public enum CheckType
    {
        Checkbox,
        Radio
    }

    // --- 1. Text, Textarea, and File Inputs ---
    [HtmlTargetElement("rcl-input")]
    public class FormInputTagHelper : TagHelper
    {
        public InputType Type { get; set; } = InputType.Text;
        public string InputId { get; set; } = string.Empty;
        public string Label { get; set; } = string.Empty;
        public string Placeholder { get; set; } = string.Empty;
        public bool IsRequired { get; set; }
        public string FeedbackText { get; set; } = string.Empty;

        public override void Process(TagHelperContext context, TagHelperOutput output)
        {
            output.TagName = null; // Strip the outer wrapper

            // Build Label
            string requiredHtml = IsRequired ? "<span class=\"required-label\">*</span> <span class=\"sr-only\">Required field:</span> " : "";
            string labelClass = Type == InputType.File ? "mb-1" : "form-control-label";
            string labelHtml = $"<label class=\"{labelClass}\" for=\"{InputId}\">{requiredHtml}{Label}</label>\n";

            // Build Input
            string inputHtml = "";
            if (Type == InputType.Textarea)
            {
                inputHtml = $"<textarea id=\"{InputId}\" class=\"form-control\" rows=\"5\" cols=\"80\"></textarea>\n";
            }
            else if (Type == InputType.File)
            {
                inputHtml = $"<div class=\"input-group mb-3\">\n  <input type=\"file\" class=\"form-control\" id=\"{InputId}\" />\n</div>\n";
            }
            else
            {
                inputHtml = $"<input type=\"text\" class=\"form-control\" id=\"{InputId}\" placeholder=\"{Placeholder}\" />\n";
            }

            // Build Feedback
            string feedbackHtml = "";
            if (IsRequired)
            {
                feedbackHtml = "<div class=\"invalid-feedback d-block\">This field is required</div>";
            }
            else if (!string.IsNullOrWhiteSpace(FeedbackText))
            {
                if (Type == InputType.Textarea)
                    feedbackHtml = $"<small>{FeedbackText}</small>";
                else if (Type == InputType.File)
                    feedbackHtml = $"<div class=\"feedback small\">{FeedbackText}</div>";
                else
                    feedbackHtml = $"<div class=\"feedback text-muted\">{FeedbackText}</div>";
            }

            output.Content.SetHtmlContent(labelHtml + inputHtml + feedbackHtml);
        }
    }

    // --- 2. Checkboxes and Radios ---
    [HtmlTargetElement("rcl-check")]
    public class FormCheckTagHelper : TagHelper
    {
        public CheckType Type { get; set; } = CheckType.Checkbox;
        public string InputId { get; set; } = string.Empty;
        public string Name { get; set; } = string.Empty;
        public string Value { get; set; } = string.Empty;
        public string Label { get; set; } = string.Empty;

        public override void Process(TagHelperContext context, TagHelperOutput output)
        {
            output.TagName = "div";
            output.Attributes.SetAttribute("class", "form-check m-b");

            string typeStr = Type == CheckType.Radio ? "radio" : "checkbox";
            string nameAttr = string.IsNullOrWhiteSpace(Name) ? "" : $" name=\"{Name}\"";

            output.Content.SetHtmlContent($@"
                <input class=""form-check-input"" type=""{typeStr}""{nameAttr} value=""{Value}"" id=""{InputId}"" />
                <label class=""form-check-label"" for=""{InputId}"">{Label}</label>
            ");
        }
    }

    // --- 3. Dropdowns (Selects) ---
    [HtmlTargetElement("rcl-select")]
    public class FormSelectTagHelper : TagHelper
    {
        public string SelectId { get; set; } = string.Empty;
        public string Label { get; set; } = string.Empty;

        public override async Task ProcessAsync(TagHelperContext context, TagHelperOutput output)
        {
            output.TagName = null;
            var childContent = await output.GetChildContentAsync();
            
            output.Content.SetHtmlContent($@"
                <label for=""{SelectId}"" class=""mb-1"">{Label}</label>
                <select class=""form-select form-select-lg mb-3"" aria-label=""{Label}"" id=""{SelectId}"">
                    {childContent.GetContent()}
                </select>
            ");
        }
    }
}


# cshtml

<rcl-input type="Text" input-id="InputName" label="Full name" placeholder="Full name" feedback-text="Helper text"></rcl-input>
<rcl-input type="Text" input-id="InputNameReq" label="Full name" placeholder="Full name" is-required="true"></rcl-input>

<rcl-input type="Textarea" input-id="CommentArea" label="Your message" feedback-text="Use this space for instructions"></rcl-input>
<rcl-input type="Textarea" input-id="CommentAreaReq" label="Your message" is-required="true"></rcl-input>

<rcl-input type="File" input-id="UploadFile" label="Upload your file" feedback-text="Feedback text."></rcl-input>

<h3 class="h4 mt-0 m-b">Pick one or more of these items:</h3>
<rcl-check type="Checkbox" input-id="check1" label="Option 1"></rcl-check>
<rcl-check type="Checkbox" input-id="check2" label="Option 2"></rcl-check>

<h3 class="h4 m-t-0 m-b">Pick only one of these items:</h3>
<rcl-check type="Radio" name="favorite_pet" input-id="radio1" label="Option 1"></rcl-check>
<rcl-check type="Radio" name="favorite_pet" input-id="radio2" label="Option 2"></rcl-check>

<rcl-select select-id="CustomSelect" label="Custom select">
    <option selected>Select an option</option>
    <option value="1">Option 1</option>
    <option value="2">Option 2</option>
</rcl-select>

# docs

Form Components

These Tag Helpers simplify form creation while enforcing CA state template accessibility and layout requirements.
<rcl-input>

Handles standard text fields, textareas, and file upload inputs.
Attribute	Type	Default	Description
type	InputType	Text	Options: Text, Textarea, File.
input-id	string	""	Binds the <label for="..."> to the input element.
label	string	""	The text for the field label.
placeholder	string	""	Placeholder text (ignored for File and Textarea).
is-required	bool	false	Injects the required * marker and invalid feedback validation state.
feedback-text	string	""	Renders a sub-text message below the input. Overridden if is-required is true.
<rcl-check>

Handles both checkboxes and radio buttons.
Attribute	Type	Default	Description
type	CheckType	Checkbox	Options: Checkbox, Radio.
input-id	string	""	Binds the label to the input.
name	string	""	Form submit name (crucial for grouping Radio buttons).
value	string	""	The value submitted to the server.
label	string	""	The display text next to the check/radio box.
<rcl-select>

Handles dropdown menus. Wraps standard <option> tags.
Attribute	Type	Default	Description
select-id	string	""	Binds the label to the select input.
label	string	""	The text for the field label.

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
    public class FormTagHelpersTests
    {
        // --- Unit Tests ---
        private (TagHelperContext, TagHelperOutput) CreateTagHelperData(string tagName, string content = "")
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
        public void FormInput_TextVariant_RendersCorrectly()
        {
            // Arrange
            var helper = new FormInputTagHelper { Type = InputType.Text, InputId = "test1", Label = "Name", Placeholder = "Enter Name" };
            var (context, output) = CreateTagHelperData("rcl-input");

            // Act
            helper.Process(context, output);
            var content = output.Content.GetContent();

            // Assert
            Assert.IsNull(output.TagName);
            StringAssert.Contains(content, "<label class=\"form-control-label\" for=\"test1\">Name</label>");
            StringAssert.Contains(content, "<input type=\"text\" class=\"form-control\" id=\"test1\" placeholder=\"Enter Name\"");
        }

        [TestMethod]
        public void FormInput_Required_InjectsRequiredHtml()
        {
            // Arrange
            var helper = new FormInputTagHelper { Type = InputType.Textarea, InputId = "req", Label = "Msg", IsRequired = true };
            var (context, output) = CreateTagHelperData("rcl-input");

            // Act
            helper.Process(context, output);
            var content = output.Content.GetContent();

            // Assert
            StringAssert.Contains(content, "<span class=\"required-label\">*</span>");
            StringAssert.Contains(content, "<span class=\"sr-only\">Required field:</span>");
            StringAssert.Contains(content, "This field is required");
        }

        [TestMethod]
        public void FormCheck_RadioVariant_RendersRadioGroup()
        {
            // Arrange
            var helper = new FormCheckTagHelper { Type = CheckType.Radio, InputId = "r1", Name = "group", Label = "Yes" };
            var (context, output) = CreateTagHelperData("rcl-check");

            // Act
            helper.Process(context, output);
            var content = output.Content.GetContent();

            // Assert
            Assert.AreEqual("div", output.TagName);
            Assert.AreEqual("form-check m-b", output.Attributes["class"].Value);
            StringAssert.Contains(content, "type=\"radio\"");
            StringAssert.Contains(content, "name=\"group\"");
            StringAssert.Contains(content, "id=\"r1\"");
            StringAssert.Contains(content, ">Yes</label>");
        }

        [TestMethod]
        public async Task FormSelect_RendersSelectWithChildren()
        {
            // Arrange
            var helper = new FormSelectTagHelper { SelectId = "s1", Label = "Pick" };
            var (context, output) = CreateTagHelperData("rcl-select", "<option>Opt 1</option>");

            // Act
            await helper.ProcessAsync(context, output);
            var content = output.Content.GetContent();

            // Assert
            Assert.IsNull(output.TagName);
            StringAssert.Contains(content, "<label for=\"s1\" class=\"mb-1\">Pick</label>");
            StringAssert.Contains(content, "<select class=\"form-select form-select-lg mb-3\" aria-label=\"Pick\" id=\"s1\">");
            StringAssert.Contains(content, "<option>Opt 1</option>");
        }
    }

    [TestClass]
    public class FormIntegrationTests
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
        public async Task Forms_RenderCorrectHtml_OnPage()
        {
            // Act
            // Assume page has: <rcl-input type="File" input-id="intFile" label="Upload"></rcl-input>
            var response = await _client.GetAsync("/FormTestPage");
            response.EnsureSuccessStatusCode();

            var responseString = await response.Content.ReadAsStringAsync();

            // Assert
            StringAssert.Contains(responseString, "<label class=\"mb-1\" for=\"intFile\">Upload</label>");
            StringAssert.Contains(responseString, "<div class=\"input-group mb-3\">");
            StringAssert.Contains(responseString, "type=\"file\"");
        }
    }
}