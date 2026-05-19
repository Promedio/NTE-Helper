; Copyright 2026 Paclora Corporation. Licensed under the Apache License, Version 2.0.

; 配置管理。
; 包含读写和解析配置的功能。


; ---- ---- ---- ----   ---- ---- ---- ----   ---- ---- ---- ----   ---- ---- ---- ----


#Requires AutoHotkey v2 ; 最低限制。


; ---- ---- ---- ----   ---- ---- ---- ----   ---- ---- ---- ----   ---- ---- ---- ----


#Include .\config\parse.ahk ; 类型解析。简化命名：pas。

; config.ahk\Config。
global cfg := Config


; ---- ---- ---- ----   ---- ---- ---- ----   ---- ---- ---- ----   ---- ---- ---- ----


; 用作模块或命名空间：cfg。
class Config {
	; config\parse.ahk\Parse。
	static pas := Parse



	; 配置文件的数据，供程序内部读取。
	; 此类完全静态，使用前应使用`synchronize`函数初始化。
	class data {
		; 游戏内角色交互世界对象的按键重复，区分映射按键与触发按键。
		; 在配置文件内作为段。
		class 交互重复 {
			; 具体段名。
			static id := "交互重复"

			; 用户真正需要按下的按键，可与`触发按键`相同。
			; 在配置文件内作为段的键。
			class 映射按键 {
				; 具体键名。
				static id   := "映射按键"
				; 具体值，字符串形式的单个按键。
				; 默认值与游戏内默认配置相同。
				static data := "f"
			} ; class 映射按键

			; 被`映射按键`触发的原始按键。
			; 在配置文件内作为段的键。
			class 触发按键 {
				; 具体键名。
				static id   := "触发按键"
				; 具体值，字符串形式的单个按键。
				; 默认值与游戏内默认配置相同。
				static data := "f"
			} ; class 触发按键

			class 功能启用 {
				; 具体键名。
				static id   := "功能启用"
				; 具体值，布尔类型。
				; 默认值为`true`。
				static data := true
			} ; class 功能启用
		} ; class 交互重复

		; 其它按键重复，根据分隔符分组触发，组间互斥覆盖。
		; 在配置文件内作为段。
		class 按键重复 {
			; 具体段名。
			static id := "按键重复"

			; 一个被`,`和`;`分割的按键列表，被`;`分割成组，其内成员由`,`分割。
			; 在配置文件内作为段的键。
			class 按键列表 {
				; 具体键名。
				static id   := "按键列表"
				; 具体值，二维数组，一维类型为字符串形式的单个按键。
				; 默认值为空数组（`[]`而非`[[]]`）。
				static data := []
			} ; class 按键列表

			class 功能启用 {
				; 具体键名。
				static id   := "功能启用"
				; 具体值，布尔类型。
				; 默认值为`true`。
				static data := true
			} ; class 功能启用
		} ; class 按键重复

		; 其它配置项。
		; 在配置文件内作为段。
		class 杂项设置 {
			; 具体段名。
			static id := "杂项设置"

			; 脚本功能的总开关按键，豁免挂起。
			; 在配置文件内作为段的键。
			class 功能开关 {
				; 具体键名。
				static id   := "功能开关"
				; 具体值，字符串形式的单个按键。
				; 默认值为右Shift键。
				static data := "RShift"
			} ; class 功能开关
		} ; class 杂项设置
	} ; class data



	; 
	static synchronize(file_name, file_path := A_ScriptDir) {

	} ; func synchronize



	; 
	static read_config_from_file(file) {

	} ; func read_config_from_file



	; 
	static write_config_to_file(file) {

	} ; func write_config_to_file



	; 打开指定文件并包含创建。
	; 打开指定文件，目标不存在时创建新文件，打开或创建失败时会弹出一个警告提示框让用户选择是否要继续执行。
	; **注意：此函数可能会退出程序。**
	; - `file_full_path`：要打开的文件的完整路径；
	; - 返回值：成功打开时返回文件对象，失败时返回`false`。
	; 实现参考：https://bitbucket.org/paclora_epo/calabiyau-helper/src/ce2c332a53d48cab1b87e6b3870195942ca9980a/Disable%20System%20Hotkey/Disable%20System%20Hotkey%20for%20CalabiYau%20-%201.1.0.ahk#lines-293 。
	static open_file_with_create_if_not_exist(file_full_path) {
		finres := false

		try {
			finres := FileOpen(file_full_path, "rw", "UTF-16")
		} catch Error as e {
			dui.warning_dialog(
				"未能打开文件 “" file_full_path "”，因为 “" e.Message "”`n"
				"`n"
				"所以，程序将使用默认配置。"
				, A_ThisFunc
			)
		}

		FINRES:
		return finres
	} ; func open_file_with_create_if_not_exist



	; 创建一个新文件。
	; 以给定路径创建文件，目标存在时不创建，创建失败时会弹出一个警告提示框让用户选择是否要继续执行。
	; **注意：此函数可能会退出程序。**
	; - `file_full_path`：要创建的文件的完整路径；
	; - 返回值：创建成功或无需创建时返回`true`，创建失败时返回`false`。
	; 实现参考：https://bitbucket.org/paclora_epo/calabiyau-helper/src/ce2c332a53d48cab1b87e6b3870195942ca9980a/Disable%20System%20Hotkey/Disable%20System%20Hotkey%20for%20CalabiYau%20-%201.1.0.ahk#lines-273 。
	static create_file_with_check(file_full_path) {
		finres := false

		; FileExist 不能与布尔对比。
		if FileExist(file_full_path) {
			finres := true
			goto FINRES
		}

		try {
			FileOpen(file_full_path, "w", "UTF-16").Close()
			finres := true
		} catch Error as e {
			dui.warning_dialog(
				"未能创建文件 “" file_full_path "”，因为 “" e.Message "”`n"
				"`n"
				"所以，程序将使用默认配置。"
				, A_ThisFunc
			)
		}

		FINRES:
		return finres
	} ; func create_file_with_check



	;@Ahk2Exe-IgnoreBegin
	; 集成测试部分。
	; 用作模块或命名空间。
	class tests {
		; 一并执行所有测试项。
		static all(Self := cfg.tests) {
			cfg.pas.tests.all()
		} ; func all
	} ; class tests
	;@Ahk2Exe-IgnoreEnd
} ; class Config

