---
title: "Newsroom"
sidenav_title: "Newsroom"
sidenav_items:
  - label: "Newsroom"
    url: "/patterns/newsroom.html"
  - label: "News articles"
    url: "javascript:;"
  - label: "Press releases"
    url: "/patterns/list-of-articles-or-content-sample.html"
  - label: "Blog"
    url: "javascript:;"
  - label: "Disaster information"
    url: "javascript:;"
  - label: "Subscription services"
    url: "javascript:;"
  - label: "Public records requests"
    url: "javascript:;"
  - label: "Press information"
    url: "javascript:;"
---

# Newsroom

## Featured

<featured-article 
    image="/images/sample/images/news-img1.png"
    title="California state department announces plans for upcoming important initiative"
    url="javascript:;"
    date="Month 00, 0000"
    type="Press release">
</featured-article>

<featured-article 
    image="/images/sample/images/news-img2.png"
    title="Experts Provide Insights on Climate Remediation"
    url="javascript:;"
    date="Month 00, 0000"
    type="Press release">
</featured-article>

<featured-article 
    image="/images/sample/images/news-img3.png"
    title="Individuals Reflect on CalFresh Awareness Month"
    url="javascript:;"
    date="Month 00, 0000"
    type="Press release">
</featured-article>


<news-card-grid>
    <news-card 
        title="Subscribe for updates" 
        url="javascript:;">
        Keep up-to-date on our latest updates. Sign up for email notifications.
    </news-card>

    <news-card 
        title="Blog post title" 
        url="javascript:;"
        date="Month 00, 0000">
        Short 1 - 2 sentence description promoting this blog post.
    </news-card>
</news-card-grid>


## Latest news

<latest-news 
    title="Local Entity Implements Changes to Operations"
    url="javascript:;"
    date="Month 00, 0000"
    type="News">
</latest-news>

<latest-news 
    title="Discussion Continues Regarding California’s Project Funding"
    url="javascript:;"
    date="Month 00, 0000"
    type="News">
</latest-news>

<latest-news 
    title="Significant Agreement Reached in San Francisco"
    url="javascript:;"
    date="Month 00, 0000"
    type="News">
</latest-news>





;#############################################



---
title: "Page heading"
sidenav_title: "Newsroom"
sidenav_items:
  - label: "Newsroom"
    url: "/patterns/newsroom-sample.html"
  - label: "News articles"
    url: "javascript:;"
  - label: "Press releases"
    url: "javascript:;"
  - label: "Blog"
    url: "javascript:;"
  - label: "Disaster information"
    url: "javascript:;"
  - label: "Subscription services"
    url: "javascript:;"
  - label: "Public records requests"
    url: "javascript:;"
  - label: "Press information"
    url: "javascript:;"
---

# Page heading

## Month 0000

<news-item 
    title="California state department announces plans for upcoming important initiative"
    url="javascript:;"
    date="Month 00, 0000"
    type="Press release">
</news-item>

<news-item 
    title="Experts Provide Insights on Climate Remediation"
    url="javascript:;"
    date="Month 00, 0000"
    type="Press release">
</news-item>

## Month 0000

<news-item 
    title="Individuals Reflect on CalFresh Awareness Month"
    url="javascript:;"
    date="Month 00, 0000"
    type="Press release">
</news-item>

<news-item 
    title="Local Entity Implements Changes to Operations"
    url="javascript:;"
    date="Month 00, 0000"
    type="Press release">
</news-item>

<news-item 
    title="Discussion Continues Regarding California’s Project Funding"
    url="javascript:;"
    date="Month 00, 0000"
    type="Press release">
</news-item>

<news-item 
    title="Significant Agreement Reached in San Francisco"
    url="javascript:;"
    date="Month 00, 0000"
    type="Press release">
</news-item>

<news-item 
    title="Official Report Sheds Light on the last Flu Season"
    url="javascript:;"
    date="Month 00, 0000"
    type="Press release">
</news-item>

---

<cagov-pagination 
    data-current-page="5" 
    data-total-pages="99">
</cagov-pagination>


check also for console in browser in local






We need to update the regex to capture the component name (e.g., card, alert, accordion) right after the :::rcl- prefix.
C#

// Updated to capture the component type: :::rcl-{componentName}
[GeneratedRegex(@"^:::rcl-([a-zA-Z0-9-]+)[ \t]*(.*?)\r?\n(.*?)\r?\n:::", RegexOptions.Multiline | RegexOptions.Singleline)]
private static partial Regex RclComponentBlockRegex();

2. The Refactored Dispatcher

This new version uses a switch statement (or a Dictionary of functions) to decide which HTML builder to call based on the tag name found in the Markdown.
C#

public static class MarkdownRclParser
{
    private static readonly MarkdownPipeline _innerPipeline = new MarkdownPipelineBuilder().UseAdvancedExtensions().Build();

    public static string ProcessRclComponents(string rawMarkdown)
    {
        return RclComponentBlockRegex().Replace(rawMarkdown, match =>
        {
            string componentType = match.Groups[1].Value.ToLower(); // e.g., "card"
            string attributesString = match.Groups[2].Value;       // e.g., title="Hello"
            string rawContent = match.Groups[3].Value;            // The inner markdown

            // 1. Parse attributes into a dictionary
            var attrs = ParseAttributes(attributesString);

            // 2. Convert inner markdown to HTML (so it works inside the component)
            string htmlContent = Markdown.ToHtml(rawContent, _innerPipeline).Trim();

            // 3. Dispatch to the correct builder
            return componentType switch
            {
                "card" => HandleCard(attrs, htmlContent),
                "alert" => HandleAlert(attrs, htmlContent),
                "accordion" => HandleAccordion(attrs, htmlContent),
                _ => $"" 
            };
        });
    }

    private static Dictionary<string, string> ParseAttributes(string attrString)
    {
        var attributes = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
        foreach (Match attrMatch in AttributeRegex().Matches(attrString))
        {
            attributes[attrMatch.Groups[1].Value] = attrMatch.Groups[2].Value;
        }
        return attributes;
    }

    // --- Specific Handlers ---

    private static string HandleCard(Dictionary<string, string> attrs, string content)
    {
        Enum.TryParse(attrs.GetValueOrDefault("variant", "Default"), true, out CardVariant variant);
        
        return CardHtmlBuilder.Build(
            variant,
            attrs.GetValueOrDefault("title", ""),
            attrs.GetValueOrDefault("href", "#"),
            attrs.GetValueOrDefault("icon", "ca-gov-icon-info"),
            content
        );
    }

    private static string HandleAlert(Dictionary<string, string> attrs, string content)
    {
        // Example: :::rcl-alert type="warning"
        string type = attrs.GetValueOrDefault("type", "info");
        return $@"<div class=""alert alert-{type}"" role=""alert"">{content}</div>";
    }
}

3. Usage in your Pipeline

Now your implementation code becomes very clean. You simply call the general processor before the final Markdown conversion.
C#

// 1. Logic checks
HelperClass.CheckHeadingNesting(this.MainContent, 1);

// 2. Process ALL RCL components at once
this.MainContent = MarkdownRclParser.ProcessRclComponents(this.MainContent);

// 3. Final Markdown to HTML conversion
var pipeline = new MarkdownPipelineBuilder().UseAdvancedExtensions().Build();
this.MainContent = Markdown.ToHtml(this.MainContent, pipeline);