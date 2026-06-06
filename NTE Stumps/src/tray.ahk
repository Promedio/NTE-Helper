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
			; 子项默认状态的预备文本。
			static name_when_default    := "关于 NTE Stumps"
			; 子项有更新时的预备文本。
			static name_when_has_uptade := "「有新版本」"
		} ; class 关于软件
		; 切换类项，将挂起所有热键。
		; 此项应独立成组，且应当在其它切换控制项之上。
		class 全局功能启用状态 {
			; 子项的预期位置。
			static id   := "2&"
			; 子项的名称文本。
			static name := "启用整体功能"
		} ; class 全局功能启用状态
		; 切换类项，将切换相关热键的启用状态。
		class 交互重复启用状态 {
			; 子项的预期位置。
			static id   := "3&"
			; 子项的名称文本。
			static name := "启用交互按键重复功能"
		} ; class 交互重复启用状态
		; 切换类项，将切换相关热键的启用状态。
		class 按键重复启用状态 {
			; 子项的预期位置。
			static id   := "4&"
			; 子项的名称文本。
			static name := "启用其它按键重复功能"
		} ; class 按键重复启用状态
		; 触发类项，将重启软件。
		; 此项不得位于最末，除非没有更需要靠后的项。
		class 重启软件 {
			; 子项的预期位置。
			static id   := "5&"
			; 子项的名称文本。
			static name := "重新启动软件"
		} ; class 重启软件
		; 触发类项，将退出软件。
		; 此项必须位于最末。
		class 退出软件 {
			; 子项的预期位置。
			static id   := "6&"
			; 子项的名称文本。
			static name := "退出软件"
		} ; class 退出软件
	} ; class item



	; 
	static construct(Self := tra, menu := A_TrayMenu) {
		Self.refresh_tray_icon(Self)
		Self.construct_tray_menu(Self, menu)
	} ; func construct



	; 
	static construct_tray_menu(Self := tra, menu := A_TrayMenu) {
		menu.Delete()

		menu.Add(Self.item.关于软件.name,         (*) => Self.cal.关于软件())
		menu.Add()
		menu.Add(Self.item.全局功能启用状态.name, (*) => Self.cal.全局功能启用状态())
		menu.Add()
		menu.Add(Self.item.交互重复启用状态.name, (*) => Self.cal.交互重复启用状态())
		menu.Add(Self.item.按键重复启用状态.name, (*) => Self.cal.按键重复启用状态())
		menu.Add()
		menu.Add(Self.item.重启软件.name,         (*) => Self.cal.重启软件())
		menu.Add(Self.item.退出软件.name,         (*) => Self.cal.退出软件())
	} ; func 



	; 
	static refresh_tray_menu_status(Self := tra, menu := A_TrayMenu) {

	} ; func refresh_tray_menu_status



	; 
	static the_program_has_update() {
		; 这个还没想好，应该放在更新的静态类里，然后这边做刷新，包括悬浮提示、菜单项名，之后的关于构造直接引用更新类好了。
	} ; func the_program_has_update



	; 
	static refresh_tray_icon(Self := tra) {
		;@Ahk2Exe-IgnoreBegin
		TraySetIcon(A_IsSuspended ? "..\ico\i2.ico" : "..\ico\i1.ico")
		;@Ahk2Exe-IgnoreEnd
	} ; func refresh_tray_icon



	;@Ahk2Exe-IgnoreBegin
	; 集成测试部分。
	; 用作模块或命名空间。
	class tests {
		; 一并执行所有测试项。
		static all(Self := tra.tests) {
			Self.construct()
			Persistent()
		} ; func all



		; 
		static construct(Self := tra) {
			Self.construct()
		} ; func construct
	} ; class tests
	;@Ahk2Exe-IgnoreEnd
} ; class Tray

