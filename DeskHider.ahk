; ============================================================================
;  DeskHider - Toggle desktop icon visibility by double-clicking the desktop
;  Lightweight: no GUI, no popups; all settings live in DeskHider.ini
;
;  Config file: DeskHider.ini in the same folder as this script (or the exe)
;               Auto-generated on first run; edit it with any text editor
;  Tray menu:   Open Config File / Reload Config / Exit
;  Reload Config applies ini changes immediately, no restart required
;
;  Auto-hide:    optionally hides the icons automatically after the desktop
;                has been clear of windows AND free of mouse/keyboard input
;                for a while (AutoHideSeconds, 0 = disabled)
; ============================================================================

#SingleInstance, Force
#Persistent
#InstallMouseHook                 ; make A_TimeIdlePhysical track physical input
#InstallKeybdHook                 ; (needed by the auto-hide idle check)

; ----------------------------------------------------------------------------
; Configuration variables (defaults; overridden by DeskHider.ini)
; ----------------------------------------------------------------------------
IniFile           := A_ScriptDir "\DeskHider.ini"
Clicks            := 2      ; Mouse clicks to toggle: 2 = double-click, 3 = triple-click
ClickWindow       := 350    ; Max interval between mouse clicks (ms)
DesktopHotkey     := ""     ; Desktop hotkey; empty = disabled
PrevDesktopHotkey := ""     ; Previously registered hotkey (unregistered first on reload)
HotkeyClicks      := 2      ; Hotkey presses to toggle: 2 = double-press, 3 = triple-press
HotkeyClickWindow := 350    ; Max interval between hotkey presses (ms); empty = same as mouse
AutoHideSeconds   := 0      ; Auto-hide icons after N seconds of windowless desktop; 0 = disabled
AutoHideLastToggle := 0     ; TickCount of the last manual toggle (restarts the auto-hide countdown)

; ----------------------------------------------------------------------------
; Startup: load config + register the desktop hotkey
; ----------------------------------------------------------------------------
LoadConfig()
RegisterDesktopHotkey()
SetTimer, AutoHideCheck, 1000     ; 1-second auto-hide watchdog (idle while disabled)

; ----------------------------------------------------------------------------
; System tray menu
; ----------------------------------------------------------------------------
Menu, Tray, NoStandard
Menu, Tray, Add, Open Config File, OpenConfigFile
Menu, Tray, Add, Reload Config, ReloadConfig
Menu, Tray, Add
Menu, Tray, Add, Exit, QuitScript
Menu, Tray, Tip, DeskHider

; ============================================================================
; Mouse multi-click (active only while the mouse is over the desktop)
; ============================================================================
#If IsDesktopUnderMouse()
~LButton::
	LButton_presses++
	SetTimer, KeyLButton, -%ClickWindow%
	if (LButton_presses = Clicks)
		MaybeToggleDesktopIcons()
return

KeyLButton:
	LButton_presses := 0
return
#If

; Toggle icons when the condition is met (original behavior: does not trigger
; over an icon unless the icons are already hidden). Any manual toggle
; restarts the auto-hide countdown.
MaybeToggleDesktopIcons()
{
	global DesktopIconsIsShow, AutoHideLastToggle
	if (!IsObject(GetDesktopIconUnderMouse()) or DesktopIconsIsShow = 0)
	{
		DesktopIconsIsShow := HideOrShowDesktopIcons()
		AutoHideLastToggle := A_TickCount
	}
}

