# tag

using Microsoft.AspNetCore.Razor.TagHelpers;

namespace MyComponentLibrary.TagHelpers
{
    public enum TableVariant
    {
        Basic,
        Default,
        Striped
    }

    [HtmlTargetElement("rcl-table")]
    public class TableTagHelper : TagHelper
    {
        public TableVariant Variant { get; set; } = TableVariant.Basic;

        public override void Process(TagHelperContext context, TagHelperOutput output)
        {
            // Transform the custom tag into a standard HTML table
            output.TagName = "table";

            // Determine the appropriate CSS classes
            string cssClass = "table";
            
            if (Variant == TableVariant.Default)
            {
                cssClass += " table-default";
            }
            else if (Variant == TableVariant.Striped)
            {
                cssClass += " table-striped";
            }

            // Apply the classes
            output.Attributes.SetAttribute("class", cssClass);
        }
    }
}


# cshtml

<rcl-table variant="Basic">
  <thead>
    <tr>
      <th scope="col">#</th>
      <th scope="col">First Name</th>
      <th scope="col">Last Name</th>
      <th scope="col">Username</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>1</td>
      <td>Alpha</td>
      <td>One</td>
      <td>@alphaone</td>
    </tr>
  </tbody>
</rcl-table>

<rcl-table variant="Default">
  <thead>
    <tr>
      <th scope="col">#</th>
      <th scope="col">First Name</th>
      <th scope="col">Last Name</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>2</td>
      <td>Beta</td>
      <td>Two</td>
    </tr>
  </tbody>
</rcl-table>

<rcl-table variant="Striped">
  <thead>
    <tr>
      <th scope="col">#</th>
      <th scope="col">First Name</th>
      <th scope="col">Last Name</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>3</td>
      <td>Charlie</td>
      <td>Three</td>
    </tr>
    <tr>
      <td>4</td>
      <td>Delta</td>
      <td>Four</td>
    </tr>
  </tbody>
</rcl-table>

# docs

Table Component (<rcl-table>)

A wrapper component that styles standard HTML tables according to the California state template guidelines.
Setup

Ensure the Tag Helpers are registered in your _ViewImports.cshtml:
HTML

@addTagHelper *, MyComponentLibrary

Properties
Attribute	Type	Default	Description
variant	TableVariant	Basic	Dictates the visual style of the table. Options: Basic, Default, Striped.

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
    public class TableTagHelpersTests
    {
        // --- Unit Tests ---
        private (TagHelperContext, TagHelperOutput) CreateTagHelperData()
        {
            var context = new TagHelperContext(
                tagName: "rcl-table",
                allAttributes: new TagHelperAttributeList(),
                items: new Dictionary<object, object>(),
                uniqueId: "test");

            var output = new TagHelperOutput(
                "rcl-table",
                new TagHelperAttributeList(),
                (useCachedResult, encoder) =>
                {
                    return Task.FromResult<TagHelperContent>(new DefaultTagHelperContent());
                });

            return (context, output);
        }

        [TestMethod]
        public void Table_BasicVariant_RendersBaseClass()
        {
            // Arrange
            var helper = new TableTagHelper { Variant = TableVariant.Basic };
            var (context, output) = CreateTagHelperData();

            // Act
            helper.Process(context, output);

            // Assert
            Assert.AreEqual("table", output.TagName);
            Assert.AreEqual("table", output.Attributes["class"].Value);
        }

        [TestMethod]
        public void Table_DefaultVariant_AppendsDefaultClass()
        {
            // Arrange
            var helper = new TableTagHelper { Variant = TableVariant.Default };
            var (context, output) = CreateTagHelperData();

            // Act
            helper.Process(context, output);

            // Assert
            Assert.AreEqual("table", output.TagName);
            Assert.AreEqual("table table-default", output.Attributes["class"].Value);
        }

        [TestMethod]
        public void Table_StripedVariant_AppendsStripedClass()
        {
            // Arrange
            var helper = new TableTagHelper { Variant = TableVariant.Striped };
            var (context, output) = CreateTagHelperData();

            // Act
            helper.Process(context, output);

            // Assert
            Assert.AreEqual("table", output.TagName);
            Assert.AreEqual("table table-striped", output.Attributes["class"].Value);
        }
    }

    [TestClass]
    public class TableIntegrationTests
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
        public async Task Table_RendersCorrectHtml_OnPage()
        {
            // Act
            // Assume page has: <rcl-table variant="Striped"><tbody><tr><td>Int Test</td></tr></tbody></rcl-table>
            var response = await _client.GetAsync("/TableTestPage");
            response.EnsureSuccessStatusCode();

            var responseString = await response.Content.ReadAsStringAsync();

            // Assert
            StringAssert.Contains(responseString, "<table class=\"table table-striped\">");
            StringAssert.Contains(responseString, "<tbody>");
            StringAssert.Contains(responseString, "<td>Int Test</td>");
        }
    }
}