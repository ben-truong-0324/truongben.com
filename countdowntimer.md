# tag

using Microsoft.AspNetCore.Razor.TagHelpers;
using System;
using System.Threading.Tasks;

namespace MyComponentLibrary.TagHelpers
{
    [HtmlTargetElement("rcl-countdown-timer")]
    public class CountdownTimerTagHelper : TagHelper
    {
        // Accept a native C# DateTime object
        public DateTime TargetDate { get; set; }

        // Optional: Let developers specify an ID, otherwise auto-generate one
        public string TimerId { get; set; }

        public override void Process(TagHelperContext context, TagHelperOutput output)
        {
            // Strip the parent tag
            output.TagName = null;

            // Generate a unique ID if one wasn't provided
            var id = string.IsNullOrWhiteSpace(TimerId) 
                ? Guid.NewGuid().ToString("N").Substring(0, 6) 
                : TimerId;

            // Format date safely for JS parsing
            string jsDateString = TargetDate.ToString("MMM d, yyyy HH:mm:ss");

            string htmlContent = $@"
<div class=""row flex-column flex-md-row countdown p-x"">
  <div class=""col bg-gray-100 text-center p-b-md p-l-0 p-r-0"">
    <span class=""countdown-text""><abbr title=""weeks"" aria-label=""weeks"" class=""text-decoration-none"">wks</abbr><br /></span>
    <span id=""weeks_{id}""></span>
  </div>
  <div class=""col bg-gray-100 text-center p-b-md p-l-0 p-r-0"">
    <span class=""countdown-text"">days<br /></span>
    <span id=""days_{id}""></span>
  </div>
  <div class=""col bg-gray-100 text-center p-b-md p-l-0 p-r-0"">
    <span class=""countdown-text""><abbr title=""hours"" aria-label=""hours"" class=""text-decoration-none"">hrs</abbr><br /></span>
    <span id=""hours_{id}""></span>
  </div>
  <div class=""col bg-gray-100 text-center p-b-md p-l-0 p-r-0"">
    <span class=""countdown-text""><abbr title=""minutes"" aria-label=""minutes"" class=""text-decoration-none"">mins</abbr><br /></span>
    <span id=""minutes_{id}""></span>
  </div>
  <div class=""col bg-gray-100 text-center p-b-md p-l-0 p-r-0"">
    <span class=""countdown-text""><abbr title=""seconds"" aria-label=""seconds"" class=""text-decoration-none"">secs</abbr><br /></span>
    <span id=""seconds_{id}""></span>
  </div>
</div>

<script>
  (function() {{
      var countDownDate = new Date(""{jsDateString}"").getTime();
      var x = setInterval(function () {{
          var now = new Date().getTime();
          var distance = countDownDate - now;

          var weeks = Math.floor(distance / (1000 * 60 * 60 * 24 * 7));
          var days = Math.floor(distance / (1000 * 60 * 60 * 24));
          var hours = Math.floor((distance % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60));
          var minutes = Math.floor((distance % (1000 * 60 * 60)) / (1000 * 60));
          var seconds = Math.floor((distance % (1000 * 60)) / 1000);

          var weeksEl = document.getElementById(""weeks_{id}"");
          var daysEl = document.getElementById(""days_{id}"");
          var hoursEl = document.getElementById(""hours_{id}"");
          var minutesEl = document.getElementById(""minutes_{id}"");
          var secondsEl = document.getElementById(""seconds_{id}"");

          if(weeksEl) weeksEl.innerHTML = weeks;
          if(daysEl) daysEl.innerHTML = days;
          if(hoursEl) hoursEl.innerHTML = hours;
          if(minutesEl) minutesEl.innerHTML = minutes;
          if(secondsEl) secondsEl.innerHTML = seconds;

          if (distance < 0) {{
              clearInterval(x);
              if(daysEl) daysEl.innerHTML = ""EXPIRED"";
          }}
      }}, 1000);
  }})();
</script>";

            output.Content.SetHtmlContent(htmlContent);
        }
    }
}

# cshtml

<rcl-countdown-timer target-date="Jan 1, 2026 00:00:00"></rcl-countdown-timer>

<rcl-countdown-timer target-date="2026-12-31T23:59:59" timer-id="NewYearsEve"></rcl-countdown-timer>

