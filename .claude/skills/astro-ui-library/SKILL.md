---
name: astro-ui-library
description: >-
  The SwiftUIPlayground UI library (AstroChat design system) — reusable SwiftUI
  components and screen patterns. Use this skill whenever building or editing
  SwiftUI UI in this project: buttons, bottom sheets, modals, dialogs, full
  screens, or implementing a Figma design. Reach for the library's AstroButton
  and the bottom-sheet pattern instead of hand-rolling views, and follow the
  project's color/preview conventions. Trigger even when the user just says
  "add a button", "build this sheet", "make a confirm dialog", or "implement
  this AstroChat screen" without naming the library.
---

# Astro UI Library

A small, self-contained SwiftUI component library for the AstroChat app, living
in this playground under `SwiftUIPlayground/UILibrary/` (components) and
`SwiftUIPlayground/ComplexUI/` (screen/sheet patterns built from them).

The guiding principle is **bare-minimum, zero-dependency UI**: components use
built-in SwiftUI colors and SF Symbols only — no asset catalogs, no custom
`Color` extensions, no third-party packages. This keeps the library portable
and makes every component compile on its own. Preserve that property when you
add to it.

## Core conventions

Follow these so new UI matches what's already here:

- **Built-in colors only.** The brand color is `.orange`. Never reintroduce a
  custom `Color(red:green:blue:)` palette or a `Color.brand`-style extension —
  these were deliberately removed. Map design intents to system colors:
  | Design intent      | Use                       |
  | ------------------ | ------------------------- |
  | Brand / primary    | `.orange`                 |
  | Subtle brand tint  | `.orange.opacity(0.12)`   |
  | Disabled           | `.gray`                   |
  | Error / destructive| `.red`                    |
  | Accent (success)   | `.yellow`                 |
  | Title text         | `.primary`                |
  | Body / secondary   | `.secondary`              |
- **No asset dependencies.** If a component needs an icon, prefer
  `Image(systemName:)` (SF Symbols). If a caller wants a custom image, expose an
  optional `Image?` parameter and let them pass it in — don't reference asset
  catalog symbols like `Image(.someIcon)` inside the library.
- **Always add a `#Preview`.** Every component and screen ends with a preview
  showing its main variants, so it can be checked in the Xcode canvas without
  running the app.
- **Self-contained structs.** A component should compile with only `import
  SwiftUI`. Break a screen into small `private var` subviews (see the sheet
  pattern) rather than one giant `body`.

## Component: `AstroButton`

The primary action button. File: `SwiftUIPlayground/UILibrary/AstroButton.swift`.

```swift
AstroButton(
    icon: Image?      = nil,   // optional leading icon (pass your own Image)
    title: String,
    style: .filled | .text | .light | .error,
    size: .small | .medium | .large | .extraLarge,
    isEnabled: Bool   = true,
    onClick: () -> Void
)
```

**Styles** (background / foreground):
- `.filled` — `.orange` bg, white text. Primary call to action.
- `.light` — `.orange.opacity(0.12)` bg, `.orange` text. Secondary action.
- `.text` — clear bg, `.orange` text. Tertiary / inline action.
- `.error` — `.red` bg, white text. Destructive action.

When `isEnabled` is false, `.filled`/`.light` fall back to a `.gray` background
and hit-testing is disabled.

**Sizes** map to heights: `.small` 36, `.medium` 40, `.large` 44,
`.extraLarge` 48. The button always stretches to `maxWidth: .infinity`, so
constrain its width by the container if you need it narrower.

**Examples:**

```swift
// Primary, full-width
AstroButton(title: "Verify Mobile Number", style: .filled, size: .large) {
    viewModel.verify()
}

// Secondary with an SF Symbol icon
AstroButton(
    icon: Image(systemName: "phone.fill"),
    title: "Call",
    style: .light,
    size: .medium
) { startCall() }

// Disabled destructive
AstroButton(title: "Delete", style: .error, size: .large, isEnabled: canDelete) {
    delete()
}
```

## Pattern: bottom sheet

Reference implementation:
`SwiftUIPlayground/ComplexUI/VerifyMobileNumberSheet.swift`. Use it as the
template for any centered confirmation / informational bottom sheet (icon →
title+body → action buttons).

Anatomy:
- A `VStack` content view padded `.horizontal, 20` / `.vertical, 30`, backed by
  an `UnevenRoundedRectangle` with `topLeadingRadius`/`topTrailingRadius` of 32
  and bottom radii 0 (rounded top only — it sits flush at the screen bottom),
  filled `Color.white`.
- An **icon circle**: a `ZStack` of a tinted `Circle()` (e.g.
  `.yellow.opacity(0.12)`) behind an SF Symbol.
- A **text block**: bold `.primary` title + regular `.secondary` body, both
  `.multilineTextAlignment(.center)`, body width-constrained.
- A **button stack**: a primary action (filled orange rounded rectangle) above a
  plain `.orange` text button. These are inline `Button`s here; for a new sheet
  you can use `AstroButton` instead for consistency.
- **Callbacks in, not logic.** The sheet takes `onVerify` / `onBack` closures
  (defaulted to `{}`) — presentation/dismissal lives with the caller.

Presenting it (see `VerifyMobileNumberSheetDemo`):

```swift
.sheet(isPresented: $isPresented) {
    MySheet(onConfirm: { isPresented = false }, onCancel: { isPresented = false })
        .presentationDetents([.height(388)])   // size to the content
        .presentationDragIndicator(.hidden)
        .presentationBackground(.clear)         // sheet draws its own rounded card
}
```

When building a new sheet from a design, copy this structure, swap the SF
Symbol, text, and detent height, and keep the rounded-top white card.

## Adding a new component

1. Create the file under `UILibrary/` (reusable component) or `ComplexUI/`
   (a screen/sheet assembled from components).
2. Keep it to `import SwiftUI` only — built-in colors, SF Symbols, optional
   `Image?` inputs. No custom color extensions, no asset symbols.
3. Expose configuration as `enum`s (like `ButtonStyle`/`Size`) and behavior as
   closures, so callers stay declarative.
4. End with a `#Preview` covering the main variants/states.
5. If a design uses a specific brand hex, still default to the system color
   (`.orange` etc.) for portability; only hardcode an exact `Color(red:...)` if
   the user explicitly asks for pixel-exact brand color.
