Models folder.
C#

public class Article
{
    public string Title { get; set; } = string.Empty;
    public DateTime Date { get; set; }
    public string Href { get; set; } = "javascript:;";
    public string Category { get; set; } = "Press release";
}

2. The Data Query Logic

In your PageModel (Index.cshtml.cs) or Controller, you need to read the JSON and group it by Month/Year.
C#

using System.Text.Json;

// ... Inside your PageModel ...

public List<IGrouping<string, Article>> GroupedArticles { get; set; } = new();

public async Task OnGetAsync()
{
    var filePath = Path.Combine(Directory.GetCurrentDirectory(), "AppData", "_ListOfArticles.json");
    
    if (File.Exists(filePath))
    {
        var jsonData = await File.ReadAllTextAsync(filePath);
        var articles = JsonSerializer.Deserialize<List<Article>>(jsonData, new JsonSerializerOptions 
        { 
            PropertyNameCaseInsensitive = true 
        }) ?? new List<Article>();

        // Query: Sort by date, then group by "Month Year" (e.g., "May 2024")
        GroupedArticles = articles
            .OrderByDescending(a => a.Date)
            .GroupBy(a => a.Date.ToString("MMMM yyyy"))
            .ToList();
    }
}

3. The Razor View

This replaces your static HTML. It uses a nested loop: the outer loop creates the <h2> headers, and the inner loop renders the articles.
Razor CSHTML

@model IndexModel

<div class="col-lg-8 col-xl-9">
    <h1 class="m-t-0">@ViewData["Title"]</h1>

    @if (Model.GroupedArticles != null && Model.GroupedArticles.Any())
    {
        @foreach (var monthGroup in Model.GroupedArticles)
        {
            <h2>@monthGroup.Key</h2>
            <hr class="m-y-md" />

            @foreach (var article in monthGroup)
            {
                <h3 class="lead font-weight-700">
                    <a href="@article.Href">@article.Title</a>
                </h3>
                <p>@article.Date.ToString("MMMM dd, yyyy") | @article.Category</p>
                
                @if (article != monthGroup.Last())
                {
                    <hr class="m-y-md" />
                }
            }
            
            @if (monthGroup != Model.GroupedArticles.Last())
            {
                <div class="m-b-lg"></div>
            }
        }
    }
    else
    {
        <p>No articles found.</p>
    }

    <hr class="m-y-lg" />
    
    <cagov-pagination 
        data-current-page="1" 
        data-total-pages="10">
    </cagov-pagination>
</div>

4. The JSON Structure (AppData/_ListOfArticles.json)

Your non-technical users just need to maintain this format. It is very forgiving:
JSON

[
  {
    "Title": "California state department announces plans for upcoming important initiative",
    "Date": "2024-05-20",
    "Href": "/news/important-initiative",
    "Category": "Press release"
  },
  {
    "Title": "Experts Provide Insights on Climate Remediation",
    "Date": "2024-05-15",
    "Href": "/news/climate-insights",
    "Category": "Press release"
  },
  {
    "Title": "Discussion Continues Regarding California’s Project Funding",
    "Date": "2024-04-10",
    "Href": "/news/funding-discussion",
    "Category": "Press release"
  }
]



###################

The C# Model and Parsing Logic
C#

using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text.Json;

namespace YourApp.Models
{
    // The model representing a single item in the JSON array
    public class ArticleItem
    {
        public string Title { get; set; }
        public DateTime Date { get; set; }
        public string Href { get; set; }
        public string Category { get; set; }
    }

    public class ArticleArchiveModel
    {
        /// <summary>
        /// Reads the JSON array, orders the articles by date (newest first), 
        /// and groups them by Year.
        /// </summary>
        public static Dictionary<int, List<ArticleItem>> GetGroupedListOfArticles(string filePath)
        {
            if (!File.Exists(filePath))
            {
                return new Dictionary<int, List<ArticleItem>>();
            }

            try
            {
                string jsonContent = File.ReadAllText(filePath);
                
                var options = new JsonSerializerOptions
                {
                    PropertyNameCaseInsensitive = true
                };

                var articles = JsonSerializer.Deserialize<List<ArticleItem>>(jsonContent, options) 
                               ?? new List<ArticleItem>();

                // Group by Year, ensuring the newest articles and newest years are first
                var groupedArticles = articles
                    .OrderByDescending(a => a.Date)
                    .GroupBy(a => a.Date.Year)
                    .ToDictionary(
                        group => group.Key, 
                        group => group.ToList()
                    );

                return groupedArticles;
            }
            catch (JsonException ex)
            {
                // Handle or log parsing errors
                return new Dictionary<int, List<ArticleItem>>();
            }
        }
    }
}

How to consume it in your Razor View

Because the return type is a Dictionary<int, List<ArticleItem>>, iterating over it in your .cshtml file is very straightforward. The dictionary Key will be the Year, and the Value will be the list of articles for that year.
HTML

@model ArticleArchivePageModel

<div class="col-lg-8 col-xl-9">
    <h1 class="m-t-0">Press Releases Archive</h1>

    @if (Model.GroupedArticles != null && Model.GroupedArticles.Any())
    {
        @foreach (var yearGroup in Model.GroupedArticles)
        {
            <div class="m-t-lg">
                <h2 class="h3 brd-bottom-1 brd-gray-300 p-b-sm">@yearGroup.Key</h2>
                
                <ul class="list-unstyled m-t-md">
                    @foreach (var article in yearGroup.Value)
                    {
                        <li class="m-b-md">
                            <h3 class="h5 m-b-0">
                                <a href="@article.Href">@article.Title</a>
                            </h3>
                            <p class="text-muted small m-t-xs">
                                @article.Date.ToString("MMMM dd, yyyy") | @article.Category
                            </p>
                        </li>
                    }
                </ul>
            </div>
        }
    }
    else
    {
        <p>No articles found.</p>
    }
</div>