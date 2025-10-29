# DMG Layout Improvements - Summary

## Problem Statement
Original GitHub Issue: https://github.com/learningequality/kolibri-app/issues/76

The current DMG layout had several usability and visual issues:
- Poor icon positioning (too high, overlapping with visual elements)
- Unclear spacing around the Learning Equality logo
- Window size caused scrolling issues
- Difficult to understand the drag-to-install action

## Solution: Improved Visual-Only Layout

A redesigned DMG background that is:
- **Language-neutral** (no text, works for all 23 supported languages)
- **Clear visual hierarchy** (logo at top, action in middle)
- **Better icon positioning** (vertically centered, proper spacing)
- **Smaller window** (no scrolling, fits better on screens)

## Changes Made

### 1. Window Dimensions
```
Before: 734 x 550 px
After:  660 x 400 px
```
Benefits:
- More standard aspect ratio
- No scrolling required
- Better fit on smaller displays
- Cleaner visual presentation

### 2. Icon Positions
```
Before:
- Kolibri.app:   (185, 120)
- Applications:  (550, 120)

After:
- Kolibri.app:   (180, 250)
- Applications:  (480, 250)
```
Benefits:
- Vertically centered in window
- Better spacing from logo
- Clearer drag path
- More balanced composition

### 3. Background Design
```
Before: 734x550 with three yellow triangles and centered logo
After:  660x400 with top logo, directional arrow, and minimal design
```
Features:
- Learning Equality logo prominently displayed at top
- Clear directional arrow indicating drag action
- Subtle drop zone hints (circles)
- Clean, modern background (Apple-style light gray)
- No text (fully language-neutral)

## Files Modified

### Configuration
- `build_config/dmgbuild_settings.py` - Updated window size and icon positions

### New Files Created
- `build_config/DMG_BACKGROUND_SPECS.md` - Complete design specifications for designers
- `build_config/generate_dmg_background.py` - Python script to generate prototype
- `src/kolibri_app/icons/Layout_new.png` - Prototype background image (660x400)

## Implementation Steps

### Option A: Use Generated Prototype
1. Review `src/kolibri_app/icons/Layout_new.png`
2. If acceptable, replace the current background:
   ```bash
   mv src/kolibri_app/icons/Layout.png src/kolibri_app/icons/Layout_old.png
   mv src/kolibri_app/icons/Layout_new.png src/kolibri_app/icons/Layout.png
   ```
3. Build and test the DMG

### Option B: Professional Designer
1. Provide `build_config/DMG_BACKGROUND_SPECS.md` to your designer
2. Designer creates polished version following specs
3. Save as `src/kolibri_app/icons/Layout.png` (660x400px PNG)
4. Build and test the DMG

### Testing
```bash
# Build the DMG with new layout
make build-dmg

# Open and verify:
# - Window size is correct (no scrolling)
# - Icons are positioned properly
# - Logo is visible and well-spaced
# - Arrow clearly indicates drag action
# - Works with Finder "Show hidden files" enabled
```

## Visual Comparison

### Before (734x550)
- Yellow triangles at top (unclear purpose)
- Icons at y=120 (too high, near logo)
- Larger window (scrolling issues)
- Logo centered in middle of content area

### After (660x400)
- Logo at top with proper spacing
- Icons at y=250 (vertically centered)
- Compact window (no scrolling)
- Clear arrow showing drag direction
- Subtle drop zone hints

## Benefits

### User Experience
- ✅ Clearer visual hierarchy
- ✅ Obvious drag-to-install action
- ✅ No scrolling required
- ✅ Professional, modern appearance
- ✅ Works for all languages (no text)

### Technical
- ✅ Smaller file size (26.8 KB vs 31 KB)
- ✅ Simpler maintenance (no text to translate)
- ✅ Better aspect ratio for modern displays
- ✅ Follows macOS Human Interface Guidelines

### Accessibility
- ✅ Clear visual indicators
- ✅ High contrast arrow
- ✅ No reliance on color alone
- ✅ Familiar macOS pattern

## Next Steps

1. **Review the prototype** (`Layout_new.png`)
2. **Decide**: Use prototype or send specs to designer
3. **Replace** the background image
4. **Test** by building the DMG
5. **Close** GitHub issue #76

## Regenerating the Background

If you need to regenerate the prototype (e.g., with different colors or styling):

```bash
python3 build_config/generate_dmg_background.py
```

The script will:
- Extract the logo from the current layout
- Generate a new 660x400 background
- Add arrow and drop zone hints
- Save as `Layout_new.png`

## Additional Notes

- The configuration in `dmgbuild_settings.py` is already updated
- No changes needed to build scripts or Makefile
- The new layout works with existing code signing and notarization
- All 23 language translations remain unaffected
