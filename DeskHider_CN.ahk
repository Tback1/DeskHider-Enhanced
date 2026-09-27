; ============================================================================
;  DeskHider_CN - 双击桌面空白处，切换桌面图标的显示 / 隐藏
;  轻量化：无界面、无弹窗；所有设置都保存在 DeskHider_CN.ini
;
;  配置文件：与本脚本（或 exe）同目录的 DeskHider_CN.ini
;           首次运行时自动生成；可用任意文本编辑器修改
;  托盘菜单：Open Config File / Reload Config / Exit
;  托盘点 Reload Config 可让 ini 修改立即生效，无需重启程序
;
;  自动隐藏：图标处于显示状态、且屏幕上没有任何可见窗口、也没有任何键鼠
;           操作，持续一段时间后自动隐藏图标（AutoHideSeconds，0 = 禁用）
; ============================================================================

#SingleInstance, Force
#Persistent
#InstallMouseHook                 ; 安装鼠标/键盘钩子，保证 A_TimeIdlePhysical
#InstallKeybdHook                 ; 能准确反映真实的键鼠输入（自动隐藏用）

; ----------------------------------------------------------------------------
; 配置变量（默认值；实际以 DeskHider_CN.ini 为准）
; ----------------------------------------------------------------------------
IniFile           := A_ScriptDir "\DeskHider_CN.ini"
Clicks            := 2      ; 鼠标连击次数：2 = 双击，3 = 三击
ClickWindow       := 350    ; 鼠标连击最大间隔（毫秒）
DesktopHotkey     := ""     ; 桌面快捷键；留空 = 禁用
PrevDesktopHotkey := ""     ; 上一次注册的快捷键（Reload 时先注销再注册）
HotkeyClicks      := 2      ; 快捷键连按次数：2 = 双按，3 = 三按
HotkeyClickWindow := 350    ; 快捷键连按最大间隔（毫秒）；留空 = 与鼠标相同
AutoHideSeconds   := 0      ; 无窗口且无键鼠操作持续 N 秒后自动隐藏图标；0 = 禁用
AutoHideLastToggle := 0     ; 上一次手动切换图标的 TickCount（手动切换会重置自动隐藏倒计时）

; ----------------------------------------------------------------------------
; 启动：读取配置 + 注册桌面快捷键
; ----------------------------------------------------------------------------
LoadConfig()
RegisterDesktopHotkey()
SetTimer, AutoHideCheck, 1000     ; 每秒���次的自动隐藏检查（禁用时自动空转）

; ----------------------------------------------------------------------------
; 托盘菜单
; ----------------------------------------------------------------------------
Menu, Tray, NoStandard
Menu, Tray, Add, Open Config File, OpenConfigFile
Menu, Tray, Add, Reload Config, ReloadConfig
Menu, Tray, Add
Menu, Tray, Add, Exit, QuitScript
Menu, Tray, Tip, DeskHider

; ============================================================================
; 鼠标连击（仅在鼠标位于桌面上时生效）
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

; 满足条件时切换图标显隐。修复：添加 IsDesktopFocused() 检查，防止鼠标钩子
; 与 Windows 原生事件冲突导致黑屏。任何手动切换都会重置自动隐藏的倒计时。
MaybeToggleDesktopIcons()
{
	global DesktopIconsIsShow, AutoHideLastToggle
	
	; 仅在焦点在桌面或没有可见窗口时才处理，防止事件冲突
	if (!IsDesktopFocused())
		return
	
	if (!IsObject(GetDesktopIconUnderMouse()) or DesktopIconsIsShow = 0)
	{
		DesktopIconsIsShow := HideOrShowDesktopIcons()
		AutoHideLastToggle := A_TickCount
	}
}

; ============================================================================
; 配置的读取 / 重载
; ============================================================================
LoadConfig()
{
	global IniFile, Clicks, ClickWindow, DesktopHotkey
	global HotkeyClicks, HotkeyClickWindow, AutoHideSeconds

	; 配置文件不存在时，先生成默认配置
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
	if (DesktopHotkey = "ERROR")          ; 键不存在 -> 使用默认快捷键
		DesktopHotkey := "Space"
	else if (DesktopHotkey = "")          ; 显式留空 -> 禁用
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
		HotkeyClickWindow := ClickWindow ; 留空 = 与鼠标连击间隔相同
	else
	{
		if HotkeyClickWindow is not integer
			HotkeyClickWindow := ClickWindow
		if (HotkeyClickWindow < 150)
			HotkeyClickWindow := 150
		if (HotkeyClickWindow > 1000)
			HotkeyClickWindow := 1000
	}

	; 自动隐藏的触发秒数；非法值或负数 = 禁用
	IniRead, AutoHideSeconds, %IniFile%, Settings, AutoHideSeconds, 0
	if AutoHideSeconds is not integer
		AutoHideSeconds := 0
	if (AutoHideSeconds < 0)
		AutoHideSeconds := 0
}

