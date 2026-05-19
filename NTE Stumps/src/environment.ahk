; Copyright 2026 Paclora Corporation. Licensed under the Apache License, Version 2.0.

; 环境保障。
; 包含一些环境感知和保障功能。


; ---- ---- ---- ----   ---- ---- ---- ----   ---- ---- ---- ----   ---- ---- ---- ----


#Requires AutoHotkey v2 ; 最低限制。


; ---- ---- ---- ----   ---- ---- ---- ----   ---- ---- ---- ----   ---- ---- ---- ----


; environment.ahk\Environment
env := Environment


; ---- ---- ---- ----   ---- ---- ---- ----   ---- ---- ---- ----   ---- ---- ---- ----


; 用作模块或命名空间：env。
class Environment {
	; 确保自身能在要求的环境下运行。
	; 当前要求：管理员权限。
	; **注意：此函数可能会退出程序。**
	static ensurance(Self := env) {
		Self.verify_uac()
	} ; func ensurance



	; 确保自身的管理员权限。
	; 若自身未持有管理员权限，将尝试以管理员权限重新启动；若启动失败，将弹出错误提示。
	; **注意：此函数可能会退出程序。**
	; 实现参考：https://bitbucket.org/paclora_epo/calabiyau-helper/src/ce2c332a53d48cab1b87e6b3870195942ca9980a/Auto%20Append%20Meow/Auto%20Append%20Meow%20for%20CalabiYau%20-%201.6.1.ahk#lines-56 。
	static  verify_uac(Self := env) {
		if A_IsAdmin == true {
			return
		}

		for arg in A_Args {
			if (InStr("/restart", arg) != 0) {
				dui.warning_dialog("未能以管理员权限运行，要再次尝试吗？", A_ThisFunc)
				break
			}
		}

		Self.restart_self_with_uac()
	} ; func verify_uac



	; 尝试以管理员权限重新启动自身。
	; 启动失败时将尝试普通启动。
	; **注意：此函数可能会退出程序。**
	; 有关提权启动，详见：https://wyagd001.github.io/v2/docs/lib/RunAs.htm 。
	; 实现参考：https://bitbucket.org/paclora_epo/calabiyau-helper/src/ce2c332a53d48cab1b87e6b3870195942ca9980a/Auto%20Append%20Meow/Auto%20Append%20Meow%20for%20CalabiYau%20-%201.6.1.ahk#lines-83 。
	static restart_self_with_uac(Self := env) {
		try {
			Run '*RunAs "' A_ScriptFullPath '" /restart'
		} catch {
			Self.restart_self()
		} finally {
			ExitApp()
		}
	} ; func restart_self_with_uac



	; 重新启动自身。
	; 启动失败时将弹出错误提示。
	; **注意：此函数可能会退出程序。**
	; 实现参考：https://bitbucket.org/paclora_epo/calabiyau-helper/src/ce2c332a53d48cab1b87e6b3870195942ca9980a/Auto%20Append%20Meow/Auto%20Append%20Meow%20for%20CalabiYau%20-%201.6.1.ahk#lines-76 。
	static restart_self() {
		try {
			Run '"' A_ScriptFullPath '" /restart'
		} catch {
			dui.error_dialog("未能重新启动。", A_ThisFunc)
		} finally {
			ExitApp()
		}
	} ; func restart_self
} ; class Environment

