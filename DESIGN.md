---
name: MaplibreX Demo
description: The runnable component reference of MaplibreX, each live map above the exact code that produced it.
colors:
  canvas: "#ffffff"
  surface: "#f4f4f6"
  surface-hover: "#e8e8ee"
  line: "#e3e3ea"
  line-strong: "#cfcfda"
  ink: "#1f2330"
  ink-muted: "#4a4a5a"
  ink-subtle: "#63637a"
  accent: "#5b3fa6"
  accent-hover: "#4b3390"
  accent-ink: "#5b3fa6"
  accent-soft: "#eee9f8"
  on-accent: "#ffffff"
  map-ink: "#1f2330"
  code: "#1f2330"
  code-ink: "#e9e9f2"
  code-muted: "#a3a6bd"
  code-line: "#343a4d"
  stable: "#17723a"
  stable-soft: "#e7f6ec"
  limited: "#8a5300"
  limited-soft: "#fdf1dc"
  planned: "#4a5470"
  planned-soft: "#eceff5"
  danger: "#b42318"
  danger-soft: "#fdecea"
  syntax-comment: "#8f94ad"
  syntax-string: "#a8d8a0"
  syntax-atom: "#7fd3c8"
  syntax-attribute: "#f0c27f"
  syntax-module: "#8fb8ff"
  syntax-number: "#f3a37a"
  syntax-keyword: "#c9a8ff"
  syntax-punct: "#a3a6bd"
typography:
  display:
    fontFamily: "Lato, ui-sans-serif, system-ui, sans-serif"
    fontSize: "2.25rem"
    fontWeight: 900
    lineHeight: 1.1
    letterSpacing: "-0.025em"
  headline:
    fontFamily: "Lato, ui-sans-serif, system-ui, sans-serif"
    fontSize: "1.375rem"
    fontWeight: 900
    lineHeight: 1.3
  lead:
    fontFamily: "Lato, ui-sans-serif, system-ui, sans-serif"
    fontSize: "1.0625rem"
    fontWeight: 400
    lineHeight: 1.6
  body:
    fontFamily: "Lato, ui-sans-serif, system-ui, sans-serif"
    fontSize: "1rem"
    fontWeight: 400
    lineHeight: 1.625
  nav:
    fontFamily: "Lato, ui-sans-serif, system-ui, sans-serif"
    fontSize: "0.9375rem"
    fontWeight: 400
    lineHeight: "1.375rem"
  ui:
    fontFamily: "Lato, ui-sans-serif, system-ui, sans-serif"
    fontSize: "0.875rem"
    fontWeight: 400
    lineHeight: "1.25rem"
  label:
    fontFamily: "Lato, ui-sans-serif, system-ui, sans-serif"
    fontSize: "0.75rem"
    fontWeight: 700
    lineHeight: "1rem"
  label-caps:
    fontFamily: "Lato, ui-sans-serif, system-ui, sans-serif"
    fontSize: "0.75rem"
    fontWeight: 700
    lineHeight: "1rem"
    letterSpacing: "0.1em"
  source:
    fontFamily: "JetBrains Mono, ui-monospace, SFMono-Regular, Menlo, monospace"
    fontSize: "0.875rem"
    fontWeight: 400
    lineHeight: 1.65
    fontFeature: "\"liga\" 0, \"calt\" 0"
  mono-label:
    fontFamily: "JetBrains Mono, ui-monospace, SFMono-Regular, Menlo, monospace"
    fontSize: "0.75rem"
    fontWeight: 400
    lineHeight: "1rem"
rounded:
  inline: "4px"
  ui: "6px"
  panel: "8px"
  full: "9999px"
spacing:
  topbar: "60px"
  sidebar: "280px"
  rail: "208px"
  preview: "360px"
  scenario: "512px"
  measure: "544px"
  page: "1056px"
