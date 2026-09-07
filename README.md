# DeskHider (Enhanced Version)

Toggle desktop icon visibility with a double-click on the desktop (or a configurable hotkey).

Lightweight: tiny, no GUI, zero popups. All settings live in a plain `DeskHider.ini` text file.

> **For end users:** you only need DeskHider.exe. The required DeskHider.ini is generated automatically the first time you run the program.

A modified fork of [DeskHider](https://github.com/iandiv/DeskHider) by Ian Div (MIT License).

## Files

| File | Purpose |
| --- | --- |
| `DeskHider.exe` | Compiled program (no AutoHotkey installation required) |
| `DeskHider.ahk` | Source code (run with AutoHotkey v1, or recompile) |
| `DeskHider.ini` | Configuration file (same folder as the program; auto-generated on first run) |

> Keep `DeskHider.exe` and `DeskHider.ini` in the same folder. `DeskHider.ahk` is the source code only and does not need to be in the same folder (unless you run it directly with AutoHotkey).

## Usage

1. Run `DeskHider.exe`; a DeskHider icon appears in the system tray.
2. **Double-click the blank area of the desktop** to hide the desktop icons; double-click again to restore them.
   - Double-clicking an **icon** itself does not trigger (original behavior — opening icons still works normally).
   - When the icons are hidden, double-clicking anywhere on the desktop restores them.
3. Right-click the tray icon:
   - **Open Config File**: opens `DeskHider.ini` in Notepad
   - **Reload Config**: applies ini changes immediately (no restart required)
   - **Exit**: quits DeskHider

## Configuration (`DeskHider.ini`)

```ini
[Settings]
Clicks=2              ; clicks to toggle: 2=double-click, 3=triple-click
ClickWindow=350       ; click interval (ms)
Hotkey=Space          ; desktop hotkey, empty=disabled
HotkeyClicks=2        ; hotkey presses to toggle, default 2
HotkeyClickWindow=350 ; hotkey interval (ms), empty=same as ClickWindow
AutoHideSeconds=0     ; auto-hide after N seconds of clear desktop, 0=disabled
```

| Key | Default | Description |
| --- | --- | --- |
| `Clicks` | `2` | Mouse clicks needed to toggle (2 = double-click, 3 = triple-click; range 2–5). |
| `ClickWindow` | `350` | Max interval between mouse clicks in milliseconds (double-click: 300–500, triple-click: 400–600). |
| `Hotkey` | `Space` | Desktop hotkey (default `Space`, double-press); empty = disabled. Fires when **either** ① no visible top-level windows exist (all closed / all minimized), or ② the desktop is focused (e.g. you clicked the desktop while a window is open). The **space bar is supported**: `Ctrl+Space`, `Space`. Two syntaxes: friendly `Ctrl+Alt+H`, or AHK native `^!h` (`^`=Ctrl, `!`=Alt, `+`=Shift, `#`=Win). Multi-press triggered (2 presses by default); never swallows keys, typing is unaffected. |
| `HotkeyClicks` | `2` | Hotkey presses needed to toggle (2 = double-press, 3 = triple-press). |
| `HotkeyClickWindow` | *(same as mouse)* | Max interval between hotkey presses in milliseconds (150–1000). Empty = same as `ClickWindow`. |
| `AutoHideSeconds` | `0` | **Auto-hide**: when the icons are visible and **no normal windows are on screen** (all closed / all minimized) for this many seconds, the icons are hidden automatically. Any physical mouse move, click or keypress restarts the countdown. `0` = disabled. Restore the icons with your usual toggle (double-click / hotkey). Example: `30` = hide icons after 30 seconds of a clear, untouched desktop. |

### Example

```ini
[Settings]
Clicks=3
ClickWindow=500
Hotkey=Ctrl+Space
HotkeyClicks=2
HotkeyClickWindow=500
```

Triple-click the desktop to toggle icons, or double-press `Ctrl+Space` (while the desktop is active) to toggle.

### Auto-hide example

```ini
[Settings]
AutoHideSeconds=30
```

Close or minimize every window, stop touching the mouse and keyboard, and after 30 seconds of nothing but the desktop the icons hide themselves — handy for a clean wallpaper view. Any input or any opened window restarts the countdown; the icons are never auto-*shown*, only hidden.

## After changing the config

Save `DeskHider.ini` → right-click the tray icon → **Reload Config** → done.

## Building from source (optional)

Install [AutoHotkey v1](https://www.autohotkey.com/) (it includes the Ahk2Exe compiler):

- Right-click `DeskHider.ahk` → **Compile Script**, or
- Open Ahk2Exe, select `DeskHider.ahk`, set the icon to `DeskHider.ico`, output `DeskHider.exe`, compile.

## License

MIT — see [LICENSE](LICENSE). Original project by [Ian Div](https://github.com/iandiv/DeskHider).