; ============================================================================
; Config loading / reloading
; ============================================================================
LoadConfig()
{
	global IniFile, Clicks, ClickWindow, DesktopHotkey
	global HotkeyClicks, HotkeyClickWindow, AutoHideSeconds

	; Create the default config file if it does not exist
	if (!FileExist(IniFile))
		CreateDefaultIni()

	IniRead, Clicks, %IniFile%, Settings, Clicks, 2
	if Clicks is not integer
		Clicks := 2
	if (Clicks < 2)
		Clicks := 2
	if (Clicks > 5)
		Clicks := 5

	IniRead, ClickWindow, %IniFile%, Settings, ClickWindow, 350
	if ClickWindow is not integer
		ClickWindow := 350
	if (ClickWindow < 150)
		ClickWindow := 150
	if (ClickWindow > 1000)
		ClickWindow := 1000

	IniRead, DesktopHotkey, %IniFile%, Settings, Hotkey
	if (DesktopHotkey = "ERROR")          ; key missing -> default hotkey
		DesktopHotkey := "Space"
	else if (DesktopHotkey = "")          ; explicitly empty -> disabled
		DesktopHotkey := ""
	else
		DesktopHotkey := NormalizeHotkey(DesktopHotkey)

	IniRead, HotkeyClicks, %IniFile%, Settings, HotkeyClicks, 2
	if HotkeyClicks is not integer
		HotkeyClicks := 2
	if (HotkeyClicks < 2)
		HotkeyClicks := 2
	if (HotkeyClicks > 5)
		HotkeyClicks := 5

	IniRead, HotkeyClickWindow, %IniFile%, Settings, HotkeyClickWindow
	if (HotkeyClickWindow = "ERROR" or HotkeyClickWindow = "")
		HotkeyClickWindow := ClickWindow ; empty = same as the mouse click window
	else
	{
		if HotkeyClickWindow is not integer
			HotkeyClickWindow := ClickWindow
		if (HotkeyClickWindow < 150)
			HotkeyClickWindow := 150
		if (HotkeyClickWindow > 1000)
			HotkeyClickWindow := 1000
	}

	; Auto-hide delay in seconds; anything invalid or negative = disabled
	IniRead, AutoHideSeconds, %IniFile%, Settings, AutoHideSeconds, 0
	if AutoHideSeconds is not integer
		AutoHideSeconds := 0
	if (AutoHideSeconds < 0)
		AutoHideSeconds := 0
}

; Write the default config file template (ANSI/ASCII so AHK v1 IniRead is happy)
CreateDefaultIni()
{
	global IniFile
	Template =
	(
; DeskHider configuration file
; After editing, save the file and click "Reload Config" in the tray menu
; to apply changes immediately (no restart required)
; Format: Name=Value ; lines starting with ; are comments

[Settings]
; Mouse clicks needed to toggle: 2 = double-click, 3 = triple-click (only one supported)
Clicks=2

; Max interval between mouse clicks, in milliseconds
; Double-click: 300-500 recommended; triple-click: 400-600 recommended
ClickWindow=350

; Desktop hotkey: triggers when any of the following is true; empty = disabled
;   1) No visible top-level windows (all windows closed / all minimized)
;   2) The desktop is focused (e.g., you clicked the desktop while a window is open)
; Two syntaxes are supported; for the space bar use "Space":
;   Friendly: Ctrl+Space, Ctrl+Alt+H, Shift+F1
;   AHK native: ^Space, ^!h, +F1
; Example: Ctrl+Space = hold Ctrl and press Space
; Note: the hotkey triggers on a multi-press; it never swallows keys or affects typing
Hotkey=Space

; Hotkey presses needed to toggle (2 = double-press, 3 = triple-press).
; Default 2, same as the mouse
HotkeyClicks=2

; Max interval between hotkey presses, in milliseconds.
; Empty = same as the mouse ClickWindow
HotkeyClickWindow= 350

; Auto-hide icons: when the icons are visible and NO normal windows are on
; screen (all closed / all minimized) for this many seconds, the icons are
; hidden automatically. Any mouse or keyboard input - even clicks injected
; by other software - and every manual toggle restarts the countdown.
; 0 = disabled. Restore the icons with your usual toggle (double-click /
; hotkey)
AutoHideSeconds=0
	)
	FileAppend, %Template%, %IniFile%
}

