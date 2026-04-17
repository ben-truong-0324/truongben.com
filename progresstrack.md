# tag

using Microsoft.AspNetCore.Razor.TagHelpers;
using System.Threading.Tasks;

namespace MyComponentLibrary.TagHelpers
{
    public enum ProgressVariant
    {
        Default,
        Bold
    }

    public enum StepState
    {
        Completed,
        Current,
        Upcoming
    }

    public enum StepPosition
    {
        First,
        Middle,
        Last
    }

    // --- 1. Progress Bar ---
    [HtmlTargetElement("rcl-progress-bar")]
    public class ProgressBarTagHelper : TagHelper
    {
        public int Percentage { get; set; } = 0;

        public override void Process(TagHelperContext context, TagHelperOutput output)
        {
            output.TagName = "div";
            output.Attributes.SetAttribute("class", "progress");

            output.Content.SetHtmlContent($@"
                <div class=""progress-bar bg-highlight overflow-auto"" 
                     role=""progressbar"" 
                     aria-valuenow=""{Percentage}"" 
                     aria-valuemin=""0"" 
                     aria-valuemax=""100"" 
                     style=""width: {Percentage}%;color:#000;"" 
                     tabindex=""0"">
                    {Percentage}%
                </div>");
        }
    }

    // --- 2. Progress Block Parent ---
    [HtmlTargetElement("rcl-progress-block")]
    public class ProgressBlockTagHelper : TagHelper
    {
        public ProgressVariant Variant { get; set; } = ProgressVariant.Default;

        public override void Process(TagHelperContext context, TagHelperOutput output)
        {
            // Share the variant with the child steps so they format themselves correctly
            context.Items["ProgressVariant"] = Variant;

            output.TagName = "div";
            output.Attributes.SetAttribute("class", "row");
        }
    }

    // --- 3. Progress Block Step ---
    [HtmlTargetElement("rcl-progress-step", ParentTag = "rcl-progress-block")]
    public class ProgressStepTagHelper : TagHelper
    {
        public string Title { get; set; } = string.Empty;
        public StepState State { get; set; } = StepState.Upcoming;
        public StepPosition Position { get; set; } = StepPosition.Middle;

        public override async Task ProcessAsync(TagHelperContext context, TagHelperOutput output)
        {
            var variant = context.Items.ContainsKey("ProgressVariant")
                ? (ProgressVariant)context.Items["ProgressVariant"]
                : ProgressVariant.Default;

            var childContent = await output.GetChildContentAsync();
            var content = childContent.GetContent();

            output.TagName = "div";
            output.Attributes.SetAttribute("class", "col-sm-3 text-sm-center d-flex d-sm-block");

            // --- CSS Logic Resolution based on State, Position, and Variant ---

            string beforeBorder = "brd-gray-light-before";
            string afterBorder = "brd-gray-light-after";
            string innerDot = "bg-white brd-gray-light";
            string boldModifier = variant == ProgressVariant.Bold ? " progress-bold" : "";

            if (Position == StepPosition.First) beforeBorder = "brd-transparent-before";
            else if (variant == ProgressVariant.Bold) beforeBorder = (State == StepState.Completed || State == StepState.Current) ? "brd-primary-light-before" : "brd-gray-light-before";

            if (Position == StepPosition.Last) afterBorder = "brd-transparent-after";
            else if (variant == ProgressVariant.Bold) afterBorder = (State == StepState.Completed) ? "brd-primary-light-after" : "brd-gray-light-after";

            if (variant == ProgressVariant.Bold)
            {
                innerDot = (State == StepState.Completed || State == StepState.Current) 
                    ? "bg-primary-light bg-primary-before brd-primary-light" 
                    : "bg-gray-light brd-gray-light";
            }
            else
            {
                innerDot = (State == StepState.Completed || State == StepState.Current) 
                    ? "bg-white bg-primary-before brd-gray-light" 
                    : "bg-white brd-gray-light";
            }

            output.Content.SetHtmlContent($@"
                <div class=""dot-line{boldModifier} {beforeBorder} {afterBorder}"">
                    <span class=""dot-line-inner {innerDot}""></span>
                </div>
                <div class=""dot-text"">
                    <h3 class=""h5 m-b"">{Title}</h3>
                    <p class=""mb-4"">{content}</p>
                </div>
            ");
        }
    }
}

# cshtml

<rcl-progress-bar percentage="60"></rcl-progress-bar>
<br />

<rcl-progress-block variant="Default">
    <rcl-progress-step title="Step 1" state="Completed" position="First">
        Briefly discuss the step or identify the milestone.
    </rcl-progress-step>

    <rcl-progress-step title="Step 2" state="Completed" position="Middle">
        Keep the message clear and concise.
    </rcl-progress-step>

    <rcl-progress-step title="Step 3" state="Current" position="Middle">
        Do not link to more information from the tracker.
    </rcl-progress-step>

    <rcl-progress-step title="Step 4" state="Upcoming" position="Last">
        Instead, link to additional information in your body content.
    </rcl-progress-step>
</rcl-progress-block>
<br />

<rcl-progress-block variant="Bold">
    <rcl-progress-step title="Step 1" state="Completed" position="First">
        Briefly discuss the step or identify the milestone.
    </rcl-progress-step>

