### Template for SRE work flow

## TODO





 (RclComponentRenderer.cs)

 Markdig finds a ::: container, pauses, hands the data to this class, renders the HTML, and drops it into the stream.
C#

using System;
using System.Collections.Generic;
using System.IO;
using Markdig.Renderers;
using Markdig.Renderers.Html;
using Markdig.Extensions.CustomContainers;
using WTS.RazorComponentLibrary.MarkdownRclParser;
using WTS.RazorComponentLibrary.Models.RclComponents;
using WTS.RazorComponentLibrary.Renderers;

namespace WTS.RazorComponentLibrary.MarkdownRclParser
{
    // Hooks natively into Markdig's AST for Custom Containers (:::)
    public class RclComponentRenderer : HtmlObjectRenderer<CustomContainer>
    {
        private readonly Dictionary<string, Func<Dictionary<string, string>, string, string>> _handlers;

        public RclComponentRenderer()
        {
            // All your existing components are registered here exactly as before
            _handlers = new Dictionary<string, Func<Dictionary<string, string>, string, string>>(StringComparer.OrdinalIgnoreCase)
            {
                { "rcl-card", (a, c) => RclCardRenderer.Render(ComponentMapper.Map<CardProperties>(a, c)) },
                { "rcl-accordion", (a, c) => RclAccordionRenderer.Render(ComponentMapper.Map<AccordionProperties>(a, c)) },
                { "rcl-accordion-item", (a, c) => RclAccordionItemRenderer.Render(ComponentMapper.Map<AccordionItemProperties>(a, c)) },
                { "rcl-tabs", (a, c) => RclTabsRenderer.Render(ComponentMapper.Map<TabsProperties>(a, c)) },
                { "rcl-tab", (a, c) => RclTabItemRenderer.Render(ComponentMapper.Map<TabItemProperties>(a, c)) },
                
                { "rcl-alert", (a, c) => RclAlertRenderer.Render(ComponentMapper.Map<AlertProperties>(a, c)) },
                { "rcl-blockquote", (a, c) => RclBlockquoteRenderer.Render(ComponentMapper.Map<BlockquoteProperties>(a, c)) },
                { "rcl-button", (a, c) => RclButtonRenderer.Render(ComponentMapper.Map<ButtonProperties>(a, c)) },
                { "rcl-table", (a, c) => RclTableRenderer.Render(ComponentMapper.Map<TableProperties>(a, c)) },
                
                { "rcl-executive-profile", (a, c) => RclExecutiveProfileRenderer.Render(ComponentMapper.Map<ExecutiveProfileProperties>(a, c)) },
                { "rcl-featured-banner", (a, c) => RclFeaturedBannerRenderer.Render(ComponentMapper.Map<FeaturedBannerProperties>(a, c)) },
                { "rcl-countdown", (a, c) => RclCountdownRenderer.Render(ComponentMapper.Map<CountdownProperties>(a, c)) },
                { "rcl-modal", (a, c) => RclModalRenderer.Render(ComponentMapper.Map<ModalProperties>(a, c)) },
                { "rcl-csv2bar", (a, c) => RclCsv2BarRenderer.Render(ComponentMapper.Map<Csv2BarProperties>(a, c)) },
                
                { "rcl-progress-bar", (a, c) => RclProgressBarRenderer.Render(ComponentMapper.Map<ProgressBarProperties>(a, c)) },
                { "rcl-progress-block", (a, c) => RclProgressBlockRenderer.Render(ComponentMapper.Map<ProgressBlockProperties>(a, c)) },
                { "rcl-progress-step", (a, c) => RclProgressBlockRenderer.RenderStep(ComponentMapper.Map<ProgressStepProperties>(a, c)) },
                { "rcl-timeline", (a, c) => RclTimelineRenderer.Render(ComponentMapper.Map<TimelineProperties>(a, c)) },
                { "rcl-timeline-item", (a, c) => RclTimelineItemRenderer.Render(ComponentMapper.Map<TimelineItemProperties>(a, c)) },
                { "rcl-step-list", (a, c) => RclStepListRenderer.Render(ComponentMapper.Map<StepListProperties>(a, c)) },
                { "rcl-step-list-item", (a, c) => RclStepListItemRenderer.Render(ComponentMapper.Map<StepListItemProperties>(a, c)) },
                { "rcl-pagination", (a, c) => RclPaginationRenderer.Render(ComponentMapper.Map<PaginationProperties>(a, c)) },
                
                { "rcl-link-grid", (a, c) => RclLinkGridRenderer.Render(ComponentMapper.Map<LinkGridProperties>(a, c)) },
                { "rcl-link-grid-item", (a, c) => RclLinkGridItemRenderer.Render(ComponentMapper.Map<LinkGridItemProperties>(a, c)) },
                { "rcl-social-container", (a, c) => RclSocialContainerRenderer.Render(ComponentMapper.Map<SocialContainerProperties>(a, c)) },
                { "rcl-social-icon", (a, c) => RclSocialIconRenderer.Render(ComponentMapper.Map<SocialIconProperties>(a, c)) },

                { "rcl-input", (a, c) => RclFormInputRenderer.Render(ComponentMapper.Map<FormInputProperties>(a, c)) },
                { "rcl-check", (a, c) => RclFormCheckRenderer.Render(ComponentMapper.Map<FormCheckProperties>(a, c)) },
                { "rcl-select", (a, c) => RclFormSelectRenderer.Render(ComponentMapper.Map<FormSelectProperties>(a, c)) }
            };
        }