; Re-register the desktop hotkey (applied immediately after "Reload Config")
; Uses ~ pass-through + Up (release) events: never swallows keys, does not
; affect typing, and holding the key down does not repeat-count
RegisterDesktopHotkey()
{
	global DesktopHotkey, PrevDesktopHotkey
	; Unregister the previous hotkey first, then register the new one
	; (invalid values are silently ignored, no popups)
	if (PrevDesktopHotkey <> "")
		try Hotkey, ~%PrevDesktopHotkey% Up, ToggleDesktopHotkey, Off
	if (DesktopHotkey <> "")
		try Hotkey, ~%DesktopHotkey% Up, ToggleDesktopHotkey, On
	PrevDesktopHotkey := DesktopHotkey
}

; Returns 1 when the desktop should be considered active (either condition):
;   1) The desktop has focus (active window is the desktop, e.g. you clicked it)
;   2) No visible top-level windows exist (all closed / all minimized)
; Returns 0 otherwise
IsDesktopFocused()
{
	; Condition 1: the desktop is focused
	WinGetClass, winClass, A
	if (winClass = "WorkerW" or winClass = "Progman")
		return 1

	; Condition 2: no visible top-level windows
	return IsDesktopClear()
}

; Returns 1 when no visible normal top-level windows exist (all closed / all
; minimized). Minimized, hidden, tool and cloaked windows as well as the
; desktop and taskbar windows themselves don't count.
IsDesktopClear()
{
	WinGet, winList, List
	loop, %winList%
	{
		hwnd := winList%A_Index%
		WinGet, style, Style, ahk_id %hwnd%
		if (style & 0x20000000)        ; minimized windows don't count
			continue
		if (!(style & 0x10000000))     ; invisible windows don't count
			continue
		WinGet, exStyle, ExStyle, ahk_id %hwnd%
		if (exStyle & 0x80)            ; tool windows (tray/notifications) don't count
			continue
		if IsWindowCloaked(hwnd)       ; suspended UWP / other-virtual-desktop windows don't count
			continue
		WinGetClass, cls, ahk_id %hwnd%
		if (cls = "WorkerW" or cls = "Progman" or cls = "Shell_TrayWnd" or cls = "Shell_SecondaryTrayWnd")
			continue                   ; desktop / taskbar windows don't count
		return 0                       ; found a visible normal window
	}
	return 1                           ; no visible normal windows
}

; DWMWA_CLOAKED (14): nonzero when DWM hides the window while keeping it
; technically "visible" (suspended UWP apps, windows on inactive virtual
; desktops). Fails gracefully on systems without DWM support -> returns 0.
IsWindowCloaked(hwnd)
{
	cloaked := 0
	DllCall("dwmapi\DwmGetWindowAttribute", "Ptr", hwnd, "UInt", 14, "UIntP", cloaked, "UInt", 4)
	return cloaked ? 1 : 0
}

; Normalize a hotkey string into AHK native syntax.
; Both of these are accepted:
;   AHK native: ^!h, ^Space, #F5, +F1
;   Friendly:   Ctrl+Alt+H, Ctrl+Space, Shift+F1, Space
NormalizeHotkey(raw)
{
	if (raw = "")
		return ""
	raw := Trim(raw)
	if (raw = "")
		return ""
	; Strip a leading ~ the user may have written (pass-through is handled by the program)
	raw := RegExReplace(raw, "^~+", "")
	if (raw = "")
		return ""
	; Modifier-only values (e.g. "^" or "Ctrl+") become the Space key
	if (RegExMatch(raw, "^[\^!+#]+$"))
		return raw . "Space"
	; Contains ^ ! #, or starts with + = AHK native syntax, use as-is
	if (InStr(raw, "^") or InStr(raw, "!") or InStr(raw, "#") or SubStr(raw, 1, 1) = "+")
		return raw

	; Friendly syntax: split by "+" into modifiers + key
	prefix := ""
	key := ""
	for i, part in StrSplit(raw, "+")
	{
		part := Trim(part)
		if (part = "")
			continue
		if (part = "Ctrl")
			prefix .= "^"
		else if (part = "Alt")
			prefix .= "!"
		else if (part = "Shift")
			prefix .= "+"
		else if (part = "Win")
			prefix .= "#"
		else if (key = "")
			key := FriendlyKeyName(part)
		else
			return raw ; multiple keys: return as-is (AHK will reject it silently)
	}
	if (key = "")
		return raw ; modifiers only: return as-is (invalid, will be ignored)
	return prefix . key
}

