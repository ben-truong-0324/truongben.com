Models folder. I've added an ImageUrl and Description to support the featured layouts.
C#

public class NewsArticle
{
    public string Title { get; set; } = string.Empty;
    public DateTime Date { get; set; }
    public string Href { get; set; } = "javascript:;";
    public string Category { get; set; } = "Press release";
    public string ImageUrl { get; set; } = "/images/sample/images/default-news.png";
    public string Description { get; set; } = string.Empty;
}

public class NewsroomViewModel
{
    public NewsArticle? Hero { get; set; }
    public List<NewsArticle> Featured { get; set; } = new();
    public List<NewsArticle> Latest { get; set; } = new();
}

2. The Data Query Logic

In your Newsroom.cshtml.cs, we load both files. We'll treat the first item in the featured list as our "Hero" banner.
C#

using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text.Json;
using System.Text.Json.Serialization;

namespace YourApp.Models 
{
    public class NewsroomPageModel
    {
        [JsonPropertyName("hero")]
        public NewsItem Hero { get; set; }

        [JsonPropertyName("featured")]
        public List<NewsItem> Featured { get; set; } = new();

        [JsonPropertyName("latest")]
        public List<NewsItem> Latest { get; set; } = new();

        /// <summary>
        /// Reads and parses the _Newsroom.json file into the view model.
        /// </summary>
        public static NewsroomPageModel GetNewsroom(string filePath)
        {
            if (!File.Exists(filePath))
            {
                return new NewsroomPageModel(); // Return empty model to prevent NullReferenceExceptions in the view
            }

            try
            {
                string jsonContent = File.ReadAllText(filePath);
                
                var options = new JsonSerializerOptions
                {
                    PropertyNameCaseInsensitive = true
                };

                return JsonSerializer.Deserialize<NewsroomPageModel>(jsonContent, options) 
                       ?? new NewsroomPageModel();
            }
            catch (JsonException ex)
            {
                // Handle parsing errors (e.g., log the exception)
                return new NewsroomPageModel();
            }
        }
    }

    public class NewsItem
    {
        [JsonPropertyName("id")]
        public string Id { get; set; }

        [JsonPropertyName("title")]
        public string Title { get; set; }

        [JsonPropertyName("slug")]
        public string Slug { get; set; }

        [JsonPropertyName("excerpt")]
        public string Excerpt { get; set; }

        [JsonPropertyName("imageUrl")]
        public string ImageUrl { get; set; }

        // Maps the JSON 'publishDate' directly to the Razor view's 'Date' property
        [JsonPropertyName("publishDate")]
        public DateTime Date { get; set; }

        [JsonPropertyName("tags")]
        public List<string> Tags { get; set; } = new();

        // --- Computed Properties for the Razor View ---

        // Generates the URL path using the slug. Adjust the base route as needed.
        [JsonIgnore]
        public string Href => $"/newsroom/{(string.IsNullOrWhiteSpace(Slug) ? Id : Slug)}";

        // Grabs the first tag to act as the primary category for the UI, defaults if empty
        [JsonIgnore]
        public string Category => Tags != null && Tags.Any() ? Tags.First() : "News";
    }
}


3. The Razor View

This view follows your State Design System structure exactly, using the JSON data to populate the fields.
Razor CSHTML

@model NewsroomPageModel

