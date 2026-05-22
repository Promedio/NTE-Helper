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

			; 指示当前功能是否可以生效。
			; 在配置文件内作为段的键。
			class 启用状态 {
				; 具体键名。
				static id   := "启用状态"
				; 具体值，布尔类型。
				; 默认值为`true`。
				static data := true
			} ; class 启用状态
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

			; 指示当前功能是否可以生效。
			; 在配置文件内作为段的键。
			class 启用状态 {
				; 具体键名。
				static id   := "启用状态"
				; 具体值，布尔类型。
				; 默认值为`true`。
				static data := true
			} ; class 启用状态
		} ; class 按键重复

		; 其它配置项。
		; 在配置文件内作为段。
		class 杂项设置 {
			; 具体段名。
			static id := "杂项设置"

			; 脚本功能的总开关按键，豁免挂起。
			; 在配置文件内作为段的键。
			class 全局按键 {
				; 具体键名。
				static id   := "全局按键"
				; 具体值，字符串形式的单个按键。
				; 默认值为右Shift键。
				static data := "RShift"
			} ; class 全局按键
		} ; class 杂项设置
	} ; class data



	; 
	static initialize(file_full_name, file_path := A_ScriptDir) {

	} ; func initialize



	; 
	static synchronize(file_full_name, file_path := A_ScriptDir) {

	} ; func synchronize



	; 
	; **注意：此函数可能会退出程序。**
	; - `file_full_path`：配置文件的完整路径；
	; - 返回值：读取成功时返回`true`，失败时返回`false`。
	; 实现参考：https://bitbucket.org/paclora_epo/calabiyau-helper/src/ce2c332a53d48cab1b87e6b3870195942ca9980a/Scroll%20Wheel%20Behavior/Scroll%20Wheel%20Behavior%20for%20CalabiYau%20-%201.1.3.ahk#lines-213 。
	static read_config_from_file(file_full_path, Self := cfg) {
		finres := false

		; 判断存在性若不存在则不读取因为程序读写必然同时发生而考虑到必然发生则实际不应判断存在性故应当直接尝试等。

		FINRES:
		return finres
	} ; func read_config_from_file



	; 将当前配置写入配置文件。
	; 打开并覆盖写入配置文件，目标不存在时创建新文件，打开或创建失败时会弹出一个警告提示框让用户选择是否要继续执行。
	; **注意：此函数可能会退出程序。**
	; - `file_full_path`：配置文件的完整路径；
	; - 返回值：写入成功时返回`true`，失败时返回`false`。
	; 实现参考：https://bitbucket.org/paclora_epo/calabiyau-helper/src/ce2c332a53d48cab1b87e6b3870195942ca9980a/Scroll%20Wheel%20Behavior/Scroll%20Wheel%20Behavior%20for%20CalabiYau%20-%201.1.3.ahk#lines-308 。
	static write_config_to_file(file_full_path, Self := cfg) {
		finres := false

		try {
			file := Self.open_file_with_create_if_not_exist(file_full_path)
		} catch Error as e {
			dui.warning_dialog(
				"未能打开或创建配置文件文件 “" file_full_path "”，因为 “" e.Message "”`n"
				"`n"
				"所以，程序将使用默认配置。"
				, A_ThisFunc
			)
			goto FINRES
		}

		file.Write(Self.stringify_config_data())
		file.Close()
		finres := true

		FINRES:
		return finres
	} ; func write_config_to_file



	; 序列化配置文件数据。
	; 因顾及用户体验，此序列化完全手动控制，包含排版和注释信息。
	; - `endl`：行结束符，按平台特性应当定义为 `r`n，但`FileOpen`的Flags有EOL选项支持，其设置为 `n 时可自动处理这些换行；
	; - 返回值：包含完整配置文件内容的字符串。
	; 有关行结束符选项，详见：https://wyagd001.github.io/v2/docs/lib/FileOpen.htm#EOL_options 、https://wyagd001.github.io/v2/docs/lib/FileOpen.htm#Remarks 。
	static stringify_config_data(endl := "`n", Self := cfg) {
		finres :=
			"# NTE Stumps 配置文件" endl .
			"# 有关可用按键，请见：https://wyagd001.github.io/v2/docs/KeyList.htm" endl .
			endl .
			endl .
			"# －“交互重复”功能可重复特定按键，" endl .
			"# 　　当您保持按下“映射按键”时，软件将持续发送“触发按键”。" endl .
			"# ＊“映射按键”是您确实需要按下的按键名；" endl .
			"# ＊“触发按键”是软件向游戏实际发送的按键名；" endl .
			"# ＊“启用状态”指示当前功能是否应当生效，一般通过托盘菜控制，" endl .
			"# 　　可填写“开”或“关”。" endl .
			"[" Self.data.交互重复.id "]" endl .
			Self.data.交互重复.映射按键.id "="                                Self.data.交互重复.映射按键.data  endl .
			Self.data.交互重复.触发按键.id "="                                Self.data.交互重复.触发按键.data  endl .
			Self.data.交互重复.启用状态.id "="      Self.pas.stringify_switch(Self.data.交互重复.启用状态.data) endl .
			endl .
			"# －“按键重复”功能可批量重复按键，区别是成组支持的按键之间不会冲突。" endl .
			"# 　　当您按下任何在“按键列表”中列出的按键时，软件将持续发送那些按键。" endl .
			"# ＊“按键列表”是您需要在按下某些按键时重复触发击键的按键名的列表，" endl .
			"# 　　由分号（也就是“;”）分割成组，组内由逗号（也就是“,”）分隔按键名，" endl .
			"# 　　组之间的按键独立执行触发，而组内部的只会重复最后一个按下的按键，" endl .
			"# 　　也就是说，对于像“1, 2, 3, 4; q, e, r; LShift, RButton”这样的配置，" endl .
			"# 　　当您同时按下“1”“2”“3”“4”的时候，" endl .
			"# 　　软件第一开始会触发您第一个按下的按键，" endl .
			"# 　　但紧接着只会重复您最后一个按下的按键（您按下按键的时机总分先后），" endl .
			"# 　　这时，如果还有其它处于列表中的按键被按下（譬如“LShift”），" endl .
			"# 　　那么软件就有了两个正在重复击键的按键，因为在这个假设的例子中，" endl .
			"# 　　您按下的按键刚好在两个按键组中——如果您不需要这个功能，可以留空；" endl .
			"# ＊“启用状态”指示当前功能是否应当生效，一般通过托盘菜控制，" endl .
			"# 　　可填写“开”或“关”。" endl .
			"[" Self.data.按键重复.id "]" endl .
			Self.data.按键重复.按键列表.id "=" Self.pas.stringify_td_key_list(Self.data.按键重复.按键列表.data) endl .
			Self.data.按键重复.启用状态.id "="      Self.pas.stringify_switch(Self.data.按键重复.启用状态.data) endl .
			endl .
			"# －“杂项设置”收纳了一些不太重要的配置项。" endl .
			"# ＊“全局按键”是供您在游戏内快捷禁用或启用软件整体功能的按键名，" endl .
			"# 　　如果您不需要这个功能，可以留空。" endl .
			"[" Self.data.杂项设置.id "]" endl .
			Self.data.杂项设置.全局按键.id "="                                Self.data.杂项设置.全局按键.data  endl .
			endl

		return finres
	} ; func stringify_config_data



	; 打开指定文件并包含创建。
	; 打开指定文件，目标不存在时创建新文件，打开或创建失败时原样返回`FileOpen`的错误。
	; - `file_full_path`：要打开的文件的完整路径；
	; - `eol_opt`：行结束符选项，配置为 `n 时可自动以面向Windows平台的方式处理换行符；
	; - 返回值：成功打开时返回文件对象，失败时返回`OSError`。
	; 实现参考：https://bitbucket.org/paclora_epo/calabiyau-helper/src/ce2c332a53d48cab1b87e6b3870195942ca9980a/Disable%20System%20Hotkey/Disable%20System%20Hotkey%20for%20CalabiYau%20-%201.1.0.ahk#lines-293 。
	static open_file_with_create_if_not_exist(file_full_path, eol_opt := "`n") {
		try {
			return FileOpen(file_full_path, "rw " . eol_opt, "UTF-16")
		} catch {
			throw
		}
	} ; func open_file_with_create_if_not_exist



	; 创建一个新文件。
	; 以给定路径创建文件，目标存在时不创建，创建失败时原样返回`FileOpen`的错误。
	; - `file_full_path`：要创建的文件的完整路径；
	; - 返回值：创建成功或无需创建时返回`true`，创建失败时返回`OSError`。
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
		} catch {
			throw
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
		;	Self.stringify_config_data()
		} ; func all



		; 打印以预览配置文件的排版格式和观察序列化情况。
		static stringify_config_data(Self := cfg) {
			OutputDebug(Self.stringify_config_data())
		} ; func stringify_config_data
	} ; class tests
	;@Ahk2Exe-IgnoreEnd
} ; class Config

