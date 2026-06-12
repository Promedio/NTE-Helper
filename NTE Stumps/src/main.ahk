; Copyright 2026 Paclora Corporation. Licensed under the Apache License, Version 2.0.

; 程序入口。
; 包含程序的主要逻辑和编译参数。


; ---- ---- ---- ----   ---- ---- ---- ----   ---- ---- ---- ----   ---- ---- ---- ----


#Requires AutoHotkey v2.0.25+ ; 限制解释器版本。（实际上不需要这么高的要求，但以防万一。）
#SingleInstance Force         ; 强制覆盖单例。重复启动相当于重新加载。

ProcessSetPriority("AboveNormal") ; 设优先级为“高于正常”。
ListLines(0)                      ; 关闭执行历史。
KeyHistory(!A_IsCompiled)         ; 编译状态下关闭按键历史。
Thread("Interrupt", 0)            ; 允许线程立即中断。

#MaxThreads 24      ; 限制最大模拟线程，理论上是为了通过触发阻塞来发现问题。
SendMode("Input")   ; 设置发送模式为 Input。
A_MenuMaskKey := "" ; 防止遮盖控制键。


; ---- ---- ---- ----   ---- ---- ---- ----   ---- ---- ---- ----   ---- ---- ---- ----


;@Ahk2Exe-IgnoreBegin
GLOBAL MAIN := TRUE           ; 引入控制。用于抑制分布页的自动执行。
GLOBAL TEST := FALSE          ; 测试控制。用于决定主页的执行分支。
;@Ahk2Exe-IgnoreEnd

#Include .\common.ahk         ; 通用功能。简化命名：com。因受到引用而必须在前引入，有：cfg、cfg.pas、upc。
#Include .\user_interface.ahk ; 用户交互。简化命名：dui。因受到引用而必须在前引入，有：env、cfg、cfg.pas、tra.cal、hks。
#Include .\environment.ahk    ; 环境保障。简化命名：env。因受到引用而必须在前引入，有：tra.cal。
#Include .\config.ahk         ; 配置管理。简化命名：cfg。因受到引用而必须在前引入，有：tra、tra.cal、hks。
#Include .\update.ahk         ; 更新检查。简化命名：upc。因受到引用而必须在前引入，有：tra。
#Include .\hotkeys.ahk        ; 宏组热键。简化命名：hks。因受到引用而必须在前引入，有：tra.cal。
#Include .\tray.ahk           ; 托盘菜单。简化命名：tra。


GLOBAL ACTIVE_TITLE_LIST := [ ; 预期的 WinTitle 列表。
;	"异环"               ,    ; 稳固标题，无法在游戏内的悬浮窗口上使用（如登录提示）。
	"ahk_exe HTGame.exe" ,    ; 固定程序，可能误判，能直接支持多个区服和客户端。
	"ahk_class Notepad++",    ; 仅限调试。
;	"ahk_exe Code.exe"   ,    ; 仅限调试。
]

; ---- ---- ---- ----   ---- ---- ---- ----   ---- ---- ---- ----   ---- ---- ---- ----


; 自动执行部分。
; TEST 未定义或为 FALSE 时进入程序入口。
try {
	TEST := TEST
	if TEST == FALSE {
		entry()
	}
}
catch {
	entry()
}

;@Ahk2Exe-IgnoreBegin
; 集成测试部分。
; TEST 为 TRUE 时执行。
if TEST == TRUE {
	tests()
}
;@Ahk2Exe-IgnoreEnd


; ---- ---- ---- ----   ---- ---- ---- ----   ---- ---- ---- ----   ---- ---- ---- ----


; 程序逻辑入口。
entry() {
	; 确保执行环境。
	env.ensurance()

	; 初始化配置。
	cfg.initialize()

	; 构造托盘。
	tra.construct()

	; 异步检查更新情况，有更新时通知托盘。
;	SetTimer((*) => check_update(300), -1)

	; 创建热键。
	hks.create()

	; 以下为内部函数定义——

	; 检查到新版本时更新托盘呈现。
	; **注意：这是一个耗时函数。**
	; - `timeout`：请求全程的最大等待时间（单位为秒）。
	check_update(timeout) {
		up_res := upc.has_update(timeout)
		if up_res != false {
			tra.the_program_has_update(up_res)
		}
	} ; func check_update
} ; func entry



;@Ahk2Exe-IgnoreBegin
; 集成测试入口。
tests() {
;	cfg.tests.all()
;	upc.tests.all()
;	tra.tests.all() ; 不含自动测试。
;	ExitApp()
} ; func tests
;@Ahk2Exe-IgnoreEnd


; ---- ---- ---- ----   ---- ---- ---- ----   ---- ---- ---- ----   ---- ---- ---- ----


;@Ahk2Exe-UpdateManifest 1 ; UAC.

;@Ahk2Exe-SetDescription    NTE Stumps
;@Ahk2Exe-SetFileVersion    1.0.0
;@Ahk2Exe-SetProductName    NTE Stumps
;@Ahk2Exe-SetProductVersion 1.0.0
;@Ahk2Exe-SetCompanyName    Paclora Corporation
;@Ahk2Exe-SetCopyright      Apache-2.0 © 2026 Paclora Corporation.
;@Ahk2Exe-SetLanguage       0x0804 ; Chinese_PRC.
;@Ahk2Exe-SetOrigFilename   NTE Stumps.exe

 ;@Ahk2Exe-SetMainIcon ..\ico\i1.ico      ; Default icon.
;;@Ahk2Exe-AddResource ..\ico\ix.ico, 160 ; The .ahk file icon.
 ;@Ahk2Exe-AddResource ..\ico\i2.ico, 206 ; "Suspend Hotkeys" status.
;;@Ahk2Exe-AddResource ..\ico\ix.ico, 207 ; "Pause Script" status.
;;@Ahk2Exe-AddResource ..\ico\ix.ico, 208 ; "Suspend Hotkeys" and "Pause Script".