; Map a friendly key name to an AHK key name (e.g. Space -> Space, Delete -> Delete)
FriendlyKeyName(name)
{
	; Chinese alias for the space bar (kept for convenience)
	if (name = "空格")
		return "Space"
	static map := {space:"Space", enter:"Enter", tab:"Tab", esc:"Esc", escape:"Esc"
		, delete:"Delete", del:"Delete", insert:"Insert", ins:"Insert"
		, home:"Home", end:"End", pgup:"PgUp", pageup:"PgUp", pgdn:"PgDn", pagedown:"PgDn"
		, up:"Up", down:"Down", left:"Left", right:"Right"
		, printscreen:"PrintScreen", prtsc:"PrintScreen", prtscr:"PrintScreen"
		, capslock:"CapsLock", numlock:"NumLock", scrolllock:"ScrollLock"}
	StringLower, low, name
	if (map.HasKey(low))
		return map[low]
	; Single letter -> uppercase (e.g. a -> A)
	if (StrLen(name) = 1 and RegExMatch(name, "i)^[a-z]$"))
	{
		StringUpper, up, name
		return up
	}
	return name
}

; ============================================================================
; Tray menu handlers
; ============================================================================
OpenConfigFile:
	Run, notepad.exe "%IniFile%"
return

ReloadConfig:
	LoadConfig()
	RegisterDesktopHotkey()
	LButton_presses := 0
	DesktopHotkey_presses := 0
return

; Desktop hotkey: fires when the desktop is active; toggles after HotkeyClicks
; presses (2 by default). Counts on key release only, so holding the key down
; never triggers; ~ pass-through keeps typing unaffected
ToggleDesktopHotkey:
	if (!IsDesktopFocused())
	{
		DesktopHotkey_presses := 0
		return
	}
	DesktopHotkey_presses++
	SetTimer, KeyDesktopHotkey, -%HotkeyClickWindow%
	if (DesktopHotkey_presses = HotkeyClicks)
	{
		DesktopIconsIsShow := HideOrShowDesktopIcons()
		AutoHideLastToggle := A_TickCount    ; manual toggle restarts the auto-hide countdown
	}
return

KeyDesktopHotkey:
	DesktopHotkey_presses := 0
return

QuitScript:
	ExitApp
return

; ============================================================================
; Auto-hide timer
; ============================================================================
; Runs once a second. Hides the visible icons once the desktop has stayed
; "clear" (no visible normal windows) with no input of any kind for
; AutoHideSeconds. Two idle clocks must both exceed the threshold:
;   A_TimeIdlePhysical - last PHYSICAL mouse/keyboard input
;   A_TimeIdle         - last input of ANY kind (also clicks/keys injected
;                        by other software, which physical-only misses)
; so every mouse move, click or keypress - real or synthetic - restarts the
; countdown. A manual toggle (mouse or hotkey) restarts it explicitly via
; AutoHideLastToggle. Icons are only hidden, never auto-shown.
AutoHideCheck:
	if (AutoHideSeconds < 1)                    ; feature disabled -> stay idle
		return
	if (!AreDesktopIconsVisible() or !IsDesktopClear())
		return
	if (A_TickCount - AutoHideLastToggle < AutoHideSeconds * 1000)
		return                                  ; recent manual toggle -> grace period
	if (A_TimeIdle >= AutoHideSeconds * 1000 and A_TimeIdlePhysical >= AutoHideSeconds * 1000)
		DesktopIconsIsShow := HideOrShowDesktopIcons()   ; sync with the click/hotkey logic
return

; ============================================================================
; Original core functions (unchanged)
; ============================================================================

IsDesktopUnderMouse()
{
	MouseGetPos, , , OutputVarWin
	WinGetClass, OutputVarClass, % "ahk_id" OutputVarWin
	if (OutputVarClass="WorkerW" or OutputVarClass="Progman")
		return, 1
	else
		return, 0
}

