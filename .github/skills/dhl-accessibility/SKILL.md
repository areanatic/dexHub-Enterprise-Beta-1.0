---
name: dhl-accessibility
description: "DHL accessibility and WCAG 2.2 compliance guide — use when reviewing accessibility, checking ARIA patterns, keyboard navigation, color contrast, screen reader support, or inclusive design questions."
---

# DHL UI Library — Accessibility Guide

This skill provides the accessibility checklist and WCAG compliance rules for the DHL UI Library.
For full documentation, read: `myDex/projects/dhl-ui-library-kb/.dex/1-analysis/01-FOUNDATIONS.md` (Section 6)

## Testing Tools

| Tool | Platform | Purpose |
|------|----------|---------|
| Axe DevTools | Chrome Extension | Automated a11y checks |
| NVDA | Windows | Screen reader |
| JAWS | Windows | Screen reader |
| VoiceOver | macOS | Native screen reader |
| TalkBack | Android | Native screen reader |
| High Contrast Mode | All | Visual accessibility |
| Browser Zoom | All | Text resize testing |

## WCAG 2.2 AA Checklist

### 1. Perceivable

#### Text Alternatives (1.1)
- Every `<img>` needs meaningful `alt` text
- Decorative images: `alt=""` or `dataRole="presentation"`
- `dhl-icon`: Use `alt` prop for meaningful icons, `dataAriaHidden="true"` for decorative
- `dhl-image`: `alt` is **required** prop

#### Color Contrast (1.4.3 / 1.4.11)
- **Text:** Minimum 4.5:1 ratio (normal text), 3:1 (large text 18px+)
- **UI Components:** Minimum 3:1 ratio against adjacent colors
- Use semantic color tokens — they are pre-validated for contrast
- Test in both light AND dark theme

#### Resize (1.4.4)
- Content must be usable at 200% zoom
- DHL UI Library uses rem-based sizing (scales automatically)
- `--dui-size-theme` variable controls global scaling

### 2. Operable

#### Keyboard (2.1)
- ALL interactive elements must be keyboard accessible
- Visible focus indicators on ALL focusable elements
- Tab order must be logical and predictable
- `dhl-modal`: ESC closes, `trapFocus` keeps focus inside
- `dhl-accordion`: Arrow keys navigate panels
- `dhl-tabs`: Arrow keys switch tabs
- `dhl-dropdown`: Arrow keys navigate options, Enter selects

#### Focus Management
```jsx
// DO: Let browser handle focus order
<DhlButton>First</DhlButton>
<DhlInputField variant={{ label: "Second" }} />

// DON'T: Use tabIndex > 0
<div tabIndex="5">Bad practice</div>

// DO: Use tabIndex="0" only for custom interactive elements
// DO: Use tabIndex="-1" for programmatic focus targets
```

#### No Keyboard Traps (2.1.2)
- User must be able to navigate away from any element
- `dhl-modal` with `trapFocus`: Must have close button AND ESC support
- `dhl-dropdown`: ESC closes dropdown, focus returns to trigger

### 3. Understandable

#### Labels & Instructions (3.3.2)
- Every form field MUST have a label via `variant={{ label: "..." }}`
- Use `for`/`id` pairing (DHL components handle this automatically)
- Group related inputs with context (fieldset pattern)
- `dhl-checkbox-group` / `dhl-radio-button` group: Use shared `name`

#### Error Messages (3.3.1)
```jsx
// Clear error with fix instruction
<DhlInputField
  variant={{ label: "E-Mail" }}
  validation={{
    type: "invalid",
    message: "Bitte gueltige E-Mail eingeben (z.B. name@example.com)"
  }}
  dataAriaDescribedby="email-error"
/>
```

#### Consistent Navigation (3.2.3)
- Navigation order consistent across pages
- Same components behave the same way everywhere
- Use `dhl-navbar` for consistent top navigation

### 4. Robust

#### Valid HTML (4.1.1)
- Use semantic HTML elements
- `lang` attribute on `<html>`
- Landmark elements: `<main>`, `<nav>`, `<aside>`, `<footer>`
- `<button>` for actions, `<a>` for navigation
- `<table>` for tabular data with `<th>` and `<caption>`

