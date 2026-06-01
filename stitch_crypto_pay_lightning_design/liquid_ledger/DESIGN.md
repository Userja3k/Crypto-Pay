---
name: Liquid Ledger
colors:
  surface: '#131313'
  surface-dim: '#131313'
  surface-bright: '#393939'
  surface-container-lowest: '#0e0e0e'
  surface-container-low: '#1b1b1b'
  surface-container: '#1f1f1f'
  surface-container-high: '#2a2a2a'
  surface-container-highest: '#353535'
  on-surface: '#e2e2e2'
  on-surface-variant: '#c4c7c8'
  inverse-surface: '#e2e2e2'
  inverse-on-surface: '#303030'
  outline: '#8e9192'
  outline-variant: '#444748'
  surface-tint: '#c6c6c7'
  primary: '#ffffff'
  on-primary: '#2f3131'
  primary-container: '#e2e2e2'
  on-primary-container: '#636565'
  inverse-primary: '#5d5f5f'
  secondary: '#4de082'
  on-secondary: '#003919'
  secondary-container: '#00b55d'
  on-secondary-container: '#003e1c'
  tertiary: '#ffffff'
  on-tertiary: '#68000a'
  tertiary-container: '#ffdad7'
  on-tertiary-container: '#c22229'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#e2e2e2'
  primary-fixed-dim: '#c6c6c7'
  on-primary-fixed: '#1a1c1c'
  on-primary-fixed-variant: '#454747'
  secondary-fixed: '#6dfe9c'
  secondary-fixed-dim: '#4de082'
  on-secondary-fixed: '#00210c'
  on-secondary-fixed-variant: '#005227'
  tertiary-fixed: '#ffdad7'
  tertiary-fixed-dim: '#ffb3ad'
  on-tertiary-fixed: '#410004'
  on-tertiary-fixed-variant: '#930013'
  background: '#131313'
  on-background: '#e2e2e2'
  surface-variant: '#353535'
typography:
  display-lg:
    fontFamily: Hanken Grotesk
    fontSize: 48px
    fontWeight: '700'
    lineHeight: '1.1'
    letterSpacing: -0.04em
  headline-lg:
    fontFamily: Hanken Grotesk
    fontSize: 32px
    fontWeight: '600'
    lineHeight: '1.2'
    letterSpacing: -0.02em
  headline-lg-mobile:
    fontFamily: Hanken Grotesk
    fontSize: 28px
    fontWeight: '600'
    lineHeight: '1.2'
  body-md:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: '1.5'
    letterSpacing: '0'
  label-sm:
    fontFamily: Geist
    fontSize: 13px
    fontWeight: '500'
    lineHeight: '1.2'
    letterSpacing: 0.02em
  mono-data:
    fontFamily: Geist
    fontSize: 14px
    fontWeight: '400'
    lineHeight: '1.4'
rounded:
  sm: 0.5rem
  DEFAULT: 1rem
  md: 1.5rem
  lg: 2rem
  xl: 3rem
  full: 9999px
spacing:
  margin-page: 24px
  gutter: 16px
  stack-sm: 8px
  stack-md: 16px
  stack-lg: 32px
  safe-area-bottom: 34px
---

## Brand & Style
The design system is centered on the "Liquid Glass" aesthetic—a premium, high-fidelity evolution of glassmorphism tailored for a high-end financial experience. It targets an ambitious African demographic, blending the elite feel of a luxury Swiss watch with the cutting-edge fluidity of a modern mobile OS.

The interface prioritizes **depth and luminosity** against a void-black backdrop. By utilizing semi-transparent surfaces and organic motion, the UI feels like floating layers of physical glass. The emotional response is one of absolute security, extreme precision, and effortless wealth management. It removes the technical friction of Bitcoin, presenting it instead as a stable, liquid asset.

## Colors
This design system utilizes a **Pure Black (#000000)** foundation to maximize the contrast of "Liquid Glass" elements and ensure perfect OLED integration. 

- **Primary:** Pure White is used for core iconography and primary text to ensure maximum legibility.
- **Accent (Success/Lightning):** #4ADE80 (Vibrant Green) represents active Lightning Network status and successful transactions.
- **Alert:** #EF4444 (System Red) is reserved for critical notifications and error states.
- **Glass System:** Surfaces are constructed using varying opacities of white (8% to 15%) combined with high-radius background blurs (30px-50px).

## Typography
The typography strategy mirrors the "San Francisco" style of high-end mobile operating systems. **Hanken Grotesk** provides a sharp, contemporary feel for headlines and balance displays. **Inter** is used for body copy due to its exceptional clarity on small screens. **Geist** is employed for monospaced data—such as transaction IDs and Satoshi amounts—to emphasize the technical precision of the underlying infrastructure while remaining aesthetically aligned with the premium theme.

Tracking should be tightened on large headlines to maintain the "editorial" feel, while labels utilize a slight letter-spacing increase for breathability.

## Layout & Spacing
The layout follows a **Fluid Grid** model with a heavy emphasis on generous safe-areas and margins. On mobile devices, a 24px outer margin is mandatory to prevent glass elements from feeling "cramped" against the screen edge.

Vertical rhythm is strictly maintained using a 8px base unit. Component stacks should favor larger gaps (32px) between distinct functional groups (e.g., Wallet Balance vs. Recent Transactions) to maintain the minimalist, airy feel. Content reflow for larger screens should center-align the main glass container, capping its width at 480px for a "handheld-first" experience even on desktop browsers.

## Elevation & Depth
Depth is the defining characteristic of this design system. It is achieved through a three-layer hierarchy:

1.  **The Void (Base):** Pure #000000 black.
2.  **Floating Glass (Primary):** Surfaces with `backdrop-filter: blur(40px)` and a 1px inner stroke of `rgba(255, 255, 255, 0.12)`. This layer has a soft, diffused shadow (`0px 20px 40px rgba(0,0,0,0.4)`).
3.  **Luminous Highlights (Active):** Interactive elements use a subtle inner glow (top-down) to simulate light catching the edge of a thick glass pane.

Avoid traditional drop shadows on text; use subtle outer glows on icons to indicate active status (e.g., the Lightning bolt).

## Shapes
Shapes are organic and "liquid." All primary containers use a **32px corner radius** (rounded-xl) to mimic the hardware curvature of premium smartphones. Small interactive components like buttons and input fields utilize the **Pill-shape** (3) logic to ensure they feel tactile and "squishy" under the thumb. Sharp corners are strictly prohibited as they break the liquid metaphor.

## Components

### Buttons
- **Primary:** Solid white with black text. Corner radius: 50px (Pill).
- **Secondary (Glass):** Semi-transparent white (15% opacity) with white text and a 1px border. Backdrop blur is essential.

### Input Fields
- Dark glass containers with 24px corner radius. Placeholder text should be 40% white. On focus, the border opacity increases to 60%.

### Cards (The "Glass Tile")
- All cards must use the 32px roundedness.
- Background: `rgba(255, 255, 255, 0.08)`.
- Edge: 1px solid `rgba(255, 255, 255, 0.1)`.
- Cards should never have a solid background; they must always allow the black void or background elements to bleed through via blur.

### Chips & Status
- **Lightning Status:** A small, pill-shaped chip with a 20% green background and 100% green text.
- **USD/BTC Toggle:** A glass segment control that slides with high-spring physics (simulated via 0.4s ease-out).

### Lists
- Items are separated by thin 1px lines at 5% white opacity, with 16px of vertical padding to ensure "fat-finger" accessibility.