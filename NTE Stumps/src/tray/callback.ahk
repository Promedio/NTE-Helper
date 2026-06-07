; Copyright 2026 Paclora Corporation. Licensed under the Apache License, Version 2.0.

; 托盘回调。
; 包含托盘菜单选项的具体功能。


; ---- ---- ---- ----   ---- ---- ---- ----   ---- ---- ---- ----   ---- ---- ---- ----


#Requires AutoHotkey v2 ; 最低限制。


; ---- ---- ---- ----   ---- ---- ---- ----   ---- ---- ---- ----   ---- ---- ---- ----


; 用作模块或命名空间：cal（于上层定义）。
class Callback {
	; 
	static 关于软件() {
		dui.open_url("https://bitbucket.org/paclora_epo/nte-helper/src/dom/README.MD")
	} ; func 关于软件



	; 
	static 全局功能启用状态(base := tra) {
		Suspend(!A_IsSuspended)
		base.refresh_tray_menu_status()
		base.refresh_tray_icon()
	} ; func 全局功能启用状态



	; 
	static 交互重复启用状态(base := tra) {
		cfg.data.交互重复.启用状态.data := !cfg.data.交互重复.启用状态.data
		cfg.synchronize()
		base.refresh_tray_menu_status()
	} ; func 交互重复启用状态



	; 
	static 按键重复启用状态(base := tra) {
		cfg.data.按键重复.启用状态.data := !cfg.data.按键重复.启用状态.data
		cfg.synchronize()
		base.refresh_tray_menu_status()
	} ; func 按键重复启用状态



	; 
	static 重启软件() {
		env.restart_self()
	} ; func 重启软件



	; 
	static 退出软件() {
		ExitApp()
	} ; func 退出软件
} ; class Callback

