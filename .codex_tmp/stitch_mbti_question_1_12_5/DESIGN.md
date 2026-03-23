# Design System Specification: Luminous Identity

## 1. Overview & Creative North Star
**The Creative North Star: "The Ethereal Curator"**

This design system moves away from the transactional, "grid-of-faces" aesthetic common in social discovery. Instead, it treats user identity as a high-end editorial subject. By utilizing **The Ethereal Curator** mindset, we prioritize intentional asymmetry, generous whitespace, and depth through translucency rather than rigid containers. 

The goal is to create a digital environment that feels like a sun-drenched, glass-walled gallery. We break the "template" look by overlapping elements (e.g., a profile tag bleeding over a photo edge) and using high-contrast typography scales that command attention without shouting. The interface should feel "breathtakingly light," allowing the vibrant colors of our community to shine through a sophisticated, frosted lens.

---

## 2. Colors & Tonal Depth

Our palette is anchored in a luminous purple, supported by the soft interplay of blue and pink. It is designed to feel "lit from within."

### The "No-Line" Rule
**Explicit Instruction:** 1px solid borders are strictly prohibited for sectioning or containment. Boundaries must be defined solely through background color shifts or tonal transitions. To separate a profile section from a feed, transition from `surface` (#f8f9fe) to `surface-container-low` (#f2f3f8). 

### Surface Hierarchy & Nesting
Treat the UI as a series of physical layers—stacked sheets of frosted glass.
*   **Base:** `surface` (#f8f9fe)
*   **Structural Sections:** `surface-container-low` (#f2f3f8)
*   **Primary Cards:** `surface-container-lowest` (#ffffff)
*   **Elevated Overlays:** `surface-bright` (#f8f9fe) with 80% opacity and 20px backdrop-blur.

### The "Glass & Gradient" Rule
To achieve "Luminous Identity," use `primary` (#7b36c2) to `primary-container` (#9552dd) linear gradients (135°) for primary actions. This adds a "soul" to the UI that flat hex codes cannot replicate. Floating elements (modals, navigation bars) should use glassmorphism: a semi-transparent `surface-container-lowest` with a heavy `backdrop-filter: blur(24px)`.

---

## 3. Typography
We utilize a dual-font strategy to balance editorial sophistication with high-performance readability.

*   **Display & Headlines (Plus Jakarta Sans):** Chosen for its modern, geometric flair and slightly wider stance. Use `display-lg` (3.5rem) for "Welcome" moments and `headline-md` (1.75rem) for profile names. High-end design requires high-contrast; don't be afraid of the size gap between a headline and body text.
*   **Body & Labels (Manrope):** A workhorse sans-serif with excellent legibility at small sizes. Manrope’s open terminals maintain the "warm and approachable" vibe even in dense chat interfaces.
*   **Hierarchy Note:** Use `on-surface-variant` (#4c4453) for secondary metadata to ensure the `primary` purple text or headlines remain the focal point.

---

## 4. Elevation & Depth

### The Layering Principle
Depth is achieved by "stacking" the surface-container tiers. Place a `surface-container-lowest` card (Pure White) on a `surface-container-low` background. This creates a soft, natural lift that feels premium and tactile without the "heaviness" of dark shadows.

### Ambient Shadows
For floating CTAs or high-priority modals, use "Ambient Shadows":
*   **Shadow Specs:** `0px 16px 40px rgba(125, 56, 196, 0.08)`
*   **Note:** The shadow is tinted with the `surface_tint` (#7d38c4) rather than black. This mimics how light bounces off colored surfaces in the real world.

### The "Ghost Border" Fallback
If a container lacks contrast against its background (e.g., on a photo), use a **Ghost Border**: `outline-variant` (#cec2d5) at 15% opacity. Never use 100% opaque borders.

---

## 5. Components

### Buttons
*   **Primary:** Gradient of `primary` to `primary-container`. `xl` (3rem) corner radius. Subtle glow on hover using an ambient shadow.
*   **Secondary:** `surface-container-highest` background with `primary` text. No border.
*   **Tertiary:** Ghost border with `primary` text. Use for low-emphasis actions like "Cancel."

### Luminous Cards
*   **Radius:** Always use `lg` (2rem) or `xl` (3rem) for profile cards.
*   **Interaction:** No dividers. Use `Spacing 6` (2rem) to separate content blocks within the card. Use `surface-container-low` for "tags" or "interests" inside a white card.

### Inputs & Selection
*   **Input Fields:** `surface-container-low` background, no border. On focus, a subtle 2px "glow" (not a sharp outline) using `primary` at 30% opacity.
*   **Chips:** Selection chips should use `secondary_fixed` (#d2e4ff) for a "soft blue" playful vibe, transitioning to `primary` when selected.

### Signature Component: The "Identity Glow"
*   **Floating Navigation:** A bottom bar using glassmorphism (`surface-container-lowest` @ 70% opacity + blur) with a `primary` glow emanating from the center active icon.

---

## 6. Do’s and Don’ts

### Do:
*   **Embrace Whitespace:** Use `Spacing 8` (2.75rem) as a default gutter for main layouts to ensure the "High-End" feel.
*   **Use Soft Corners:** Stick to the `lg` (2rem) and `xl` (3rem) scale for any container larger than a button.
*   **Layer Textures:** Place translucent text containers over photography to maintain legibility while keeping the "airy" vibe.

### Don’t:
*   **Don't Use Pure Black:** Even for text, use `on-surface` (#191c1f). Pure black kills the "luminous" effect.
*   **Don't Use Dividers:** Never use a horizontal line to separate chat messages or list items. Use background color shifts or `Spacing 3` (1rem).
*   **Don't Crowd the Edge:** Elements should never feel "trapped." If a button is near a card edge, ensure at least `Spacing 4` (1.4rem) of breathing room.
*   **Avoid "Mystical" Overload:** While we use glows and blurs, keep them tied to functional UI elements. Do not add floating sparkles or unnecessary decorative gradients that aren't tied to interaction.