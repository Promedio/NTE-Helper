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

#Include .\user_interface.ahk ; 用户交互。简化命名：dui。因受到引用而必须在前引入，有：env、cfg。
#Include .\environment.ahk    ; 环境保障。简化命名：env。
#Include .\config.ahk         ; 配置管理。简化命名：cfg。
#Include .\update.ahk         ; 更新检查。简化命名：upc。


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

; 测试执行部分。
; TEST 为 TRUE 时执行。
;@Ahk2Exe-IgnoreBegin
if TEST == TRUE {
	; 此处是测试调用。
	standard_key_name()
	duplicate_keys()
}
;@Ahk2Exe-IgnoreEnd


; ---- ---- ---- ----   ---- ---- ---- ----   ---- ---- ---- ----   ---- ---- ---- ----


; 程序入口。
entry() {
	; 
	env.ensurance()
} ; func entry



;@Ahk2Exe-IgnoreBegin
; 测试是否能如期获得标准按键名。
standard_key_name() {
	assert(cfg.get_standard_key_name("lctrl"), "LControl")
} ; func standard_key_name



; 测试是否能如期检测到重复的按键变体。
duplicate_keys() {
	assert(cfg.check_key_duplicate("Space"), false)
	Hotkey("Space", (*) => {}, "Off")
	assert(cfg.check_key_duplicate("Space"), true)
} ; func duplicate_keys



; 断言`result_a`一定等于`result_b`，否则退出程序。
; 不论结果如何，函数都会向调试器打印执行结果。
; **注意：此函数可能会退出程序。**
; - `result_a`：要对比的值之一；
; - `result_b`：要对比的另一个值；
; - `func_name`：当前函数名，留空时默认为`A_ThisFunc`。
assert(result_a, result_b, func_name := A_ThisFunc) {
	if result_a == result_b {
		OutputDebug("succeed. (" func_name ")`n")
	} else {
		OutputDebug("failed. (" func_name ")`n")
		ExitApp()
	}
} ; func assert
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

;@Ahk2Exe-SetMainIcon  .\icon\i1.ico      ; Default icon.
;;@Ahk2Exe-AddResource .\icon\ix.ico, 160 ; The .ahk file icon.
;@Ahk2Exe-AddResource  .\icon\i2.ico, 206 ; "Suspend Hotkeys" status.
;;@Ahk2Exe-AddResource .\icon\ix.ico, 207 ; "Pause Script" status.
;;@Ahk2Exe-AddResource .\icon\ix.ico, 208 ; "Suspend Hotkeys" and "Pause Script".

