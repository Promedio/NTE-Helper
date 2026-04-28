; Copyright 2026 Paclora Corporation. Licensed under the Apache License, Version 2.0.

; 环境保障。
; 包含一些环境感知和保障功能。


; ---- ---- ---- ----   ---- ---- ---- ----   ---- ---- ---- ----   ---- ---- ---- ----


#Requires AutoHotkey v2.0.0+ ; 最低限制。


; ---- ---- ---- ----   ---- ---- ---- ----   ---- ---- ---- ----   ---- ---- ---- ----


class env {
	; 确保自身能在要求的环境下运行。
	; 当前要求有：管理员权限。
	static ensurance(Self := env) {
		Self.verify_uac()
	} ; func ensurance



	; 确保自身的管理员权限。
	; 若自身未持有管理员权限，将尝试以管理员权限重新启动；若启动失败，将弹出错误提示。
	static  verify_uac(Self := env) {
		if A_IsAdmin == true {
			return
		}

		for arg in A_Args {
			if (InStr("/restart", arg) != 0) {
				user_choice := MsgBox("未能以管理员权限运行，要再次尝试吗？", A_ThisFunc, "OC Icon!")
				if (user_choice == "Cancel")
					ExitApp()
				break
			}
		}

		Self.restart_self_with_uac()
	} ; func verify_uac



	; 尝试以管理员权限重新启动自身。
	; 启动失败时将尝试普通启动。
	; 有关提权启动，详见：https://wyagd001.github.io/v2/docs/lib/RunAs.htm 。
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
	static restart_self() {
		try {
			Run '"' A_ScriptFullPath '" /restart'
		} catch {
			MsgBox("未能重新启动。", A_ThisFunc, "OK IconX")
		} finally {
			ExitApp()
		}
	} ; func restart_self
} ; class env

