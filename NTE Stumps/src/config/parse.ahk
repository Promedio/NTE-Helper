; Copyright 2026 Paclora Corporation. Licensed under the Apache License, Version 2.0.

; 类型解析。
; 包含类型解析和序列化功能。


; ---- ---- ---- ----   ---- ---- ---- ----   ---- ---- ---- ----   ---- ---- ---- ----


#Requires AutoHotkey v2 ; 最低限制。


; ---- ---- ---- ----   ---- ---- ---- ----   ---- ---- ---- ----   ---- ---- ---- ----


; 用作模块或命名空间：pas（于上层定义）。
class Parse {
	; 解析单个按键。
	; 解析失败时将弹出错误提示。
	; **注意：此函数可能会退出程序。**
	; - `key_name`：要解析的单个按键名；
	; - `can_be_empty`：为`true`时可接受空值（可含空格）并使函数返回空值；
	; - 返回值：`key_name`的标准按键名，若`key_name`为空字符串且`can_be_empty`为`true`时返回空字符串而不弹出错误提示。
	static parse_single_key(key_name, can_be_empty := false, Self := cfg.pas) {
		finres := false

		; 过滤给定文本，去除空格。
		key_name_of_filtered := ""
		loop parse key_name {
			if A_LoopField == " " {
				continue
			} else {
				key_name_of_filtered .= A_LoopField
			}
		}

		; 允许为空时可返回空，否则需要报错。
		if key_name_of_filtered == "" {
			if can_be_empty == true {
				finres := ""
				goto FINRES
			} else {
				dui.error_dialog(
					"有不可留空的按键名。`n"
					"`n"
					"遗憾的是，程序无法纠正这个错误。"
					, A_ThisFunc
				)
			}
		}

		finres := Self.get_standard_key_name(key_name_of_filtered)
		if finres == false {
			dui.error_dialog(
				"“" key_name "” 作为按键名是无效的。`n"
				"`n"
				"遗憾的是，程序无法纠正这个错误。"
				, A_ThisFunc
			)
		}

		FINRES:
		return finres
	}



