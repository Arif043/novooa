# Luminous Precision — Layout & Elevation Guidelines

## Grid

- Desktop: 12-column fluid grid
- Mobile: 4-column grid
- Page margins: `var(--space-margin-mobile)` (20px) mobile, `var(--space-margin-desktop)` (40px) desktop
- Use `.page` wrapper class for consistent margins

## Spacing Rhythm

Strict 4px/8px baseline — only use multiples of 4px.

| Token | Value | Use |
|---|---|---|
| `--space-xs` | 4px | Tight internal gaps (icon + label) |
| `--space-sm` | 8px | List item gaps, inline spacing |
| `--space-md` | 16px | Component internal padding |
| `--space-lg` | 24px | Card padding, section sub-gaps |
| `--space-xl` | 32px | Between major groups |
| `--space-xxl` | 48px | Between sections on a page |
| `--space-section` | 80px | Between distinct page-level blocks |

Whitespace is functional — use generous spacing to group related elements instead of adding borders or dividers.

## Elevation

The surface is layered; each level adds visual depth.

| Level | Use | CSS |
|---|---|---|
| 0 | Page background — flat | `background: var(--color-background)` |
| 1 | Cards, list rows | `background: var(--color-card-bg); box-shadow: var(--shadow-1)` |
| 2 | Dropdowns, tooltips, popovers | `box-shadow: var(--shadow-2)` |
| 3 | Modals | `box-shadow: var(--shadow-3); backdrop-filter: blur(20px)` |

Level 1 cards may use a subtle 1px border (`var(--border-card)`) instead of a shadow — both are correct.

## Shape (Border Radius)

Proportional to element size:

| Token | Value | Use |
|---|---|---|
| `--radius-sm` | 4px | Tags, badges |
| `--radius-md` | 12px | Buttons, inputs, chips |
| `--radius-lg` | 16px | Standard cards |
| `--radius-xl` | 24px | Page-level wrappers, hero cards |
| `--radius-full` | 9999px | Pills, avatar circles |

Larger elements require larger radii to maintain the squircular visual harmony.
