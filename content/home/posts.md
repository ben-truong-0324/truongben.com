---
# An instance of the Featured Posts widget.
# Documentation: https://docs.hugoblox.com/getting-started/page-builder/
widget: posts

# This file represents a page section.
headless: true

# Order that this section appears on the page.
weight: 20

title: Recent Posts
subtitle: ''

content:
  # Page type to display. E.g. post, event, or publication.
  page_type: post

  # Choose how many posts to display (0 = all).
  count: 5

  # Filter on criteria
  filters:
    author: ''
    category: ''
    tag: ''
    publication_type: ''
    exclude_featured: false
    exclude_future: false
    exclude_past: false
  
  # Choose how to order the posts.
  order: desc # asc or desc

design:
  # Choose a layout view for the listings:
  #   1 = List
  #   2 = Compact
  #   3 = Card
  #   4 = Citation (ideal for publications)
  view: 2 
---