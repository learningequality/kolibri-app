#!/usr/bin/env python3
"""
Generate DMG background image for Kolibri macOS installer.
Creates a simple, clean background with logo and arrow.
"""

from PIL import Image, ImageDraw, ImageFont
import os

# Configuration
WIDTH = 660
HEIGHT = 400
BACKGROUND_COLOR = (245, 245, 247)  # Apple-style light gray
ARROW_COLOR = (208, 208, 208, 200)  # Light gray with transparency
ARROW_Y = 250  # Vertical center for arrow and icons

# Icon positions (these will match dmgbuild_settings.py)
KOLIBRI_ICON_X = 180
APPLICATIONS_ICON_X = 480

def create_background():
    """Create the base background image."""
    # Create image with subtle gradient
    img = Image.new('RGBA', (WIDTH, HEIGHT), BACKGROUND_COLOR)
    draw = ImageDraw.Draw(img, 'RGBA')

    # Add very subtle vertical gradient
    for y in range(HEIGHT):
        alpha = int(255 * (1 - y / HEIGHT * 0.05))  # Very subtle
        color = (250, 250, 250, alpha)
        draw.rectangle([(0, y), (WIDTH, y + 1)], fill=color)

    return img, draw

def extract_logo_from_current_layout():
    """Extract the Learning Equality logo from current Layout.png."""
    current_layout_path = os.path.join(
        os.path.dirname(__file__),
        '..',
        'src',
        'kolibri_app',
        'icons',
        'Layout.png'
    )

    if os.path.exists(current_layout_path):
        try:
            current_layout = Image.open(current_layout_path)
            # The logo in the current layout is roughly centered
            # Approximate crop: center region, lower portion
            # Based on the visible layout, logo is around y: 300-500, centered
            logo_region = current_layout.crop((150, 340, 584, 520))
            return logo_region
        except Exception as e:
            print(f"Warning: Could not extract logo from current layout: {e}")
            return None
    return None

def draw_arrow(draw, start_x, end_x, y):
    """Draw a simple arrow from start_x to end_x at height y."""
    # Arrow shaft
    shaft_width = 3
    draw.line(
        [(start_x, y), (end_x - 15, y)],
        fill=ARROW_COLOR,
        width=shaft_width
    )

    # Arrow head (triangle)
    arrow_head = [
        (end_x, y),  # Point
        (end_x - 15, y - 8),  # Top
        (end_x - 15, y + 8),  # Bottom
    ]
    draw.polygon(arrow_head, fill=ARROW_COLOR)

def add_drop_zone_hints(draw, x, y):
    """Add subtle circular hint for icon drop zone."""
    radius = 70
    # Very subtle circle
    circle_color = (220, 220, 220, 60)  # Very light gray, mostly transparent
    draw.ellipse(
        [(x - radius, y - radius), (x + radius, y + radius)],
        outline=circle_color,
        width=2
    )

def main():
    print("Generating DMG background image...")

    # Create base background
    img, draw = create_background()

    # Add logo
    logo = extract_logo_from_current_layout()
    if logo:
        # Resize logo to fit nicely at top
        logo_width = 400
        aspect_ratio = logo.size[1] / logo.size[0]
        logo_height = int(logo_width * aspect_ratio)
        logo = logo.resize((logo_width, logo_height), Image.Resampling.LANCZOS)

        # Center logo at top
        logo_x = (WIDTH - logo_width) // 2
        logo_y = 70

        # Paste logo
        if logo.mode == 'RGBA':
            img.paste(logo, (logo_x, logo_y), logo)
        else:
            img.paste(logo, (logo_x, logo_y))
        print(f"✓ Added logo at ({logo_x}, {logo_y})")
    else:
        print("✗ Could not add logo (file not found or error)")

    # Add arrow between icon zones
    arrow_start_x = KOLIBRI_ICON_X + 70  # Start after Kolibri icon
    arrow_end_x = APPLICATIONS_ICON_X - 70  # End before Applications icon
    draw_arrow(draw, arrow_start_x, arrow_end_x, ARROW_Y)
    print(f"✓ Added arrow from ({arrow_start_x}, {ARROW_Y}) to ({arrow_end_x}, {ARROW_Y})")

    # Add subtle drop zone hints (optional)
    add_drop_zone_hints(draw, KOLIBRI_ICON_X, ARROW_Y)
    add_drop_zone_hints(draw, APPLICATIONS_ICON_X, ARROW_Y)
    print(f"✓ Added drop zone hints at ({KOLIBRI_ICON_X}, {ARROW_Y}) and ({APPLICATIONS_ICON_X}, {ARROW_Y})")

    # Save
    output_path = os.path.join(
        os.path.dirname(__file__),
        '..',
        'src',
        'kolibri_app',
        'icons',
        'Layout_new.png'
    )

    img.save(output_path, 'PNG')
    print(f"\n✓ Background image saved to: {output_path}")
    print(f"  Dimensions: {WIDTH}x{HEIGHT}px")
    print(f"  File size: {os.path.getsize(output_path) / 1024:.1f} KB")
    print("\nNext steps:")
    print("1. Review the generated image")
    print("2. If acceptable, rename Layout_new.png to Layout.png")
    print("3. Or provide this to a designer for refinement")
    print("4. Update dmgbuild_settings.py with new window size and icon positions")

if __name__ == '__main__':
    main()
