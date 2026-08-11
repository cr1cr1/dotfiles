# dotfiles — dotdrift profile

CachyOS setup profile managed by [dotdrift](https://github.com/thedataflows/dotdrift).

## Desktop experience: Scrollable-tiling WM with Niri + Dank Material Shell (DMS)

An alternative scrollable-tiling desktop environment available at login (via Plasma Login Manager), alongside the default KDE Plasma. It is fully functional and can be used as a daily driver for me, yet. KDE Plasma is amazing, and the memory footprint is as similar as Niri+DMS.

**Niri** is a scrollable-tiling Wayland compositor that provides a unique workflow where windows are arranged in a scrollable column layout. Combined with **Dank Material Shell (DMS)**, it offers a fairly complete desktop experience with integrated widgets, launcher, notifications, and system monitoring.

Use `Niri` session at login to use it. I have fixed most quirks and issues, and it is now my daily driver to see how it feels.

### Key features

- Text seems sharper compared to KDE Plasma!
- Scrollable-tiling layout as default, fast and buttery smooth.
- DMS provides: top widget panel and bottom docking panel, application launcher (Super+Space), clipboard manager (Super+V), task manager/dgop (Super+Shift+Esc), notification center (Super+N), etc. Ctrl+Shift+/ show a list of the main shortcuts. For all my keybindings, see [binds.kdl](modules/niri/home/.config/niri/dms/binds.kdl)
- Catppuccin Mocha theme throughout
- Uses existing KeePassXC for secrets (no kwallet)
- Using KDE portal for integration, using the same KDE file dialogs, etc. Also uses KDE polkit agent for step-up authentication dialogs.
- Fully integratable with dsearch (filesystem search) and dgop (system monitoring) - I don't use them though, prefer DMS/KDE Launchers and `btop`.

![Niri + DMS](niri-dms-01.png)
![Niri + DMS - Overview Mode](niri-dms-02.png)

## The layout of this profile

```
dotdrift.toml            # minimal profile root
modules/<app>/           # one module per pimp app (89 user + 19 system scope)
  module.toml
  home/...               # dotfile sources (verbatim copies)
modules/system-setup/    # post-hooks: idempotent system setup scripts
modules/user-setup/      # post-hooks: idempotent user setup scripts
modules/mountpoints/     # empty base module; per-host overlays below
hosts/<host>/modules/mountpoints/  # rendered systemd mount units + enable hooks
scripts/                 # legacy scripts
```

App activation hooks: an optional `apps/<app>/post-hooks` file (one shell
command per line; `#` comments and blank lines ignored) is emitted as that
app module's `[hooks] post` — attached to the system module when the app
has one, else the user module. System-scope hooks carry their own `sudo`
(e.g. `system-logind` restarts `systemd-logind` after its drop-in lands).

## Install

This profile is self-contained: [mise](https://mise.jdx.dev) bootstraps both
itself and dotdrift (both listed in `mise.toml`) — no Go toolchain, no separate
dotdrift checkout.

```sh
sudo pacman -Sy mise
# or
curl https://mise.run | sh     # install mise → ~/.local/bin
```

```sh
cd ~/dotfiles
mise up                   # installs dotdrift (+ latest mise) from mise.toml
exec $SHELL                    # reload shell so mise shims are on PATH
dotdrift detect                # sanity check: prints host/user/os facts
```

## Apply

```sh
dotdrift plan    # dry-run first
dotdrift apply
```

One `apply` covers everything: packages (via the distro backend), user
dotfiles, system dotfiles (via sudo — one password prompt per apply thanks
to sudo's timestamp cache), and hooks. Resume-safe: re-running continues
from the first incomplete step. Skip hooks with `--no-hooks`.

## Information

```sh
# Modules listing and Information
dotdrift modules
# Status of the profile (what's applied, what needs to be applied)
dotdrift status --diff
```

## License

[MIT](LICENSE)
