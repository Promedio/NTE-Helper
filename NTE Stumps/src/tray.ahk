; Copyright 2026 Paclora Corporation. Licensed under the Apache License, Version 2.0.

; 托盘菜单。
; 包含托盘菜单的所有功能。


; ---- ---- ---- ----   ---- ---- ---- ----   ---- ---- ---- ----   ---- ---- ---- ----


#Requires AutoHotkey v2 ; 最低限制。


; ---- ---- ---- ----   ---- ---- ---- ----   ---- ---- ---- ----   ---- ---- ---- ----


#Include .\tray\callback.ahk ; 类型解析。简化命名：cal。

; tray.ahk\Tray
global tra := Tray


; ---- ---- ---- ----   ---- ---- ---- ----   ---- ---- ---- ----   ---- ---- ---- ----


; 用作模块或命名空间：tra。
class Tray {
	; tray\callback.ahk\Callback。
	static cal := Callback



	; 托盘菜单的子项，仅供父类使用。
	class item {
		; 触发类项，将打开一个页面来展示信息。
		; 此项必须置顶（顺序必须为1），有更新时文本可能变化，故`name`变量应在变动时及时更新。
		class 关于软件 {
			; 子项的预期位置。
			static id   := "1&"
			; 子项的名称文本。可能变化，需要及时更新。
			static name := "关于 NTE Stumps"
		} ; class 关于软件
		; 切换类项，将挂起所有热键。
		; 此项应独立成组，且应当在其它切换控制项之上。
		class 全局功能启用状态 {
			; 子项的预期位置。
			static id   := "3&"
			; 子项的名称文本。
			static name := "启用整体功能"
		} ; class 全局功能启用状态
		; 切换类项，将切换相关热键的启用状态。
		class 交互重复启用状态 {
			; 子项的预期位置。
			static id   := "5&"
			; 子项的名称文本。
			static name := "启用交互按键重复功能"
		} ; class 交互重复启用状态
		; 切换类项，将指示相关宏的内部逻辑。
		class 交互滚轮启用状态 {
			; 子项的预期位置。
			static id   := "6&"
			; 子项的名称文本。
			static name := "重复时附带滚轮"
		} ; class 交互滚轮启用状态
		; 切换类项，将切换相关热键的启用状态。
		class 按键重复启用状态 {
			; 子项的预期位置。
			static id   := "8&"
			; 子项的名称文本。
			static name := "启用其它按键重复功能"
		} ; class 按键重复启用状态
		; 触发类项，将重启软件。
		; 此项不得位于最末，除非没有更需要靠后的项。
		class 重启软件 {
			; 子项的预期位置。
			static id   := "10&"
			; 子项的名称文本。
			static name := "重新启动软件"
		} ; class 重启软件
		; 触发类项，将退出软件。
		; 此项必须位于最末。
		class 退出软件 {
			; 子项的预期位置。
			static id   := "11&"
			; 子项的名称文本。
			static name := "退出软件"
		} ; class 退出软件
	} ; class item



	; 构造托盘的图标、提示、默认点击功能、菜单。
	static construct(Self := tra, menu := A_TrayMenu) {
		Self.refresh_tray_icon()
		Self.construct_tray_menu(Self, menu)
		Self.construct_tray_icon_tip()
	} ; func construct



	; 构造托盘菜单。
	; 托盘图标的默认击键被设为单次，功能被设置为切换热键的挂起状态。
	static construct_tray_menu(Self := tra, menu := A_TrayMenu) {
		menu.Delete()

		menu.Add(Self.item.关于软件.name        , (*) => Self.cal.关于软件()        ) ;  1&
		menu.Add()                                                                    ;  2&
		menu.Add(Self.item.全局功能启用状态.name, (*) => Self.cal.全局功能启用状态()) ;  3&
		menu.Add()                                                                    ;  4&
		menu.Add(Self.item.交互重复启用状态.name, (*) => Self.cal.交互重复启用状态()) ;  5&
		menu.Add(Self.item.交互滚轮启用状态.name, (*) => Self.cal.交互滚轮启用状态()) ;  6&
		menu.Add()                                                                    ;  7&
		menu.Add(Self.item.按键重复启用状态.name, (*) => Self.cal.按键重复启用状态()) ;  8&
		menu.Add()                                                                    ;  9&
		menu.Add(Self.item.重启软件.name        , (*) => Self.cal.重启软件()        ) ; 10&
		menu.Add(Self.item.退出软件.name        , (*) => Self.cal.退出软件()        ) ; 11&

		menu.ClickCount := 1
		menu.Default := Self.item.全局功能启用状态.name

		Self.refresh_tray_menu_status(Self, menu)
	} ; func construct_tray_menu



