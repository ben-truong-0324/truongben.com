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