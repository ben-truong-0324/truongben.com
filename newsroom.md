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

using System.Text.Json;

public NewsroomViewModel ViewModel { get; set; } = new();

public async Task OnGetAsync()
{
    var options = new JsonSerializerOptions { PropertyNameCaseInsensitive = true };
    
    // Load Featured News
    var featuredPath = Path.Combine(Directory.GetCurrentDirectory(), "AppData", "FeaturedNews.json");
    if (File.Exists(featuredPath))
    {
        var featuredData = await File.ReadAllTextAsync(featuredPath);
        var allFeatured = JsonSerializer.Deserialize<List<NewsArticle>>(featuredData, options) ?? new();
        
        // Use the first one for the big banner, the rest for the secondary list
        ViewModel.Hero = allFeatured.FirstOrDefault();
        ViewModel.Featured = allFeatured.Skip(1).ToList();
    }

    // Load Latest News
    var latestPath = Path.Combine(Directory.GetCurrentDirectory(), "AppData", "LatestNews.json");
    if (File.Exists(latestPath))
    {
        var latestData = await File.ReadAllTextAsync(latestPath);
        ViewModel.Latest = JsonSerializer.Deserialize<List<NewsArticle>>(latestData, options) ?? new();
    }
}

3. The Razor View

This view follows your State Design System structure exactly, using the JSON data to populate the fields.
Razor CSHTML

@model NewsroomPageModel

<div class="col-lg-8 col-xl-9">
    <h1 class="m-t-0">Newsroom</h1>

    @if (Model.ViewModel.Hero != null)
    {
        <h2>Featured</h2>
        <div class="container p-0">
            <div class="row brd-solid-1 brd-gray-200 bg-gray-50-hover mx-0">
                <div class="col-lg-8 col-md-6 p-0 text-right d-flex justify-content-center">
                    <a href="@Model.ViewModel.Hero.Href"
                       class="feature-img w-100"
                       style="background: url('@Model.ViewModel.Hero.ImageUrl'); background-size: cover; min-height: 250px;"
                       aria-label="@Model.ViewModel.Hero.Title"></a>
                </div>
                <div class="col-md-6 col-lg-4 p-a-md">
                    <h2 class="h4 m-t-0">
                        <a href="@Model.ViewModel.Hero.Href">@Model.ViewModel.Hero.Title</a>
                    </h2>
                    <p>@Model.ViewModel.Hero.Date.ToString("MMMM dd, yyyy") | @Model.ViewModel.Hero.Category</p>
                </div>
            </div>
        </div>
    }

    @if (Model.ViewModel.Featured.Any())
    {
        <article class="news-item m-t-md">
            @foreach (var item in Model.ViewModel.Featured)
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
    @foreach (var news in Model.ViewModel.Latest.OrderByDescending(x => x.Date))
    {
        <h3 class="lead font-weight-700">
            <a href="@news.Href">@news.Title</a>
        </h3>
        <p>@news.Date.ToString("MMMM dd, yyyy") | @news.Category</p>
        <hr class="m-y-md" />
    }
</div>

4. Sample JSON (AppData/FeaturedNews.json)

The first item in this file will automatically become the big banner.
JSON

[
  {
    "Title": "California state department announces plans for upcoming initiative",
    "Date": "2024-05-20",
    "Href": "/news/initiative",
    "Category": "Press release",
    "ImageUrl": "/images/sample/images/news-img-featured.png"
  },
  {
    "Title": "Experts Provide Insights on Climate Remediation",
    "Date": "2024-05-18",
    "Href": "/news/climate",
    "Category": "News",
    "ImageUrl": "/images/sample/images/news-img1.png"
  }
]

