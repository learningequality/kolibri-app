# DMG Background Image Design Specifications

## Overview
This document provides specifications for the Kolibri macOS DMG installer background image.

## Image Specifications

### Technical Requirements
- **Dimensions**: 660 x 400 pixels
- **Format**: PNG with transparency support
- **Color Mode**: RGBA (8-bit)
- **Resolution**: 72 PPI (standard screen resolution)
- **File Size Target**: < 50 KB (for fast loading)

### Layout Grid

```
┌─────────────────────────────────────────────────────────┐  0px
│                                                         │
│  MARGIN TOP (60px)                                      │
│                                                         │
├─────────────────────────────────────────────────────────┤  60px
│                                                         │
│              [Learning Equality Logo]                   │
│                 (centered horizontally)                 │
│                                                         │
├─────────────────────────────────────────────────────────┤  160px
│                                                         │
│                                                         │
│              [Icon Drop Zone - Left]                    │  250px (vertical center)
│                  x: 180, y: 250                         │
│                                                         │
│        ────────────────────►                           │  (arrow graphic)
│                                                         │
│              [Applications Drop Zone - Right]           │  250px (vertical center)
│                  x: 480, y: 250                         │
│                                                         │
│                                                         │
├─────────────────────────────────────────────────────────┤  340px
│                                                         │
│  MARGIN BOTTOM (60px)                                   │
│                                                         │
└─────────────────────────────────────────────────────────┘  400px
    0px                                              660px
```

## Design Elements

### 1. Learning Equality Logo
- **Position**: Top center
- **Vertical Position**: ~80-100px from top
- **Horizontal Position**: Centered (x: 330px from left edge)
- **Max Width**: 400px
- **Max Height**: 80px
- **Source**: Use existing logo from current Layout.png
- **Colors**: Black text "learning equality" + Yellow/Gold accent circle with "le" script

### 2. Arrow Graphic
- **Style**: Large, bold directional arrow pointing right (→)
- **Position**: Horizontally centered between two icon zones
- **Vertical Position**: y: 250px (same as icon centers)
- **Start Point**: x: 250px
- **End Point**: x: 410px
- **Color**: Light gray (#D0D0D0) or subtle gradient
- **Width**: 160px long
- **Stroke**: 3-4px thick, smooth/rounded ends
- **Style Options**:
  - Simple line arrow: ────►
  - Or dotted line: ─ ─ ─►
  - Or curved/swoosh arrow
- **Opacity**: 60-80% (subtle but visible)

### 3. Background
- **Style**: Clean, modern, minimal
- **Color Options**:
  - **Option A**: Solid light color (#F5F5F7 - Apple-style light gray)
  - **Option B**: Subtle vertical gradient:
    - Top: #FAFAFA
    - Bottom: #F0F0F0
  - **Option C**: White (#FFFFFF) with subtle texture
- **No patterns** or busy graphics that compete with icons

### 4. Icon Drop Zones (Visual Guides)

**Left Zone (Kolibri.app)**
- **Position**: x: 180px, y: 250px (center point)
- **Size**: 128x128px icon will be placed here by macOS
- **Visual Treatment**:
  - Optional: Very subtle circular background glow
  - Optional: Light shadow to suggest depth
  - Keep minimal - let the Kolibri icon stand out

**Right Zone (Applications)**
- **Position**: x: 480px, y: 250px (center point)
- **Size**: 128x128px folder icon will be placed here by macOS
- **Visual Treatment**: Same as left zone

### Spacing & Alignment
- **Horizontal spacing between icons**: 300px (center to center)
- **Top margin**: 60px minimum
- **Bottom margin**: 60px minimum
- **Side margins**: 90px on each side
- **All elements**: Optically centered and balanced

## Design Principles

### 1. Simplicity
- No text (language-neutral design)
- Clear visual hierarchy
- Obvious user action (drag left to right)

### 2. Accessibility
- High contrast between arrow and background
- Clear distinction between interactive and static elements
- No reliance on color alone to convey meaning

### 3. Brand Consistency
- Use Learning Equality brand colors from logo
- Professional, clean aesthetic
- Consistent with Kolibri app design language

### 4. Platform Integration
- Follows macOS Human Interface Guidelines
- Familiar to Mac users (standard DMG pattern)
- Works well with both light and dark menu bar

## Assets Needed

### Source Files
- Learning Equality logo (extract from `src/kolibri_app/icons/Layout.png`)
- Kolibri brand colors:
  - Primary Yellow: #FFC107 or similar (from kolibri-icon.png)
  - Primary Blue: #3F51B5 or similar (from kolibri-icon.png)

### Export
- **Final file**: `src/kolibri_app/icons/Layout.png`
- PNG format, 660x400px, RGBA

## Visual Testing Checklist

- [ ] Logo is clearly visible and properly spaced
- [ ] Arrow direction is obvious (left to right)
- [ ] Works with hidden files visible in Finder
- [ ] No visual conflicts with icon drop shadows
- [ ] Scales well on Retina displays
- [ ] Looks good on light and dark menu bars
- [ ] No scrolling required in DMG window
- [ ] Print/test on actual macOS Finder window

## Notes

- The actual Kolibri.app and Applications icons will be rendered by macOS Finder on top of this background
- Icon sizes are controlled by dmgbuild_settings.py (typically 128x128px)
- Window frame adds ~22px title bar at top
- Design should account for Finder chrome/controls

## References

- Current background: `src/kolibri_app/icons/Layout.png` (734x550px)
- Configuration: `build_config/dmgbuild_settings.py`
- Icon positions: Updated in dmgbuild_settings.py to (180, 250) and (480, 250)
