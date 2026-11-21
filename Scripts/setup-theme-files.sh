#!/usr/bin/env bash
# Generate missing Prodi theme files (hypr.theme, theme.dcol, wallpapers/, wall.set)
# for themes shipped in Configs/.local/share/themes/

THEMES_DIR="/tmp/kilo/hyprland-config/Configs/.local/share/themes"
WALLPAPERS_DIR="/tmp/kilo/hyprland-config/Configs/.config/hypr/assets/wallpapers"

# Map theme name -> wallpaper directory
declare -A theme_wallpaper=(
  ["Catppuccin-Latte"]="Catppuccin Latte"
  ["Catppuccin-Mocha"]="Catppuccin Mocha"
  ["Decay-Green"]="Decay Green"
  ["Edge-Runner"]="Edge Runner"
  ["Frosted-Glass"]="Frosted Glass"
  ["Graphite-Mono"]="Graphite Mono"
  ["Gruvbox-Retro"]="Gruvbox Retro"
  ["Material-Sakura"]="Material Sakura"
  ["Nordic-Blue"]="Nordic Blue"
  ["Rose-Pine"]="Rosé Pine"
  ["Synth-Wave"]="Synth Wave"
  ["Tokyo-Night"]="Tokyo Night"
  ["Wallbash-Gtk"]=""
)

for theme_dir in "$THEMES_DIR"/*/; do
  theme_name="$(basename "$theme_dir")"
  echo "Processing theme: $theme_name"

  # 1. Create wallpapers/ directory
  mkdir -p "$theme_dir/wallpapers"

  # 2. Symlink matching wallpaper if available
  wp_dir="${theme_wallpaper[$theme_name]:-}"
  if [[ -n "$wp_dir" && -d "$WALLPAPERS_DIR/$wp_dir" ]]; then
    count=0
    for wp in "$WALLPAPERS_DIR/$wp_dir"/*; do
      [[ -f "$wp" ]] || continue
      ln -sf "$wp" "$theme_dir/wallpapers/$(basename "$wp")" 2>/dev/null || true
      ((count++))
      [[ $count -ge 3 ]] && break  # up to 3 wallpapers per theme
    done
  fi

  # 3. Create wall.set symlink to first wallpaper
  if compgen -G "$theme_dir/wallpapers/*" > /dev/null 2>&1; then
    wp_file=$(ls "$theme_dir/wallpapers/" | head -1)
    ln -sf "$theme_dir/wallpapers/$wp_file" "$theme_dir/wall.set" 2>/dev/null || true
  fi

  # 4. Create hypr.theme if missing
  if [[ ! -f "$theme_dir/hypr.theme" ]]; then
    cat > "$theme_dir/hypr.theme" << THEME
# Prodi theme: $theme_name
\$THEME_NAME = $theme_name
\$COLOR_ACCENT = #ffffff
\$COLOR_BACKGROUND = #000000
\$COLOR_FOREGROUND = #ffffff
THEME
  fi

  # 5. Create theme.dcol if missing
  if [[ ! -f "$theme_dir/theme.dcol" ]]; then
    cat > "$theme_dir/theme.dcol" << DCOL
# Prodi color state: $theme_name
background=0x000000ff
foreground=0xffffffff
accent=0xffffffff
DCOL
  fi
done

echo "Done."
