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




older Structure Suggestion

    /MarkdownEngine

        MarkdownRclParser.cs (The Entry Point/Router)

        RclAttributeParser.cs (Shared utility)

        /Handlers

            IRclComponentHandler.cs (The Interface)

            CardHandler.cs

            AlertHandler.cs

1. The Interface (IRclComponentHandler.cs)

This ensures every new component you add follows the same contract.
C#

using System.Collections.Generic;

namespace YourProject.MarkdownEngine.Handlers;

public interface IRclComponentHandler
{
    // The 'content' passed here is already converted to HTML
    string Render(Dictionary<string, string> attributes, string htmlContent);
}

2. The Shared Attribute Parser (RclAttributeParser.cs)

Since every component needs to parse key="value", let's centralize it.
C#

using System;
using System.Collections.Generic;
using System.Text.RegularExpressions;

namespace YourProject.MarkdownEngine;

public static partial class RclAttributeParser
{
    [GeneratedRegex(@"([a-zA-Z0-9_-]+)=""([^""]+)""")]
    private static partial Regex AttributeRegex();

    public static Dictionary<string, string> Parse(string attributeString)
    {
        var attributes = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
        foreach (Match match in AttributeRegex().Matches(attributeString))
        {
            attributes[match.Groups[1].Value] = match.Groups[2].Value;
        }
        return attributes;
    }
}

3. The Entry Point Router (MarkdownRclParser.cs)

This is the "Brain." It finds the blocks, identifies the component type, and delegates the work.
C#

using System;
using System.Collections.Generic;
using System.Text.RegularExpressions;
using Markdig;
using YourProject.MarkdownEngine.Handlers;

namespace YourProject.MarkdownEngine;

public partial class MarkdownRclParser
{
    private readonly MarkdownPipeline _pipeline;
    private readonly Dictionary<string, IRclComponentHandler> _handlers;

    // The Regex looks for :::rcl-{name} {attributes} \n {content} \n :::
    [GeneratedRegex(@"^:::rcl-([a-zA-Z0-9-]+)[ \t]*(.*?)\r?\n(.*?)\r?\n:::", RegexOptions.Multiline | RegexOptions.Singleline)]
    private static partial Regex RclComponentRegex();

    public MarkdownRclParser(MarkdownPipeline pipeline)
    {
        _pipeline = pipeline;
        
        // Register your handlers here
        _handlers = new Dictionary<string, IRclComponentHandler>(StringComparer.OrdinalIgnoreCase)
        {
            { "card", new CardHandler() },
            // { "alert", new AlertHandler() } // Add more as you build them
        };
    }

    public string Process(string rawMarkdown)
    {
        return RclComponentRegex().Replace(rawMarkdown, match =>
        {
            string tagName = match.Groups[1].Value;
            string attrString = match.Groups[2].Value;
            string bodyMarkdown = match.Groups[3].Value;

            if (_handlers.TryGetValue(tagName, out var handler))
            {
                var attrs = RclAttributeParser.Parse(attrString);
                
                // Convert the inner markdown to HTML before giving it to the handler
                string bodyHtml = Markdown.ToHtml(bodyMarkdown, _pipeline).Trim();
                
                return handler.Render(attrs, bodyHtml);
            }

            // If no handler exists, return a comment so the dev knows it's missing
            return $"";
        });
    }
}

4. A Specific Component Handler (Handlers/CardHandler.cs)

This file now contains zero regex logic—it only cares about building HTML.
C#

using System;
using System.Collections.Generic;

namespace YourProject.MarkdownEngine.Handlers;

public class CardHandler : IRclComponentHandler
{
    public string Render(Dictionary<string, string> attributes, string htmlContent)
    {
        string title = attributes.GetValueOrDefault("title", "");
        string href = attributes.GetValueOrDefault("href", "#");
        string icon = attributes.GetValueOrDefault("icon", "ca-gov-icon-info");
        
        // Parse Variant Enum (Assuming CardVariant is defined globally)
        Enum.TryParse(attributes.GetValueOrDefault("variant", "Default"), true, out CardVariant variant);

        if (variant == CardVariant.Icon)
        {
            return $@"
                <article class=""no-underline d-block bg-gray-50 bg-gray-lightest-hover p-a-md pos-rel"">
                    <div class=""text-center p-b"">
                        <span class=""{icon} color-p2 color-p2-hover text-huge d-block"" aria-hidden=""true""></span>
                        <a href=""{href}"" class=""h4 m-t-0 m-b color-gray-dark link-before text-left no-underline d-block"">{title}</a>
                        <div class=""color-gray-dark text-left"">{htmlContent}</div>
                    </div>
                </article>";
        }

        return $"";
    }
}

5. Implementation in your Pipeline

Now, your main logic is extremely clean. You initialize the parser once and run it.
C#

// 1. Setup the standard pipeline
var pipeline = new MarkdownPipelineBuilder().UseAdvancedExtensions().Build();

// 2. Initialize our custom RCL Router
var rclParser = new MarkdownRclParser(pipeline);

// 3. Process components FIRST
this.MainContent = rclParser.Process(this.MainContent);

// 4. Then process the rest of the Markdown
this.MainContent = Markdown.ToHtml(this.MainContent, pipeline);