<rcl-countdown-timer target-date="@Model.ProjectLaunchDate"></rcl-countdown-timer>

# docs

Countdown Timer Component (<rcl-countdown-timer>)

Renders a 5-column countdown timer (weeks, days, hours, minutes, seconds) and automatically injects the necessary scoped JavaScript to update it every second.
Setup

Ensure the Tag Helpers are registered in your _ViewImports.cshtml:
HTML

@addTagHelper *, MyComponentLibrary

Here is the implementation for the Countdown Timer.

Because countdown timers rely on element id attributes to update the DOM via JavaScript, I've added a unique ID generation step. This ensures that if you put multiple <rcl-countdown-timer> components on the same page, their scripts won't collide and overwrite each other. I also wrapped the generated JavaScript in an Immediately Invoked Function Expression (IIFE) to prevent polluting the global window scope with variables.
1. The Tag Helper Logic (CountdownTimerTagHelper.cs)
C#

using Microsoft.AspNetCore.Razor.TagHelpers;
using System;
using System.Threading.Tasks;

namespace MyComponentLibrary.TagHelpers
{
    [HtmlTargetElement("rcl-countdown-timer")]
    public class CountdownTimerTagHelper : TagHelper
    {
        // Accept a native C# DateTime object
        public DateTime TargetDate { get; set; }

        // Optional: Let developers specify an ID, otherwise auto-generate one
        public string TimerId { get; set; }

        public override void Process(TagHelperContext context, TagHelperOutput output)
        {
            // Strip the parent tag
            output.TagName = null;

            // Generate a unique ID if one wasn't provided
            var id = string.IsNullOrWhiteSpace(TimerId) 
                ? Guid.NewGuid().ToString("N").Substring(0, 6) 
                : TimerId;

            // Format date safely for JS parsing
            string jsDateString = TargetDate.ToString("MMM d, yyyy HH:mm:ss");

            string htmlContent = $@"
<div class=""row flex-column flex-md-row countdown p-x"">
  <div class=""col bg-gray-100 text-center p-b-md p-l-0 p-r-0"">
    <span class=""countdown-text""><abbr title=""weeks"" aria-label=""weeks"" class=""text-decoration-none"">wks</abbr><br /></span>
    <span id=""weeks_{id}""></span>
  </div>
  <div class=""col bg-gray-100 text-center p-b-md p-l-0 p-r-0"">
    <span class=""countdown-text"">days<br /></span>
    <span id=""days_{id}""></span>
  </div>
  <div class=""col bg-gray-100 text-center p-b-md p-l-0 p-r-0"">
    <span class=""countdown-text""><abbr title=""hours"" aria-label=""hours"" class=""text-decoration-none"">hrs</abbr><br /></span>
    <span id=""hours_{id}""></span>
  </div>
  <div class=""col bg-gray-100 text-center p-b-md p-l-0 p-r-0"">
    <span class=""countdown-text""><abbr title=""minutes"" aria-label=""minutes"" class=""text-decoration-none"">mins</abbr><br /></span>
    <span id=""minutes_{id}""></span>
  </div>
  <div class=""col bg-gray-100 text-center p-b-md p-l-0 p-r-0"">
    <span class=""countdown-text""><abbr title=""seconds"" aria-label=""seconds"" class=""text-decoration-none"">secs</abbr><br /></span>
    <span id=""seconds_{id}""></span>
  </div>
</div>

<script>
  (function() {{
      var countDownDate = new Date(""{jsDateString}"").getTime();
      var x = setInterval(function () {{
          var now = new Date().getTime();
          var distance = countDownDate - now;

          var weeks = Math.floor(distance / (1000 * 60 * 60 * 24 * 7));
          var days = Math.floor(distance / (1000 * 60 * 60 * 24));
          var hours = Math.floor((distance % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60));
          var minutes = Math.floor((distance % (1000 * 60 * 60)) / (1000 * 60));
          var seconds = Math.floor((distance % (1000 * 60)) / 1000);

          var weeksEl = document.getElementById(""weeks_{id}"");
          var daysEl = document.getElementById(""days_{id}"");
          var hoursEl = document.getElementById(""hours_{id}"");
          var minutesEl = document.getElementById(""minutes_{id}"");
          var secondsEl = document.getElementById(""seconds_{id}"");

          if(weeksEl) weeksEl.innerHTML = weeks;
          if(daysEl) daysEl.innerHTML = days;
          if(hoursEl) hoursEl.innerHTML = hours;
          if(minutesEl) minutesEl.innerHTML = minutes;
          if(secondsEl) secondsEl.innerHTML = seconds;

          if (distance < 0) {{
              clearInterval(x);
              if(daysEl) daysEl.innerHTML = ""EXPIRED"";
          }}
      }}, 1000);
  }})();
</script>";

            output.Content.SetHtmlContent(htmlContent);
        }
    }
}