HideOrShowDesktopIcons()
{
	ControlGet, OutputVarHwnd, Hwnd,, SysListView321, ahk_class WorkerW
	if (OutputVarHwnd="")
      ControlGet, OutputVarHwnd, Hwnd,, SysListView321, ahk_class Progman

	if (DllCall("IsWindowVisible", UInt, OutputVarHwnd))
	{
		WinHide, ahk_id %OutputVarHwnd%
		return, 0
	}
	else
	{
		WinShow, ahk_id %OutputVarHwnd%
		return, 1
	}
}

; Returns 1 when the desktop icon ListView is currently visible, 0 when it is
; hidden (or cannot be found). Queries the real window state instead of the
; DesktopIconsIsShow flag, so it is also correct at script start.
AreDesktopIconsVisible()
{
	hwnd := ""
	ControlGet, hwnd, Hwnd,, SysListView321, ahk_class WorkerW
	if (hwnd = "")
		ControlGet, hwnd, Hwnd,, SysListView321, ahk_class Progman
	if (hwnd = "")
		return 0
	return DllCall("IsWindowVisible", "Ptr", hwnd) ? 1 : 0
}

GetDesktopIconUnderMouse() {
	static MEM_COMMIT := 0x1000, MEM_RELEASE := 0x8000, PAGE_ReadWRITE := 0x04
		, PROCESS_VM_OPERATION := 0x0008, PROCESS_VM_READ := 0x0010
		, LVM_GETITEMCOUNT := 0x1004, LVM_GETITEMRECT := 0x100E

	Icon := ""
	MouseGetPos, x, y, hwnd
	if not (hwnd = WinExist("ahk_class Progman") || hwnd = WinExist("ahk_class WorkerW"))
		return
	ControlGet, hwnd, HWND, , SysListView321
	if not WinExist("ahk_id" hwnd)
		return
	WinGet, pid, PID
	if (hProcess := DllCall("OpenProcess" , "UInt", Process_VM_OPERATION|Process_VM_Read, "Int",  false, "UInt", pid)) {
		VarSetCapacity(iCoord, 16)
		SendMessage, %LVM_GETITEMCOUNT%, 0, 0
		loop, %ErrorLevel% {
			pItemCoord := DllCall("VirtualAllocEx", "Ptr", hProcess, "Ptr", 0, "UInt", 16, "UInt", MEM_COMMIT, "UInt", PAGE_ReadWRITE)
			SendMessage, %LVM_GETITEMRECT%, % A_Index-1, %pItemCoord%
			DllCall("ReadProcessMemory", "Ptr", hProcess, "Ptr", pItemCoord, "Ptr", &iCoord, "UInt", 16, "UInt", 0)
			DllCall("VirtualFreeEx", "Ptr", hProcess, "Ptr", pItemCoord, "UInt", 0, "UInt", MEM_RELEASE)
			left   := NumGet(iCoord,  0, "Int")
			top    := NumGet(iCoord,  4, "Int")
			Right  := NumGet(iCoord,  8, "Int")
			bottom := NumGet(iCoord, 12, "Int")
			if (left < x and x < Right and top < y and y < bottom) {
				ControlGet, list, List
				RegExMatch(StrSplit(list, "`n")[A_Index], "O)(.*)\t(.*)\t(.*)\t(.*)", Match)
				Icon := {left:left, top:top, Right:Right, bottom:bottom
					, name:Match[1], size:Match[2], type:Match[3]
				; Delete extraneous date characters (https://goo.gl/pMw6AM):
				; - Unicode LTR (Left-to-Right) mark (0x200E = 8206)
				; - Unicode RTL (Right-to-Left) mark (0x200F = 8207)
					, date:RegExReplace(Match[4], A_IsUnicode ? "[\x{200E}-\x{200F}]" : "\?")}
				break
			}
		}
		DllCall("CloseHandle", "Ptr", hProcess)
	}
	return Icon
}
