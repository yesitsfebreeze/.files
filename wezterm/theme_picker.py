import urllib.request
import urllib.error
import json
import re
import os
import sys


def fetch_themes():
    """Fetch list of themes from Gogh repository."""
    url = "https://api.github.com/repos/Gogh-Co/Gogh/contents/themes"
    try:
        with urllib.request.urlopen(url) as response:
            data = json.loads(response.read().decode())
    except Exception as e:
        print(f"Error fetching themes: {e}")
        sys.exit(1)

    themes = []
    for item in data:
        if item["type"] == "file" and item["name"].endswith(".yml"):
            theme_name = item["name"][:-4]  # Remove .yml extension
            themes.append({"name": theme_name, "download_url": item["download_url"]})
    return themes


def parse_theme(content):
    """Parse Gogh theme content to extract colors."""
    colors = {}
    # Pattern for color_01 to color_16 (YAML format)
    color_pattern = re.compile(r"color_(\d+)\s*:\s*([^\s]+)")
    # Pattern for background and foreground (YAML format)
    bg_fg_pattern = re.compile(r"(background|foreground)\s*:\s*([^\s]+)")
    # Pattern for cursor (optional)
    cursor_pattern = re.compile(r"cursor\s*:\s*([^\s]+)")

    for line in content.splitlines():
        line = line.strip()
        # Skip comments and empty lines
        if line.startswith("#") or not line or line.startswith("---"):
            continue

        color_match = color_pattern.match(line)
        if color_match:
            num = int(color_match.group(1))
            hex_color = color_match.group(2).strip().strip("'\"")
            colors[f"COLOR_{num:02d}"] = hex_color
            continue

        bg_fg_match = bg_fg_pattern.match(line)
        if bg_fg_match:
            key = bg_fg_match.group(1).upper()  # Convert to uppercase
            hex_color = bg_fg_match.group(2).strip().strip("'\"")
            colors[key] = hex_color
            continue

        cursor_match = cursor_pattern.match(line)
        if cursor_match:
            hex_color = cursor_match.group(1).strip().strip("'\"")
            colors["CURSOR"] = hex_color

    return colors


def convert_to_wezterm(colors):
    """Convert Gogh colors to WezTerm color scheme."""
    # Extract ANSI colors (0-15)
    ansi = []
    brights = []
    for i in range(1, 17):
        key = f"COLOR_{i:02d}"
        if key in colors:
            hex_color = colors[key]
            if i <= 8:
                ansi.append(hex_color)
            else:
                brights.append(hex_color)
        else:
            # Fallback to default if missing
            hex_color = "#000000" if i <= 8 else "#ffffff"
            if i <= 8:
                ansi.append(hex_color)
            else:
                brights.append(hex_color)

    # Get background and foreground
    background = colors.get("BACKGROUND", "#000000")
    foreground = colors.get("FOREGROUND", "#ffffff")

    # WezTerm color scheme
    scheme = {
        "foreground": foreground,
        "background": background,
        "cursor_bg": foreground,
        "cursor_fg": background,
        "cursor_border": foreground,
        "selection_bg": foreground,
        "selection_fg": background,
        "ansi": ansi,
        "brights": brights,
    }
    return scheme


def choose_theme(themes):
    """Let user choose a theme from the list."""
    print("\nAvailable Gogh themes:")
    for i, theme in enumerate(themes, start=1):
        print(f"{i:3d}. {theme['name']}")

    while True:
        try:
            choice = input("\nEnter theme number (or 0 to cancel): ").strip()
            if choice == "0":
                return None
            idx = int(choice) - 1
            if 0 <= idx < len(themes):
                return themes[idx]
            else:
                print("Invalid number. Please try again.")
        except ValueError:
            print("Please enter a valid number.")
        except EOFError:
            # Handle non-interactive environment
            print("\nNon-interactive environment detected.")
            print("Selecting theme #1 (3024 Day) for demonstration.")
            return themes[0] if themes else None


def read_wezterm_lua(filepath):
    """Read the wezterm.lua file."""
    try:
        with open(filepath, "r", encoding="utf-8") as f:
            return f.read()
    except FileNotFoundError:
        return None
    except Exception as e:
        print(f"Error reading {filepath}: {e}")
        return None


