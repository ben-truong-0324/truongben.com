# tag

using Microsoft.AspNetCore.Razor.TagHelpers;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace MyComponentLibrary.TagHelpers
{
    public enum NewsVariant
    {
        List,
        ListFeatured,
        Block,
        Card,
        FeaturedBanner
    }

    [HtmlTargetElement("rcl-news-item")]
    public class NewsItemTagHelper : TagHelper
    {
        public NewsVariant Variant { get; set; } = NewsVariant.List;

        // Core Properties
        public string Title { get; set; } = string.Empty;
        public string Href { get; set; } = "javascript:;";
        
        // Metadata
        public string Date { get; set; } = string.Empty;
        public string Category { get; set; } = string.Empty; // e.g., "Press release" or "News"
        public string Author { get; set; } = string.Empty; // Only used in Block variant
        public string Agency { get; set; } = string.Empty; // Only used in Block variant
        
        // Image Properties
        public string ImageSrc { get; set; } = string.Empty;
        public string ImageAlt { get; set; } = string.Empty;

        public override async Task ProcessAsync(TagHelperContext context, TagHelperOutput output)
        {
            output.TagName = null; // Strip the outer tag
            
            var childContent = await output.GetChildContentAsync();
            var content = childContent.GetContent();

            // Safely combine Date and Category for list/banner views (e.g., "Month 00, 0000 | Press release")
            var metaParts = new List<string>();
            if (!string.IsNullOrWhiteSpace(Date)) metaParts.Add(Date);
            if (!string.IsNullOrWhiteSpace(Category)) metaParts.Add(Category);
            string combinedMeta = string.Join(" | ", metaParts);
            string metaHtml = string.IsNullOrWhiteSpace(combinedMeta) ? "" : $"<p>{combinedMeta}</p>";

            if (Variant == NewsVariant.Block)
            {
                // Author and Agency logic for the Block variant
                string authorHtml = string.IsNullOrWhiteSpace(Author) ? "" 
                    : $@"<li class=""list-inline-item""><span class=""color-gray"">By:</span> <span class=""color-gray-dark color-primary-hover"">{Author}</span></li>";
                string agencyHtml = string.IsNullOrWhiteSpace(Agency) ? "" 
                    : $@"<li class=""list-inline-item""><span class=""color-gray"">In:</span> <span class=""color-gray-dark color-primary-hover"">{Agency}</span></li>";
                
                string metaListHtml = (string.IsNullOrWhiteSpace(authorHtml) && string.IsNullOrWhiteSpace(agencyHtml)) ? "" 
                    : $@"<ul class=""list-inline small m-y-0"">{authorHtml}{agencyHtml}</ul>";

                string dateBadgeHtml = string.IsNullOrWhiteSpace(Date) ? "" 
                    : $@"<figcaption class=""pos-abs top-sm p-l-0 rounded-3""><span class=""btn btn-sm btn-standout rounded-0"">{Date}</span></figcaption>";

                output.Content.SetHtmlContent($@"
                    <article class=""bg-gray-50-hover p-b-md brd-solid-1 brd-gray-light pos-rel h-100"">
                        <figure class=""pos-rel m-b-0"">
                            <img class=""img-fluid w-100"" src=""{ImageSrc}"" alt=""{ImageAlt}"" />
                            {dateBadgeHtml}
                        </figure>
                        <div class=""p-a"">
                            {metaListHtml}
                            <h3 class=""h4 m-t-0 m-b-sm"">
                                <a class=""u-link-v5 color-gray-dark color-primary-hover link-before no-underline"" href=""{Href}"">{Title}</a>
                            </h3>
                            <p>{content}</p>
                        </div>
                    </article>");
            }
            else if (Variant == NewsVariant.Card)
            {
                string dateHtml = string.IsNullOrWhiteSpace(Date) ? "" : $"<p class=\"font-size-16 color-black mb-1\">{Date}</p>";
                output.Content.SetHtmlContent($@"
                    <div class=""brd-gray-200 brd-solid-1 rounded-5 h-100 transition-0_3 shadow2-hover bg-white bg-gray-75-hover pos-rel p-a-md"">
                        <h3 class=""h5 m-t-0"">
                            <a href=""{Href}"" class=""link-before no-underline"">{Title}</a>
                        </h3>
                        {dateHtml}
                        <p class=""font-size-16 color-black m-0"">{content}</p>
                    </div>");
            }
            else if (Variant == NewsVariant.FeaturedBanner)
            {
                output.Content.SetHtmlContent($@"
                    <div class=""row brd-solid-1 brd-gray-200 bg-gray-50-hover mb-4"">
                        <div class=""col-lg-8 col-md-6 p-0 text-right d-flex justify-content-center"">
                            <a href=""{Href}"" class=""feature-img"" style=""background: url('{ImageSrc}')"" aria-label=""{ImageAlt}""></a>
                        </div>
                        <div class=""col-md

# cshtml

<h2 class="h3">Latest news</h2>
<hr class="m-y-md" />
<rcl-news-item variant="List" title="Local Entity Implements Changes" date="June 12, 2026" category="News" href="/news/1"></rcl-news-item>
<rcl-news-item variant="List" title="Significant Agreement Reached" date="June 10, 2026" category="News" href="/news/2"></rcl-news-item>

<article class="news-item">
    <rcl-news-item variant="ListFeatured" title="State Dept Announces Plans" date="May 01, 2026" category="Press release" image-src="/img1.png" image-alt="Meeting"></rcl-news-item>
</article>

<div class="row">
    <div class="col-md-4 m-b-md">
        <rcl-news-item variant="Block" title="Climate Remediation" date="Apr 15, 2026" author="Jane Doe" agency="Dept of Ecology" image-src="/img2.jpg" image-alt="Forest">
            Briefly tell your reader what they will find at the card's destination.
        </rcl-news-item>
    </div>
</div>

<div class="row m-t-lg">
    <div class="col-md-6 mb-4">
        <rcl-news-item variant="Card" title="Blog post title" date="March 05, 2026" href="/blog/1">
            Short 1 - 2 sentence description promoting this blog post.
        </rcl-news-item>
    </div>
</div>

<h2>Featured</h2>
<rcl-news-item variant="FeaturedBanner" title="California announces new initiative" date="Feb 20, 2026" category="Press release" image-src="/featured.png" image-alt="Capitol building"></rcl-news-item>

# docs

3. Documentation (README.md)
News Item Component (<rcl-news-item>)

A highly versatile Tag Helper that renders news articles, press releases, and blog posts in five distinct layouts.
Setup

Ensure the Tag Helpers are registered in your _ViewImports.cshtml:
HTML

@addTagHelper *, MyComponentLibrary

Properties

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
    public class NewsItemTagHelpersTests
    {
        // --- Unit Tests ---
        private (TagHelperContext, TagHelperOutput) CreateTagHelperData(string content = "")
        {
            var context = new TagHelperContext(
                tagName: "rcl-news-item",
                allAttributes: new TagHelperAttributeList(),
                items: new Dictionary<object, object>(),
                uniqueId: "test");

            var output = new TagHelperOutput(
                "rcl-news-item",
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
        public async Task NewsItem_ListVariant_RendersCorrectly()
        {
            // Arrange
            var helper = new NewsItemTagHelper { Variant = NewsVariant.List, Title = "Test Title", Date = "Jan 1, 2026", Category = "News", Href = "/test" };
            var (context, output) = CreateTagHelperData();

            // Act
            await helper.ProcessAsync(context, output);
            var content = output.Content.GetContent();

            // Assert
            Assert.IsNull(output.TagName);
            StringAssert.Contains(content, "<h3 class=\"lead font-weight-700\">");
            StringAssert.Contains(content, "<a href=\"/test\">Test Title</a>");
            StringAssert.Contains(content, "<p>Jan 1, 2026 | News</p>");
            StringAssert.Contains(content, "<hr class=\"m-y-md\" />");
        }

        [TestMethod]
        public async Task NewsItem_BlockVariant_RendersImageAndMeta()
        {
            // Arrange
            var helper = new NewsItemTagHelper 
            { 
                Variant = NewsVariant.Block, 
                Title = "Block Title", 
                Author = "John Doe",
                Agency = "Dept X",
                ImageSrc = "/img.jpg"
            };
            var (context, output) = CreateTagHelperData("Block Description");

            // Act
            await helper.ProcessAsync(context, output);
            var content = output.Content.GetContent();

            // Assert
            StringAssert.Contains(content, "<article class=\"bg-gray-50-hover p-b-md brd-solid-1 brd-gray-light pos-rel h-100\">");
            StringAssert.Contains(content, "src=\"/img.jpg\"");
            StringAssert.Contains(content, "<span class=\"color-gray-dark color-primary-hover\">John Doe</span>");
            StringAssert.Contains(content, "<span class=\"color-gray-dark color-primary-hover\">Dept X</span>");
            StringAssert.Contains(content, "Block Description");
        }

        [TestMethod]
        public async Task NewsItem_FeaturedBannerVariant_RendersRowAndBackground()
        {
            // Arrange
            var helper = new NewsItemTagHelper 
            { 
                Variant = NewsVariant.FeaturedBanner, 
                Title = "Banner Title",
                ImageSrc = "/bg.png",
                ImageAlt = "Banner Image"
            };
            var (context, output) = CreateTagHelperData();

            // Act
            await helper.ProcessAsync(context, output);
            var content = output.Content.GetContent();

            // Assert
            StringAssert.Contains(content, "<div class=\"row brd-solid-1 brd-gray-200 bg-gray-50-hover mb-4\">");
            StringAssert.Contains(content, "style=\"background: url('/bg.png')\"");
            StringAssert.Contains(content, "aria-label=\"Banner Image\"");
            StringAssert.Contains(content, "<a href=\"javascript:;\">Banner Title</a>");
        }

        [TestMethod]
        public async Task NewsItem_MetaConcatenation_HandlesMissingValues()
        {
            // Arrange (Missing Category)
            var helper = new NewsItemTagHelper { Variant = NewsVariant.ListFeatured, Title = "Test", Date = "Feb 2026" };
            var (context, output) = CreateTagHelperData();

            // Act
            await helper.ProcessAsync(context, output);
            var content = output.Content.GetContent();

            // Assert
            StringAssert.Contains(content, "<p>Feb 2026</p>"); // No trailing pipe
            Assert.IsFalse(content.Contains("|"));
        }
    }

    [TestClass]
    public class NewsItemIntegrationTests
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
        public async Task NewsItem_RendersCorrectHtml_OnPage()
        {
            // Act
            // Assume page has: <rcl-news-item variant="Card" title="Int Test Title" date="Int Date">Card Content</rcl-news-item>
            var response = await _client.GetAsync("/NewsTestPage");
            response.EnsureSuccessStatusCode();

            var responseString = await response.Content.ReadAsStringAsync();

            // Assert
            StringAssert.Contains(responseString, "brd-gray-200 brd-solid-1 rounded-5 h-100 transition-0_3");
            StringAssert.Contains(responseString, "Int Test Title");
            StringAssert.Contains(responseString, "Int Date");
            StringAssert.Contains(responseString, "Card Content");
        }
    }
}