components:
  button-primary:
    backgroundColor: "{colors.accent}"
    textColor: "{colors.on-accent}"
    typography: "{typography.ui}"
    rounded: "{rounded.ui}"
    padding: "0 16px"
    height: "40px"
  button-primary-hover:
    backgroundColor: "{colors.accent-hover}"
    textColor: "{colors.on-accent}"
  button-secondary:
    backgroundColor: "{colors.canvas}"
    textColor: "{colors.ink}"
    typography: "{typography.ui}"
    rounded: "{rounded.ui}"
    padding: "0 16px"
    height: "40px"
  button-secondary-hover:
    backgroundColor: "{colors.surface}"
  example-button:
    backgroundColor: "{colors.canvas}"
    textColor: "{colors.ink}"
    typography: "{typography.ui}"
    rounded: "{rounded.ui}"
    padding: "0 10px"
    height: "32px"
  example-button-hover:
    backgroundColor: "{colors.surface}"
  example-button-pressed:
    backgroundColor: "{colors.accent-soft}"
    textColor: "{colors.accent-ink}"
  input-search:
    backgroundColor: "{colors.canvas}"
    textColor: "{colors.ink}"
    typography: "{typography.ui}"
    rounded: "{rounded.ui}"
    padding: "0 36px"
    height: "36px"
  tree-item:
    textColor: "{colors.ink}"
    typography: "{typography.nav}"
    rounded: "{rounded.ui}"
    padding: "7px 10px"
  tree-item-hover:
    backgroundColor: "{colors.surface-hover}"
  tree-item-current:
    backgroundColor: "{colors.accent}"
    textColor: "{colors.on-accent}"
  tab:
    textColor: "{colors.ink-subtle}"
    typography: "{typography.ui}"
    padding: "10px 16px"
  tab-current:
    textColor: "{colors.accent-ink}"
  status-badge-stable:
    backgroundColor: "{colors.stable-soft}"
    textColor: "{colors.stable}"
    typography: "{typography.label}"
    rounded: "{rounded.ui}"
    padding: "2px 8px 2px 6px"
  status-badge-limited:
    backgroundColor: "{colors.limited-soft}"
    textColor: "{colors.limited}"
    typography: "{typography.label}"
    rounded: "{rounded.ui}"
    padding: "2px 8px 2px 6px"
  status-badge-planned:
    backgroundColor: "{colors.planned-soft}"
    textColor: "{colors.planned}"
    typography: "{typography.label}"
    rounded: "{rounded.ui}"
    padding: "2px 8px 2px 6px"
  code-block:
    backgroundColor: "{colors.code}"
    textColor: "{colors.code-ink}"
    typography: "{typography.source}"
    rounded: "{rounded.panel}"
    padding: "14px 16px"
  inline-code:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.ink}"
    rounded: "{rounded.inline}"
    padding: "0.05em 0.3em"
  chip:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.ink}"
    typography: "{typography.mono-label}"
    rounded: "{rounded.inline}"
    padding: "2px 6px"
  panel:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.ink}"
    typography: "{typography.ui}"
    rounded: "{rounded.panel}"
    padding: "12px 16px"
---

# Design System: MaplibreX Demo

## Overview

**Creative North Star: "The Reference That Runs"**

The demo is a component reference in the category standard of shadcn/ui and the MapLibre GL JS documentation: a white ground, a cool grey sidebar and top bar divided by one-pixel hairlines, near-black ink with a blue cast, and a single Elixir purple that marks where the reader is and what can be pressed. Nothing on the page competes with the two things a visitor came for, the running map and the code that produced it. The map preview sits directly above its source, and the source is shown on a dark code ground in both themes.

Density is that of documentation, not marketing: a 60 px top bar, a 280 px family tree, a reading column capped near 66rem with prose held to a 34rem measure, and an "On this page" rail on wide screens. Headings are heavy (Lato Black) and short; everything else is quiet. Depth comes from hairlines and a tonal grey surface, not from shadows; the one shadow is reserved for things that float above the page.

Light and dark themes share the same role names: the dark theme redefines the colour roles, so markup never states which theme it is in. The system refuses the full-bleed map under a floating glass panel that the demo had before; a map lives inside a framed preview, in the flow of the page.

