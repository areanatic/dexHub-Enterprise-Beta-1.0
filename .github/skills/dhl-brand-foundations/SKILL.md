---
name: dhl-brand-foundations
description: "DHL brand design foundations — use when user asks about colors, typography, spacing tokens, grid system, design tokens, dark theme, or brand refresh. Covers the complete DHL visual identity system."
---

# DHL Brand & Design Foundations

This skill provides the DHL UI Library design system foundations (v2.30.1).
For full documentation, read: `myDex/projects/dhl-ui-library-kb/.dex/1-analysis/01-FOUNDATIONS.md`

## Responsive Grid System

### Breakpoints

| Breakpoint | Min-Width | Container | Gutter |
|------------|-----------|-----------|--------|
| **SM** | 320px (20rem) | 280px | 1.25rem |
| **MD** | 768px (48rem) | 700px | 1.25rem |
| **LG** | 1024px (64rem) | 940px | 1.25rem |
| **XL** | 1365px (85.3125rem) | 1204px | 1.25rem |
| **2XL** | 1920px (120rem) | 1204px | 1.25rem |

Uniform 1.25rem guttering. SM has additional 1.25rem offset margin.

### Grid Usage
```jsx
<DhlGridContainer columns={[1, 2, 3, 4]}>  // sm:1, md:2, lg:3, xl:4 columns
  <DhlGridCell spanColumns={[12, 6, 4, 3]}> // responsive spanning
```

## Metric System (Spacing)

Base: **16px** (1rem). Scaling factor: `--dui-size-theme: 1`

### Space Tokens
```css
--dui-size-space-0        /* 0 */
--dui-size-space-1x       /* base unit */
--dui-size-space-2x       /* 2x base */
--dui-size-space-4x       /* 4x base */
--dui-size-space-8x       /* 8x base */
--dui-size-space-12x
--dui-size-space-16x
--dui-size-space-20x
--dui-size-space-full     /* 100% */
```

### Custom Scaling
```css
:root { --dui-size-theme: 1.2; } /* 20% larger */
```

## Semantic Colors

### Categories

| Category | Purpose | Token Pattern |
|----------|---------|---------------|
| **Foreground** | Text, visible elements | `--dui-colors-foreground-{variant}` |
| **Background** | Base layer | `--dui-colors-background-{variant}` |
| **Action FG** | Button/link text | `--dui-colors-action-foreground-{variant}` |
| **Action BG** | Button backgrounds | `--dui-colors-action-background-{variant}` |
| **Icons** | Icon colors | `--dui-colors-icon-{variant}` |
| **Stroke** | Borders, outlines | `--dui-colors-stroke-{variant}` |

### Essential Tokens
```css
/* Most used */
var(--dui-colors-background-base)          /* Page background */
var(--dui-colors-foreground-primary)       /* Main text */
var(--dui-colors-action-background-primary) /* Primary button */
var(--dui-colors-stroke-default)           /* Borders */
```

### CRITICAL RULE: Never Hardcode Colors!
```css
/* WRONG — breaks dark theme */
.my-component { color: #333333; background: #ffffff; }

/* CORRECT — works in all themes */
.my-component {
  color: var(--dui-colors-foreground-primary);
  background: var(--dui-colors-background-base);
}
```

## Typography

### Font System
```css
var(--dui-typography-font-family-{name})    /* Font families */
var(--dui-typography-font-size-{step})      /* Sizes (rem-based) */
var(--dui-typography-font-weight-{name})    /* 200, 400, 700, 800 */
var(--dui-typography-letter-spacing-{name})
var(--dui-typography-line-height-{name})
```

### Headline Component
| designLevel | Usage |
|-------------|-------|
| 1 | Page title (largest) |
| 2 | Section header |
| 3 | Sub-section |
| 4 | Card header |
| 5 | Smallest heading |

**Important:** `tag` = semantics (h1-h6), `designLevel` = visual size. Never skip heading levels!

### Text Component Sizes
```
xs | sm | md (default) | lg | xl | 2xl | 3xl | ... | 11xl
```
Weights: `200` (light) | `400` (regular) | `700` (bold) | `800` (black)

## Other Design Tokens

| Category | Token Pattern | Examples |
|----------|---------------|----------|
| **Animation** | `--dui-animation-duration-{name}` | Transitions |
| **Gradient** | `--dui-gradient-{name}` | Color gradients |
| **Radius** | `--dui-radius-{name}` | Border radius |
| **Border Width** | `--dui-border-width-{name}` | Stroke widths |
| **Highlight** | `--dui-highlight-{name}` | Element highlights |
| **Shadow** | `--dui-shadow-{name}` | Box shadows |
| **Icon Sizes** | `--dui-icon-size-{name}` | Icon dimensions |

## Dark Theme

Enable via `dhl-theme-switch` component (since v2.15.0):
```html
<dhl-theme-switch></dhl-theme-switch>
```

Sets `data-dui-theme` on `<html>`. Values: `"theme-light"` (default) / `"theme-dark"`.

Recommended variables for custom elements:
- Background: `var(--dui-colors-background-base)`
- Text: `var(--dui-colors-foreground-primary)`

## Brand Refresh (v2.28.1+)

```html
<!-- Enable brand refresh styles -->
<html data-dui-brand-refresh-ui-enabled="true">

<!-- Or via localStorage -->
localStorage.setItem('is-brand-refresh-ui-enabled', 'true')
```

## BrandHub Assets

Available locally (if BrandHub assets have been imported into the KB project):
```
myDex/projects/dhl-ui-library-kb/.dex/inputs/brandhub/
├── DHL_Logo_2025-V1-0/          ← Official logo files
├── Delivery_V2.500/              ← DHL font family
├── DHL_Quick_Start_Guide_*.pptx  ← Brand quick start
├── DHL_Layout_and_Image_Library_*.pptx ← Layout rules
├── DHL_Illustration_Library_*.pptx     ← Illustration system
├── DHL_Template_Basics-Library_*/      ← Base templates
└── DHL_Dynamic-Elements_Starter-Kit_*/ ← Dynamic elements
```

## Component Size Consistency

| Value | Available in |
|-------|-------------|
| `"XS"` | Button only |
| `"SM"` | Most components |
| `"MD"` | Default for most |
| `"LG"` | Loader, Avatar |
| `"XL"` | Loader, Avatar |