    <rcl-progress-step title="Step 2" state="Completed" position="Middle">
        Keep the message clear and concise.
    </rcl-progress-step>

    <rcl-progress-step title="Step 3" state="Current" position="Middle">
        Do not link to more information from the tracker.
    </rcl-progress-step>

    <rcl-progress-step title="Step 4" state="Upcoming" position="Last">
        Instead, link to additional information in your body content.
    </rcl-progress-step>
</rcl-progress-block>

# docs

Progress Components
<rcl-progress-bar>

Renders a horizontal percentage meter.
Attribute	Type	Default	Description
percentage	int	0	A number between 0 and 100 representing completion.
<rcl-progress-block> and <rcl-progress-step>

Renders a multi-step tracker. The parent block determines the styling, while the child steps automatically calculate the required connector line CSS depending on their state.
Parent (<rcl-progress-block>)
Attribute	Type	Default	Description
variant	ProgressVariant	Default	Visual style options: Default, Bold.
Child (<rcl-progress-step>)
Attribute	Type	Default	Description
title	string	""	The heading for the step (e.g., "Step 1").
state	StepState	Upcoming	Status. Options: Completed, Current, Upcoming.
position	StepPosition	Middle	Layout location. Options: First, Middle, Last. Dictates the existence of connecting lines before or after the

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
    public class ProgressTagHelpersTests
    {
        // --- Unit Tests ---
        private (TagHelperContext, TagHelperOutput) CreateTagHelperData(string tagName, string content = "Step Text")
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
        public void ProgressBar_SetsPercentageCorrectly()
        {
            // Arrange
            var helper = new ProgressBarTagHelper { Percentage = 75 };
            var (context, output) = CreateTagHelperData("rcl-progress-bar");

            // Act
            helper.Process(context, output);
            var content = output.Content.GetContent();

            // Assert
            Assert.AreEqual("div", output.TagName);
            Assert.AreEqual("progress", output.Attributes["class"].Value);
            StringAssert.Contains(content, "aria-valuenow=\"75\"");
            StringAssert.Contains(content, "style=\"width: 75%;color:#000;\"");
            StringAssert.Contains(content, "75%");
        }

        [TestMethod]
        public async Task ProgressStep_FirstPosition_RemovesBeforeBorder()
        {
            // Arrange
            var helper = new ProgressStepTagHelper { Position = StepPosition.First, State = StepState.Completed };
            var (context, output) = CreateTagHelperData("rcl-progress-step");

            // Act
            await helper.ProcessAsync(context, output);
            var content = output.Content.GetContent();

            // Assert
            StringAssert.Contains(content, "brd-transparent-before");
        }

        [TestMethod]
        public async Task ProgressStep_LastPosition_RemovesAfterBorder()
        {
            // Arrange
            var helper = new ProgressStepTagHelper { Position = StepPosition.Last, State = StepState.Upcoming };
            var (context, output) = CreateTagHelperData("rcl-progress-step");

            // Act
            await helper.ProcessAsync(context, output);
            var content = output.Content.GetContent();

            // Assert
            StringAssert.Contains(content, "brd-transparent-after");
        }

        [TestMethod]
        public async Task ProgressStep_BoldVariant_CompletedState_ColorsBordersAndDots()
        {
            // Arrange
            var helper = new ProgressStepTagHelper { Position = StepPosition.Middle, State = StepState.Completed };
            var (context, output) = CreateTagHelperData("rcl-progress-step");
            context.Items["ProgressVariant"] = ProgressVariant.Bold; // Simulate parent passing variant

            // Act
            await helper.ProcessAsync(context, output);
            var content = output.Content.GetContent();

            // Assert
            StringAssert.Contains(content, "progress-bold");
            StringAssert.Contains(content, "brd-primary-light-before");
            StringAssert.Contains(content, "brd-primary-light-after");
            StringAssert.Contains(content, "bg-primary-light bg-primary-before brd-primary-light");
        }

        [TestMethod]
        public async Task ProgressStep_DefaultVariant_CurrentState_ColorsDotsProperly()
        {
            // Arrange
            var helper = new ProgressStepTagHelper { Position = StepPosition.Middle, State = StepState.Current };
            var (context, output) = CreateTagHelperData("rcl-progress-step");
            context.Items["ProgressVariant"] = ProgressVariant.Default;

            // Act
            await helper.ProcessAsync(context, output);
            var content = output.Content.GetContent();

            // Assert
            StringAssert.Contains(content, "brd-gray-light-before");
            StringAssert.Contains(content, "brd-gray-light-after");
            StringAssert.Contains(content, "bg-white bg-primary-before brd-gray-light"); // Dot marked as reached
        }
    }

    [TestClass]
    public class ProgressIntegrationTests
    {
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
        public async Task Progress_RendersCorrectHtml_OnPage()
        {
            // Act
            // Assume page has: <rcl-progress-bar percentage="42"></rcl-progress-bar>
            var response = await _client.GetAsync("/ProgressTestPage");
            response.EnsureSuccessStatusCode();

            var responseString = await response.Content.ReadAsStringAsync();

            // Assert
            StringAssert.Contains(responseString, "aria-valuenow=\"42\"");
            StringAssert.Contains(responseString, "width: 42%;");
        }
    }
}