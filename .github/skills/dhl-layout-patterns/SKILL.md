---
name: dhl-layout-patterns
description: "DHL layout patterns and responsive design — use when user asks about page layout, grid compositions, responsive behavior, page templates, form layouts, or component composition patterns."
---

# DHL UI Library — Layout Patterns & Composition

This skill provides ready-to-use layout patterns for the DHL UI Library.
For full documentation, read: `myDex/projects/dhl-ui-library-kb/.dex/1-analysis/03-PATTERNS.md`

## Page Structure Template

```jsx
<>
  {/* Skip Link BEFORE navbar (a11y requirement) */}
  <a href="#main" className="skip-link">Zum Hauptinhalt</a>

  {/* Navigation */}
  <DhlNavbar logo={{ href: "/", alt: "DHL Logo" }} appName="App Name"
    primaryNavigationItems={[...]} />

  {/* Main Content */}
  <main id="main">
    <DhlGridContainer>
      {/* Page content */}
    </DhlGridContainer>
  </main>

  {/* Footer */}
  <DhlFooter copyright="2026 (c) DHL" meta={{...}} social={{...}} />
</>
```

## Grid Patterns

### Single Column (Content Page)
```jsx
<DhlGridContainer columns={12}>
  <DhlGridCell spanColumns={[12, 10, 8]} startColumn={[1, 2, 3]}>
    {/* Centered content, max 8/12 columns on desktop */}
  </DhlGridCell>
</DhlGridContainer>
```

### Two Column (Sidebar + Content)
```jsx
<DhlGridContainer columns={12} rowGap="var(--dui-size-space-8x)">
  <DhlGridCell spanColumns={[12, 8]}>
    {/* Main content — full on mobile, 8/12 on desktop */}
  </DhlGridCell>
  <DhlGridCell spanColumns={[12, 4]}>
    {/* Sidebar — stacks below on mobile */}
  </DhlGridCell>
</DhlGridContainer>
```

### Card Grid (Responsive)
```jsx
{/* 1 col mobile → 2 tablet → 3 desktop → 4 wide */}
<DhlGridContainer columns={[1, 2, 3, 4]} rowGap="var(--dui-size-space-8x)">
  {items.map(item => (
    <DhlGridCell key={item.id}>
      <DhlCard>
        <DhlImage slot="image" src={item.img} alt={item.title} />
        <DhlHeadline slot="header" designLevel="4" noMargin>{item.title}</DhlHeadline>
        <DhlText>{item.desc}</DhlText>
        <DhlLink slot="footer" href={item.url}>Details</DhlLink>
      </DhlCard>
    </DhlGridCell>
  ))}
</DhlGridContainer>
```

### Equal Columns
```jsx
{/* 2 equal columns */}
<DhlGridContainer columns={[1, 2]}>
  <DhlGridCell><DhlCard>Left</DhlCard></DhlGridCell>
  <DhlGridCell><DhlCard>Right</DhlCard></DhlGridCell>
</DhlGridContainer>

{/* 3 equal columns */}
<DhlGridContainer columns={[1, 2, 3]}>
  <DhlGridCell>A</DhlGridCell>
  <DhlGridCell>B</DhlGridCell>
  <DhlGridCell>C</DhlGridCell>
</DhlGridContainer>
```

## Form Patterns

### Standard Form
```jsx
<form>
  <DhlGridContainer rowGap="var(--dui-size-space-8x)">
    {/* Two fields side by side on desktop */}
    <DhlGridCell spanColumns={[12, 6]}>
      <DhlInputField variant={{ label: "Vorname" }} required />
    </DhlGridCell>
    <DhlGridCell spanColumns={[12, 6]}>
      <DhlInputField variant={{ label: "Nachname" }} required />
    </DhlGridCell>

    {/* Full width field */}
    <DhlGridCell spanColumns={12}>
      <DhlInputField variant={{ label: "E-Mail" }} type="email" required />
    </DhlGridCell>

    {/* Dropdown */}
    <DhlGridCell spanColumns={[12, 6]}>
      <DhlDropdown label="Land" name="country" data={countries} showFilter />
    </DhlGridCell>

    {/* Date range */}
    <DhlGridCell spanColumns={[12, 6]}>
      <DhlDateRangePicker name="dates" />
    </DhlGridCell>

    {/* Actions */}
    <DhlGridCell spanColumns={12}>
      <DhlButtonGroup>
        <DhlButton type="submit" variant="primary">Absenden</DhlButton>
        <DhlButton type="reset" variant="outline">Zuruecksetzen</DhlButton>
      </DhlButtonGroup>
    </DhlGridCell>
  </DhlGridContainer>
</form>
```

