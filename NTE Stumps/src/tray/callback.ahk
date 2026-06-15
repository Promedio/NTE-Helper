; Copyright 2026 Paclora Corporation. Licensed under the Apache License, Version 2.0.

; 托盘回调。
; 包含托盘菜单选项的具体功能。


; ---- ---- ---- ----   ---- ---- ---- ----   ---- ---- ---- ----   ---- ---- ---- ----


#Requires AutoHotkey v2 ; 最低限制。


; ---- ---- ---- ----   ---- ---- ---- ----   ---- ---- ---- ----   ---- ---- ---- ----


; 用作模块或命名空间：cal（于上层定义）。
class Callback {
	; 通过用户默认浏览器打开指定链接。
	static 关于软件(Self := tra.cal) {
		dui.open_url(Self.关于软件_url)
	} ; func 关于软件

	; `关于软件`所要打开的链接，可能在运行中修改。
	; 默认指向项目托管页面的`README.MD`，有更新时通过其它函数将其修改为下载页面。
	; *备注：托管页面可能还是太慢了，有几率一直白屏打不开，所以指向下载页面是防止用户放弃更新。*
	static 关于软件_url := "https://bitbucket.org/paclora_epo/nte-helper/src/dom/README.MD"



	; 切换挂起状态并刷新托盘菜单子项的勾选状态及托盘图标。
	; 托盘图标应当能立即反映程序热键的挂起状态，并且托盘菜单子项的勾选状态也始终反映实际情况。
	static 全局功能启用状态(Base := tra) {
		Suspend(!A_IsSuspended)
		Base.refresh_tray_menu_status()
		Base.refresh_tray_icon()
	} ; func 全局功能启用状态



	; 修改特定值，然后向配置同步，启用或禁用相关热键，最后刷新托盘菜单子项的勾选状态。
	; 如果配置文件未能写入，用户的操作可能不生效，托盘菜单子项的勾选状态始终反映实际情况。
	static 交互重复启用状态(Base := tra) {
		cfg.data.交互重复.启用状态.data := !cfg.data.交互重复.启用状态.data
		cfg.synchronize()
		hks.set_hotkeys_enable_state([cfg.data.交互重复.映射按键.data], cfg.data.交互重复.启用状态.data)
		Base.refresh_tray_menu_status()
	} ; func 交互重复启用状态



	; 修改特定值，然后向配置同步，启用或禁用相关热键，最后刷新托盘菜单子项的勾选状态。
	; 如果配置文件未能写入，用户的操作可能不生效，托盘菜单子项的勾选状态始终反映实际情况。
	static 按键重复启用状态(Base := tra) {
		cfg.data.按键重复.启用状态.data := !cfg.data.按键重复.启用状态.data
		cfg.synchronize()
		for key_list in cfg.data.按键重复.按键列表.data {
			hks.set_hotkeys_enable_state(key_list, cfg.data.按键重复.启用状态.data)
		}
		Base.refresh_tray_menu_status()
	} ; func 按键重复启用状态



	; 立即重启程序，不执行任何提权。
	static 重启软件() {
		env.restart_self()
	} ; func 重启软件



	; 立即退出程序，不执行任何后续。
	static 退出软件() {
		ExitApp()
	} ; func 退出软件
} ; class Callback

