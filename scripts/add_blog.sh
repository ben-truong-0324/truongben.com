#!/bin/bash

# Function to slugify a string (convert to URL-friendly format)
slugify() {
  echo "$1" | iconv -t ascii//TRANSLIT | sed -E 's/[^a-zA-Z0-9]+/-/g' | sed -E 's/^-+|-+$//g' | tr A-Z a-z
}

echo "--- Create New Hugo Blog Post ---"

read -p "Enter blog post title: " POST_TITLE
if [ -z "$POST_TITLE" ]; then
  echo "Error: Title cannot be empty. Exiting."
  exit 1
fi

read -p "Enter subtitle (optional): " POST_SUBTITLE
read -p "Enter tags (comma-separated, e.g., tech,ai,devops): " POST_TAGS
read -p "Enter categories (comma-separated, e.g., blog,updates): " POST_CATEGORIES
read -p "Enter a short summary for the post: " POST_SUMMARY

# Generate slug from title
POST_SLUG=$(slugify "$POST_TITLE")
POST_DIR="content/post/$POST_SLUG"
INDEX_MD="$POST_DIR/index.md"
CURRENT_DATE=$(date +"%Y-%m-%dT%H:%M:%S%z") # Get current date/time in ISO 8601 format

# --- Create post directory ---
if [ -d "$POST_DIR" ]; then
  echo "Warning: Directory '$POST_DIR' already exists. This script will overwrite '$INDEX_MD' if it exists."
else
  mkdir -p "$POST_DIR"
  echo "Created directory: $POST_DIR"
fi

# --- Format tags and categories for YAML front matter ---
TAGS_FORMATTED=""
IFS=',' read -ra ADDR <<< "$POST_TAGS"
for i in "${ADDR[@]}"; do
  # xargs is used here to trim leading/trailing whitespace from each tag
  TAGS_FORMATTED+="  - $(echo "$i" | xargs)"$'\n'
done

CATEGORIES_FORMATTED=""
IFS=',' read -ra ADDR <<< "$POST_CATEGORIES"
for i in "${ADDR[@]}"; do
  CATEGORIES_FORMATTED+="  - $(echo "$i" | xargs)"$'\n'
done

# --- Write index.md front matter and initial content ---
echo "Creating $INDEX_MD..."
cat <<EOF > "$INDEX_MD"
---
title: "$POST_TITLE"
subtitle: "$POST_SUBTITLE"
date: $CURRENT_DATE
draft: true 
tags:
$(echo "$TAGS_FORMATTED")
categories:
$(echo "$CATEGORIES_FORMATTED")
authors:
  - admin # Default author, change if needed (refers to content/authors/admin/_index.md)
summary: "$POST_SUMMARY"
---

# $POST_TITLE


EOF

# --- Handle optional HTML file inclusion ---
read -p "Do you want to include an HTML file directly within this blog post? (y/N): " INCLUDE_HTML_CHOICE
INCLUDE_HTML_CHOICE=${INCLUDE_HTML_CHOICE:-N} # Default to No if no input

if [[ "$INCLUDE_HTML_CHOICE" =~ ^[Yy]$ ]]; then
  read -p "Enter the name for your HTML file (e.g., my-chart.html): " HTML_FILENAME
  if [ -z "$HTML_FILENAME" ]; then
    echo "Error: HTML filename cannot be empty. Skipping HTML inclusion."
  else
    HTML_FILEPATH="$POST_DIR/$HTML_FILENAME"
    touch "$HTML_FILEPATH"
    echo "Created empty HTML file: $HTML_FILEPATH"
    echo "You can now paste your raw HTML content (e.g., D3.js charts, custom widgets) into this file."

    # Append shortcode call to index.md
    echo "" >> "$INDEX_MD"
    echo "---" >> "$INDEX_MD"
    echo "## Custom HTML Content Section" >> "$INDEX_MD"
    echo "" >> "$INDEX_MD"
    echo "The following content is loaded from '$HTML_FILENAME':" >> "$INDEX_MD"
    # The shortcode call to embed the HTML file
    echo '{{< rawhtml "'"$HTML_FILENAME"'" >}}' >> "$INDEX_MD"
    echo "" >> "$INDEX_MD"
    echo "---" >> "$INDEX_MD"
    echo "" >> "$INDEX_MD"

    # --- Create the rawhtml shortcode if it doesn't exist ---
    SHORTCODE_DIR="layouts/shortcodes"
    RAWHTML_SHORTCODE="$SHORTCODE_DIR/rawhtml.html"

    if [ ! -f "$RAWHTML_SHORTCODE" ]; then
      mkdir -p "$SHORTCODE_DIR"
      echo "Creating Hugo shortcode: $RAWHTML_SHORTCODE"
      cat <<'EOF_SHORTCODE' > "$RAWHTML_SHORTCODE"
{{/*
  rawhtml shortcode
  Embeds raw HTML content from a file located in the same directory as the calling Markdown file.
  Usage: {{< rawhtml "your-file.html" >}}
*/}}
{{ $file := .Get 0 }}
{{ $path := printf "%s/%s" .Page.File.Dir $file }}
{{ if fileExists $path }}
    {{ readFile $path | safeHTML }}
{{ else }}
    {{ end }}
EOF_SHORTCODE
      echo "Shortcode '$RAWHTML_SHORTCODE' created. This enables embedding raw HTML from files."
    else
      echo "Shortcode '$RAWHTML_SHORTCODE' already exists. No need to recreate."
    fi
  fi
fi

echo "--- Done! ---"
echo "Your new blog post structure is ready at: $POST_DIR"
echo "1. Edit '$INDEX_MD' to add your Markdown content."
if [[ "$INCLUDE_HTML_CHOICE" =~ ^[Yy]$ && -n "$HTML_FILENAME" ]]; then
  echo "2. Add raw HTML content to '$HTML_FILEPATH'."
fi
echo "3. Run 'hugo serve' to preview site locally."
