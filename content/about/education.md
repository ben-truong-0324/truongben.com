---
# An instance of the Experience widget.
# Documentation: https://docs.hugoblox.com/page-builder/
widget: experience

# This file represents a page section.
headless: true

# Order that this section appears on the page.
weight: 30

title: Education
subtitle:

# Date format for experience
#   Refer to https://docs.hugoblox.com/customization/#date-format
date_format: Jan 2006

# Experiences.
#   Add/remove as many `experience` items below as you like.
#   Required fields are `title`, `company`, and `date_start`.
#   Leave `date_end` empty if it's your current employer.
#   Begin multi-line descriptions with YAML's `|2-` multi-line prefix.
experience:
  - title: M.S. Computer Science (Machine Learning Track)
    company: Georgia Institute of Technology
    location: Remote
    company_url: https://www.gatech.edu
    date_start: 2023-08-01
    date_end: 2026-05-01
    description: |-
      * Fine-tuned RL with DynaQ models for stock trading, achieving a 3% gain over S&P 500 in back-tests.
      * Improved ICU diagnosis model (Gangavarapu et al, 2020) from 80% to 98% accuracy using NLP on unstructured clinical notes.
      * Built A* and Dijkstra path planning models with real-time Bayesian updates for simulated robot and network traffic environments.

  - title: Palantir Winter Developer Fellowship
    company: Palantir Technologies
    location: Remote
    date_start: 2024-12-01
    date_end: 2025-01-31
    description: |-
      * Used AIP platform to build an ETL pipeline and LLM evaluation dashboard for rapid model analysis and selection.

  - title: B.A. Cognitive Science (High Honors)
    company: UC Berkeley
    location: Berkeley, CA
    company_url: https://www.berkeley.edu
    date_start: 2017-08-01
    date_end: 2019-05-31
    description: |-
      * GPA: 3.8 / 4.0
      * Glushko Prize for thesis on Outgroup Alienation and Empathy Suppression: behavioral + neurological mechanisms.


design:
  columns: '1'
---