2. Usage in your Views (.cshtml)

You can pass standard strings that C# can implicitly parse into DateTime, or pass explicit DateTime models.
HTML

<rcl-countdown-timer target-date="Jan 1, 2026 00:00:00"></rcl-countdown-timer>

<rcl-countdown-timer target-date="2026-12-31T23:59:59" timer-id="NewYearsEve"></rcl-countdown-timer>

<rcl-countdown-timer target-date="@Model.ProjectLaunchDate"></rcl-countdown-timer>

3. Documentation (README.md)
Countdown Timer Component (<rcl-countdown-timer>)

Renders a 5-column countdown timer (weeks, days, hours, minutes, seconds) and automatically injects the necessary scoped JavaScript to update it every second.
Setup

Ensure the Tag Helpers are registered in your _ViewImports.cshtml:
HTML

@addTagHelper *, MyComponentLibrary

Properties
Attribute	Type	Default	Description
target-date	DateTime	0001-01-01	Required. The future date and time to count down to.
timer-id	string	Random GUID	An optional prefix to use for the inner element IDs. If omitted, the Tag Helper will generate a random string to prevent JavaScript collisions.

Here is the implementation for the Countdown Timer.

Because countdown timers rely on element id attributes to update the DOM via JavaScript, I've added a unique ID generation step. This ensures that if you put multiple <rcl-countdown-timer> components on the same page, their scripts won't collide and overwrite each other. I also wrapped the generated JavaScript in an Immediately Invoked Function Expression (IIFE) to prevent polluting the global window scope with variables.
1. The Tag Helper Logic (CountdownTimerTagHelper.cs)
C#

using Microsoft.AspNetCore.Razor.TagHelpers;
using System;
using System.Threading.Tasks;

namespace MyComponentLibrary.TagHelpers
{
    [HtmlTargetElement("rcl-countdown-timer")]
    public class CountdownTimerTagHelper : TagHelper
    {
        // Accept a native C# DateTime object
        public DateTime TargetDate { get; set; }

        // Optional: Let developers specify an ID, otherwise auto-generate one
        public string TimerId { get; set; }

