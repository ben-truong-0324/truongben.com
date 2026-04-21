# tag

Component	Tag	Key Properties (C#)
Accordion	<rcl-accordion>	Variant (Default, List, SideNav)
Alert	<rcl-alert>	Variant (Info, Warning, Danger, Resolution)
Blockquote	<rcl-blockquote>	Variant, Author, ImageSrc
Button	<rcl-button>	Color, Size, IsOutline, Href
Card	<rcl-card>	Variant, Title, ImageSrc, LegacyType
Countdown	<rcl-countdown-timer>	TargetDate (DateTime), TimerId
Exec Profile	<rcl-executive-profile>	Variant, Name, OfficialTitle, ImageSrc
Feature Card	<rcl-feature-card>	Title, ButtonHref, ImageSrc
Forms	<rcl-input>, <rcl-check>	Type, InputId, IsRequired
Search	<rcl-featured-search>	Action, Placeholder
Modal	<rcl-modal>	ModalId, Title, Size
News	<rcl-news-item>	Variant, Title, Date, Category
Pagination	<rcl-pagination>	CurrentPage, TotalPages
Progress	<rcl-progress-block>	Variant (Default, Bold)
Social	<rcl-social-icon>	Platform (Facebook, Twitter, etc.)
Step List	<rcl-step-list>	N/A (Wraps <rcl-step-list-item>)
Table	<rcl-table>	Variant (Basic, Default, Striped)
Tabs	<rcl-tabs>	N/A (Wraps <rcl-tab>)
Timeline	<rcl-timeline>	N/A (Wraps <rcl-timeline-item>)

# Attributes

Here is a comprehensive attribute reference guide you can add directly to your documentation. It breaks down every component we've built, the attributes they accept, and specifically highlights the ADA (Accessibility) properties required to keep your site compliant with state standards.
Component Attribute & Accessibility Reference

This guide details all available attributes for the Razor Class Library (RCL) components.

Attributes marked with a ♿ Accessibility badge are crucial for screen readers, keyboard navigation, and overall ADA compliance. Always provide meaningful values for these fields.
1. Accordion (<rcl-accordion> & <rcl-accordion-item>)

Parent (<rcl-accordion>)

    variant (Enum): Default, List, SideNav (Default: Default).

Child (<rcl-accordion-item>)

    heading (String): The text displayed on the clickable summary.

    is-open (Bool): If true, the accordion is expanded by default (used mainly in SideNav).

2. Alert (<rcl-alert>)

    variant (Enum): Info, Warning, Danger, Resolution (Default: Info). The Tag Helper automatically generates the correct semantic icons and hidden screen reader text based on this variant.

3. Blockquote (<rcl-blockquote>)

    variant (Enum): Default, NoGraphic, Prominent, Pull, WithImage.

    author (String): Name displayed in the <footer> tag.

    image-src (String): Required if variant is WithImage.

    ♿ image-alt (String): Required if variant is WithImage. Provides screen reader text for the author/quote image.

4. Button (<rcl-button>)

    color (Enum): Primary, Highlight, Standout, Default (Default: Primary).

    size (Enum): Default, Lg, Sm, Xs.

    is-outline, is-disabled, is-hover (Bool): Modifies button states.

    ♿ href (String): If provided, safely transforms the <button> into a compliant <a> tag with role="button".

5. Card (<rcl-card>)

    variant (Enum): Default, Icon, Image, Legacy.

    title (String): The main heading for the card.

    href (String): The destination link.

    is-grid-item (Bool): Applies CSS to stretch evenly in Bootstrap rows.

    button-text (String): Text for the action button.

    icon-class (String): CSS class for the icon (Default: ca-gov-icon-info).

    image-src (String): Required for Image variant.

    ♿ image-alt (String): Required for Image variant. Describes the card's thumbnail image to screen readers.

    legacy-type (Enum): Applies color modifiers for the Legacy variant.

6. Countdown Timer (<rcl-countdown-timer>)

    target-date (DateTime): The future date to count down to.

    ♿ timer-id (String): A unique ID. The Tag Helper auto-generates this if left blank to prevent JavaScript collisions, ensuring reliable DOM updates for screen readers.

7. Executive Profile (<rcl-executive-profile>)

    variant (Enum): Default, Transparent, Dark.

    name, official-title, agency, link-text, link-href (Strings): Profile data.

    image-src (String): URL for the headshot.

    ♿ image-alt (String): Screen reader description of the photo (e.g., "Headshot of Jane Doe").

    ♿ link-aria-label (String): Screen reader text for the bio link. If omitted, it automatically generates "Link to {Name}'s Website".

8. Feature Card (<rcl-feature-card>)

    title, button-text, button-href, image-src, image-href (Strings): Core content.

    ♿ button-aria-label (String): Appends hidden context to the button (e.g., if the button just says "Learn More", the aria-label can add "about Ocean Conservation").

    ♿ image-alt (String): Applies aria-label to the background image's hyperlink so screen readers know where the image click leads.

9. Forms (<rcl-input>, <rcl-check>, <rcl-select>)

Input (<rcl-input>)

    type (Enum): Text, Textarea, File.

    label, placeholder, feedback-text (Strings): Form copy.

    ♿ input-id (String): Crucial. Connects the <label for="..."> strictly to the input field.

    ♿ is-required (Bool): Injects the visual * and the hidden <span class="sr-only">Required field:</span> for ADA compliance.

Check / Radio (<rcl-check>)

    type (Enum): Checkbox, Radio.

    name, value, label (Strings): Input properties.

    ♿ input-id (String): Connects the label to the toggle box.

Select (<rcl-select>)

    ♿ select-id (String): Connects the label to the dropdown.

    ♿ label (String): Used for the visual label and injected as the aria-label for the select box.

10. Featured Search (<rcl-featured-search>)

    action, placeholder (Strings): Form routing and copy.

    ♿ sr-label (String): Hidden text describing the search box (Default: "Custom Google Search").

    ♿ input-id (String): Used to link the aria-labelledby attribute on the search input to the hidden sr-label.

11. Modal (<rcl-modal>)

    title, footer-close-text (Strings): Modal copy.

    size (Enum): Default, Lg, Sm, Xl.

    show-footer (Bool): Toggles the bottom button row.

    ♿ modal-id (String): Crucial. Allows trigger buttons (data-bs-target) to properly link to and open the dialog via accessibility APIs.

12. News Item (<rcl-news-item>)

    variant (Enum): List, ListFeatured, Block, Card, FeaturedBanner.

    title, href, date, category, author, agency, image-src (Strings): Content properties.

    ♿ image-alt (String): Screen reader text for the thumbnail/banner image.

13. Pagination (<rcl-pagination>)

    current-page, total-pages (Integers): The numerical data properties fed into the state template's web component logic.

14. Progress (<rcl-progress-bar>, <rcl-progress-block>, <rcl-progress-step>)

Bar (<rcl-progress-bar>)

    ♿ percentage (Int): Automatically updates the visual width and the aria-valuenow property for screen readers.

Block & Step (<rcl-progress-block> & <rcl-progress-step>)

    variant (Enum): Default, Bold.

    title (String): Step heading.

    state (Enum): Completed, Current, Upcoming.

    position (Enum): First, Middle, Last.

15. Social Media Icons (<rcl-social-icon>)

    platform (Enum): Facebook, GitHub, Twitter, YouTube, LinkedIn, Instagram, Email.

    href (String): The destination link.

    ♿ title (String): Generates the title="..." attribute for tooltips and screen readers. If omitted, it defaults to "{Platform} Link".

16. Step List (<rcl-step-list> & <rcl-step-list-item>)

    heading (String): The primary instruction. The component automatically wraps the sub-content in standard State Template structural spans.

17. Table (<rcl-table>)

    variant (Enum): Basic, Default, Striped. (Semantic <th> and <tbody> structure must be written manually inside the tag for maximum ADA compliance).

18. Tabs (<rcl-tabs> & <rcl-tab>)

    title (String): Navigation link text.

    ♿ tab-id (String): Generates the anchor link targets. If omitted, auto-generates unique IDs to ensure reliable keyboard navigation.

19. Timeline (<rcl-timeline> & <rcl-timeline-item>)

    title (String): The milestone heading (e.g., "Phase 1").

    timeframe (String): The date or duration (e.g., "2024 - 2025").


# for non tech

Force Markdig to output <rcl- tags

If you have a special build pipeline (like a static site generator) where you actually need Markdig to output literal <rcl-card> HTML tags instead of <div class="rcl-card">, you can replace Markdig's default renderer with a custom one.

1. 


using Markdig.Renderers;
using Markdig.Renderers.Html;
using Markdig.Extensions.CustomContainers;

public class RclContainerRenderer : HtmlObjectRenderer<CustomContainer>
{
    protected override void Write(HtmlRenderer renderer, CustomContainer obj)
    {
        // obj.Info is the word typed after ::: (e.g., "rcl-card")
        string tagName = string.IsNullOrWhiteSpace(obj.Info) ? "div" : obj.Info;

        renderer.WriteLine($"<{tagName}>");
        renderer.WriteChildren(obj); // Renders the inner markdown
        renderer.WriteLine($"</{tagName}>");
    }
}

2. Inject into Markdig Pipeline
C#

var pipeline = new MarkdownPipelineBuilder()
    .UseCustomContainers()
    .Build();

var htmlRenderer = new HtmlRenderer(new StringWriter());
pipeline.Setup(htmlRenderer);

// Remove the default div renderer and use our custom Tag Helper renderer
htmlRenderer.ObjectRenderers.RemoveAll(x => x is HtmlCustomContainerRenderer);
htmlRenderer.ObjectRenderers.Add(new RclContainerRenderer());

// Render the markdown
var html = Markdown.ToHtml("::: rcl-card\nHello\n:::", pipeline);

Result:
HTML

<rcl-card>
  <p>Hello</p>
</rcl-card>

# rcl-component sharing

some components can be both rcl-xxx and class="xxx"
this means both developers and non-tech can use the same name to refer to the same component they wish to have,
just different implementaiton under th ehood inside the libraries.

JS DOM rewrite is a possibliity
Mrakdig custom reneder / Model logic to override html wrapper before output


tab, card, button, block quote, modal, countdowntimer, steplist, timelnie , featured card
social media

[CmdletBinding()]
param(
    [switch]$DevBuild,
    [switch]$ReleaseBuild,
    [Parameter(Mandatory = $false, Position = 0)]
    [switch]$NoPush,
    [switch]$NoTest
)

if ($args -contains '--no-push') { $NoPush = $true }
if ($args -contains '--no-test') { $NoTest = $true }
if ($args -contains '--dev-build') { $DevBuild = $true }
if ($args -contains '--release-build') { $ReleaseBuild = $true }

if ($DevBuild -and $ReleaseBuild) {
    Write-Error "Cannot specify both DevBuild and ReleaseBuild. Choose one."
    exit 1
}

$ArtifactsDir = "local-nugget-feed"

$CleanPath1 = "$HOME/.nugget/packages/webtemplatelibrary"
$CleanPath2 = "$HOME/.nugget/packages/webtemplaterazorlibrary"
$CleanPath3 = "$HOME/.nugget/packages/webtemplates"

# Demo Project Paths
$demoProjPath = "WebTemplateDemo\WebTemplateDemo.csproj"
$demoTestsProjPath = "WebTemplateDemoTests\WebTemplateDemoTests.csproj"

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Section([string]$Name) {
    Write-Host "`n== $Name ===" -ForegroundColor Cyan
}

function Exec {
    param(
    [Parameter(Mandatory = $true)]
    [string]$Cmd,

    [Parameter()]
    [string[]]$Arguments = @()
    )

    $render = "$Cmd " + $($Arguments -join ' ')
    Write-Host "> $render" -ForegroundColor DarkGray

    & $Cmd @Arguments

    if ($LASTEXITCODE -ne 0) {
        throw "Command failed with exit code $LASTEXITCODE"
    }
}

function Ensure-Dir([String]$path) {
    if (-not (Test-Path $path)) {
        New-Item -ItemType Directory -Path $path | Out-Null
    }
}

# Helper function to swap Project/Package references in csproj
function Swap-References {
    param([string]$FilePath, [string]$FindRegex, [string]$Replace)
    
    if (Test-Path $FilePath) {
        $content = Get-Content $FilePath -Raw
        if ($content -match $FindRegex) {
            $content = $content -replace $FindRegex, $Replace
            Set-Content -Path $FilePath -Value $content -NoNewline
            Write-Host "  Updated $FilePath" -ForegroundColor DarkGray
        }
    } else {
        Write-Warning "Could not find file to swap references: $FilePath"
    }
}

try {
    Section "Clean"
    Exec "dotnet" @("clean")

    if ($CleanPath1 -and (Test-Path $CleanPath1)) {
        Write-Host "Removing $CleanPath1" -ForegroundColor Gray
        Remove-Item -Path $CleanPath1 -Recurse -Force
    }

    if ($CleanPath2 -and (Test-Path $CleanPath2)) {
        Write-Host "Removing $CleanPath2" -ForegroundColor Gray
        Remove-Item -Path $CleanPath2 -Recurse -Force
    }

    if ($CleanPath3 -and (Test-Path $CleanPath3)) {
        Write-Host "Removing $CleanPath3" -ForegroundColor Gray
        Remove-Item -Path $CleanPath3 -Recurse -Force
    }

    Ensure-Dir $ArtifactsDir
    Write-Host "Cleaning $ArtifactsDir/" -ForegroundColor Gray
    Remove-Item -Path (Join-Path $ArtifactsDir "*") -Recurse -Force

    # ==========================================
    # DEV / RELEASE BUILD LOGIC
    # ==========================================
    
    # Regex patterns to find either variation so we can swap them safely
    $wtlPkgRegex = '<PackageReference Include="WebTemplateLibrary".*?/>'
    $wtlProjRef  = '<ProjectReference Include="..\WebTemplateLibrary\WebTemplateLibrary.csproj" />'
    $wtlProjRegex = '<ProjectReference Include="\.\.\\WebTemplateLibrary\\WebTemplateLibrary\.csproj".*?/>'
    $wtlPkgRef   = '<PackageReference Include="WebTemplateLibrary" Version="1.0.0" />'

    $wtrPkgRegex = '<PackageReference Include="WebTemplateRazorLibrary".*?/>'
    $wtrProjRef  = '<ProjectReference Include="..\WebTemplateRazorLibrary\WebTemplateRazorLibrary.csproj" />'
    $wtrProjRegex = '<ProjectReference Include="\.\.\\WebTemplateRazorLibrary\\WebTemplateRazorLibrary\.csproj".*?/>'
    $wtrPkgRef   = '<PackageReference Include="WebTemplateRazorLibrary" Version="1.0.0" />'

    $wttPkgRegex = '<PackageReference Include="WebTemplateTests".*?/>'
    $wttProjRef  = '<ProjectReference Include="..\WebTemplateTests\WebTemplateTests.csproj" />'
    $wttProjRegex = '<ProjectReference Include="\.\.\\WebTemplateTests\\WebTemplateTests\.csproj".*?/>'
    $wttPkgRef   = '<PackageReference Include="WebTemplateTests" Version="1.0.0" />'


    if ($DevBuild) {
        Section "Configuring DEV Build (Direct References)"
        Swap-References -FilePath $demoProjPath -FindRegex $wtlPkgRegex -Replace $wtlProjRef
        Swap-References -FilePath $demoProjPath -FindRegex $wtrPkgRegex -Replace $wtrProjRef
        Swap-References -FilePath $demoTestsProjPath -FindRegex $wttPkgRegex -Replace $wttProjRef
    }

    if ($ReleaseBuild) {
        Section "Configuring RELEASE Build (Package References)"
        Swap-References -FilePath $demoProjPath -FindRegex $wtlProjRegex -Replace $wtlPkgRef
        Swap-References -FilePath $demoProjPath -FindRegex $wtrProjRegex -Replace $wtrPkgRef
        Swap-References -FilePath $demoTestsProjPath -FindRegex $wttProjRegex -Replace $wttPkgRef
    }

    # ==========================================
    # PACK & BUILD
    # ==========================================

    if (-not $DevBuild) {
        Section "Pack -> local-nugget-feed/"
        Exec "dotnet" @("pack", "WebTemplateLibrary.csproj", "-c", "Release", "-o", "local-nugget-feed")
        Exec "dotnet" @("pack", "WebTemplateRazorLibrary\WebTemplateRazorLibrary.csproj", "-c", "Release", "-o", "local-nugget-feed")
        Exec "dotnet" @("pack", "WebTemplateTests\WebTemplateTests.csproj", "-c", "Release", "-o", "local-nugget-feed")
    } else {
        Section "Pack Skipped (Dev Build)"
    }

    Section "Build"
    Exec "dotnet" @("build")

    if (-not $NoTest) {
        Section "Test"
        Exec "dotnet" @("test")
    }

    if (-not $NoPush) {
        $commitMsg = Read-Host -Prompt "Enter SVN commit message"
        cd ..
        svn status | ForEach-Object { if ($_ -match '^\?\s+(.*)$') { svn add $matches[1] } elseif ($_ -match '^!\s+(.*)$') { svn delete $matches[1] } }

        Write-Host "Committing... " -ForegroundColor Cyan
        Exec -Cmd "svn" -Arguments @('commit', '-m', $commitMsg)

        Write-Host "SVN commit completed." -ForegroundColor Cyan
        cd Source

        Section "Done"
        $feedPath = (Resolve-Path $ArtifactsDir).Path
        Write-Host "Packages available in: $feedPath" -ForegroundColor Green
        exit 0
    }
}
catch {
    Write-Error $_.Exception.Message
    exit 1
}