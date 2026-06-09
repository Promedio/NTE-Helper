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

#MaxThreads 9       ; 此值被设定为同时可容许热键（4）的二倍，并额外扩充了其它阻塞任务的数目（1）。
SendMode("Input")   ; 设置发送模式为 Input。
A_MenuMaskKey := "" ; 防止遮盖控制键。


; ---- ---- ---- ----   ---- ---- ---- ----   ---- ---- ---- ----   ---- ---- ---- ----


;@Ahk2Exe-IgnoreBegin
GLOBAL MAIN := TRUE           ; 引入控制。用于抑制分布页的自动执行。
GLOBAL TEST := TRUE           ; 测试控制。用于决定主页的执行分支。
;@Ahk2Exe-IgnoreEnd

#Include .\common.ahk         ; 通用功能。简化命名：com。因受到引用而必须在前引入，有：cfg、cfg.pas、upc。
#Include .\user_interface.ahk ; 用户交互。简化命名：dui。因受到引用而必须在前引入，有：env、cfg、cfg.pas、tra.cal。
#Include .\update.ahk         ; 更新检查。简化命名：upc。因受到引用而必须在前引入，有：tra。
#Include .\config.ahk         ; 配置管理。简化命名：cfg。因受到引用而必须在前引入，有：tra、tra.cal。
#Include .\environment.ahk    ; 环境保障。简化命名：env。因受到引用而必须在前引入，有：tra.cal。
#Include .\tray.ahk           ; 托盘菜单。简化命名：tra。


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
	env.ensurance()
} ; func entry



;@Ahk2Exe-IgnoreBegin
; 集成测试入口。
tests() {
;	cfg.tests.all()
;	upc.tests.all()
	tra.tests.all() ; 不含自动测试。
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

