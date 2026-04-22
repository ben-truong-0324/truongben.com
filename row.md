The key to making this work is Recursion. The RowHandler needs to take its inner content and ask the MarkdownRclParser to process it again before wrapping it in the <div class="row"> HTML.
1. The Row Handler (RowHandler.cs)

This handler is very simple. Its only job is to provide the container and ensure that any cards inside it get processed.
C#

using MyProject.Rcl.Core.Models;
using System.Collections.Generic;

namespace YourProject.MarkdownEngine.Handlers;

public class RowHandler : IRclComponentHandler
{
    // We will pass the parser's process delegate to this handler
    private readonly Func<string, string> _subProcess;

    public RowHandler(Func<string, string> subProcess)
    {
        _subProcess = subProcess;
    }

    public string Render(Dictionary<string, string> attributes, string htmlContent)
    {
        // 'htmlContent' here is the raw markdown inside the row.
        // We re-process it to find the :::rcl-card tags.
        string processedInnerContent = _subProcess(htmlContent);

        // Add SDS/Bootstrap row classes
        string extraClasses = attributes.GetValueOrDefault("class", "");
        
        return $@"
<div class=""row {extraClasses}"">
    {processedInnerContent}
</div>";
    }
}

2. Updating the Card for the Grid

For a grid to work, cards usually need to be wrapped in a column (e.g., col-md-4). We should update the CardHandler and Renderer to support a column attribute.

In RclCardModels.cs (Core):
C#

public class CardProperties {
    // ... previous properties ...
    public string ColumnClass { get; set; } = string.Empty; // e.g., "col-md-4"
}

In RclCardRenderer.cs (Core):
Wrap the entire card output in the column div if ColumnClass is provided.
C#

public static string Render(CardProperties p) 
{
    // ... existing logic to generate 'cardHtml' ...
    string cardHtml = p.Variant switch { ... };

    if (!string.IsNullOrEmpty(p.ColumnClass))
    {
        return $@"<div class=""{p.ColumnClass}"">{cardHtml}</div>";
    }

    return cardHtml;
}

3. The Recursive Parser (MarkdownRclParser.cs)

We need to update the Parser to register the RowHandler and pass itself in so the row can process nested cards.
C#

public partial class MarkdownRclParser
{
    private readonly MarkdownPipeline _pipeline;
    private readonly Dictionary<string, IRclComponentHandler> _handlers;

    public MarkdownRclParser(MarkdownPipeline pipeline)
    {
        _pipeline = pipeline;
        
        _handlers = new Dictionary<string, IRclComponentHandler>(StringComparer.OrdinalIgnoreCase)
        {
            { "card", new CardHandler() },
            // Pass the 'Process' method as a delegate to the RowHandler
            { "row", new RowHandler(this.Process) } 
        };
    }

    public string Process(string rawMarkdown)
    {
        if (string.IsNullOrWhiteSpace(rawMarkdown)) return rawMarkdown;

        // Use the Nuclear Regex we perfected earlier
        return RclComponentRegex().Replace(rawMarkdown, match =>
        {
            string tagName = match.Groups[1].Value.ToLower();
            string attrString = match.Groups[2].Value;
            string bodyMarkdown = match.Groups[3].Value;

            if (_handlers.TryGetValue(tagName, out var handler))
            {
                var attrs = RclAttributeParser.Parse(attrString);
                
                // If it's a row, the handler will call Process(bodyMarkdown) recursively.
                // If it's a card, the handler uses the content directly.
                return $"\n\n{handler.Render(attrs, bodyMarkdown)}\n\n";
            }

            return match.Value;
        });
    }
}

4. How the User Writes It

Now your non-technical users can create beautiful layouts without touching a single <div>.
Markdown

:::rcl-row
:::rcl-card title="Service A" column="col-md-6" griditem="true"
This is the first service.
:::

:::rcl-card title="Service B" column="col-md-6" griditem="true"
This is the second service.
:::
:::

Why this works:

    Outer Match: The Parser finds :::rcl-row.

    Delegation: It gives the bodyMarkdown (which contains two cards) to the RowHandler.

    Recursion: The RowHandler calls the parser again on that inner text.

    Inner Match: The parser finds the two :::rcl-card blocks and converts them to HTML (including the column wrappers).

    Final Wrap: The RowHandler wraps the resulting HTML in the <div class="row"> and returns it.