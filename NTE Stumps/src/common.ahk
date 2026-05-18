; Copyright 2026 Paclora Corporation. Licensed under the Apache License, Version 2.0.

; 通用功能。
; 包含项目的通用功能。


; ---- ---- ---- ----   ---- ---- ---- ----   ---- ---- ---- ----   ---- ---- ---- ----


#Requires AutoHotkey v2 ; 最低限制。


; ---- ---- ---- ----   ---- ---- ---- ----   ---- ---- ---- ----   ---- ---- ---- ----


; config.ahk\Config。
global com := Common


; ---- ---- ---- ----   ---- ---- ---- ----   ---- ---- ---- ----   ---- ---- ---- ----


; 用作模块或命名空间：com。
class Common {
	; 断言`result_a`一定等于`result_b`，否则退出程序。
	; 不论结果如何，函数都会向调试器打印执行结果。
	; **注意：此函数可能会退出程序。**
	; - `result_a`：要对比的值之一；
	; - `result_b`：要对比的另一个值；
	; - `func_name`：当前函数名，留空时默认为`A_ThisFunc`。
	static assert(result_a, result_b, func_name := A_ThisFunc) {
		if result_a == result_b {
			OutputDebug("succeed. (" func_name ")`n")
		} else {
			OutputDebug("failed. (" func_name ")`n")
			ExitApp()
		}
	} ; func assert
} ; class Common

