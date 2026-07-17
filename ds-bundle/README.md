# Luminous Precision — Design System

Design system for the Syscat2 Flutter application. Defines the visual language used across all surfaces: colors, typography, spacing, elevation, and component conventions.

**Core principle:** Content over chrome. The interface recedes so user data takes center stage. Minimalist, premium, high-utility.

---

## Quick Start

Include `styles.css` — it imports all token files transitively:

```html
<link rel="stylesheet" href="styles.css" />
```

All design tokens are CSS custom properties on `:root`. Use them everywhere — never hardcode hex values.

---

## Color System

Primary accent is orange `#FF9500` (`var(--color-accent)`). Used sparingly for actionable elements, progress, and important states. Everything else is on a neutral off-white/warm-gray surface.

**Key colors:**

| Token | Value | Use |
|---|---|---|
| `--color-accent` | #FF9500 | CTAs, active states, focus rings |
| `--color-accent-subtle` | rgba(255,149,0,0.10) | Secondary button bg, hover tints |
| `--color-page-bg` | #FCF8FB | Page background |
| `--color-card-bg` | #FFFFFF | Card / elevated surface |
| `--color-on-surface` | #1B1B1D | Primary text |
| `--color-on-surface-variant` | #554334 | Secondary text, metadata |
| `--color-outline` | #887361 | Borders, dividers |
| `--color-error` | #BA1A1A | Error states |

Full token list: `tokens/colors.css`

---

## Typography

Font: **Inter** (loaded from Google Fonts in `tokens/typography.css`). Never substitute a different font.

| Scale | Size | Weight | Use |
|---|---|---|---|
| `type-display-lg` | 48px / 700 | -0.02em | Hero headings |
| `type-headline-lg` | 32px / 600 | -0.01em | Section headers (desktop) |
| `type-headline-lg-mobile` | 28px / 600 | -0.01em | Section headers (mobile) |
| `type-title-md` | 22px / 600 | 0em | Card titles, dialogs |
| `type-body-lg` | 17px / 400 | -0.01em | All readable body text |
| `type-body-sm` | 14px / 400 | 0em | Secondary text, captions |
| `type-label-caps` | 12px / 600 | +0.05em | Overlines (uppercase) |

Use CSS class `.type-display-lg`, `.type-headline-lg`, etc. — or apply the `--type-*` custom properties directly.

Body text is 17px to align with mobile readability standards and prevent iOS auto-zoom on inputs.

---

## Spacing

4px base unit. Use only multiples of 4px.

```
--space-xs: 4px   --space-sm: 8px   --space-md: 16px
--space-lg: 24px  --space-xl: 32px  --space-xxl: 48px
--space-section: 80px
```

Page margins: 20px mobile (`--space-margin-mobile`), 40px desktop (`--space-margin-desktop`).

---

## Components

See `guidelines/components.prompt.md` for component-level rules.
See `guidelines/layout.prompt.md` for elevation, grid, and shape system.

### Buttons
- **Primary** — `.btn-primary` — orange fill, white text, 12px radius
- **Secondary** — `.btn-secondary` — orange tint bg, orange text
- **Ghost** — `.btn-ghost` — no background, orange text

### Cards
`.card` — white bg, 16px radius, `var(--shadow-1)` or `var(--border-card)`, 24px padding

### Inputs
`.input` — gray bg default, white + orange border on focus, 17px font

---

## Elevation

| Level | Shadow | Use |
|---|---|---|
| 0 | none | Page base |
| 1 | 0px 4px 12px rgba(0,0,0,0.05) | Cards |
| 2 | 0px 8px 24px rgba(0,0,0,0.12) | Dropdowns |
| 3 | 0px 16px 48px rgba(0,0,0,0.16) + blur(20px) | Modals |
