# Windows window-manager configs

Tracked copies of the laptop's Windows-side WM configs:

| repo file              | Windows target                          |
| ---------------------- | --------------------------------------- |
| `glazewm/config.yaml`  | `%USERPROFILE%\.glzr\glazewm\config.yaml`  |
| `yasb/config.yaml`     | `%USERPROFILE%\.config\yasb\config.yaml`   |
| `yasb/styles.css`      | `%USERPROFILE%\.config\yasb\styles.css`    |

These live **outside** the chezmoi root (`home/`), so `chezmoi apply` ignores
them. They can't be symlinked across the WSL/Windows boundary (Developer Mode is
off), so they're synced as copies with `sync-to-windows.sh`.

## Usage (run in WSL on the laptop)

```sh
./sync-to-windows.sh          # push repo -> Windows, reload YASB
./sync-to-windows.sh --pull   # capture live edits Windows -> repo, then commit
```

After a push, press **Alt+Shift+R** to reload GlazeWM (it runs elevated, so the
script can't reload it for you). YASB is reloaded automatically.