        public override void Process(TagHelperContext context, TagHelperOutput output)
        {
            // Strip the parent tag
            output.TagName = null;

            // Generate a unique ID if one wasn't provided
            var id = string.IsNullOrWhiteSpace(TimerId) 
                ? Guid.NewGuid().ToString("N").Substring(0, 6) 
                : TimerId;

            // Format date safely for JS parsing
            string jsDateString = TargetDate.ToString("MMM d, yyyy HH:mm:ss");

            string htmlContent = $@"
<div class=""row flex-column flex-md-row countdown p-x"">
  <div class=""col bg-gray-100 text-center p-b-md p-l-0 p-r-0"">
    <span class=""countdown-text""><abbr title=""weeks"" aria-label=""weeks"" class=""text-decoration-none"">wks</abbr><br /></span>
    <span id=""weeks_{id}""></span>
  </div>
  <div class=""col bg-gray-100 text-center p-b-md p-l-0 p-r-0"">
    <span class=""countdown-text"">days<br /></span>
    <span id=""days_{id}""></span>
  </div>
  <div class=""col bg-gray-100 text-center p-b-md p-l-0 p-r-0"">
    <span class=""countdown-text""><abbr title=""hours"" aria-label=""hours"" class=""text-decoration-none"">hrs</abbr><br /></span>
    <span id=""hours_{id}""></span>
  </div>
  <div class=""col bg-gray-100 text-center p-b-md p-l-0 p-r-0"">
    <span class=""countdown-text""><abbr title=""minutes"" aria-label=""minutes"" class=""text-decoration-none"">mins</abbr><br /></span>
    <span id=""minutes_{id}""></span>
  </div>
  <div class=""col bg-gray-100 text-center p-b-md p-l-0 p-r-0"">
    <span class=""countdown-text""><abbr title=""seconds"" aria-label=""seconds"" class=""text-decoration-none"">secs</abbr><br /></span>
    <span id=""seconds_{id}""></span>
  </div>
</div>

<script>
  (function() {{
      var countDownDate = new Date(""{jsDateString}"").getTime();
      var x = setInterval(function () {{
          var now = new Date().getTime();
          var distance = countDownDate - now;

          var weeks = Math.floor(distance / (1000 * 60 * 60 * 24 * 7));
          var days = Math.floor(distance / (1000 * 60 * 60 * 24));
          var hours = Math.floor((distance % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60));
          var minutes = Math.floor((distance % (1000 * 60 * 60)) / (1000 * 60));
          var seconds = Math.floor((distance % (1000 * 60)) / 1000);

          var weeksEl = document.getElementById(""weeks_{id}"");
          var daysEl = document.getElementById(""days_{id}"");
          var hoursEl = document.getElementById(""hours_{id}"");
          var minutesEl = document.getElementById(""minutes_{id}"");
          var secondsEl = document.getElementById(""seconds_{id}"");

          if(weeksEl) weeksEl.innerHTML = weeks;
          if(daysEl) daysEl.innerHTML = days;
          if(hoursEl) hoursEl.innerHTML = hours;
          if(minutesEl) minutesEl.innerHTML = minutes;
          if(secondsEl) secondsEl.innerHTML = seconds;

          if (distance < 0) {{
              clearInterval(x);
              if(daysEl) daysEl.innerHTML = ""EXPIRED"";
          }}
      }}, 1000);
  }})();
</script>";

            output.Content.SetHtmlContent(htmlContent);
        }
    }
}

2. Usage in your Views (.cshtml)

You can pass standard strings that C# can implicitly parse into DateTime, or pass explicit DateTime models.
HTML

<rcl-countdown-timer target-date="Jan 1, 2026 00:00:00"></rcl-countdown-timer>

<rcl-countdown-timer target-date="2026-12-31T23:59:59" timer-id="NewYearsEve"></rcl-countdown-timer>

<rcl-countdown-timer target-date="@Model.ProjectLaunchDate"></rcl-countdown-timer>

3. Documentation (README.md)
Countdown Timer Component (<rcl-countdown-timer>)

Renders a 5-column countdown timer (weeks, days, hours, minutes, seconds) and automatically injects the necessary scoped JavaScript to update it every second.
Setup

Ensure the Tag Helpers are registered in your _ViewImports.cshtml:
HTML

@addTagHelper *, MyComponentLibrary

Properties
Attribute	Type	Default	Description
target-date	DateTime	0001-01-01	Required. The future date and time to count down to.
timer-id	string	Random GUID	An optional prefix to use for the inner element IDs. If omitted, the Tag Helper will generate a random string to prevent JavaScript collisions.
Example
HTML

<rcl-countdown-timer target-date="2026-07-04 12:00:00"></rcl-countdown-timer>


# tests

using Microsoft.VisualStudio.TestTools.UnitTesting;
using Microsoft.AspNetCore.Razor.TagHelpers;
using MyComponentLibrary.TagHelpers;
using System.Collections.Generic;
using System;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc.Testing;
using System.Net.Http;
using MyComponentLibrary.TestHost; // Adjust to your test host app namespace

namespace MyComponentLibrary.Tests
{
    [TestClass]
    public class CountdownTimerTagHelpersTests
    {
        // --- Unit Tests ---

        private (TagHelperContext, TagHelperOutput) CreateTagHelperData()
        {
            var context = new TagHelperContext(
                tagName: "rcl-countdown-timer",
                allAttributes: new TagHelperAttributeList(),
                items: new Dictionary<object, object>(),
                uniqueId: "test");

            var output = new TagHelperOutput(
                "rcl-countdown-timer",
                new TagHelperAttributeList(),
                (useCachedResult, encoder) =>
                {
                    return Task.FromResult<TagHelperContent>(new DefaultTagHelperContent());
                });

            return (context, output);
        }

