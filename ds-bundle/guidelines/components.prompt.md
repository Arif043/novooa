# Luminous Precision — Component Guidelines

## Buttons

Three variants only — never invent others:

**Primary** — the one call-to-action per screen
```html
<button class="btn-primary">Continue</button>
```
- Background: `var(--color-accent)` (#FF9500)
- Text: white, 600 weight
- Radius: `var(--radius-md)` (12px)

**Secondary** — supporting actions alongside primary
```html
<button class="btn-secondary">Save Draft</button>
```
- Background: `rgba(255, 149, 0, 0.10)` = `var(--color-accent-subtle)`
- Text: `var(--color-accent)`

**Ghost / Tertiary** — low-emphasis, destructive, or navigation links
```html
<button class="btn-ghost">Cancel</button>
```
- No background, text in `var(--color-accent)` or `var(--color-on-surface)`

## Input Fields

Always use 17px font size to prevent iOS auto-zoom.

```html
<input class="input" type="text" placeholder="Label" />
```
- Default: `#F2F2F7` background, no border
- Focus: white background + `2px solid var(--color-accent)`

## Cards

Cards are the primary container for grouped content.

```html
<div class="card">
  <!-- content -->
</div>
```
- Background: white (`var(--color-card-bg)`)
- Radius: `var(--radius-lg)` (16px) for standard, `var(--radius-xl)` (24px) for hero
- Padding: `var(--space-lg)` (24px) minimum
- Shadow: `var(--shadow-1)` — 0px 4px 12px rgba(0,0,0,0.05)

## Selection Controls

- Checkboxes/radios: use `var(--color-accent)` for selected state, white glyph
- Switches: `var(--color-accent)` for ON (not green)

## Progress & Status

- Active progress/loading: `var(--color-accent)` (#FF9500)
- Success states: standard system green (`#34C759`)
- Errors: `var(--color-error)` (#BA1A1A)