        protected override void Write(HtmlRenderer renderer, CustomContainer obj)
        {
            string tagName = obj.Info?.ToLowerInvariant() ?? "";

            // If it's a generic Markdig container, output normal div
            if (!tagName.StartsWith("rcl-"))
            {
                renderer.Write("<div class=\"").WriteEscape(tagName).Write("\">");
                renderer.WriteChildren(obj);
                renderer.Write("</div>");
                return;
            }

            // 1. Capture Inner Content (Stream Capture Technique)
            // We temporarily swap Markdig's output stream into a string variable.
            // This safely resolves all nested Accordions, Tabs, Bold, Italics, etc., natively.
            string childHtml;
            var originalWriter = renderer.Writer;
            
            using (var stringWriter = new StringWriter())
            {
                renderer.Writer = stringWriter;
                renderer.WriteChildren(obj);
                renderer.Writer = originalWriter; // Restore the main stream
                childHtml = stringWriter.ToString().Trim();
            }

            // 2. Strip surrounding <p> tags for inline elements (Alerts, Badges)
            if (childHtml.StartsWith("<p>") && childHtml.EndsWith("</p>"))
            {
                if (childHtml.IndexOf("<p>", 3) == -1) // If there are no other paragraphs
                {
                    childHtml = childHtml.Substring(3, childHtml.Length - 7).Trim();
                }
            }

            // 3. Map attributes and Render Component
            if (_handlers.TryGetValue(tagName, out var handlerFunc))
            {
                var attrs = RclAttributeParser.Parse(obj.Arguments);
                string generatedHtml = handlerFunc(attrs, childHtml);
                
                // Write our generated HTML directly into Markdig's final output stream
                renderer.Write(generatedHtml);
            }
            else
            {
                // Fallback for unknown RCL tags
                renderer.Write($"");
                renderer.Write(childHtml);
            }
        }
    }
}



private void UpdateSectionsToHtml()
{
    // Check heading nesting.
    HelperClass.CheckHeadingNesting(this.MainContent, 1);

    // 1. Setup Markdig Pipeline with Custom Containers enabled
    var pipeline = new MarkdownPipelineBuilder()
        .UseAdvancedExtensions()
        .UseCustomContainers() // CRITICAL: Enables native ::: parsing
        .Build();

    // 2. Create the HTML renderer and inject our Component Renderer
    using (var stringWriter = new System.IO.StringWriter())
    {
        var renderer = new Markdig.Renderers.HtmlRenderer(stringWriter);
        pipeline.Setup(renderer);
        
        // Inject our custom logic to hijack RCL containers
        renderer.ObjectRenderers.InsertBefore<Markdig.Renderers.Html.CustomContainerRenderer>(new RclComponentRenderer());

        // 3. Parse the Markdown and render to HTML in a single native pass!
        var document = Markdown.Parse(this.MainContent, pipeline);
        renderer.Render(document);
        
        this.MainContent = stringWriter.ToString();
    }

    // --- The rest of your existing logic remains untouched ---
    
    if (autoGenerateToc && !string.IsNullOrEmpty(this.SideNavContent.Replace("\r", "").Replace("\n", "")))
    {
        throw new ArgumentException("User indicated to auto generate the table of contents, but also inserted contents in the side navigation.");
    }

    if (!string.IsNullOrEmpty(this.SideNavTitle))
    {
        this.SideNavTitle = Markdown.ToHtml(this.SideNavTitle, pipeline);
        this.SideNavTitle = this.SideNavTitle.Replace("<h1 ", $"<h1 class='{this.SideNavTitleClass}' ");
    }

    if (this.autoGenerateToc)
    {
        this.SideNavContent = HtmlParsingClass.GenerateMarkdownTOC(this.MainContent, true, this.h20nly);
    }

    if (!string.IsNullOrEmpty(this.SideNavContent))
    {
        // normalize line breaks for consistent splitting
        var sideNavSplit = this.SideNavContent.Split(new[] { "\r\n", "\r", "\n" }, StringSplitOptions.None);
        // init new outer nav wrapper
        string newSideNav = $"<nav aria-label=\"list navigation\" aria-labelledby=\"components-list\" class=\"side-navigation sticky-6 overflow-auto\">";
        
        // ... rest of side nav generation
    }
}