        [TestMethod]
        public void CountdownTimer_GeneratesRandomId_WhenTimerIdIsNull()
        {
            // Arrange
            var target = new DateTime(2026, 1, 1);
            var helper = new CountdownTimerTagHelper { TargetDate = target };
            var (context, output) = CreateTagHelperData();

            // Act
            helper.Process(context, output);
            var content = output.Content.GetContent();

            // Assert
            Assert.IsNull(output.TagName); // Ensure wrapper stripped
            
            // Check that it generated some kind of id for the spans
            StringAssert.Contains(content, "<span id=\"weeks_");
            
            // Check that the JS script was outputted
            StringAssert.Contains(content, "<script>");
            StringAssert.Contains(content, "(function() {");
        }

        [TestMethod]
        public void CountdownTimer_UsesProvidedId_WhenTimerIdIsSet()
        {
            // Arrange
            var target = new DateTime(2026, 1, 1);
            var helper = new CountdownTimerTagHelper { TargetDate = target, TimerId = "MyCustomTimer" };
            var (context, output) = CreateTagHelperData();

            // Act
            helper.Process(context, output);
            var content = output.Content.GetContent();

            // Assert
            StringAssert.Contains(content, "<span id=\"weeks_MyCustomTimer\"></span>");
            StringAssert.Contains(content, "document.getElementById(\"weeks_MyCustomTimer\")");
        }

        [TestMethod]
        public void CountdownTimer_FormatsDateCorrectlyForJavaScript()
        {
            // Arrange
            var target = new DateTime(2026, 12, 31, 23, 59, 59);
            var helper = new CountdownTimerTagHelper { TargetDate = target };
            var (context, output) = CreateTagHelperData();

            // Act
            helper.Process(context, output);
            var content = output.Content.GetContent();

            // Assert
            // The format JS expects is "Dec 31, 2026 23:59:59"
            StringAssert.Contains(content, "var countDownDate = new Date(\"Dec 31, 2026 23:59:59\").getTime();");
        }
    }

    [TestClass]
    public class CountdownTimerIntegrationTests
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
        public async Task CountdownTimer_RendersCorrectHtml_OnPage()
        {
            // Act
            // Assume test page has: <rcl-countdown-timer target-date="2026-01-01" timer-id="IntTest"></rcl-countdown-timer>
            var response = await _client.GetAsync("/CountdownTestPage");
            response.EnsureSuccessStatusCode();

            var responseString = await response.Content.ReadAsStringAsync();

            // Assert
            StringAssert.Contains(responseString, "class=\"row flex-column flex-md-row countdown p-x\"");
            StringAssert.Contains(responseString, "id=\"weeks_IntTest\"");
            StringAssert.Contains(responseString, "Math.floor(distance /");
        }
    }
}


###########################################



:::rcl-countdown targetdate="2026-12-31 23:59:00" timerid="launchTimer" :::

2. The Implementation

We will extract the HTML/JS logic into the builder, and add a parser that gracefully handles invalid date formats so the page doesn't crash if a user typos the date.
Step 1: The Countdown Timer HTML Builder

This is a direct port of your TagHelper logic. Note that since we are using C# string interpolation ($@""), the curly braces for the JavaScript functions must be escaped using double braces ({{ and }}).
C#

using System;