**Key Characteristics:**
- One accent, Elixir purple, for the current location and for pressable things only.
- Lato for prose and interface, JetBrains Mono for anything typed as code.
- One-pixel hairlines and a tonal grey surface instead of shadows.
- Dark code blocks in both themes, highlighted on the server.
- Status always as a drawn mark plus a word, on a tint.
- Small, consistent corners: 6 px for controls, 8 px for panels.

## Colors

A neutral, slightly cool palette of greys and blue-cast ink, with one saturated purple and three muted status hues that only ever appear with a word.

### Primary
- **Elixir Purple** (accent): the fill of the current sidebar item, the primary call to action, and the active state of a map control button. Its hover fill is **Deep Elixir Purple** (accent-hover). In the dark theme the fill becomes `#6a4cc0` and hovers lighter (`#7a5dd0`).
- **Elixir Purple as Ink** (accent-ink): the accent used as text and strokes: the current tab underline, the current section underline in the top bar, the wordmark, links, issue numbers, focus outlines and the caret. Identical to the fill in light; lifts to `#b7a3f3` in dark so it stays legible on the dark ground.
- **Lavender Wash** (accent-soft): the tint behind a pressed example button, the "required" marker, the current item in the drawer's section list, text selection, and the fading highlight of a changed assign. Dark: `#2c2445`.
- **On Purple** (on-accent): text and icons on the purple fill, white in both themes.

### Secondary
- **Night Code** (code): the ground of every code block, in both themes (dark: `#0b0d12`). With **Code Ink** (code-ink) for source text, **Code Mist** (code-muted) for the file caption and the copy and expand buttons, and **Code Rule** (code-line) for the block's border and inner dividers.
- **Syntax set** (syntax-comment, syntax-string, syntax-atom, syntax-attribute, syntax-module, syntax-number, syntax-keyword, syntax-punct): pastel token colours tuned for the code ground of either theme; they never appear outside a code block.

### Tertiary
- **Stable Green** (stable) on **Stable Mint** (stable-soft); dark `#74d6a0` on `#133021`.
- **Limited Amber** (limited) on **Limited Cream** (limited-soft); dark `#f2bd63` on `#36280f`.
- **Planned Slate** (planned) on **Planned Mist** (planned-soft); dark `#aab5d2` on `#222939`.
- **Error Red** (danger) on **Error Blush** (danger-soft): the flash and map-error icon, a 40 % red border around an error notice, and input errors. Dark `#ff8f80` on `#3b1714`.

### Neutral
- **Paper White** (canvas): the page ground, the top bar, inputs and the floating notices. Dark: `#12141b`.
- **Cool Grey Surface** (surface): the sidebar and drawer, the map frame while it loads, table headers, issue panels, inline code and chips. Dark: `#191c25`. **Surface Hover** (surface-hover) is the hover fill of rows that already sit on the surface. Dark: `#242836`.
- **Hairline** (line): every one-pixel rule: top bar and sidebar edges, tab row, list and table dividers, panel borders. Dark: `#2a2e3b`. **Strong Hairline** (line-strong) borders inputs, outline buttons and the empty-filter box, and colours the scrollbar thumb. Dark: `#3d4255`.
- **Blue-Cast Ink** (ink): headings, body text and current labels. Dark: `#e8e9f1`.
- **Muted Ink** (ink-muted): leads, descriptions, secondary prose. Dark: `#bcbecc`.
- **Subtle Ink** (ink-subtle): captions, placeholders, group labels, inactive tabs, decorative icons. Dark: `#9a9db0`.
- **Map Ink** (map-ink): the text colour forced inside MapLibre's controls, attribution and popups, which stay on white in both themes.

### Named Rules
**The Pressable Purple Rule.** The accent marks the current location (sidebar item, top-bar section, tab, rail entry) and things that can be pressed (primary button, pressed choice, link, active map control). It is never decoration, never a heading colour, never a background panel.

