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



	; 预期配置文件的完整文件名，仅供类内读取。
	static config_file_full_name := "NTE Stumps 配置文件.ini"



	; 配置文件的数据，供程序内部读取。
	; 此类完全静态，使用前应使用`initialize`函数初始化。
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

			; 指示当前功能的附加行为。
			; 在配置文件内作为段的键。
			class 附加滚轮 {
				; 具体键名。
				static id   := "附加滚轮"
				; 具体值，布尔类型。
				; 默认值为`true`。
				static data := true
			} ; class 附加滚轮

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
				; 默认值有内容。若要指定空值请设为空数组（`[]`而非`[[]]`）。
				static data := [["1", "2", "3", "4"], ["q", "e", "r"]]
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



	; 初始化配置数据，应在使用`cfg.data`前调用一次，程序整个生命周期内无需再次调用。
	; 打开并读取和格式化配置文件，解析或写入出错时将弹出错误提示以中止程序，若文件不存在则创建，打开或创建失败时将弹出警告提示，由用户选择是否要继续执行。
	; **注意：此函数可能会退出程序。**
	; - `file_full_name`：配置文件的完整文件名；
	; - `file_dir`：配置文件所在目录的路径，默认为程序所在的目录（`A_ScriptDir`）。
	static initialize(file_full_name := cfg.config_file_full_name, file_dir := A_ScriptDir, Self := cfg) {
		config_file_full_path := file_dir "\" file_full_name

		; 假定初次读取，文件不存在时完整创建，创建失败时弹出警告提示框，
		; 如果用户选择继续执行，程序将使用默认值运行，但未创建配置。
		; 此处不是必须创建，因为默认值没有改变，这里主要是为了用户能够编辑。
		if !FileExist(config_file_full_path) {
			try {
				Self.write_config_to_file(config_file_full_path, true)
			} catch Error as e {
				dui.warning_dialog(
					"未能创建配置文件 “" config_file_full_path "”，因为 “" e.Message "”`n"
					"`n"
					"所以，程序未能生成配置文件。"
					, A_ThisFunc
				)
			}
		}
		; 配置文件已经存在，尝试读取——
		; 若读取成功，程序还将执行一次写入来格式化，写入失败时不做任何提示；
		; 若读取失败，程序弹出警告提示框，如果用户选择继续执行，程序将使用默认值，
		; 此处还尝试写入一次，这是为了补充缺失的配置部分，写入失败时不做任何提示。
		; 备注：所以其实不管怎么样都执行一次静默写入，写在 finally 里了。
		else {
			try {
				Self.read_config_from_file(config_file_full_path)
			} catch Error as e {
				dui.warning_dialog(
					"未能打开或读取配置文件 “" config_file_full_path "”，因为 “" e.Message "”`n"
					"`n"
					"所以，程序将使用默认配置。"
					, A_ThisFunc
				)
			} finally {
				try {
					Self.write_config_to_file(config_file_full_path)
				}
			}
		}
	} ; func initialize



	; 同步当前配置数据到配置文件，应在`cfg.data`被修改时调用一次，每次修改一个或多个配置数据后都应该调用。
	; 打开并写入配置文件，若文件不存在则创建，打开或创建失败时将弹出警告提示，由用户选择是否要继续执行。
	; **注意：此函数可能会退出程序。**
	; - `full_stringify`：指示是否需要完整序列化，多用于初次创建配置文件。
	; - `file_full_name`：配置文件的完整文件名；
	; - `file_dir`：配置文件所在目录的路径，默认为程序所在的目录（`A_ScriptDir`）。
	static synchronize(full_stringify := false, file_full_name := cfg.config_file_full_name, file_dir := A_ScriptDir, Self := cfg) {
		config_file_full_path := file_dir "\" file_full_name

		; 假定数据变更后的情形，覆盖写入配置文件，文件不存在时创建文件，打开或创建失败时进入catch。
		; 如果进入catch，且用户选择继续执行，则程序可以继续执行，但配置文件未能保存。
		try {
			Self.write_config_to_file(config_file_full_path, full_stringify)
		} catch Error as e {
			dui.warning_dialog(
				"未能创建或写入配置文件 “" config_file_full_path "”，因为 “" e.Message "”`n"
				"`n"
				"所以，程序无法保存配置。"
				, A_ThisFunc
			)
		}
	} ; func synchronize



	; 从配置文件中读取数据。
	; 打开并读取配置文件，目标不存在时不存在或打开失败时原样返回`IniRead`的错误，解析失败时将弹出错误提示。
	; **注意：此函数可能会退出程序。**
	; - `file_full_path`：配置文件的完整路径；
	; - 返回值：读取成功时返回`true`，读取失败时返回`OSError`。
	; 实现参考：https://bitbucket.org/paclora_epo/calabiyau-helper/src/ce2c332a53d48cab1b87e6b3870195942ca9980a/Scroll%20Wheel%20Behavior/Scroll%20Wheel%20Behavior%20for%20CalabiYau%20-%201.1.3.ahk#lines-213 、https://bitbucket.org/paclora_epo/3oostumps/src/fb6b63869c04e6e1ccdf038bf947447eee4e966c/%E6%BA%90%E7%A0%81/3ooStumps/.PARTIAL/DataValidation.ahk#lines-126 。
	static read_config_from_file(file_full_path, Self := cfg) {
		try {
			current_section  := Self.data.交互重复 ; 组 --- --- --- ---

			current_key      := current_section.映射按键
			current_key.data := Self.pas.parse_single_key( IniRead(file_full_path, current_section.id, current_key.id), true) ; 支持空结果。
			current_key      := current_section.触发按键
			current_key.data := Self.pas.parse_single_key( IniRead(file_full_path, current_section.id, current_key.id), true) ; 支持空结果。
			current_key      := current_section.附加滚轮
			current_key.data := Self.pas.parse_switch(     IniRead(file_full_path, current_section.id, current_key.id))
			current_key      := current_section.启用状态
			current_key.data := Self.pas.parse_switch(     IniRead(file_full_path, current_section.id, current_key.id))

			current_section  := Self.data.按键重复 ; 组 --- --- --- ---

			current_key      := current_section.按键列表
			current_key.data := Self.pas.parse_td_key_list(IniRead(file_full_path, current_section.id, current_key.id)) ; 默认支持空结果。
			current_key      := current_section.启用状态
			current_key.data := Self.pas.parse_switch(     IniRead(file_full_path, current_section.id, current_key.id))

			current_section  := Self.data.杂项设置 ; 组 --- --- --- ---

			current_key      := current_section.全局按键
			current_key.data := Self.pas.parse_single_key( IniRead(file_full_path, current_section.id, current_key.id), true) ; 支持空结果。
		} catch {
			throw ; 抛出而不报错是因为上层逻辑中可能存在不同的解释方式。
		}

		return true
	} ; func read_config_from_file



	; 将当前配置写入配置文件。
	; 打开并覆盖写入配置文件，目标不存在时创建新文件，打开或创建失败时原样返回`FileOpen`的错误。
	; - `file_full_path`：配置文件的完整路径；
	; - `full_stringify`：指示是否需要完整序列化，多用于初次创建配置文件。
	; - 返回值：写入成功时返回`true`，失败时返回`OSError`。
	; 实现参考：https://bitbucket.org/paclora_epo/calabiyau-helper/src/ce2c332a53d48cab1b87e6b3870195942ca9980a/Scroll%20Wheel%20Behavior/Scroll%20Wheel%20Behavior%20for%20CalabiYau%20-%201.1.3.ahk#lines-308 。
	static write_config_to_file(file_full_path, full_stringify := false, Self := cfg) {
		try {
			if full_stringify == true {
				file := Self.open_file(file_full_path, true)
				file.Write(Self.stringify_config_data())
				file.Close()
			} else {
				current_section := Self.data.交互重复 ; 组 --- --- --- ---

				current_key     := current_section.映射按键
				IniWrite(                               current_key.data , file_full_path, current_section.id, current_key.id)
				current_key     := current_section.触发按键
				IniWrite(                               current_key.data , file_full_path, current_section.id, current_key.id)
				current_key     := current_section.附加滚轮
				IniWrite(     Self.pas.stringify_switch(current_key.data), file_full_path, current_section.id, current_key.id)
				current_key     := current_section.启用状态
				IniWrite(     Self.pas.stringify_switch(current_key.data), file_full_path, current_section.id, current_key.id)

				current_section := Self.data.按键重复 ; 组 --- --- --- ---

				current_key     := current_section.按键列表
				IniWrite(Self.pas.stringify_td_key_list(current_key.data), file_full_path, current_section.id, current_key.id)
				current_key     := current_section.启用状态
				IniWrite(     Self.pas.stringify_switch(current_key.data), file_full_path, current_section.id, current_key.id)

				current_section := Self.data.杂项设置 ; 组 --- --- --- ---

				current_key     := current_section.全局按键
				IniWrite(                               current_key.data, file_full_path, current_section.id, current_key.id)
			}
		} catch {
			throw ; 抛出而不报错是因为上层逻辑中可能存在不同的解释方式。
		}

		return true
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
			"# ＊“映射按键”是您确实需要按下的按键名，" endl .
			"# 　　如果您留空，当前功能不会生效；" endl .
			"# ＊“触发按键”是软件向游戏实际发送的按键名，" endl .
			"# 　　如果您留空，当前功能不会生效；" endl .
			"# ＊“附加滚轮”指示当前功能是否应在重复中附加滚轮，一般通过托盘菜控制，" endl .
			"# 　　可填写“开”或“关”。" endl .
			"# ＊“启用状态”指示当前功能是否应当生效，一般通过托盘菜控制，" endl .
			"# 　　可填写“开”或“关”。" endl .
			"[" Self.data.交互重复.id "]" endl .
			Self.data.交互重复.映射按键.id "="                                Self.data.交互重复.映射按键.data  endl .
			Self.data.交互重复.触发按键.id "="                                Self.data.交互重复.触发按键.data  endl .
			Self.data.交互重复.附加滚轮.id "="      Self.pas.stringify_switch(Self.data.交互重复.附加滚轮.data) endl .
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
			"# 　　与其它功能不同的是，您需要连续按下两次才能触发它，" endl .
			"# 　　如果您不需要这个功能，可以留空。" endl .
			"[" Self.data.杂项设置.id "]" endl .
			Self.data.杂项设置.全局按键.id "="                                Self.data.杂项设置.全局按键.data  endl .
			endl

		return finres
	} ; func stringify_config_data



	; 打开指定文件。
	; 打开指定文件，也可指定当目标不存在时创建新文件，打开或创建失败时原样返回`FileOpen`的错误。
	; - `file_full_path`：要打开的文件的完整路径；
	; - `create_if_not_exist`：指示函数是否应在目标不存在时创建新文件，需要写入文件时必须为`true`；
	; - `eol_opt`：行结束符选项，配置为 `n 时可自动以面向Windows平台的方式处理换行符；
	; - 返回值：成功打开时返回`File`对象，失败时返回`OSError`。
	; 实现参考：https://bitbucket.org/paclora_epo/calabiyau-helper/src/ce2c332a53d48cab1b87e6b3870195942ca9980a/Disable%20System%20Hotkey/Disable%20System%20Hotkey%20for%20CalabiYau%20-%201.1.0.ahk#lines-293 。
	static open_file(file_full_path, create_if_not_exist := false, eol_opt := "`n") {
		try {
			; 使用 UTF-16 是因为 IniRead 和 IniWrite 只支持 UTF-16 件中的 Unicode，详见：https://wyagd001.github.io/v2/docs/lib/IniRead.htm#Remarks 。
			return FileOpen(file_full_path, (create_if_not_exist ? "rw " : "r ") . eol_opt, "UTF-16")
		} catch {
			throw
		}
	} ; func open_file



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
			; 使用 UTF-16 是因为 IniRead 和 IniWrite 只支持 UTF-16 件中的 Unicode，详见：https://wyagd001.github.io/v2/docs/lib/IniRead.htm#Remarks 。
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
			Self.read_config_from_file()
			Self.write_config_to_file()
		} ; func all



		; 打印以预览配置文件的排版格式和观察序列化情况。
		static stringify_config_data(Self := cfg) {
			OutputDebug(Self.stringify_config_data())
		} ; func stringify_config_data



		; 测试配置文件是否能如期读取。
		static read_config_from_file(Self := cfg) {
			; 文件路径相对于最终执行文件的位置（main.ahk）。
			Self.read_config_from_file("..\smp\config_file_used_to_read_wa_default.ini")
			com.assert(Self.data.交互重复.映射按键.data       , "f")
			com.assert(Self.data.交互重复.触发按键.data       , "f")
			com.assert(Self.data.交互重复.启用状态.data       , true)
			com.assert(Self.data.按键重复.按键列表.data.Length, 0)
			com.assert(Self.data.按键重复.启用状态.data       , true)
			com.assert(Self.data.杂项设置.全局按键.data, "RShift")
			Self.read_config_from_file("..\smp\config_file_used_to_read_wa_custom.ini")
			com.assert(Self.data.交互重复.映射按键.data      , "f")
			com.assert(Self.data.交互重复.触发按键.data      , "LControl")
			com.assert(Self.data.交互重复.启用状态.data      , true)
			com.assert(Self.data.按键重复.按键列表.data[1][1], "F1")
			com.assert(Self.data.按键重复.按键列表.data[1][2], "F2")
			com.assert(Self.data.按键重复.按键列表.data[1][3], "F3")
			com.assert(Self.data.按键重复.按键列表.data[1][4], "F4")
			com.assert(Self.data.按键重复.按键列表.data[2][1], "F5")
			com.assert(Self.data.按键重复.按键列表.data[2][2], "F6")
			com.assert(Self.data.按键重复.按键列表.data[2][3], "F7")
			com.assert(Self.data.按键重复.按键列表.data[3][1], "RAlt")
			com.assert(Self.data.按键重复.按键列表.data[3][2], "XButton2")
			com.assert(Self.data.按键重复.启用状态.data      , true)
			com.assert(Self.data.杂项设置.全局按键.data, "")
		;	Self.read_config_from_file("..\smp\config_file_used_to_read_wa_incorrect_of_no_somekey.ini")  ; 空按键错误。
		;	Self.read_config_from_file("..\smp\config_file_used_to_read_wa_incorrect_of_invalid_key.ini") ; 无效按键错误。
		} ; func read_config_from_file



		; 测试配置文件是否能如期写入，但测试结果需要人工对比。
		static write_config_to_file(Self := cfg) {
			target_file_path := "..\smp\config_file_used_to_write_wa_custom.ini"
			Self.data.交互重复.映射按键.data := "p"
			Self.data.交互重复.触发按键.data := "m"
			Self.data.交互重复.启用状态.data := false
			Self.data.按键重复.按键列表.data := [["c", "k"], ["t", "y"]]
			Self.data.按键重复.启用状态.data := false
			Self.data.杂项设置.全局按键.data := "g"
			if FileExist(target_file_path) {
				FileDelete(target_file_path)
			}
			Self.write_config_to_file(target_file_path)
		} ; func write_config_to_file
	} ; class tests
	;@Ahk2Exe-IgnoreEnd
} ; class Config

