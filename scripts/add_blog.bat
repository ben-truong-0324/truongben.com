@echo off
setlocal EnableDelayedExpansion

:: --- Prompt user for blog post metadata ---
echo --- Create New Hugo Blog Post ---

set /p POST_TITLE=Enter blog post title: 
if "%POST_TITLE%"=="" (
    echo Error: Title cannot be empty. Exiting.
    exit /b 1
)

set /p POST_SUBTITLE=Enter subtitle (optional): 
set /p POST_TAGS=Enter tags (comma-separated, e.g., tech,ai,devops): 
set /p POST_CATEGORIES=Enter categories (comma-separated, e.g., blog,updates): 
set /p POST_SUMMARY=Enter a short summary for the post: 

:: --- Slugify the title ---
:: Convert to lowercase, replace non-alphanumerics with dashes
set "POST_SLUG=%POST_TITLE%"
set "POST_SLUG=%POST_SLUG: =-%"
for /f "delims=" %%a in ('powershell -NoProfile -Command "[regex]::Replace('%POST_SLUG%', '[^a-zA-Z0-9]+', '-').ToLower().Trim('-')"') do set "POST_SLUG=%%a"

set "POST_DIR=content\post\%POST_SLUG%"
set "INDEX_MD=%POST_DIR%\index.md"

:: Get current date-time in ISO 8601 format
for /f %%i in ('powershell -NoProfile -Command "(Get-Date).ToString('yyyy-MM-ddTHH:mm:sszzz')"') do set "CURRENT_DATE=%%i"

:: --- Create directory ---
if exist "%POST_DIR%" (
    echo Warning: Directory "%POST_DIR%" already exists. This will overwrite index.md if it exists.
) else (
    mkdir "%POST_DIR%"
    echo Created directory: %POST_DIR%
)

:: --- Format tags ---
set "TAGS_FORMATTED="
for %%t in (%POST_TAGS:)=",%" do (
    set "TAG=%%t"
    call set "TAGS_FORMATTED=!TAGS_FORMATTED!  - !TAG: =!"
    set "TAGS_FORMATTED=!TAGS_FORMATTED!^&echo("
)

:: --- Format categories ---
set "CATEGORIES_FORMATTED="
for %%c in (%POST_CATEGORIES:)=",%" do (
    set "CAT=%%c"
    call set "CATEGORIES_FORMATTED=!CATEGORIES_FORMATTED!  - !CAT: =!"
    set "CATEGORIES_FORMATTED=!CATEGORIES_FORMATTED!^&echo("
)

:: --- Write front matter to index.md ---
> "%INDEX_MD%" (
    echo ---
    echo title: "%POST_TITLE%"
    echo subtitle: "%POST_SUBTITLE%"
    echo date: %CURRENT_DATE%
    echo draft: true
    echo image:
    echo   filename: _.png
    echo   focal_point: "Smart"
    echo   preview_only: false
    echo tags:>> "%INDEX_MD%"
    for %%t in (%POST_TAGS:)=",%" do (
        set "TAG=%%t"
        call echo   - !TAG: =!>> "%INDEX_MD%"
    )

    echo categories:>> "%INDEX_MD%"
    for %%c in (%POST_CATEGORIES:)=",%" do (
        set "CAT=%%c"
        call echo   - !CAT: =!>> "%INDEX_MD%"
    )

    echo categories:
    for %%l in (!CATEGORIES_FORMATTED!) do echo %%l
    echo authors:
    echo   - admin
    echo summary: "%POST_SUMMARY%"
    echo ---
)

:: --- Ask about HTML inclusion ---
set /p INCLUDE_HTML_CHOICE=Do you want to include an HTML file directly within this blog post? (y/N): 
if /i "!INCLUDE_HTML_CHOICE!"=="y" (
    set /p HTML_FILENAME=Enter the name for your HTML file (e.g., my-chart.html): 
    if "%HTML_FILENAME%"=="" (
        echo Error: HTML filename cannot be empty. Skipping HTML inclusion.
    ) else (
        set "HTML_FILEPATH=%POST_DIR%\%HTML_FILENAME%"
        type nul > "%HTML_FILEPATH%"
        echo Created empty HTML file: %HTML_FILEPATH%
        echo You can now paste your raw HTML content (e.g., D3.js charts) into this file.

        >> "%INDEX_MD%" echo.
        >> "%INDEX_MD%" echo ---
        >> "%INDEX_MD%" echo {{^< rawhtml "%HTML_FILENAME%" >^}}
        >> "%INDEX_MD%" echo ---
        >> "%INDEX_MD%" echo.

        set "SHORTCODE_DIR=layouts\shortcodes"
        set "RAWHTML_SHORTCODE=%SHORTCODE_DIR%\rawhtml.html"

        if not exist "%RAWHTML_SHORTCODE%" (
            mkdir "%SHORTCODE_DIR%"
            > "%RAWHTML_SHORTCODE%" (
                echo {{/*
                echo   rawhtml shortcode
                echo   Embeds raw HTML content from a file located in the same directory as the calling Markdown file.
                echo   Usage: {{< rawhtml "your-file.html" >}}
                echo */}}
                echo {{ $file := .Get 0 }}
                echo {{ $path := printf "%%s/%%s" .Page.File.Dir $file }}
                echo {{ if fileExists $path }}
                echo     {{ readFile $path ^| safeHTML }}
                echo {{ else }}
                echo {{ end }}
            )
            echo Shortcode "%RAWHTML_SHORTCODE%" created.
        ) else (
            echo Shortcode already exists: "%RAWHTML_SHORTCODE%"
        )
    )
)

echo --- Done! ---
echo Your new blog post is ready at: %POST_DIR%
echo 1. Edit "%INDEX_MD%" to add your Markdown content.
if /i "!INCLUDE_HTML_CHOICE!"=="y" if not "%HTML_FILENAME%"=="" (
    echo 2. Add raw HTML content to "%HTML_FILEPATH%".
)
echo 3. Run "hugo serve" to preview site locally.

endlocal
pause
