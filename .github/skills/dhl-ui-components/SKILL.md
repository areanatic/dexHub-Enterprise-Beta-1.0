---
name: dhl-ui-components
description: "DHL UI Library component reference — use when user asks about UI components, their props, variants, events, slots, code examples, or when-to-use decisions. Covers 30+ components across React, Angular, and Vue.js."
---

# DHL UI Library — Component Reference

This skill provides the complete API reference for all DHL UI Library components (v2.30.1).
For the full detailed documentation, read: `myDex/projects/dhl-ui-library-kb/.dex/1-analysis/02-COMPONENTS.md`

## Import Pattern (all components)

```javascript
// React
import { DhlButton } from "@dhl-official/react-library"

// Vue.js
import { DhlButton } from "@dhl-official/vue-library"

// Angular / Web Component
// <dhl-button></dhl-button>
```

**NPM Token required** (contact DHL UI Library Team, DHL CSI)

## Common Props (nearly all components)

| Prop | Type | Description |
|------|------|-------------|
| `dataId` | string | HTML ID (auto-generated if empty) |
| `dataTestid` | string | Test identifier |
| `dataClassName` | string | Additional CSS class |
| `dataAriaLabel` | string | Screen reader text |
| `dataAriaDescribedby` | string | Reference IDs for error messages |
| `dataTracking` | string | Analytics tracking |

## Component Decision Tree

### "I need user input..."
- **Text input** → `dhl-input-field` (most versatile form component)
- **Select from list** → `dhl-dropdown` (multi-select, groups, filter) or `dhl-select` (simple single-select with autocomplete)
- **Type-ahead suggestions** → `dhl-autocomplete-field`
- **Yes/No toggle** → `dhl-checkbox`
- **One of many** → `dhl-radio-button`
- **Date** → `dhl-datepicker` or `dhl-date-range-picker`
- **Number +/-** → `dhl-counter`

### "I need to show content..."
- **Card container** → `dhl-card` (slots: header, footer, image)
- **Data table** → `dhl-table` (columns, rowData, striped)
- **List of items** → `dhl-list` (bullet, check, number)
- **User avatar** → `dhl-avatar` (image, initials, icon + badge)
- **Tags/filters** → `dhl-chip` (selectable, dismissible)
- **Loading state** → `dhl-loader` (ring, ring-dual, ring-percentage, ring-done)

### "I need navigation..."
- **Top navbar** → `dhl-navbar` (logo, nav items, search, mobile)
- **Tab sections** → `dhl-tabs` (horizontal, vertical, icons)
- **Collapsible sections** → `dhl-accordion` + `dhl-panel`
- **Page footer** → `dhl-footer` (copyright, meta, social)

### "I need feedback..."
- **Notification** → `dhl-alert` (toast or inline, 5 types)
- **Dialog/confirm** → `dhl-modal` (header, footer, focus trap)
- **Tooltip** → `dhl-popover` (top, right, bottom, left)

### "I need actions..."
- **Primary action** → `dhl-button` (7 variants: primary, outline, ghost, tonal, text, ghostBlack, outlineBlack)
- **Grouped buttons** → `dhl-button-group` (horizontal, vertical)
- **Selectable card** → `dhl-selectable-card` (checkbox or radio mode)

### "I need layout..."
- **Grid system** → `dhl-grid-container` + `dhl-grid-cell`
- **Icons** → `dhl-icon` (from @dhl-official/icons)
- **Images** → `dhl-image` (responsive, srcset, aspect-ratio)

## Key Components Quick Reference

### dhl-button
```jsx
<DhlButton variant="primary" size="MD" icon={ArrowIcon} iconOrientation="right">
  Absenden
</DhlButton>
```
Variants: `primary` | `outline` | `ghost` | `ghostBlack` | `outlineBlack` | `text` | `tonal`
Sizes: `XS` | `SM` | `MD`

### dhl-input-field
```jsx
<DhlInputField
  variant={{ label: "E-Mail", placeholder: "name@example.com" }}
  type="email"
  required
  validation={{ type: "invalid", message: "Ungueltige E-Mail" }}
/>
```
Events: `dhlInput` | `dhlChange` | `dhlBlur` | `dhlFocus` | `dhlKeyDown`
Methods: `checkValidity()` | `reportValidity()` | `getInputElement()`

