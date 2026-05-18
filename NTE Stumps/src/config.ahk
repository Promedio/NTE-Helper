; Copyright 2026 Paclora Corporation. Licensed under the Apache License, Version 2.0.

; 配置管理。
; 包含读写和解析配置的功能。


; ---- ---- ---- ----   ---- ---- ---- ----   ---- ---- ---- ----   ---- ---- ---- ----


#Requires AutoHotkey v2 ; 最低限制。


; ---- ---- ---- ----   ---- ---- ---- ----   ---- ---- ---- ----   ---- ---- ---- ----


; config.ahk\Config。
global cfg := Config


; ---- ---- ---- ----   ---- ---- ---- ----   ---- ---- ---- ----   ---- ---- ---- ----


; 用作模块或命名空间：cfg。
class Config {
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
				; 默认值保持为空（`[]`而非`[[]]`）。
				static data := []
			} ; class 按键列表
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
	; 读设置解析若出错则警告，无配置再默认。
	; 还未确认同步的顺序是读写读还是写读写。
	static synchronize(file_name, file_path := A_ScriptDir) {

	} ; func synchronize



	; 
	static read_config_from_file(file) {

	} ; func read_config_from_file



	; 解析按键列表。
	; 从指定形式的字符串中解析出具有标准按键名的按键列表，解析失败（按键无效或重复）时会弹出一个警告提示框让用户选择是否要继续执行。
	; **注意：此函数可能会退出程序。**
	; - `key_list_text`：以`,`和`;`分割的按键列表字符串，以`;`分割成组，以`,`分割为成员（也可以是全角形式）；
	; - 返回值：以标准按键名字符串为成员的二维数组，视情况也可能返回空数组，因此该返回值不一定总有成员。
	static parse_key_list(key_list_text, Self := cfg) {
		; 过滤给定文本，去除空格、转换全角逗号和分号。
		key_list_text_of_filtered := ""
		loop parse key_list_text {
			switch A_LoopField {
			case " ":
				continue
			case "，":
				key_list_text_of_filtered .= ","
			case "；":
				key_list_text_of_filtered .= ";"
			default:
				key_list_text_of_filtered .= A_LoopField
			}
		}

		; 按键总组，默认为空（空成员也具位置，也就是说`[[]]`有 1 长度。
		; 以 `;` 为分割解析字符串，每次循环为一个按键组，忽略空组。
		key_group := []
		loop parse key_list_text_of_filtered, ";" {
			; 按键单组，默认为空。
			; 以 `,` 为分割解析字符串，每次循环为一个按键，忽略空字符串。
			key_list_of_single_group := []
			loop parse A_LoopField, "," {
				; 确保按键名是有效的单按键，否则弹出错误。
				standard_key_name := Self.get_standard_key_name(A_LoopField)
				if standard_key_name == false {
					dui.error_dialog("按键无效")
				}
				; 确保按键名没有重复，否则弹出错误。
				if Self.check_key_duplicate(standard_key_name) == true {
					dui.error_dialog("按键重复")
				}
				; 创建一个无效的热键，以供后续逻辑检测重复。
				Hotkey(standard_key_name, (*) => {}, "Off")
				; 追加标准按键名。
				key_list_of_single_group.Push(standard_key_name)
			}
			; 不追加空的按键组。
			if key_list_of_single_group.Length > 0 {
				key_group.Push(key_list_of_single_group)
			}
		}

		return key_group
	} ; func parse_key_list



	; 从字符串获取标准按键名。
	; 此函数仅可获取单个按键的标准按键名，也接受单个虚拟键码（VK）或单个扫描码（SC）。
	; - `key_name`：要检查的按键名；
	; - 返回值：获取成功时返回字符串形式的标准按键名称，失败时返回`false`。
	; 有关标准按键名，详见：https://wyagd001.github.io/v2/docs/lib/GetKeyName.htm 。
	static get_standard_key_name(key_name) {
		finres := false

		standard_key_name := GetKeyName(key_name)
		if standard_key_name != "" {
			finres := standard_key_name
		}

		return finres
	} ; func get_standard_key_name



	; 检查给定按键在当前条件下是否存在热键变体。
	; 必须给定标准按键名，否则类似于“lctrl”与“LControl”的情形将被视为不同按键。
	; - `standard_key_name`：要检查的标准按键名；
	; - 返回值：当前条件下存在热键变体时返回`true`，否则返回`false`。
	; 实现参考：https://wyagd001.github.io/v2/docs/lib/Hotkey.htm#Error_Handling 。
	static check_key_duplicate(standard_key_name) {
		finres := false

		try {
			Hotkey(standard_key_name)
			finres := true
		}
		
		return finres
	} ; func check_key_duplicate



	; 
	static write_config_to_file(file) {

	} ; func write_config_to_file



	; 
	static stringify_key_list(key_list) {

	} ; func stringify_key_list



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
			Self.standard_key_name()
			Self.duplicate_keys()
			Self.parse_key_list()
		} ; func all



		; 测试是否能如期获得标准按键名。
		static standard_key_name(Self := cfg) {
			com.assert(Self.get_standard_key_name("lctrl"), "LControl")
		} ; func standard_key_name



		; 测试是否能如期检测到重复的按键变体。
		static duplicate_keys(Self := cfg) {
			com.assert(Self.check_key_duplicate("Space"), false)
			Hotkey("Space", (*) => {}, "Off")
			com.assert(Self.check_key_duplicate("Space"), true)
		} ; func duplicate_keys



		; 测试按键列表是否能如期解析。
		static parse_key_list(Self := cfg) {
			;Self.parse_key_list("cc")  ; 按键无效。
			;Self.parse_key_list("c,c") ; 按键重复。
			array_res_a := Self.parse_key_list("1, 2, 3, 4; q, e, r; f; lctrl; xbutton1, rbutton")
			array_res_b := [["1", "2", "3", "4"], ["q", "e", "r"], ["f"], ["LControl"], ["XButton1", "RButton"]]
			com.assert(td_array_to_string(array_res_a), td_array_to_string(array_res_b))

			; 依照二维数组生成字符串，用于内容对比。
			; 内层数组不能是空的，成员不能是空字符串。
			; - `td_array`：目标二维数组；
			; - 返回值：以空格拼合的字符串，若无内容则返回空字符串。
			td_array_to_string(td_array) {
				finres := ""

				for one in td_array {
					; 内层数组不能为空。
					if one.Length == 0 {
						com.assert(1,0)
					}
					for two in one {
						; 成员不能是空字符串。
						if two == "" {
							com.assert(1,0)
						}
						finres .= two " "
					}
				}

				return finres
			}
		}
	} ; class tests
	;@Ahk2Exe-IgnoreEnd
} ; class Config

