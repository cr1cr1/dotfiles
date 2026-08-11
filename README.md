# dotfiles — dotdrift profile

CachyOS setup managed by [dotdrift](https://github.com/thedataflows/dotdrift).

## Layout

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

## Verify parity (before applying anything)

```sh
python3 ~/dotfiles/contrib/verify-parity.py
```

Compares this profile against the pimp repo's generated ground truth
(`mise.user.toml`, `mise.system.toml`, `apps/*/packages.yaml`) using
`dotdrift plan --json` (runs `go run .` inside the dotdrift checkout —
override with `DOTDRIFT_REPO`). Checks every dotfile target/mode/scope,
byte-identity of every source file, and the full package install/remove sets.
Prints and writes `PARITY.md`; the last line is the verdict
(`PARITY: 100%`).

## Apply

```sh
cd dev/dotdrift
go run . plan --profile ~/dotfiles     # dry-run first
go run . apply --profile ~/dotfiles    # or: dotdrift apply --profile ~/dotfiles
```

One `apply` covers everything: packages (via the distro backend), user
dotfiles, system dotfiles (via sudo — one password prompt per apply thanks
to sudo's timestamp cache), and hooks. Resume-safe: re-running continues
from the first incomplete step. Skip hooks with `--no-hooks`.

## Cutover status (2026-07-19)

**User scope is live**: all 114 user dotfiles were relinked from
`~/pimp-my-cachyos` to this profile (64 file links + 50 symlink-each dirs,
source-verified, 0 wrong targets). The first full `apply` will:

- Install 10 missing packages: `cachyos-wallpapers`, `gamescope-nvidia`,
  `kate`, `kwalletmanager`, `moonlight-qt`, `panel-colorizer`, `sddm-kcm`,
  `sunshine`, `swaylock`, `zellij` (the other 293 are already installed).
- Remove 5 GRUB packages (`grub`, `grub-btrfs`, `grub-customizer`,
  `grub-hook`, `catppuccin-mocha-grub-theme-git`) — safe: Limine is the
  active bootloader (EFI entry Boot0003).
- Copy 22 `/etc` dotfiles (content already byte-identical to what's in
  place from pimp; the step just confirms it).
- Run the setup hooks (idempotent re-confirmation of configured state).
- Relink user dotfiles — a no-op, they already point here.

Post-checks: re-login or open a new shell, spot-check kitty/niri, then
`python3 ~/dotfiles/contrib/verify-parity.py` (should stay 100%). Rollback
until pimp is retired: `cd ~/pimp-my-cachyos && mise run all`.

## scripts/ — what runs automatically vs manually

Copied verbatim from pimp's `mise-tasks/`.

**Hooked into apply** (post-hooks):

- `modules/system-setup` (scope=system): `system/snapper.sh`,
  `system/services.sh`, `system/video-drivers.sh`, `system/faillock.sh`,
  `system/locale.sh`, `system/smb.sh`, `system/virtualization.sh`
  (in pimp's original `all.sh` order).
- `modules/user-setup` (scope=user): `user/shell.sh`, `user/cleanup.sh`.

**Run manually** (one-time, risky, or on-demand — never hooked):

- `scripts/system/limine.sh`, `scripts/system/replace-grub-with-limine.sh`,
  `scripts/system/edk2-ovmf-downgrade.sh` — one-time bootloader/firmware
  migrations.
- `scripts/system/mountpoints.sh` — superseded by
  `hosts/<host>/modules/mountpoints/` (rendered units + enable hooks).
- `scripts/user/containerd.sh` — disabled upstream (requires `--force`).
- `scripts/network/firewall.sh`, `scripts/network/sshd.sh`,
  `scripts/backup.sh`, `scripts/env-reload.sh` — on-demand ops.
- `scripts/all.sh`, `scripts/packages.sh` — orchestration, subsumed by
  dotdrift itself.

## Known limitations

- Several `system-setup` hook scripts rely on `$PARU`; the generated hooks
  define it inline (`sudo env PARU="paru -S --noconfirm --needed --cleanafter"
  bash scripts/system/<name>.sh`). If you add system scripts that use `$PARU`,
  define it the same way or they will fail on `set -u`.
- Mountpoints units install to `/etc/systemd/system/`; upstream used
  `/usr/local/lib/systemd/system/`.
- dotdrift's `[when]` is module-level. No `packages.yaml` in the source repo
  currently uses per-package `hosts:` lists.
