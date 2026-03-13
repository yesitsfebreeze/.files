# Gogh Theme Picker for WezTerm

This script allows you to easily browse and apply themes from the [Gogh-Co/Gogh](https://github.com/Gogh-Co/Gogh) collection to your WezTerm configuration.

## Features

- Fetches all available themes from the Gogh repository
- Lets you preview and select a theme
- Automatically converts Gogh themes to WezTerm color scheme format
- Updates your `wezterm.lua` file with the selected theme
- Creates a new `wezterm.lua` file if one doesn't exist

## Requirements

- Python 3.x
- Internet connection (to fetch themes from GitHub)

## Usage

1. Place the `theme_picker.py` script in your WezTerm configuration directory (typically `~/.config/wezterm/` on Linux/macOS or `%USERPROFILE%\.config\wezterm\` on Windows)

2. Run the script:
   ```bash
   python theme_picker.py
   ```

3. Follow the prompts:
   - Browse the list of available Gogh themes
   - Select a theme by entering its number
   - Preview the theme colors
   - Confirm to apply the theme to your `wezterm.lua` file

## How It Works

1. The script fetches the list of themes from the Gogh-Co/Gogh GitHub repository
2. You select a theme from the numbered list
3. The script downloads the selected theme's shell script
4. It parses the color values from the Gogh theme format
5. Converts the colors to WezTerm's color scheme format
6. Updates (or creates) your `wezterm.lua` file with:
   - The new color scheme in the `color_schemes` table
   - The `color_scheme` setting pointing to your selected theme

## Example Output

After running the script and selecting a theme, your `wezterm.lua` will contain entries like:

```lua
color_schemes = {
    -- Other schemes...
    [".theme-name"] = {
        foreground = "#ffffff",
        background = "#000000",
        cursor_bg = "#ffffff",
        cursor_fg = "#000000",
        cursor_border = "#ffffff",
        selection_bg = "#ffffff",
        selection_fg = "#000000",
        ansi = {
            "#000000",
            "#cd3131",
            -- ... more colors
        },
        brights = {
            "#ffffff",
            "#f14c4c",
            -- ... more colors
        },
    },
}

color_scheme = "theme-name"
```

## Notes

- The script backs up no existing configuration - consider version controlling your `wezterm.lua` or making manual backups
- If your `wezterm.lua` doesn't have a `color_schemes` table, the script will create one
- The script preserves any existing content in your `wezterm.lua` file
- Theme names are sanitized to work as Lua table keys

## Troubleshooting

- If you encounter network issues, ensure you can access `github.com`
- If parsing fails, the theme may use a non-standard format
- For Lua syntax errors after applying a theme, check that your `wezterm.lua` is valid Lua

## License

This script is provided as-is without warranty. Feel free to modify and distribute it as needed.