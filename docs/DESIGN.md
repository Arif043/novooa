---
name: Luminous Precision
colors:
  surface: '#fcf8fb'
  surface-dim: '#dcd9dc'
  surface-bright: '#fcf8fb'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f6f3f5'
  surface-container: '#f0edef'
  surface-container-high: '#eae7ea'
  surface-container-highest: '#e4e2e4'
  on-surface: '#1b1b1d'
  on-surface-variant: '#554334'
  inverse-surface: '#303032'
  inverse-on-surface: '#f3f0f2'
  outline: '#887361'
  outline-variant: '#dbc2ad'
  surface-tint: '#8c5000'
  primary: '#8c5000'
  on-primary: '#ffffff'
  primary-container: '#ff9500'
  on-primary-container: '#643700'
  inverse-primary: '#ffb874'
  secondary: '#5d5f5f'
  on-secondary: '#ffffff'
  secondary-container: '#dfe0e0'
  on-secondary-container: '#616363'
  tertiary: '#5d5e60'
  on-tertiary: '#ffffff'
  tertiary-container: '#aeafb1'
  on-tertiary-container: '#414244'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#ffdcbf'
  primary-fixed-dim: '#ffb874'
  on-primary-fixed: '#2d1600'
  on-primary-fixed-variant: '#6a3b00'
  secondary-fixed: '#e2e2e2'
  secondary-fixed-dim: '#c6c6c7'
  on-secondary-fixed: '#1a1c1c'
  on-secondary-fixed-variant: '#454747'
  tertiary-fixed: '#e2e2e4'
  tertiary-fixed-dim: '#c6c6c8'
  on-tertiary-fixed: '#1a1c1d'
  on-tertiary-fixed-variant: '#454749'
  background: '#fcf8fb'
  on-background: '#1b1b1d'
  surface-variant: '#e4e2e4'
typography:
  display-lg:
    fontFamily: Inter
    fontSize: 48px
    fontWeight: '700'
    lineHeight: 52px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Inter
    fontSize: 32px
    fontWeight: '600'
    lineHeight: 38px
    letterSpacing: -0.01em
  headline-lg-mobile:
    fontFamily: Inter
    fontSize: 28px
    fontWeight: '600'
    lineHeight: 34px
    letterSpacing: -0.01em
  title-md:
    fontFamily: Inter
    fontSize: 22px
    fontWeight: '600'
    lineHeight: 28px
    letterSpacing: 0em
  body-lg:
    fontFamily: Inter
    fontSize: 17px
    fontWeight: '400'
    lineHeight: 24px
    letterSpacing: -0.01em
  body-sm:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
    letterSpacing: 0em
  label-caps:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.05em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  unit: 4px
  xs: 4px
  sm: 8px
  md: 16px
  lg: 24px
  xl: 32px
  xxl: 48px
  section: 80px
  gutter: 20px
  margin-mobile: 20px
  margin-desktop: 40px
---

## Brand & Style
The design system is rooted in the principles of clarity, deference, and depth. It aims to evoke a premium, high-utility emotional response through a minimalist lens. By prioritizing content over chrome, the interface recedes to let the user's data take center stage. 

The aesthetic is a refined interpretation of modern digital craftsmanship—combining expansive whitespace, a restrained color palette, and high-precision typography. It utilizes a sophisticated "Layered Minimalism" style: light-weight containers, subtle depth through shadows, and high-contrast accents that guide the eye without overwhelming the senses.

Every agent appears as Noovi, the mascot (a friendly ghost). Use `NooviImage`/`NooviThinking` from `lib/core/widgets/noovi/` instead of generic sparkle icons whenever an agent speaks, works or can be opened; poses and their meaning: [Noovi, das Maskottchen](./notes/noovi-maskottchen.md).

## Colors
The palette is dominated by a clean "Off-White" (`#F5F5F7`) for primary backgrounds to reduce eye strain compared to pure white. Pure White (`#FFFFFF`) is reserved for elevated surface containers like cards and modals to create a natural hierarchy.

The primary accent is a vibrant Orange (`#FF9500`), used sparingly for actionable elements, progress indicators, and states of importance. Typography relies on a deep Carbon (`#1D1D1F`) for maximum legibility and a muted Secondary Gray (`#86868B`) for metadata and de-emphasized content.

## Typography
This design system utilizes Inter for its systematic, neutral, and highly legible qualities, mirroring the characteristics of San Francisco. 

Scale is used to denote hierarchy. Large display and headline sizes use tighter letter spacing and heavier weights to feel "locked-in" and authoritative. Body text is set at 17px to align with standard mobile readability patterns. For smaller labels, a slightly increased letter spacing and uppercase styling are used to maintain clarity at small scales.

## Layout & Spacing
The layout follows a fluid 12-column grid for desktop and a 4-column grid for mobile. A strict 4px/8px baseline rhythm ensures vertical consistency. 

Generous whitespace is a functional requirement, not just an aesthetic choice; it is used to group related elements without the need for heavy visual dividers. Section-level spacing (`80px+`) should be used to provide breathing room between distinct content blocks. Page margins are set to `20px` on mobile to allow content to feel expansive yet contained.

## Elevation & Depth
Depth is conveyed through "Ambient Shadows"—soft, extremely diffused shadows with low opacity that mimic natural light. 

1.  **Level 0 (Base):** Background color (`#F5F5F7`). Elements are flat.
2.  **Level 1 (Cards):** Surface color (`#FFFFFF`) with a subtle 1px border (`#E5E5E7`) or a very soft shadow (0px 4px 12px rgba(0,0,0,0.05)).
3.  **Level 2 (Dropdowns/Popovers):** Surface color with a more pronounced shadow (0px 8px 24px rgba(0,0,0,0.12)).
4.  **Level 3 (Modals):** High elevation with backdrop blur (20px) on the underlying content to focus user attention.

## Shapes
The shape language is defined by "Squircular" influence—using large, smooth corner radii to feel approachable and modern. 

Standard components like buttons and input fields use a `12px` radius. Larger containers like cards use `16px`, while primary page-level wrappers or featured hero elements use `20px`. The progression of radii should be proportional to the size of the element; larger elements require larger radii to maintain visual harmony.

## Components

### Buttons
- **Primary:** Background `#FF9500`, Text `#FFFFFF`. Bold weight. 12px corner radius.
- **Secondary:** Background `rgba(255, 149, 0, 0.1)`, Text `#FF9500`. 
- **Tertiary/Ghost:** No background, Text `#FF9500` or `#1D1D1F`.

### Input Fields
Inputs should feature a subtle `#F2F2F7` background in their default state, transitioning to a white background with a 2px `#FF9500` border on focus. Text should be 17px to prevent iOS auto-zoom.

### Cards
Cards are the primary container. They use `#FFFFFF` background, `16px` or `20px` corner radius, and a soft 1px gray border or low-opacity shadow. Padding within cards should be `24px` to maintain the "generous whitespace" philosophy.

### Selection Controls
- **Checkboxes/Radios:** Use the primary orange for the selected state. High contrast white icons for the "checked" glyph.
- **Switches:** Follow the HIG standard: green for 'on' is replaced here with primary orange.

### Progress & Status
Use the primary orange for active progress. For success states, use a standard system green, but keep the orange for primary interactions to maintain brand consistency.