**The Role Not Hue Rule.** Markup names roles (`canvas`, `surface`, `ink-muted`, `accent-ink`), never hues. A new colour is a new role defined in both themes; the two dark-theme blocks in the stylesheet stay identical.

**The Mark-and-Word Rule.** A status is always a drawn mark plus its word on its tint (check for stable, triangle for limited, clock for planned). Colour alone never carries a status.

**The Night Code Rule.** Code blocks keep their dark ground in both themes; syntax colours exist only on that ground.

## Typography

**Display Font:** Lato (with ui-sans-serif, system-ui, sans-serif), self-hosted at 400, 700 and 900
**Body Font:** Lato (with ui-sans-serif, system-ui, sans-serif)
**Label/Mono Font:** JetBrains Mono (with ui-monospace, SFMono-Regular, Menlo, monospace), self-hosted variable 100 to 800

**Character:** A plain, friendly humanist sans set heavy for headings and regular for everything else, paired with a code face that appears whenever the text is something a developer would type. The scale is a fixed set of rem steps of about 1.2, with no fluid sizes.

### Hierarchy
- **Display** (900, 2.25rem, 1.1, tracking -0.025em): the single page title: the library name on the overview, a component's name, Components, Scenarios, Roadmap, error pages.
- **Headline** (900, 1.375rem, 1.3): section headings within a page (Install, Components by family, a family on the components index, a scenario's name). The top-bar wordmark uses the same size and weight in accent ink.
- **Lead** (400, 1.0625rem, 1.6): the one-sentence summary under the page title, in muted ink, within the 34rem measure.
- **Body** (400, 1rem, 1.625): prose paragraphs, held to the 34rem measure. Sub-headings (h3) use this size at 700.
- **Nav** (400, 0.9375rem, 1.375rem line): sidebar tree items and top-bar section links; 700 when current.
- **UI** (400, 0.875rem, 1.25rem line): controls, tabs (700), table cells, notices, list descriptions.
- **Label** (700, 0.75rem, 1rem line): status badges, captions, button labels in small controls, "Previous" and "Next".
- **Label Caps** (700, 0.75rem, 0.1em tracking, uppercase): family group labels in the sidebar and on the roadmap, and the "On this page" rail title. Table headers use the same role at 0.06em.
- **Source** (JetBrains Mono 400, 0.875rem, 1.65): code blocks.
- **Mono Label** (JetBrains Mono, 0.75rem): file captions, assign names and values, attribute and event names, the version badge, issue numbers, labels of controls named after an assign.

### Named Rules
**The Typed-As-Code Rule.** Anything a developer would type (assigns, attributes, events, function names, file paths, versions, issue numbers) is set in JetBrains Mono; prose and interface labels are Lato.

**The As-Typed Rule.** Code, `kbd` and `pre` disable ligatures, so `->` and `=>` read as typed.

**The Heavy Few Rule.** Only page titles and section headings use Lato Black; everything below a heading is 400 or 700.

## Layout

A three-column documentation shell on wide screens. A sticky 60 px top bar spans the page (wordmark and version, the Components, Scenarios and Roadmap sections, search, language and theme switches). From 1024 px, a sticky 280 px sidebar on the cool grey surface holds the component tree grouped by family, scrolling on its own; below 1024 px it becomes a left drawer (a modal dialog, at most 20rem or 88 % of the width) opened from the top bar, and the section links move into the drawer below 768 px.

The main column has 16 px side padding on phones, 32 px from 640 px and 48 px from 1024 px, with about 32 px above and 96 px below. Content is capped at 66rem (1056 px); prose, leads and notes are capped at the 34rem (544 px) measure. From 1280 px, pages with sections add a 208 px "On this page" rail beside the content, separated by a 48 px gap, sticky under the top bar.

The component page is the signature composition: title and status badge, lead, an optional "why" panel, the tab row (Preview, HEEx, Events, Attributes), the 360 px map preview framed directly under the tabs, the example's controls and assign readout, then the template's code block about 18 px below. Scenarios use a 512 px preview from 640 px. Sections within a page are separated by 48 to 56 px; headings reached through a link stop 1.5rem below the top bar.

Spacing otherwise follows Tailwind's 4 px rhythm: 6 px gaps inside control rows, 12 to 16 px inside panels, 20 px between a heading and its content.

### Named Rules
**The Code Beneath Rule.** An example's map and the code that produces it are adjacent in one column: preview first, source directly below, never in separate pages or side by side.

## Elevation & Depth

The system is flat. Depth is conveyed by one-pixel hairlines and by the tonal step from paper white to the cool grey surface; panels, tables, cards and code blocks sit on the page with a border and no shadow. One shadow exists, for elements that float above the page: the navigation drawer, flash notices, the map error notice and the skip link. The drawer's backdrop is ink at 40 % opacity.

### Shadow Vocabulary
- **Overlay** (`box-shadow: 0 18px 40px -12px rgb(16 18 30 / 0.3), 0 2px 6px -2px rgb(16 18 30 / 0.12)`): anything that floats above the page and must read as detached from it.

### Named Rules
**The Hairline First Rule.** A resting surface separates itself with a one-pixel line or a tonal step, never a shadow. Shadow means "floating", and nothing else.

## Shapes

Corners are small and consistent. Controls (buttons, inputs, tree items, badges, switches) use a gently rounded 6 px corner; containers (code blocks, panels, tables, the pager, the preview's bottom edge) use 8 px. Inline elements nested in text or inside controls (inline code, chips, count pills, the key hint) use a tight 4 px corner. Full rounding is kept for small circles: install step numbers, colour swatches and the heatmap legend. The preview frame is square-topped where it meets the tab row and rounded at its bottom corners, so tabs, map, controls and readout read as one object.

Borders are always one pixel. The current tab and the current top-bar section carry a 2 px underline in accent ink; the current rail entry carries a one-pixel left rule in accent ink.

## Components

### Buttons
Restrained and compact; the purple fill is spent on one action per view.
- **Shape:** gently rounded (6 px).
- **Primary:** purple fill with white text, UI size at 700, 40 px tall with 16 px side padding, an optional trailing arrow icon. Used for the overview's main action and for error-page actions.
- **Hover / Focus:** the fill deepens to accent-hover; focus is a 2 px outline in accent ink, offset 2 px, on every interactive element.
- **Secondary:** the same size with a strong-hairline border on the ground and ink text; hover fills with the grey surface.
- **Example buttons:** 32 px tall, 10 px side padding, strong-hairline border; hover darkens the border to subtle ink and fills with surface; pressed choices take a lavender wash with an accent-ink border and text and expose `aria-pressed`. Buttons named after a function or value set their label in mono.
- **Icon buttons:** 36 px square (28 px in small groups), subtle ink, filling with surface on hover.

### Chips
- **Style:** component-name chips on the grey surface with a 4 px corner, mono label size, ink text; hover fills with surface-hover and turns the text accent ink.
- **Sample-data badge:** a strong-hairline outline badge with a beaker mark and the words "Sample data", in muted ink.

### Status Badges
- **Style:** mark plus word, label size at 700, on the status tint with the status colour as text, 6 px corner, 2 px vertical and 6 to 8 px horizontal padding. In the sidebar, a non-stable component shows its mark alone with a screen-reader word; on the current (purple) item the mark turns white.

### Cards / Containers
- **Corner Style:** 8 px.
- **Background:** the grey surface for notes and "why it is limited" panels; the ground for tables and the pager.
- **Shadow Strategy:** none at rest (see Elevation & Depth).
- **Border:** one-pixel hairline; tables add a surface-filled header row with Label Caps, hairline row dividers and a strong-hairline rule above the totals.
- **Internal Padding:** 12 to 14 px vertical, 16 px horizontal.
- **Pager:** two bordered panels for previous and next; hover strengthens the border, fills with surface and turns the name accent ink.

### Inputs / Fields
- **Style:** 36 px tall, strong-hairline border on the ground, 6 px corner, UI size, placeholder in subtle ink. The search field carries a leading magnifier and, in the top bar, a "/" key hint.
- **Focus:** the global accent-ink outline; the caret is accent ink.
- **Error:** the border turns danger, and an error line with a mark follows in danger at label size.
- **Sliders and checkboxes:** native controls tinted with the accent, labelled in mono with the assign they set.

### Navigation
- **Top bar:** section links at nav size in muted ink; the current section is accent ink at 700 with a 2 px accent underline sitting on the bar's bottom hairline.
- **Sidebar tree:** family labels in Label Caps; items at nav size in ink with 7 px by 10 px padding and a 6 px corner; hover fills with surface-hover; the current item is filled purple with white bold text.
- **Tabs:** UI size at 700 in subtle ink with a 2 px underline that is transparent at rest and accent ink when current; Events and Attributes show their count in a small surface pill.
- **"On this page" rail:** UI-size links in muted ink on a hairline left rule; the section being read turns accent ink and bold with an accent rule.
- **Segmented switches** (language, theme): a surface-filled group with a hairline border and 2 px padding; the chosen segment sits on the ground in ink.
- **Mobile:** the sidebar becomes a drawer sliding in from the left (240 ms, ease-out-expo) over an ink backdrop.

### Code Block (signature)
The dark figure on which every source appears. A 40 px caption bar names the file in mono label at code-muted, with a "Copy" button that switches to "Copied" for two seconds. The source is set in Source type with 14 px by 16 px padding, scrolls horizontally, and is highlighted on the server. A long source (over 24 lines) shows its first 20 lines under a fade into the code ground, with a full-width "Show full source" toggle; the whole source stays in the page.

### Example Panel (signature)
The framed preview under the tab row: a 360 px map frame on the surface ("Loading the map" until MapLibre paints), the example's control groups (a label in subtle ink, a row of example buttons, sliders), and a readout of the current assigns as `@name value` in mono. A value that changes flashes the lavender wash in accent ink and fades out over 1.4 s. MapLibre's own controls stay on white with map ink; an active custom control button is filled purple.

The basemap follows the theme, live: OpenFreeMap's Positron or Liberty in the light theme, its Dark style in the dark theme. The heatmap, particles and deck.gl scenarios keep the dark basemap in both themes, because their data is drawn for a dark ground, and the two blank-style examples draw their own ground. The attribution strip is 85 % white rather than MapLibre's 50 % (the compact one stays opaque), so its text stays legible over the dark basemap. Sample data on the maps uses a lighter purple (`#7c5cd6`) than the accent, one that reads on both basemaps; the few colours tied to the ground follow the theme too: label halos take the page's canvas, fill outlines the theme's ink, the blank-style land and the 3D scenario's hillshading darken in the dark theme.

## Do's and Don'ts

### Do:
- **Do** reserve the purple for the current location and for pressable things (The Pressable Purple Rule).
- **Do** name colours by role and define every new role in both themes, keeping the two dark-theme blocks identical.
- **Do** show every status as its mark plus its word on its tint.
- **Do** set code, assigns, attributes, events, paths and versions in JetBrains Mono with ligatures off.
- **Do** place an example's source directly beneath its running map, on the dark code ground.
- **Do** separate resting surfaces with one-pixel hairlines and the grey surface; keep the overlay shadow for drawers, notices and the map error.
- **Do** use 6 px corners on controls, 8 px on containers and 4 px on inline elements.
- **Do** keep prose within the 34rem measure and page content within 66rem.
- **Do** honour reduced motion: animations and transitions collapse to near zero.

### Don't:
- **Don't** put a full-bleed map under a floating glass panel; a map lives in a framed preview in the page flow.
- **Don't** convey a status by colour alone.
- **Don't** introduce a second accent hue or use the purple as decoration, a heading colour or a panel fill.
- **Don't** give code blocks a light ground in the light theme, or use syntax colours outside code.
- **Don't** put shadows on resting cards, panels, tables or code blocks.
- **Don't** use raw Tailwind palette colours (gray, violet, green) in interface markup; use the role tokens.
- **Don't** render code with ligatures.
