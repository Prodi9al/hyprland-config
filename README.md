<div align="center">

# Prodi9al Hyprland Config

[![Hyprland](https://img.shields.io/badge/Hyprland-0.45+-blue?logo=wayland)](https://hyprland.org/)
[![Lua](https://img.shields.io/badge/Lua-5.4-blue?logo=lua)](https://www.lua.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

</div>

---

<div align="center">

<br>

<a href="#installation"><kbd> Installation </kbd></a>&ensp;&ensp;
<a href="#updating"><kbd> Updating </kbd></a>&ensp;&ensp;
<a href="#themes"><kbd> Themes </kbd></a>&ensp;&ensp;
<a href="#styles"><kbd> Styles </kbd></a>&ensp;&ensp;
<a href="#keybinds"><kbd> Keybinds </kbd></a>&ensp;&ensp;
<a href="#prodi-framework"><kbd> Prodi Framework </kbd></a>&ensp;&ensp;

</div><br>

<div align="center">
  <div style="display: flex; flex-wrap: nowrap; justify-content: center;">
    <img src="https://img.shields.io/badge/Arch%20Linux-1793D1?style=for-the-badge&logo=arch-linux&logoColor=white" alt="Arch Linux" style="width: auto; margin: 10px;"/>
    <img src="https://img.shields.io/badge/CachyOS-000000?style=for-the-badge" alt="CachyOS" style="width: auto; margin: 10px;"/>
    <img src="https://img.shields.io/badge/EndeavourOS-E44C1C?style=for-the-badge&logo=endeavouros&logoColor=white" alt="EndeavourOS" style="width: auto; margin: 10px;"/>
    <img src="https://img.shields.io/badge/Garuda-FF1B6D?style=for-the-badge&logo=garuda&logoColor=white" alt="Garuda" style="width: auto; margin: 10px;"/>
    <img src="https://img.shields.io/badge/NixOS-5276C7?style=for-the-badge&logo=nixos&logoColor=white" alt="NixOS" style="width: auto; margin: 10px;"/>
  </div>
</div>

---

## Preview

### Lock Screen Themes (`hyprlock/`)

| Theme | Config File |
|-------|-------------|
| **Prodi9al** (default) | `hyprlock/Prodi9al.conf` |
| SF Pro | `hyprlock/SF Pro.conf` |
| Arfan on Clouds | `hyprlock/Arfan on Clouds.conf` |
| Anurati | `hyprlock/Anurati.conf` |
| IBM Plex | `hyprlock/IBM Plex.conf` |
| IMB Xtented | `hyprlock/IMB Xtented.conf` |
| Greetd Wallbash | `hyprlock/greetd-wallbash.conf` |
| Greetd | `hyprlock/greetd.conf` |

Set the active layout in `hyprlock.conf`:

```bash
$LAYOUT_PATH=/home/prodi9al/.config/hypr/hyprlock/Prodi9al.conf
```

---

<a id="styles"></a>

### Featured Wallpaper

<div align="center">

<img src="Configs/.config/hypr/assets/wallpapers/Gojo Satoru/satoru-gojo-jjk-3840x2160-19527.png" width="400"/>

</div>

From `Configs/.config/hypr/assets/wallpapers/Gojo Satoru/`.

| Wallpaper | Directory |
|-----------|-----------|
| Black Summoner | `Configs/.config/hypr/assets/wallpapers/Black Summoner/` |
| Decay Green | `Configs/.config/hypr/assets/wallpapers/Decay Green/` |
| Gojo Satoru | `Configs/.config/hypr/assets/wallpapers/Gojo Satoru/` |
| Graphite Mono | `Configs/.config/hypr/assets/wallpapers/Graphite Mono/` |
| Kengan Ashura | `Configs/.config/hypr/assets/wallpapers/Kengan Ashura/` |
| Material Sakura | `Configs/.config/hypr/assets/wallpapers/Material Sakura/` |
| Nordic Blue | `Configs/.config/hypr/assets/wallpapers/Nordic Blue/` |
| Sukuna | `Configs/.config/hypr/assets/wallpapers/Sukuna/` |
| The World's Finest Assassin | `Configs/.config/hypr/assets/wallpapers/The World's Finest Assassin/` |

Set wallpaper via `prodi-shell wallpaper` or in `hyprland.lua`:

```lua
hl.env("WALLPAPER_CUSTOM_PATHS", os.getenv("HOME") .. "/Pictures/Wallpapers")
```

---

<a id="themes"></a>
<img src="https://readme-typing-svg.herokuapp.com?font=Lexend+Giga&size=25&pause=1000&color=CCA9DD&vCenter=true&width=435&height=25&lines=THEMES" width="450"/>

---

All available themes (37 total), each with its own `hypr.theme`, `kitty.theme`, `rofi.theme`, `waybar.theme`, `kvantum/`, and `wallpapers/` set. Organized by series below.

Switch themes with `prodi-shell theme.switch` or `theme.select.sh`.

---

### 🔥 Shonen Action

**Black Clover** — Magic Knights, grimoires, and Asta's anti-magic crusade in a world where magic decides everything *(20 wallpapers)*

<img src="Configs/.config/hypr/assets/wallpapers/Black Clover/wallhaven_Black_Clover_p1_10.jpg" width="300"/>

**Bleach** — Soul Reapers, Hollows, and Ichigo Kurosaki's journey through the Soul Society *(20 wallpapers)*

<img src="Configs/.config/hypr/assets/wallpapers/Bleach/wallhaven_Bleach_p1_10.jpg" width="300"/>

**Blue Lock** — Egoistic strikers locked in a brutal competition to become the world's best striker *(20 wallpapers)*

<img src="Configs/.config/hypr/assets/wallpapers/Blue Lock/blue_lock_p1_1.png" width="300"/>

**Demon Slayer** — Tanjiro Kamado's quest to cure his sister Nezuko and slay demons with breathing styles *(37 wallpapers)*

<img src="Configs/.config/hypr/assets/wallpapers/Demon Slayer/wallhaven_Demon_Slayer_p1_10.jpg" width="300"/>

**Dr. Stone** — Senku Ishigami rebuilds civilization from the Stone Age with the power of science *(9 wallpapers)*

<img src="Configs/.config/hypr/assets/wallpapers/Dr. Stone/danbooru_Dr._Stone_p21_4.jpg" width="300"/>

**Fullmetal Alchemist: Brotherhood** — The Elric brothers' search for the Philosopher's Stone and the truth of alchemy *(21 wallpapers)*

<img src="Configs/.config/hypr/assets/wallpapers/Fullmetal Alchemist: Brotherhood/wallhaven_Fullmetal_Alchemist:_Brotherhood_p1_10.png" width="300"/>

**High School DxD** — Issei Hyoudou's rise as a devil in a world of angels, fallen angels, and dragons *(23 wallpapers)*

<img src="Configs/.config/hypr/assets/wallpapers/High School DxD/danbooru_High_School_DxD_p137_6.jpg" width="300"/>

**Hunter x Hunter** — Gon Freecss's quest to find his father and become a top-tier Hunter *(20 wallpapers)*

<img src="Configs/.config/hypr/assets/wallpapers/Hunter x Hunter/danbooru_Hunter_x_Hunter_p113_3.jpg" width="300"/>

**Jujutsu Kaisen** — Cursed spirits, jujutsu sorcerers, and Yuji Itadori's battle against the King of Curses *(45 wallpapers)*

<img src="Configs/.config/hypr/assets/wallpapers/Jujutsu Kaisen/jujutsu_kaisen_10.jpg" width="300"/>

**Kaiju No. 8** — Kafka Hibino's fight against kaiju monsters as a member of the Defense Force *(12 wallpapers)*

<img src="Configs/.config/hypr/assets/wallpapers/Kaiju No. 8/danbooru_Kaiju_No._8_p17_1.jpg" width="300"/>

**My Hero Academy** — Quirk-powered heroes-in-training at U.A. High School aiming to become the Symbol of Peace *(20 wallpapers)*

<img src="Configs/.config/hypr/assets/wallpapers/My Hero Academy/wallhaven_my_hero_academy_p1_10.png" width="300"/>

**Seven Deadly Sins** — Meliodas and the legendary knights framed for treason, clearing their names *(21 wallpapers)*

<img src="Configs/.config/hypr/assets/wallpapers/Seven Deadly Sins/wallhaven_Seven_Deadly_Sins_p1_10.png" width="300"/>

**Soul Land** — Tang San's cultivation journey in a world where spirit masters wield martial souls *(5 wallpapers)*

<img src="Configs/.config/hypr/assets/wallpapers/Soul Land/soul_land_1.jpg" width="300"/>

**Sword Art Online** — Kirito's fight to escape a virtual death game where dying in-game means dying for real *(20 wallpapers)*

<img src="Configs/.config/hypr/assets/wallpapers/Sword Art Online/wallhaven_sword_art_online_p1_10.png" width="300"/>

---

### 🌀 Isekai & Fantasy

**Re:Zero** — Subaru Natsuki's Return by Death as he navigates a dangerous fantasy world *(20 wallpapers)*

<img src="Configs/.config/hypr/assets/wallpapers/Re:Zero/wallhaven_Re:Zero_p1_10.png" width="300"/>

**That Time I Got Reincarnated as a Slime** — Rimuru Tempest builds a monster nation starting from slime form *(19 wallpapers)*

<img src="Configs/.config/hypr/assets/wallpapers/That Time I Got Reincarnated as a Slime/danbooru_That_Time_I_Got_Reincarnated_as_a_Slime_p19_1.png" width="300"/>

**The Eminence in Shadow** — Cid Kagenou's delusional shadowbrother fantasy becomes all too real *(20 wallpapers)*

<img src="Configs/.config/hypr/assets/wallpapers/The Eminence in Shadow/danbooru_The_Eminence_in_Shadow_p20_1.jpg" width="300"/>

**The Rising of the Shield Hero** — Naofumi Iwatani's betrayal-fueled rise as the Shield Hero *(20 wallpapers)*

<img src="Configs/.config/hypr/assets/wallpapers/The Rising of the Shield Hero/danbooru_The_Rising_of_the_Shield_Hero_p20_1.jpg" width="300"/>

---

### 👻 Supernatural & Dark Fantasy

**Death Note** — Light Yagami's deadly game of justice with a notebook that kills anyone whose name is written *(20 wallpapers)*

<img src="Configs/.config/hypr/assets/wallpapers/Death Note/danbooru_Death_Note_p11_2.jpg" width="300"/>

**Tokyo Ghoul** — Ken Kaneki's transformation into a half-ghoul caught between human and monster worlds *(20 wallpapers)*

<img src="Configs/.config/hypr/assets/wallpapers/Tokyo Ghoul/wallhaven_Tokyo_Ghoul_p1_10.png" width="300"/>

---

### ⚔️ Character Themes

**Gojo Satoru** — The strongest jujutsu sorcerer, blindfolded and wielding the Limitless technique *(18 wallpapers)*

<img src="Configs/.config/hypr/assets/wallpapers/Gojo Satoru/gojo_satoru_10.jpg" width="300"/>

**Megumi Fushiguro** — Jujutsu sorcerer commanding the Ten Shadows Technique and its shikigami *(13 wallpapers)*

<img src="Configs/.config/hypr/assets/wallpapers/Megumi Fushiguro/megumi_fushiguro_10.png" width="300"/>

**Sukuna** — The King of Curses, incarnate and wreaking havoc through Yuji Itadori's body *(19 wallpapers)*

<img src="Configs/.config/hypr/assets/wallpapers/Sukuna/323485185758555283_rotated.png" width="300"/>

**Yuji Itadori** — Tokyo Jujutsu High first-year and vessel of Ryomen Sukuna *(15 wallpapers)*

<img src="Configs/.config/hypr/assets/wallpapers/Yuji Itadori/yuji_itadori_10.png" width="300"/>

---

### ⚡ Cyberpunk & Disney

**Edge Runner** — David Martinez's rise as an edgerunner surviving in the neon-soaked Night City *(5 wallpapers)*

<img src="Configs/.config/hypr/assets/wallpapers/Edge Runner/cyberpunk_dave.png" width="300"/>

**Mulan** — The warrior who took her father's place in the army, defending China with honor *(2 wallpapers)*

<img src="Configs/.config/hypr/assets/wallpapers/Mulan/mulan_1.jpg" width="300"/>

---

### 🌈 Color & Scheme Themes

**Catppuccin Latte** — Pastel light theme from the soothing Catppuccin color palette *(15 wallpapers)*

<img src="Configs/.config/hypr/assets/wallpapers/Catppuccin Latte/abstract_blured.jpg" width="300"/>

**Catppuccin Mocha** — Dark coffee-soaked theme from the Catppuccin color palette *(15 wallpapers)*

<img src="Configs/.config/hypr/assets/wallpapers/Catppuccin Mocha/1%20rain_world.png" width="300"/>

**Decay Green** — Decay-inspired green scheme with muted, organic tones *(7 wallpapers)*

<img src="Configs/.config/hypr/assets/wallpapers/Decay Green/arcade_decay_red.png" width="300"/>

**Frosted Glass** — Translucent glassmorphism aesthetic with blurred backgrounds *(6 wallpapers)*

<img src="Configs/.config/hypr/assets/wallpapers/Frosted Glass/blue_desert.png" width="300"/>

**Graphite Mono** — Monochrome graphite tones for a minimalist, professional look *(13 wallpapers)*

<img src="Configs/.config/hypr/assets/wallpapers/Graphite Mono/chainsawman_sketch.png" width="300"/>

**Gruvbox Retro** — Retro 70s-inspired Gruvbox colors with warm, earthy tones *(9 wallpapers)*

<img src="Configs/.config/hypr/assets/wallpapers/Gruvbox Retro/finalizer.png" width="300"/>

**Material Sakura** — Soft pastel cherry blossom palette with gentle pinks and whites *(9 wallpapers)*

<img src="Configs/.config/hypr/assets/wallpapers/Material Sakura/material_pastel_1.jpg" width="300"/>

**Nordic Blue** — Cool Nordic blues evoking Scandinavian winter landscapes *(8 wallpapers)*

<img src="Configs/.config/hypr/assets/wallpapers/Nordic Blue/forest.jpg" width="300"/>

**Rosé Pine** — Soothing rose-pine colors designed for comfort and focus *(17 wallpapers)*

<img src="Configs/.config/hypr/assets/wallpapers/Rosé Pine/burning_cherry.jpeg" width="300"/>

**Synth Wave** — 80s neon retrowave aesthetic with glowing magentas and cyans *(4 wallpapers)*

<img src="Configs/.config/hypr/assets/wallpapers/Synth Wave/beach.jpg" width="300"/>

**Tokyo Night** — Dark neon Tokyo nightscape with deep blues and vibrant accents *(6 wallpapers)*

<img src="Configs/.config/hypr/assets/wallpapers/Tokyo Night/cat_lofi_cafe.jpg" width="300"/>

---

---

<a id="shaders"></a>
<img src="https://readme-typing-svg.herokuapp.com?font=Lexend+Giga&size=25&pause=1000&color=CCA9DD&vCenter=true&width=435&height=25&lines=SHADERS" width="450"/>

---

Fragment shaders for hyprlock/hyprsunset visual effects:

| Shader | Effect |
|--------|--------|
| `blue-light-filter.frag` | Blue light reduction |
| `color-vision.frag` | Color vision simulation |
| `custom.frag` | Combined custom shader |
| `disable.frag` | Disable effects |
| `grayscale.frag` | Grayscale filter |
| `invert-colors.frag` | Color inversion |
| `oled-saver.frag` | OLED screen saver |
| `paper.frag` | Paper texture |
| `vibrance.frag` | Color vibrance boost |
| `wallbash.frag` | Wallbash wallpaper effect |

---

<a id="keybinds"></a>
<img src="https://readme-typing-svg.herokuapp.com?font=Lexend+Giga&size=25&pause=1000&color=CCA9DD&vCenter=true&width=435&height=25&lines=KEYBINDS" width="450"/>

---

(mainMod = SUPER)

| Key | Action |
|-----|--------|
| `Q` | Launch terminal (`kitty`) |
| `C` | Close window |
| `M` | Shutdown/exit Hyprland |
| `E` | File manager (`dolphin`) |
| `V` | Toggle floating |
| `R` | Menu (`wofi`) |
| `D` | Prodi9al home screen launchpad |
| `A` | Prodi9al app selector |
| `P` | Pseudo-tiling toggle |
| `J` | Toggle split (dwindle) |
| `Arrow keys` | Move focus |
| `SHIFT + Arrow` | Move window (Prodi9al overrides) |
| `0-9` | Switch/move to workspace |
| `SHIFT + 0-9` | Move window to workspace |
| `S` | Toggle scratchpad (`magic`) |
| `SHIFT + S` | Move window to scratchpad |
| `SUPER + scroll` | Cycle workspaces |
| `SUPER + LMB/RMB` | Drag/resize windows |

### Multimedia Keys
| Key | Action |
|-----|--------|
| `XF86AudioRaiseVolume` | Volume +5% |
| `XF86AudioLowerVolume` | Volume -5% |
| `F5` | Mute audio toggle |
| `XF86AudioMicMute` | Mic mute toggle |
| `XF86MonBrightnessUp` | Brightness +5% |
| `XF86MonBrightnessDown` | Brightness -5% |
| `XF86AudioNext` | Next track |
| `XF86AudioPause` / `XF86AudioPlay` | Play/pause |
| `XF86AudioPrev` | Previous track |

---

<a id="prodi-framework"></a>
<img src="https://readme-typing-svg.herokuapp.com?font=Lexend+Giga&size=25&pause=1000&color=CCA9DD&vCenter=true&width=435&height=25&lines=PRODI FRAMEWORK" width="450"/>

---

Includes the full Prodi framework so this repo can recreate your complete setup:

| Path | Purpose |
|------|---------|
| `prodi-shell` | CLI tool — lockscreen, theme.switch, wallpaper, reload |
| `prodi-lib/` | Shell, Lua, and Python scripts |
| `prodi-share/` | Rofi themes, config registry, assets |
| `prodi-share-hypr/` | Prodi Lua module (`prodi.lua`, `lua/prodi/`, `schema/`) |

### `prodi-lib/` Scripts
- `display-cycle.sh` — Cycle display/projection modes
- `lockscreen.sh` — Lock screen launcher
- `wallpaper.sh` / `wallbashtoggle.sh` — Wallpaper management
- `brightnesscontrol.sh`, `battery.sh`, `volumecontrol.sh` — Hardware controls
- `cliphist.sh` — Clipboard history
- `rofi.sh`, `rofilaunch.sh` — Rofi integration
- `theme.select.sh`, `theme.switch.sh` — Theme switching
- `config.lua`, `layouts.lua`, `animations.lua` — Lua config modules
- `weather.py`, `mediaplayer.py`, `session.py` — Python utilities

---

## Structure

| Path | Purpose |
|------|---------|
| `hyprland.lua` | Main Hyprland Lua config (keybinds, rules, animations, autostart) |
| `hyprlock.conf` | Hyprlock lock screen config |
| `hypridle.conf` | Hypridle idle actions (dim, lock, DPMS, suspend) |
| `hyprsunset.conf` | Hyprsunset color temperature config |
| `hyprlock/*.conf` | Lock screen layouts & themes |
| `shaders/*.frag` | Fragment shaders for hyprlock/hyprsunset visual effects |
| `themes/colors.conf` | Color theme definitions |
| `assets/rofi-assets/` | Rofi theme preview images |
| `Configs/.config/hypr/assets/wallpapers/` | Wallpaper collections |
| `.gitignore` | Excludes `*.before-*` backups and `hyprlock-backups/` |

---

### Waybar Config

Waybar configuration is shipped under `Configs/.config/waybar/`. It includes:

| File | Purpose |
|------|---------|
| `config.jsonc` | Main waybar bar configuration |
| `modules/custom-htb.jsonc` | Hack The Box rank module |
| `scripts/htb.py` | HTB API fetcher (requires `HTB_TOKEN` and `HTB_USER_ID`) |
| `style.css` / `theme.css` | Bar styling |
| `includes/` | Module includes and shared styles |

**HTB module setup:** Create `~/.config/waybar/scripts/htb_token.env` with your API token:

```bash
export HTB_TOKEN="your_hackthebox_api_token"
```

And set your user ID via environment:

```bash
export HTB_USER_ID="your_htb_user_id"
```

The token file is gitignored — never commit it.

---

### UI Configs

Full desktop UI configuration is shipped under `Configs/`. It includes:

| Path | Purpose |
|------|---------|
| `Configs/.config/dunst` | Notification daemon config |
| `Configs/.config/fastfetch` | System info display |
| `Configs/.config/gtk-3.0` / `Configs/.config/gtk-4.0` | GTK theming |
| `Configs/.config/kitty` | Terminal emulator |
| `Configs/.config/Kvantum` | Qt SVG theme engine |
| `Configs/.config/nwg-look` | GTK config tool settings |
| `Configs/.config/pypr` | Hyprland wrapper config |
| `Configs/.config/qt5ct` / `Configs/.config/qt6ct` | Qt theming |
| `Configs/.config/swaync` | Notification daemon (alt to dunst) |
| `Configs/.config/wlogout` | Logout/shutdown menu UI |
| `Configs/.config/xsettingsd` | X settings daemon |
| `Configs/.config/hyde` | Hyde theme system data |
| `Configs/.local/share/themes` | GTK/Kvantum themes (Catppuccin, Decay-Green, Edge-Runner, etc.) |
| `Configs/.local/share/icons` | Icon themes (BeautyLine, Bibata, Gruvbox, etc.) |
| `Configs/.local/share/fonts` | Font files (JetBrainsMono, MapleMono, Mononoki, etc.) |
| `Configs/.local/share/waybar` | Additional waybar includes, layouts, modules, styles |
| `Configs/.local/share/sddm` | Display manager theme |
| `Configs/.local/share/rofi` | Rofi themes |
| `Configs/.local/share/wallbash` | Wallbash color cache |

All hardcoded paths use `$HOME` or `$XDG_*` placeholders — no personal data is committed.

---

## Repository Structure

| Path | Purpose |
|------|---------|
| `Configs/.config/` | Dotfiles restored to `~/.config/` (hypr, waybar, gtk, kitty, rofi, zsh, fish, etc.) |
| `Configs/.local/` | Dotfiles restored to `~/.local/` (prodi, themes, waybar, rofi, sddm, etc.) |
| `Scripts/install.sh` | Arch Linux install script |
| `Scripts/pkg_core.lst` | Core package list (pacman) |
| `Scripts/pkg_extra.lst` | Extra package list (AUR) |
| `Scripts/restore_cfg.lst` | Config restore manifest |
| `Scripts/uninstall.sh` | Uninstall script |
| `Scripts/install_aur.sh` | AUR package installer |
| `Scripts/restore_cfg.sh` | Config restore script |
| `Scripts/version.sh` | Version info |
| `Scripts/hypr_autogen.sh` | Hyprland config autogenerator |
| `Scripts/themepatcher.lst` | Available themes list |
| `Scripts/dots-groups/` | Dotfile group manifests (core, extra, shell, etc.) |
| `dots.toml` | Dotfile manifest |
| `Source/assets/` | Wallpapers and showcase images |
| `Source/docs/` | Documentation (migration guide, etc.) |
| `Source/misc/` | Miscellaneous source files |
| `LICENSE` | MIT License |
| `CONTRIBUTING.md` | Contribution guidelines |
| `KEYBINDINGS.md` | Keybinding reference |
| `CHANGELOG.md` | Release history |

---

## Installation

### Option 1: Install script (recommended)

```bash
# Clone the repo
gh repo clone Prodi9al/hyprland-config ~/hyprland-config
cd ~/hyprland-config

# Run the Arch Linux installer
./Scripts/install.sh
```

The installer handles dependency installation, backs up existing configs to `~/.config/cfg_backups/`, and restores all dotfiles from `Configs/` to their target locations.

**Options:**
- `./Scripts/install.sh` — Standard install (pacman packages only)
- `./Scripts/install.sh --aur` — Also install AUR packages (requires yay/paru/pamac)

**Other scripts:**
- `./Scripts/uninstall.sh` — Remove all restored dotfiles
- `./Scripts/restore_cfg.sh` — Restore configs from `Configs/` with backup
- `./Scripts/install_aur.sh` — Install AUR packages from `pkg_extra.lst`
- `./Scripts/version.sh` — Show version info

### Option 2: Manual

```bash
# Clone the full setup
gh repo clone Prodi9al/hyprland-config ~/hyprland-config
cd ~/hyprland-config

# Restore .config/ dotfiles
cp -r Configs/.config/* ~/.config/

# Restore .local/ dotfiles
cp -r Configs/.local/* ~/.local/

# Make prodi-shell executable
chmod +x ~/.local/bin/prodi-shell

# Add ~/.local/bin to PATH
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
```

### Dependencies (Arch)

Install manually if not using the installer:

```bash
sudo pacman -S --needed \
  hyprland hyprlock hypridle hyprsunset xdg-desktop-portal-hyprland \
  kitty konsole waybar rofi wofi \
  swww hyprpaper mpvpaper awww waydeeper grimblast swappy \
  brightnessctl pamixer pipewire pipewire-pulse polkit polkit-gnome \
  dunst mako fastfetch fzf jq curl wget unzip tar git \
  base-devel make gcc lua luarocks python python-pip \
  xdg-desktop-portal xdg-desktop-portal-gtk kvantum dolphin
```

---

## License

Personal dotfiles — use at your own risk.