; 生成默认配置文件模板
CreateDefaultIni()
{
	global IniFile
	Template =
	(
; DeskHider_CN 配置文件
; 修改保存后，在托盘菜单点"Reload Config"即可生效（无需重启程序）
; 每项格式：名称=值，行首分号 ; 表示注释

[Settings]
; 鼠标连击次数：2 = 双击切换，3 = 三击切换（最多支持一种连击）
Clicks=2

; 鼠标连击间隔（毫秒）：两次点击之间的最大时间间隔
; 双击建议 300-500，三击建议 400-600
ClickWindow=350

; 桌面快捷键：满足下面任一条件才触发，留空 = 禁用
;   1) 没有可见的顶层窗口（窗口全部关闭 / 全部最小化）
;   2) 焦点在桌面（例如有窗口时单击过一次桌面）
; 支持两种写法，空格键可写 Space 或 空格：
;   友好写法：Ctrl+Space、Ctrl+Alt+H、Shift+F1、空格
;   AHK 写法：^Space、^!h、+F1
; 示例：Ctrl+Space = 按住 Ctrl 再按空格
; 提示：热键是"连按触发"，不吞按键、不影响输入
Hotkey=Space

; 桌面快捷键连击次数（2 = 双击，3 = 三击），默认 2，和鼠标一样
HotkeyClicks=2

; 桌面快捷键连击间隔（毫秒），留空 = 与鼠标 ClickWindow 相同
HotkeyClickWindow= 350

; 自动隐藏图标：当图标处于显示状态，且屏幕上没有任何普通窗口
; （全部关闭 / 全部最小化）持续达到该秒数后，自动隐藏图标
; 任何鼠标、键盘操作（包括其他软件模拟的点击）都会让倒计时重新开始；
; 手动切换图标后倒计时同样重新开始
; 0 = 禁用该功能；重新显示图标用平时的方式即可（双击桌面 / 快捷键）
AutoHideSeconds=0
	)
	FileAppend, %Template%, %IniFile%
}

; （重新）注册桌面快捷键，托盘点"Reload Config"后立即生效
; 使用 ~ 透传 + Up（松开）事件：不吞按键、不影响打字，按住不放不会重复计数
RegisterDesktopHotkey()
{
	global DesktopHotkey, PrevDesktopHotkey
	; 先注销旧的，再注册新的（非法值会被静默忽略，不弹窗）
	if (PrevDesktopHotkey <> "")
		try Hotkey, ~%PrevDesktopHotkey% Up, ToggleDesktopHotkey, Off
	if (DesktopHotkey <> "")
		try Hotkey, ~%DesktopHotkey% Up, ToggleDesktopHotkey, On
	PrevDesktopHotkey := DesktopHotkey
}

; 判断"桌面处于可触发状态"（满足任一条件即返回 1，否则返回 0）：
;   1) 焦点在桌面（活动窗口就是桌面，例如点过一次桌面）
;   2) 没有可见的顶层窗口（窗口全部关闭 / 全部最小化）
IsDesktopFocused()
{
	; 条件 1：焦点在桌面
	WinGetClass, winClass, A
	if (winClass = "WorkerW" or winClass = "Progman")
		return 1

	; 条件 2：没有可见的顶层窗口
	return IsDesktopClear()
}

; 屏幕上没有任何"可见的普通窗���"时返回 1（全部关闭 / 全部最小化）。
; 最小化、隐藏、工具窗口、被 DWM 遮蔽的窗口，以及桌面和任务栏窗口本身，
; 都不算"可见的普通窗口"。
IsDesktopClear()
{
	WinGet, winList, List
	loop, %winList%
	{
		hwnd := winList%A_Index%
		WinGet, style, Style, ahk_id %hwnd%
		if (style & 0x20000000)        ; 最小化的窗口不算
			continue
		if (!(style & 0x10000000))     ; 不可见的窗口不算
			continue
		WinGet, exStyle, ExStyle, ahk_id %hwnd%
		if (exStyle & 0x80)            ; 工具窗口（托盘/通知类）不算
			continue
		if IsWindowCloaked(hwnd)       ; 被 DWM 遮蔽的窗口（挂起的 UWP 等）不算
			continue
		WinGetClass, cls, ahk_id %hwnd%
		if (cls = "WorkerW" or cls = "Progman" or cls = "Shell_TrayWnd" or cls = "Shell_SecondaryTrayWnd")
			continue                   ; 桌面 / 任务栏窗口不算
		return 0                       ; 找到一个可见的普通窗口
	}
	return 1                           ; 没有可见的普通窗口
}