public static class CountdownTimerHtmlBuilder
{
    public static string Build(DateTime targetDate, string timerId)
    {
        string id = string.IsNullOrWhiteSpace(timerId) 
            ? Guid.NewGuid().ToString("N").Substring(0, 6) 
            : timerId;

        string jsDateString = targetDate.ToString("MMM d, yyyy HH:mm:ss");

        return $@"
<div class=""row flex-column flex-md-row countdown p-x"">
  <div class=""col bg-gray-100 text-center p-b-md p-l-0 p-r-0"">
    <span class=""countdown-text""><abbr title=""weeks"" aria-label=""weeks"" class=""text-decoration-none"">wks</abbr><br /></span>
    <span id=""weeks_{id}""></span>
  </div>
  <div class=""col bg-gray-100 text-center p-b-md p-l-0 p-r-0"">
    <span class=""countdown-text"">days<br /></span>
    <span id=""days_{id}""></span>
  </div>
  <div class=""col bg-gray-100 text-center p-b-md p-l-0 p-r-0"">
    <span class=""countdown-text""><abbr title=""hours"" aria-label=""hours"" class=""text-decoration-none"">hrs</abbr><br /></span>
    <span id=""hours_{id}""></span>
  </div>
  <div class=""col bg-gray-100 text-center p-b-md p-l-0 p-r-0"">
    <span class=""countdown-text""><abbr title=""minutes"" aria-label=""minutes"" class=""text-decoration-none"">mins</abbr><br /></span>
    <span id=""minutes_{id}""></span>
  </div>
  <div class=""col bg-gray-100 text-center p-b-md p-l-0 p-r-0"">
    <span class=""countdown-text""><abbr title=""seconds"" aria-label=""seconds"" class=""text-decoration-none"">secs</abbr><br /></span>
    <span id=""seconds_{id}""></span>
  </div>
</div>

<script>
  (function() {{
      var countDownDate = new Date(""{jsDateString}"").getTime();
      var x = setInterval(function () {{
          var now = new Date().getTime();
          var distance = countDownDate - now;

          var weeks = Math.floor(distance / (1000 * 60 * 60 * 24 * 7));
          var days = Math.floor(distance / (1000 * 60 * 60 * 24));
          var hours = Math.floor((distance % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60));
          var minutes = Math.floor((distance % (1000 * 60 * 60)) / (1000 * 60));
          var seconds = Math.floor((distance % (1000 * 60)) / 1000);

          var weeksEl = document.getElementById(""weeks_{id}"");
          var daysEl = document.getElementById(""days_{id}"");
          var hoursEl = document.getElementById(""hours_{id}"");
          var minutesEl = document.getElementById(""minutes_{id}"");
          var secondsEl = document.getElementById(""seconds_{id}"");

          if(weeksEl) weeksEl.innerHTML = weeks;
          if(daysEl) daysEl.innerHTML = days;
          if(hoursEl) hoursEl.innerHTML = hours;
          if(minutesEl) minutesEl.innerHTML = minutes;
          if(secondsEl) secondsEl.innerHTML = seconds;

          if (distance < 0) {{
              clearInterval(x);
              if(daysEl) daysEl.innerHTML = ""EXPIRED"";
          }}
      }}, 1000);
  }})();
</script>";
    }
}

Step 2: The Regex Parser

Add this pattern and method to your MarkdownComponentParser. We use DateTime.TryParse here so that if a content editor accidentally types targetdate="next tuesday", it won't crash the .NET server—it will just default to 30 days from now.
C#

using System.Text.RegularExpressions;
using System.Collections.Generic;
using System;

public partial class MarkdownComponentParser
{
    // Match the single-line block: :::rcl-countdown [attributes] :::
    [GeneratedRegex(@":::rcl-countdown[ \t]+(.*?):::", RegexOptions.IgnoreCase)]
    private static partial Regex RclCountdownRegex();

    // Your existing AttributeRegex() is reused here

    public static string ProcessCountdownTimers(string rawMarkdown)
    {
        return RclCountdownRegex().Replace(rawMarkdown, match =>
        {
            string attributesString = match.Groups[1].Value;

            // 1. Parse attributes
            var attributes = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
            foreach (Match attrMatch in AttributeRegex().Matches(attributesString))
            {
                attributes[attrMatch.Groups[1].Value] = attrMatch.Groups[2].Value;
            }

            // 2. Extract values
            string timerId = attributes.GetValueOrDefault("timerid", string.Empty);
            string targetDateStr = attributes.GetValueOrDefault("targetdate", string.Empty);

            // 3. Parse the Date safely
            if (!DateTime.TryParse(targetDateStr, out DateTime targetDate))
            {
                // Fallback: If they mess up the date format, set it 30 days in the future
                // so the component at least renders on the page for debugging.
                targetDate = DateTime.Now.AddDays(30);
            }

            // 4. Build and return the HTML
            return CountdownTimerHtmlBuilder.Build(targetDate, timerId);
        });
    }
}

Step 3: Wire it into the Pipeline

Add the new countdown processor to your chain.
C#

string processedContent = MarkdownComponentParser.ProcessCards(rawMarkdown);
processedContent = MarkdownComponentParser.ProcessButtons(processedContent);
processedContent = MarkdownComponentParser.ProcessTabs(processedContent);
processedContent = MarkdownComponentParser.ProcessBlockquotes(processedContent);
processedContent = MarkdownComponentParser.ProcessModals(processedContent);
processedContent = MarkdownComponentParser.ProcessCountdownTimers(processedContent); // <--- Add Countdown here

string finalHtml = markdownToHtml(processedContent);