def update_wezterm_lua(content, theme_name, scheme):
    """Update wezterm.lua with the new color scheme."""
    lines = content.splitlines() if content else []

    # Find color_schemes table
    start_index = None
    end_index = None
    brace_count = 0
    scheme_indent = ""

    for i, line in enumerate(lines):
        stripped = line.lstrip()
        if start_index is None and stripped.startswith("color_schemes = {"):
            start_index = i
            scheme_indent = line[: len(line) - len(stripped)]
            brace_count = 1
        elif start_index is not None:
            # Count braces
            brace_count += line.count("{") - line.count("}")
            if brace_count == 0:
                end_index = i
                break

    # Format the new scheme entry
    scheme_lines = []
    scheme_lines.append(f'{scheme_indent}    ["{theme_name}"] = {{')
    for key, value in scheme.items():
        if isinstance(value, list):
            # Format as comma-separated list
            list_str = ", ".join(f'"{v}"' for v in value)
            scheme_lines.append(f"{scheme_indent}        {key} = {{{list_str}}},")
        else:
            scheme_lines.append(f'{scheme_indent}        {key} = "{value}",')
    scheme_lines.append(f"{scheme_indent}    }},")

    # Insert the new scheme before the closing brace
    if start_index is not None and end_index is not None:
        # Insert scheme lines at end_index (so they appear before the closing brace)
        for j, scheme_line in enumerate(scheme_lines):
            lines.insert(end_index + j, scheme_line)
        # Adjust end_index because we inserted lines
        end_index += len(scheme_lines)
    else:
        # If we didn't find color_schemes table, create one at the end
        lines.append("")
        lines.append("color_schemes = {")
        lines.extend(scheme_lines)
        lines.append("}")
        end_index = len(lines) - 1  # The closing brace line

    # Find and update color_scheme line
    scheme_found = False
    for i, line in enumerate(lines):
        stripped = line.lstrip()
        if stripped.startswith("--") or not stripped:
            continue
        if "color_scheme" in stripped and "=" in stripped:
            # Replace the line
            indent = line[: len(line) - len(stripped)]
            lines[i] = f'{indent}color_scheme = "{theme_name}"'
            scheme_found = True
            break

    if not scheme_found:
        # Append color_scheme setting at the end
        lines.append("")
        lines.append(f'color_scheme = "{theme_name}"')

    return "\n".join(lines)


def main():
    """Main function."""
    print("Gogh Theme Picker for WezTerm")
    print("=" * 40)

    # Fetch themes
    print("Fetching themes from Gogh-Co/Gogh...")
    themes = fetch_themes()
    if not themes:
        print("No themes found. Exiting.")
        return

    # Let user choose
    chosen = choose_theme(themes)
    if not chosen:
        print("Cancelled.")
        return

    print(f"\nSelected theme: {chosen['name']}")
    print("Downloading theme...")

    # Download theme
    try:
        with urllib.request.urlopen(chosen["download_url"]) as response:
            theme_content = response.read().decode("utf-8")
    except Exception as e:
        print(f"Error downloading theme: {e}")
        return

    # Parse theme
    colors = parse_theme(theme_content)
    if not colors:
        print("Failed to parse theme colors.")
        return

    # Convert to WezTerm format
    scheme = convert_to_wezterm(colors)

    # Show preview
    print("\nTheme preview:")
    print(f"  Background: {scheme['background']}")
    print(f"  Foreground: {scheme['foreground']}")
    print(f"  ANSI colors: {', '.join(scheme['ansi'][:4])}...")
    print(f"  Bright colors: {', '.join(scheme['brights'][:4])}...")

    # Confirm
    try:
        confirm = input("\nApply this theme to wezterm.lua? (y/N): ").strip().lower()
    except EOFError:
        # Handle non-interactive environment
        print("\nNon-interactive environment detected.")
        print("Applying theme automatically.")
        confirm = "y"
    if confirm != "y":
        print("Cancelled.")
        return

    # Update wezterm.lua
    wezterm_path = os.path.join(os.getcwd(), "wezterm.lua")
    print(f"\nUpdating {wezterm_path}...")

    content = read_wezterm_lua(wezterm_path)
    if content is None:
        print("Creating new wezterm.lua")
        content = ""

    updated_content = update_wezterm_lua(content, chosen["name"], scheme)

    try:
        with open(wezterm_path, "w", encoding="utf-8") as f:
            f.write(updated_content)
        print("Successfully updated wezterm.lua!")
        print(f"Theme '{chosen['name']}' is now active.")
    except Exception as e:
        print(f"Error writing to {wezterm_path}: {e}")


if __name__ == "__main__":
    main()