; DWMWA_CLOAKED（14）：窗口被 DWM"遮蔽"时返回非 0（典型：挂起的 UWP 应用、
; 其他虚拟桌面上的窗口——样式上"可见"但屏幕上并没有显示）。
; 不支持 DWM 的系统上调用会失败并返回 0，因此任何系统下都安全。
IsWindowCloaked(hwnd)
{
	cloaked := 0
	DllCall("dwmapi\DwmGetWindowAttribute", "Ptr", hwnd, "UInt", 14, "UIntP", cloaked, "UInt", 4)
	return cloaked ? 1 : 0
}

; 把快捷键写法统一转换成 AHK 原生语法，两种写法都支持：
;   AHK 原生：^!h、^Space、#F5、+F1
;   友好写法：Ctrl+Alt+H、Ctrl+Space、Shift+F1、Space
NormalizeHotkey(raw)
{
	if (raw = "")
		return ""
	raw := Trim(raw)
	if (raw = "")
		return ""
	; 去掉用户可能多写的 ~ 前缀（透传由程序自己处理）
	raw := RegExReplace(raw, "^~+", "")
	if (raw = "")
		return ""
	; 只有修饰键（例如 "^" 或 "Ctrl+"）时，默认按到空格键上
	if (RegExMatch(raw, "^[\^!+#]+$"))
		return raw . "Space"
	; 含 ^ ! #，或以 + 开头 = AHK 原生写法，原样使用
	if (InStr(raw, "^") or InStr(raw, "!") or InStr(raw, "#") or SubStr(raw, 1, 1) = "+")
		return raw

	; 友好写法：按 "+" 拆分成修饰键 + 按键
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
			return raw ; 多个按键：原样返回（AHK 会静默忽略）
	}
	if (key = "")
		return raw ; 只有修饰键：原样返回（非法，会被忽略）
	return prefix . key
}

; 友好按键名 -> AHK 按键名（例如 Space -> Space、Delete -> Delete）
FriendlyKeyName(name)
{
	; 空格键的中文别名（保留方便中文用户）
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
	; 单个字母 -> 转大写（例如 a -> A）
	if (StrLen(name) = 1 and RegExMatch(name, "i)^[a-z]$"))
	{
		StringUpper, up, name
		return up
	}
	return name
}

; ============================================================================
; 托盘菜单处理
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

; 桌面快捷键：桌面处于可触发状态时才计数，连按 HotkeyClicks 次（默认 2 次）
; 触发。只在松开（Up）时计数，按住不放不会触发；~ 透传不影响打字
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
		AutoHideLastToggle := A_TickCount    ; 手动切换后重置自动隐藏倒计时
	}
return

KeyDesktopHotkey:
	DesktopHotkey_presses := 0
return

QuitScript:
	ExitApp
return

; ============================================================================
; 自动隐藏计时器
; ============================================================================
; 每秒运行一次。功能开启时（AutoHideSeconds > 0），"干净桌面"（没有可见的
; 普通窗口）且没有任何输入持续达到 AutoHideSeconds 秒后，自动隐藏一次图标。
; 用两个"闲置时钟"同时判断，任一未超时都不隐藏：
;   A_TimeIdlePhysical - 距上一次"物理"键鼠输入（只认真实键鼠）
;   A_TimeIdle         - 距上一次任何输入（包括其他软件模拟的点击/按键，
;                        只查物理时钟会漏掉这类输入）
; 因此任何鼠标移动、点击、按键——真实的或软件模拟的——都会让倒计时重新
; 开始；手动切换图标（鼠标或快捷键）也会显式重置倒计时（AutoHideLastToggle）。
; 只隐藏、从不自动恢复。
AutoHideCheck:
	if (AutoHideSeconds < 1)                    ; 功能禁用 -> 空转
		return
	if (!AreDesktopIconsVisible() or !IsDesktopClear())
		return
	if (A_TickCount - AutoHideLastToggle < AutoHideSeconds * 1000)
		return                                  ; 刚手动切换过 -> 宽限期内不隐藏
	if (A_TimeIdle >= AutoHideSeconds * 1000 and A_TimeIdlePhysical >= AutoHideSeconds * 1000)
		DesktopIconsIsShow := HideOrShowDesktopIcons()   ; 与点击/快捷键的状态保持同步
return

; ============================================================================
; 原有核心函数（未改动）
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

; 桌面图标列表（SysListView32）当前是否可见：可见返回 1，隐藏（或找不到
; 控件）返回 0。直接查询真实窗口状态，而不是依赖 DesktopIconsIsShow 标记，
; 因此脚本刚启动时结果也是准确的。
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
				; 去掉日期里多余的字符（https://goo.gl/pMw6AM）：
				; - Unicode LTR（从左到右）标记 (0x200E = 8206)
				; - Unicode RTL（从右到左）标记 (0x200F = 8207)
					, date:RegExReplace(Match[4], A_IsUnicode ? "[\x{200E}-\x{200F}]" : "\?")}
				break
			}
		}
		DllCall("CloseHandle", "Ptr", hProcess)
	}
	return Icon
}