	; 解析多组按键列表。
	; 从指定形式的字符串中解析出具有标准按键名的按键列表，解析失败（按键无效或重复）时将弹出错误提示。
	; **注意：此函数可能会退出程序。**
	; - `key_list_text`：以`,`和`;`分割的按键列表字符串，以`;`分割成组，以`,`分割为成员（也可以是全角形式）；
	; - 返回值：以标准按键名字符串为成员的二维数组，视情况也可能返回空数组，因此该返回值不一定总有成员。
	static parse_td_key_list(key_list_text, Self := cfg.pas) {
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
				; 跳过空的解析结果。
				if A_LoopField == "" {
					continue
				}
				; 确保按键名是有效的单按键，否则弹出错误。
				standard_key_name := Self.get_standard_key_name(A_LoopField)
				if standard_key_name == false {
					dui.error_dialog(
						"给定配置 “" key_list_text "” 中，“" A_LoopField "” 作为按键名是无效的。`n"
						"`n"
						"遗憾的是，程序无法纠正这个错误。"
						, A_ThisFunc
					)
				}
				; 确保按键名没有重复，否则弹出错误。
				if Self.check_key_duplicate(standard_key_name) == true {
					dui.error_dialog(
						"给定配置 “" key_list_text "” 的标准化结果 “" key_list_text_of_filtered "” 中，“" standard_key_name "” 重复出现了。`n"
						"`n"
						"遗憾的是，程序无法纠正这个错误。"
						, A_ThisFunc
					)
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
	} ; func parse_td_key_list



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



	; 序列化多组按键列表。
	; 将以按键名为成员的二维数组序列化为字符串。
	; - `key_list`：以按键名字符串为成员的二维数组；
	; - 返回值：以`,`和`;`分割的按键列表字符串，以`;`分割成组，以`,`分割为成员，视情况也可能返回空字符串。
	; **注意：不正确的热键创建也可能触发此函数的错误。**
	static stringify_td_key_list(key_list) {
		finres := ""

		; 遍历取出按键组。
		group_number := key_list.Length
		for one in key_list {
			key_number := one.Length
			; 跳过空组。
			if one.Length == 0 {
				continue
			}
			; 遍历取出按键名。
			for two in one {
				; 跳过空按键名。
				if two == "" {
					continue
				}
				; 追加按键名。
				finres .= two
				; 插入分隔符，但不在末尾添加。
				if A_Index != key_number {
					finres .= ", "
				}
			}
			; 插入分隔符，但不在末尾添加。
			if A_Index != group_number {
				finres .= "`; "
			}
		}

		return finres
	} ; func stringify_td_key_list



	; 解析功能开关指示。
	; 解析失败时将弹出错误提示。
	; **注意：此函数可能会退出程序。**
	; - `switch_text`：要解析的功能开关指示文本；
	; - 返回值：`switch_text`为`"开"`、`"真"`、`"on"`、`"true"`时返回`true`，为`"关"`、`"假"`、`"off"`、`"false"`时返回`false`。
	static parse_switch(switch_text) {
		; 过滤给定文本，去除空格。
		switch_text_of_filtered := ""
		loop parse switch_text {
			if A_LoopField == " " {
				continue
			} else {
				switch_text_of_filtered .= A_LoopField
			}
		}

		switch switch_text_of_filtered {
		case "开":
			return true
		case "真":
			return true
		case "关":
			return false
		case "假":
			return false
		default:
			if StrCompare(switch_text_of_filtered, "on", "Off") == 0 {
				return true
			}
			if StrCompare(switch_text_of_filtered, "true", "Off") == 0 {
				return true
			}
			if StrCompare(switch_text_of_filtered, "off", "Off") == 0 {
				return false
			}
			if StrCompare(switch_text_of_filtered, "false", "Off") == 0 {
				return false
			}
			dui.error_dialog(
				"给定配置 “" switch_text "” 无法指示启用状态，请用 “开” “真” “on” “true” 或 “关” “假” “off” “false” 来指示功能的开启或关闭。`n"
				"`n"
				"遗憾的是，程序无法纠正这个错误。"
				, A_ThisFunc
			)
		}
	} ; func parse_switch



	; 序列化功能开关指示。
	; 序列化失败时将弹出错误提示。
	; **注意：此函数可能会退出程序。**
	; - `boolean`：要序列化的布尔值；
	; - 返回值：`boolean`为`true`时返回`"开"`，为`false`时返回`"关"`。
	static stringify_switch(boolean) {
		switch boolean {
		case true:
			return "开"
		case false:
			return "关"
		default:
			if IsNumber(boolean) {
				dui.error_dialog("布尔型序列化遇到意外数型：" boolean "。", A_ThisFunc, "内部错误")
			} else {
				dui.error_dialog("布尔型序列化遇到其它类型。", A_ThisFunc, "内部错误")
			}
		}
	} ; func stringify_witch



	;@Ahk2Exe-IgnoreBegin
	; 集成测试部分。
	; 用作模块或命名空间。
	class tests {
		; 一并执行所有测试项。
		static all(Self := cfg.pas.tests) {
			Self.standard_key_name()
			Self.duplicate_keys()
			Self.parse_single_key()
			Self.parse_td_key_list()
			Self.stringify_td_key_list()
		;	Self.parse_and_stringify_td_key_list() ; 由于`parse_td_key_list`会创建热键，所以不能同时执行两个解析测试。
			Self.parse_switch()
			Self.stringify_switch()
		} ; func all



		; 测试是否能如期获得标准按键名。
		static standard_key_name(Self := cfg.pas) {
			com.assert(Self.get_standard_key_name("lctrl"), "LControl")
		} ; func standard_key_name



		; 测试是否能如期检测到重复的按键变体。
		static duplicate_keys(Self := cfg.pas) {
			com.assert(Self.check_key_duplicate("Space"), false)
			Hotkey("Space", (*) => {}, "Off")
			com.assert(Self.check_key_duplicate("Space"), true)
		} ; func duplicate_keys



		; 测试单个按键是否能如期解析。
		static parse_single_key(Self := cfg.pas) {
			com.assert(Self.parse_single_key("a"), "a")
			com.assert(Self.parse_single_key(" s "), "s")
			com.assert(Self.parse_single_key("ralt"), "RAlt")
			com.assert(Self.parse_single_key("", true), "")
			com.assert(Self.parse_single_key("    ", true), "")
		} ; func parse_single_key



		; 测试多组按键列表是否能如期解析。
		static parse_td_key_list(Self := cfg.pas) {
		;	Self.parse_td_key_list("1，2，3；a，b，cc")   ; 按键无效。
		;	Self.parse_td_key_list("1，2，3；a，b，c，c") ; 按键重复。
			array_res_a := Self.parse_td_key_list("1, 2, 3, 4; q, e, r; f; lctrl; xbutton1, rbutton")
			array_res_b := [["1", "2", "3", "4"], ["q", "e", "r"], ["f"], ["LControl"], ["XButton1", "RButton"]]
			com.assert(td_array_to_string(array_res_a), td_array_to_string(array_res_b))
			array_res_c := Self.parse_td_key_list("5, , 6") ; 这里是在测试空忽略。
			array_res_d := [["5", "6"]]
			com.assert(td_array_to_string(array_res_c), td_array_to_string(array_res_d))

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
		} ; func parse_td_key_list



		; 测试多组按键列表是否能如期序列化。
		static stringify_td_key_list(Self := cfg.pas) {
			text_res_a := "1, 2, 3, 4; q, e, r; f; LControl; XButton1, RButton"
			text_res_b := Self.stringify_td_key_list([["1", "2", "3", "4"], ["q", "e", "r"], ["f"], ["LControl"], ["XButton1", "RButton"]])
			com.assert(text_res_a, text_res_b)
		} ; func stringify_td_key_list



		; 测试多组按键列表是否能如期解析和序列化。
		static parse_and_stringify_td_key_list(Self := cfg.pas) {
			text_res_a := "1, 2, 3, 4; q, e, r; f; LControl; XButton1, RButton"
			text_res_b := Self.stringify_td_key_list(Self.parse_td_key_list(text_res_a))
			com.assert(text_res_a, text_res_b)
		} ; func parse_and_stringify_td_key_list



		; 测试开关是否能如期解析。
		static parse_switch(Self := cfg.pas) {
			com.assert(Self.parse_switch("开"), true)
			com.assert(Self.parse_switch("真"), true)
			com.assert(Self.parse_switch("on"), true)
			com.assert(Self.parse_switch("On"), true)
			com.assert(Self.parse_switch("true"), true)
			com.assert(Self.parse_switch("True"), true)
			com.assert(Self.parse_switch("关"), false)
			com.assert(Self.parse_switch("假"), false)
			com.assert(Self.parse_switch("off"), false)
			com.assert(Self.parse_switch("Off"), false)
			com.assert(Self.parse_switch("false"), false)
			com.assert(Self.parse_switch("False"), false)
			com.assert(Self.parse_switch("  假 "), false)
			com.assert(Self.parse_switch("  False"), false)
		;	Self.parse_switch("sunma") ; 解析错误。
		;	Self.parse_switch("monna") ; 解析错误。
		} ; func parse_switch



		; 测试开关是否能如期序列化。
		static stringify_switch(Self := cfg.pas) {
			com.assert(Self.stringify_switch(true), "开")
			com.assert(Self.stringify_switch(1), "开")
			com.assert(Self.stringify_switch(false), "关")
			com.assert(Self.stringify_switch(0), "关")
		;	Self.stringify_switch(2)   ; 内部错误。
		;	Self.stringify_switch("a") ; 内部错误。
		} ; func stringify_switch
	} ; class tests
	;@Ahk2Exe-IgnoreEnd
} ; class Parse

