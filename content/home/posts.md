<!-- ---
# An instance of the Featured Posts widget.
# Documentation: https://docs.hugoblox.com/getting-started/page-builder/
widget: pages #pages # As of v5.8-dev, 'pages' is renamed 'collection'

# This file represents a page section.
headless: true

# Order that this section appears on the page.
weight: 20

title: Recent Posts
subtitle: ''

content:
  # Filter content to display
  filters:
    # The folders to display content from
    folders:
      - post
    tag: ''
    category: ''
    publication_type: ''
    author: ''
    featured_only: false
    exclude_featured: false
    exclude_future: false
    exclude_past: false
  # Choose how many pages you would like to display (0 = all pages)
  count: 10
  # Choose how many pages you would like to offset by
  # Useful if you wish to show the first item in the Featured widget
  offset: 0
  # Field to sort by, such as Date or Title
  sort_by: 'Date'
  sort_ascending: false
design:
  # Choose a listing view
  view: compact
  # Choose how many columns the section has. Valid values: '1' or '2'.
  columns: '1' -->