### dhl-dropdown
```jsx
<DhlDropdown
  label="Land auswaehlen"
  name="country"
  data={[
    { label: "Deutschland", value: "DE" },
    { type: "group", label: "EU", items: [
      { label: "Frankreich", value: "FR" }
    ]}
  ]}
  multiple
  showFilter
/>
```
Events: `dhlChange` | `dhlOpen` | `dhlClose` | `dhlFilter` | `dhlClickOption`

### dhl-card
```jsx
<DhlCard size="md">
  <DhlHeadline slot="header" designLevel="4" noMargin>Titel</DhlHeadline>
  <DhlText>Inhalt hier</DhlText>
  <div slot="footer"><DhlButton>Aktion</DhlButton></div>
</DhlCard>
```
Slots: `header` | `footer` | `image` | `menu` | unnamed

### dhl-alert
```jsx
<DhlAlert
  type="success"        // error | info | neutral | success | warning
  variant="toast"       // toast | inline
  titleText="Gespeichert"
  bodyText="Aenderungen uebernommen."
  position="top-right"
  duration={5000}
/>
```

### dhl-modal
```jsx
<DhlModal isOpen={show} isFullScreenOnMobile trapFocus>
  <DhlHeadline slot="header" designLevel="4" noMargin>Dialog</DhlHeadline>
  <DhlText>Sind Sie sicher?</DhlText>
  <DhlButtonGroup slot="footer">
    <DhlButton variant="primary">Ja</DhlButton>
    <DhlButton variant="outline">Abbrechen</DhlButton>
  </DhlButtonGroup>
</DhlModal>
```

### dhl-table
```jsx
<DhlTable
  caption="Sendungen"
  variant="striped"
  columns={[
    { name: "Nr.", selector: "id" },
    { name: "Status", selector: "status", textAlign: "center" }
  ]}
  rowData={[
    { id: "1", status: "Zugestellt" },
    { id: "2", status: "Unterwegs" }
  ]}
  mobileVariant="vertical"
/>
```

### dhl-icon
```javascript
// Direct import (tree-shaking)
import CalendarIcon from "@dhl-official/icons/calendar-friday-english.svg"
// Named export
import { CalendarFridayEnglish } from "@dhl-official/icons"
// Icons object (no tree-shaking)
import { icons } from "@dhl-official/icons"
// → icons.calendarFridayEnglish
// Flags
import { DE, US } from "@dhl-official/icons"

<DhlIcon src={CalendarIcon} size="2rem" alt="Kalender" />
```

## Validation Pattern (all form components)

```jsx
// Prop-based
validation={{ type: "invalid", message: "Fehler" }}   // invalid | valid | warning | note

// Method-based (async)
await component.checkValidity()        // → boolean
await component.reportValidity()       // → boolean
await component.getValidationMessage() // → string
await component.setValidity(validity, message)
```

## Event Pattern (v2)

Three mechanisms (not old/new — they coexist):
```jsx
// 1. React synthetic event handler (recommended in React)
onDhlChange={(e) => e.detail.value}

// 2. Custom DOM event name (for addEventListener)
element.addEventListener('dhlChange', (e) => e.detail.value)

// 3. Prop-based handler (v2 — works in all frameworks)
changeEvent={(e) => e.detail.value}
```

**Migration from v1:** `onClick` → `clickEvent`, `onChange` → `changeEvent`

## Migration v1 → v2

| Old (v1) | New (v2) |
|----------|----------|
| `onClick` | `clickEvent` or `dhlClick` |
| `onChange` | `changeEvent` or `dhlChange` |
| `disabled` | `isDisabled` |
| `isBlock` | `isFullWidth` |
| `fontStretch` | `stretch` |
| `onClose` | `handleOnClose` |
| `isStatic` | `trapFocus` |
| `onKeyPress` | `keyPressEvent` |
| `dhl-center` | `dhl-grid-container` + `dhl-grid-cell` |
| `dhl-tracking-bar` | `dhl-action-bar` |
