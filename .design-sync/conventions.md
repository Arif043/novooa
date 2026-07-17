# Luminous Precision — Agent Conventions

## Setup

No JavaScript provider or wrapper needed. Include `styles.css` and all tokens are ready:

```html
<link rel="stylesheet" href="_ds/styles.css" />
```

`styles.css` loads Inter from Google Fonts and imports all four token sheets. Every `var(--*)` below is live after this one import.

## Styling Idiom

This system uses CSS custom properties — no utility framework. Style via `var(--token)` or the `.type-*`/`.btn-*`/`.card`/`.input` classes defined in `styles.css`. Do not invent Tailwind classes or use inline hex values.

**Color tokens you must use:**

| Token | Value | When |
|---|---|---|
| `var(--color-accent)` | #FF9500 | All primary actions, active states, focus rings |
| `var(--color-accent-subtle)` | rgba(255,149,0,0.10) | Secondary button bg, hover tints |
| `var(--color-page-bg)` | #FCF8FB | Page / screen background |
| `var(--color-card-bg)` | #FFFFFF | Every card or elevated container |
| `var(--color-on-surface)` | #1B1B1D | Primary text |
| `var(--color-on-surface-variant)` | #554334 | Secondary text, metadata |
| `var(--color-outline-variant)` | #DBC2AD | Subtle dividers |
| `var(--color-error)` | #BA1A1A | Error/destructive states |

**Spacing** — use only multiples of 4px via `var(--space-xs/sm/md/lg/xl/xxl/section)`.

**Radius** — `var(--radius-md)` (12px) for buttons/inputs, `var(--radius-lg)` (16px) for cards, `var(--radius-xl)` (24px) for hero/page wrappers.

**Elevation** — `var(--shadow-1)` for cards, `var(--shadow-2)` for dropdowns, `var(--shadow-3)` + `backdrop-filter: blur(20px)` for modals.

## Where to Read

- All tokens: `_ds/styles.css` (imports `tokens/colors.css`, `typography.css`, `spacing.css`, `elevation.css`)
- Component rules: `_ds/guidelines/components.prompt.md`
- Layout rules: `_ds/guidelines/layout.prompt.md`

## Idiomatic Example

```jsx
export default function FeatureCard({ title, body, onAction }) {
  return (
    <div className="card" style={{ display: 'flex', flexDirection: 'column', gap: 'var(--space-md)' }}>
      <p className="type-label-caps" style={{ color: 'var(--color-on-surface-variant)' }}>
        Feature
      </p>
      <h2 className="type-title-md">{title}</h2>
      <p className="type-body-lg" style={{ color: 'var(--color-on-surface-variant)' }}>
        {body}
      </p>
      <button className="btn-primary" onClick={onAction}>
        Get started
      </button>
    </div>
  );
}
```

Key rules from this example:
- `.card` handles bg, radius, shadow, and padding — do not re-specify them
- `.type-label-caps` is always uppercase; do not add `text-transform: uppercase` manually
- `.btn-primary` is the only orange-fill button — use `.btn-secondary` for supporting actions
- Gap between card children: `var(--space-md)` (16px) standard, `var(--space-lg)` (24px) for spacious layouts