#### ARIA (4.1.2)
- DHL components handle ARIA automatically
- Custom content needs manual ARIA:

```jsx
// DHL components — ARIA built in
<DhlButton>Action</DhlButton>  // role="button" automatic

// Custom elements — add ARIA manually
<div role="alert" aria-live="polite">Error message</div>

// Expandable regions
<DhlButton dataAriaExpanded={isOpen} dataAriaControls="panel-1">
  Toggle
</DhlButton>
<div id="panel-1" hidden={!isOpen}>Content</div>
```

## DHL Component ARIA Props

All interactive DHL components support:

| Prop | ARIA Attribute | Usage |
|------|---------------|-------|
| `dataAriaLabel` | `aria-label` | Screen reader text (alternative to visible label) |
| `dataAriaDescribedby` | `aria-describedby` | References error/help text IDs |
| `dataAriaExpanded` | `aria-expanded` | Expandable region state |
| `dataAriaControls` | `aria-controls` | ID of controlled element |
| `dataAriaPressed` | `aria-pressed` | Toggle button state |
| `dataAriaHasPopup` | `aria-haspopup` | Popup presence |
| `dataAriaLabelledby` | `aria-labelledby` | References labeling element |
| `dataRole` | `role` | ARIA role override |

## Common Violations & Fixes

### V1: Missing Form Labels
```jsx
// WRONG
<DhlInputField type="email" />

// CORRECT
<DhlInputField variant={{ label: "E-Mail Adresse" }} type="email" />
```

### V2: Images Without Alt Text
```jsx
// WRONG
<DhlImage src="/photo.jpg" />

// CORRECT
<DhlImage src="/photo.jpg" alt="DHL Paketbote uebergibt Sendung" />

// DECORATIVE
<DhlIcon src={decorativeIcon} dataAriaHidden="true" dataRole="presentation" />
```

### V3: Hardcoded Colors Breaking Contrast
```css
/* WRONG — may fail contrast in dark theme */
.label { color: #666666; }

/* CORRECT — tokens are contrast-validated */
.label { color: var(--dui-colors-foreground-secondary); }
```

### V4: Missing Skip Link
```html
<!-- Add before navbar -->
<a href="#main-content" class="skip-link">Zum Hauptinhalt springen</a>
<DhlNavbar ... />
<main id="main-content">...</main>
```

### V5: Heading Hierarchy Broken
```jsx
// WRONG — skips h2
<DhlHeadline tag="h1">Page</DhlHeadline>
<DhlHeadline tag="h3">Section</DhlHeadline>

// CORRECT — descending order
<DhlHeadline tag="h1" designLevel="1">Page</DhlHeadline>
<DhlHeadline tag="h2" designLevel="3">Section</DhlHeadline>  // visual small, semantic correct!
```

### V6: Button vs Link Confusion
```jsx
// WRONG — action as link
<DhlLink href="#" clickEvent={handleDelete}>Loeschen</DhlLink>

// CORRECT — action as button
<DhlButton variant="text" clickEvent={handleDelete}>Loeschen</DhlButton>

// CORRECT — navigation as link
<DhlLink href="/details/123">Details ansehen</DhlLink>
```

## Content & Writing Rules

- Target reading level: 8th grade
- No vague phrases: "Click here" → "Sendung verfolgen"
- One `<h1>` per page
- Descending heading hierarchy (h1 → h2 → h3, never skip)
- Adequate line spacing for low-vision users
- `autocomplete` attribute on form fields where applicable

## Audit Checklist (Quick)

- [ ] All images have alt text (or are marked decorative)
- [ ] Color contrast meets 4.5:1 (text) / 3:1 (UI)
- [ ] All forms have visible labels
- [ ] All interactive elements keyboard accessible
- [ ] Focus indicators visible
- [ ] Tab order is logical
- [ ] Skip link present
- [ ] Heading hierarchy correct (no skips)
- [ ] Error messages clear and linked via aria-describedby
- [ ] Modals trap focus and close with ESC
- [ ] Language attribute set on `<html>`
- [ ] Tested with screen reader (VoiceOver/NVDA)
- [ ] Works at 200% zoom
- [ ] Works in high contrast mode