### Selection Form (Cards)
```jsx
<DhlGridContainer columns={[1, 2, 3]}>
  {options.map(opt => (
    <DhlGridCell key={opt.id}>
      <DhlSelectableCard
        isChecked={selected === opt.id}
        handleSelectionChange={() => setSelected(opt.id)}
        selectionVariant="radio-button"
      >
        <DhlHeadline slot="header" designLevel="4">{opt.title}</DhlHeadline>
        <DhlText>{opt.description}</DhlText>
        <DhlText slot="footer" size="lg" weight={700}>{opt.price}</DhlText>
      </DhlSelectableCard>
    </DhlGridCell>
  ))}
</DhlGridContainer>
```

## Feedback & Data Patterns

For component API details (props, events), see the `dhl-ui-components` skill.
These patterns show **composition** — how to combine components in layouts.

### Confirmation Dialog (Modal + ButtonGroup)
```jsx
<DhlModal isOpen={showConfirm} isFullScreenOnMobile trapFocus>
  <DhlHeadline slot="header" designLevel="4" noMargin>Bestaetigung</DhlHeadline>
  <DhlText>Moechten Sie den Eintrag loeschen?</DhlText>
  <DhlButtonGroup slot="footer">
    <DhlButton variant="primary" clickEvent={handleDelete}>Loeschen</DhlButton>
    <DhlButton variant="outline" clickEvent={() => setShowConfirm(false)}>
      Abbrechen
    </DhlButton>
  </DhlButtonGroup>
</DhlModal>
```

### Loading → Content Transition
```jsx
{isLoading ? <DhlLoader /> : <DhlTable caption="Ergebnisse" columns={cols} rowData={data} />}
```

### Accordion FAQ
```jsx
<DhlAccordion soloExpandable>
  {faqs.map((faq, i) => (
    <DhlPanel key={i}>
      <span slot="heading">{faq.question}</span>
      <DhlText>{faq.answer}</DhlText>
    </DhlPanel>
  ))}
</DhlAccordion>
```

### Tabbed Content
```jsx
<DhlTabs tabStyle="secondary">
  <li data-label="Uebersicht">{overviewContent}</li>
  <li data-label="Details">{detailContent}</li>
  <li data-label="Historie">{historyContent}</li>
</DhlTabs>
```

## Spacing Rules

```css
/* Use these tokens for consistent spacing */
padding: var(--dui-size-space-8x);       /* Standard padding */
gap: var(--dui-size-space-4x);           /* Item gaps */
margin-bottom: var(--dui-size-space-20x); /* Section spacing */
```

**Rule:** Grid `rowGap` controls vertical spacing between grid rows.
Use `--dui-size-space-8x` as default row gap.

## Responsive Behavior Summary

| Element | SM (320) | MD (768) | LG (1024) | XL (1365) |
|---------|----------|----------|-----------|-----------|
| Nav | Hamburger | Hamburger | Full nav | Full nav |
| Cards | 1 col | 2 col | 3 col | 3-4 col |
| Form fields | Stacked | Side by side | Side by side | Side by side |
| Sidebar | Below content | Below content | Beside content | Beside content |
| Table | Vertical cards | Horizontal | Horizontal | Horizontal |
| Modal | Fullscreen | Centered | Centered | Centered |

## Anti-Patterns

| Don't | Do Instead |
|-------|-----------|
| Hardcode `px` widths | Use grid system + tokens |
| Use `dhl-center` | Use `DhlGridContainer` + `DhlGridCell` |
| Nest grids deeply (3+) | Flatten with proper spanning |
| Mix hardcoded and token spacing | Always use `--dui-size-space-*` |
| Ignore mobile layout | Design mobile-first, expand upward |
| Use `position: fixed` for modals | Use `dhl-modal` component |
