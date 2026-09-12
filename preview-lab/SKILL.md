---
name: preview-lab
description: Publish Hermes UI, UX, wireframe, and landing page artifacts to the shared Preview Lab URL.
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux]
triggers:
  - landing page
  - web UI
  - UI/UX
  - wireframe
  - prototype
  - demo page
  - preview
  - frontend
---

# Hermes Preview Lab

Use this skill whenever the user asks for a web UI, UI/UX concept, wireframe,
landing page, product research presentation, interactive prototype, or frontend
demo that they should be able to inspect in a browser.

## Preview Contract

The shared preview base URL is:

```text
https://preview.cloudnes.space
```

Publish completed browser artifacts with:

```bash
hermes-preview-publish <source_dir> <slug> "<title>" "<summary>"
```

The command returns the public URL:

```text
https://preview.cloudnes.space/sites/<slug>/
```

## Workflow

1. Clarify the brief only when the missing detail would change the product direction.
2. Research the product, competitors, references, audience, and conversion goal when needed.
3. Create the UI artifact as HTML/CSS/JS or as a built static app.
4. Make the first screen useful immediately. Avoid marketing filler for tools or dashboards.
5. Verify that `index.html` exists and the page renders without broken assets.
6. Publish with `hermes-preview-publish`.
7. Return the preview URL to the user and mention what was built.

## Build Locations

Use a project-specific working folder, for example:

```text
/root/hermes-workspace/previews/<slug>
```

For a static HTML artifact, publish that folder directly. For Vite/React or
similar, run the build and publish the build output directory, usually `dist`.

## Slug Rules

Use short lowercase slugs:

```text
sepatu-landing
produk-a-research-ui
crm-wireframe
```

Only use lowercase letters, numbers, and hyphens.

## Security

Never publish secrets, `.env` files, API keys, auth tokens, private customer
data, or internal logs. Use mock data in prototypes unless the user explicitly
provides publishable content.