<div class="col-lg-8 col-xl-9">
    <h1 class="m-t-0">Newsroom</h1>

    @if (Model.Hero != null)
    {
        <h2>Featured</h2>
        <div class="container p-0">
            <div class="row brd-solid-1 brd-gray-200 bg-gray-50-hover mx-0">
                <div class="col-lg-8 col-md-6 p-0 text-right d-flex justify-content-center">
                    <a href="@Model.Hero.Href"
                       class="feature-img w-100"
                       style="background: url('@Model.Hero.ImageUrl'); background-size: cover; min-height: 250px;"
                       aria-label="@Model.Hero.Title"></a>
                </div>
                <div class="col-md-6 col-lg-4 p-a-md">
                    <h2 class="h4 m-t-0">
                        <a href="@Model.Hero.Href">@Model.Hero.Title</a>
                    </h2>
                    <p>@Model.Hero.Date.ToString("MMMM dd, yyyy") | @Model.Hero.Category</p>
                </div>
            </div>
        </div>
    }

    @if (Model.Featured.Any())
    {
        <article class="news-item m-t-md">
            @foreach (var item in Model.Featured)
            {
                <div class="row py-1">
                    <div class="col-md-4">
                        <img src="@item.ImageUrl" class="img-fluid" alt="@item.Title" />
                    </div>
                    <div class="col-md-8">
                        <h3 class="h4 mb-2">
                            <a href="@item.Href">@item.Title</a>
                        </h3>
                        <p>@item.Date.ToString("MMMM dd, yyyy") | @item.Category</p>
                    </div>
                </div>
                <hr />
            }
        </article>
    }

    <div class="row m-t-lg">
        <div class="col-md-6 mb-4">
            <div class="brd-gray-200 brd-solid-1 rounded-5 h-100 transition-0_3 shadow2-hover bg-white bg-gray-75-hover pos-rel p-a-md">
                <h3 class="h5 m-t-0">
                    <a href="/subscribe" class="link-before no-underline">Subscribe for updates</a>
                </h3>
                <p class="font-size-16 color-black">Keep up-to-date on our latest updates. Sign up for email notifications.</p>
            </div>
        </div>
        <div class="col-md-6 mb-4">
            <div class="brd-gray-200 brd-solid-1 rounded-5 h-100 transition-0_3 shadow2-hover bg-white bg-gray-75-hover pos-rel p-a-md">
                <h3 class="h5 m-t-0">
                    <a href="/blog" class="link-before no-underline">Department Blog</a>
                </h3>
                <p class="font-size-16 color-black">Insights and stories from our team across California.</p>
            </div>
        </div>
    </div>

    <h2 class="h3">Latest news</h2>
    <hr class="m-y-md" />
    @foreach (var news in Model.Latest.OrderByDescending(x => x.Date))
    {
        <h3 class="lead font-weight-700">
            <a href="@news.Href">@news.Title</a>
        </h3>
        <p>@news.Date.ToString("MMMM dd, yyyy") | @news.Category</p>
        <hr class="m-y-md" />
    }
</div>

4. Sample JSON (AppData/FeaturedNews.json)


{
  "hero": {
    "id": "e4b3d2a1-1234-5678-9abc-def012345678",
    "title": "Deploying Secure LLM Architectures in the Public Sector",
    "slug": "deploying-secure-llm-public-sector",
    "excerpt": "A deep dive into implementing dynamic security policies to defend against prompt injection in enterprise-grade RAG pipelines.",
    "author": "System Administrator",
    "publishDate": "2026-04-22T14:30:00Z",
    "imageUrl": "/images/news/secure-llm-hero.jpg",
    "tags": ["AI Security", "RAG", "Enterprise Architecture"]
  },
  "featured": [
    {
      "id": "a1b2c3d4-8765-4321-cba9-876543210fed",
      "title": "Migrating Markdown Metadata to YAML Frontmatter",
      "slug": "migrating-markdown-metadata-yaml",
      "excerpt": "Best practices for refactoring legacy HTML comments into standard YAML frontmatter for improved parsing.",
      "author": "Content Team",
      "publishDate": "2026-04-18T09:15:00Z",
      "imageUrl": "/images/news/markdown-yaml-feat.jpg",
      "tags": ["Development", "Documentation", "Best Practices"]
    },
    {
      "id": "f8e7d6c5-2468-1357-aceg-246813579bdf",
      "title": "Q3 Infrastructure Upgrades Completed",
      "slug": "q3-infrastructure-upgrades",
      "excerpt": "Our latest migration to Kubernetes has resulted in a 40% reduction in deployment times across all microservices.",
      "author": "DevOps Team",
      "publishDate": "2026-04-10T11:00:00Z",
      "imageUrl": "/images/news/infrastructure-q3.jpg",
      "tags": ["DevOps", "Kubernetes", "Infrastructure"]
    }
  ],
  "latest": [
    {
      "id": "b2c3d4e5-1122-3344-5566-778899aabbcc",
      "title": "New Tooling Available for Automated Testing",
      "slug": "new-automated-testing-tooling",
      "excerpt": "We are rolling out new MSTest suites for our web applications. Here is what you need to know.",
      "author": "QA Department",
      "publishDate": "2026-04-20T08:00:00Z",
      "imageUrl": null,
      "tags": ["Testing", "QA", "Releases"]
    },
    {
      "id": "c3d4e5f6-9988-7766-5544-33221100ffee",
      "title": "Upcoming Maintenance Window: Database Migrations",
      "slug": "upcoming-maintenance-database-migrations",
      "excerpt": "Scheduled downtime for primary databases will occur this Saturday at 02:00 PST.",
      "author": "Database Administration",
      "publishDate": "2026-04-19T16:45:00Z",
      "imageUrl": "/images/news/db-maintenance.jpg",
      "tags": ["Maintenance", "Database"]
    }
  ]
}