	; 刷新托盘菜单子项的勾选状态。
	; 该函数的刷新结果始终反映实际情况。
	static refresh_tray_menu_status(Self := tra, menu := A_TrayMenu) {
		if A_IsSuspended == false {
			menu.Check(  Self.item.全局功能启用状态.id)
		} else {
			menu.Uncheck(Self.item.全局功能启用状态.id)
		}
		if cfg.data.交互重复.启用状态.data == true {
			menu.Check(  Self.item.交互重复启用状态.name)
		} else {
			menu.Uncheck(Self.item.交互重复启用状态.name)
		}
		if cfg.data.交互重复.附加滚轮.data == true {
			menu.Check(  Self.item.交互滚轮启用状态.name)
		} else {
			menu.Uncheck(Self.item.交互滚轮启用状态.name)
		}
		if cfg.data.按键重复.启用状态.data == true {
			menu.Check(  Self.item.按键重复启用状态.name)
		} else {
			menu.Uncheck(Self.item.按键重复启用状态.name)
		}
	} ; func refresh_tray_menu_status



	; 根据自身版本号构建托盘提示。
	; 自身不具有版本号时（比如处于脚本执行状态）将显示`(开发中的版本)`。
	static construct_tray_icon_tip() {
		local_ver_res := upc.get_local_version()
		A_IconTip := "NTE Stumps" . (local_ver_res != "" ? (" v" local_ver_res) : (" (开发中的版本)"))
	} ; func construct_tray_icon_tip



	; 向托盘通知程序有更新，使其产生一些改变。
	; 目前，该函数会修改——
	; - 托盘菜单第一个子项所指向的链接为下载页面；
	; - 托盘菜单第一个子项的文本为`「有新版本」vX.X.X`；
	; - 托盘提示的文本为`NTE Stumps (有新版本)`。
	; 这些修改是单向的，无法撤销或复原。
	; - `new_version`：最新版本的版本号，将用于后续显示。
	static the_program_has_update(new_version, Self := tra, menu := A_TrayMenu) {
		Self.cal.关于软件_url := "https://www.ilanzou.com/s/k9GX147s"
		menu.Rename(Self.item.关于软件.id, "「有新版本」v" new_version)
		A_IconTip := "NTE Stumps (有新版本)"
	} ; func the_program_has_update



	; 根据程序的状态设置托盘图标。
	; 目前支持：挂起（`A_IsSuspended`）。
	static refresh_tray_icon() {
		;@Ahk2Exe-IgnoreBegin
		TraySetIcon(A_IsSuspended ? "..\ico\i2.ico" : "..\ico\i1.ico", , true)
		;@Ahk2Exe-IgnoreEnd
	} ; func refresh_tray_icon



	;@Ahk2Exe-IgnoreBegin
	; 集成测试部分。
	; 用作模块或命名空间。
	class tests {
		; 一并执行所有测试项。
		static all(Self := tra.tests) {
			Self.construct()
		;	Self.construct_with_update()
			Persistent()
		} ; func all



		; 构建托盘菜单供实际测试。
		static construct(Self := tra) {
			Self.construct()
		} ; func construct



		; 构建托盘菜单供实际测试，同时附带一次更新通知。
		static construct_with_update(Self := tra) {
			Self.construct()
			Self.the_program_has_update("1.2.0")
		} ; func construct_with_update
	} ; class tests
	;@Ahk2Exe-IgnoreEnd
} ; class Tray

