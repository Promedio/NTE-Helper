; Copyright 2026 Paclora Corporation. Licensed under the Apache License, Version 2.0.

; 用户交互。
; 包含一些用于提示及接受选择和不甚直观的交互功能。


; ---- ---- ---- ----   ---- ---- ---- ----   ---- ---- ---- ----   ---- ---- ---- ----


#Requires AutoHotkey v2 ; 最低限制。


; ---- ---- ---- ----   ---- ---- ---- ----   ---- ---- ---- ----   ---- ---- ---- ----


; user_interface.ahk\UserInterface
dui := UserInterface


; ---- ---- ---- ----   ---- ---- ---- ----   ---- ---- ---- ----   ---- ---- ---- ----


; 用作模块或命名空间：dui。（d 意自 dialog。）
class UserInterface {
	; 弹出一个普通的消息提示框。
	; 弹出的消息提示框不附带任务，因此无论用户如何选择都不会影响程序运行（但保持不选会占用一个线程）。
	; - `message_content`：要显示的消息内容，留空时显示“未提供更多信息。”；
	; - `dialog_title`：；要显示的标题文本，留空时显示“提示”；
	; - `function_name`：当前函数名，将改变“`dialog_title`”为“`dialog_title`（`function_name`）”，留空时不显示。
	; 实现参考：https://bitbucket.org/paclora_epo/snowbreak-helper/src/a6e8f9485a2750a274dfda607ee90f49f200f203/Quick%20Launch/prtl/UserInterface.ahk#lines-13 。
	static info_dialog(message_content := "", function_name := "", dialog_title := "") {
		full_title := (dialog_title  != "" ? dialog_title : "提示") .
		              (function_name == "" ? ""           : "（" function_name "）")
		full_message := message_content != "" ? message_content : "未提供更多信息。"

		MsgBox(full_message, full_title)
	} ; func info_dialog



	; 弹出一个具有警告意味的消息提示框。
	; 用户选择“确认”不会有任何效果（但保持不选会占用一个线程），选择“取消”将立即退出程序。
	; **注意：此函数可能会退出程序。**
	; - `message_content`：要显示的消息内容，留空时显示“未提供更多信息。”；
	; - `dialog_title`：；要显示的标题文本，留空时显示“警告”；
	; - `function_name`：当前函数名，将改变“`dialog_title`”为“`dialog_title`（`function_name`）”，留空时不显示。
	; 实现参考：https://bitbucket.org/paclora_epo/snowbreak-helper/src/a6e8f9485a2750a274dfda607ee90f49f200f203/Quick%20Launch/prtl/UserInterface.ahk#lines-13 。
	static warning_dialog(message_content := "", function_name := "", dialog_title := "") {
		full_title := (dialog_title  != "" ? dialog_title : "警告") .
		              (function_name == "" ? ""           : "（" function_name "）")
		full_message := (message_content != "" ? message_content : "未提供更多信息。") .
		                "`n`n——点击“确认”继续执行，点击“取消”退出程序。"

		if MsgBox(full_message, full_title, "Icon! OC") == "OK" {
			return
		} else {
			ExitApp()
		}
	} ; func warning_dialog



	; 弹出一个错误提示框。
	; 弹出此提示框意味着遇到了不可解决的错误，因此无论用户如何选择都会退出程序（但保持不选会占用一个线程）。
	; **注意：此函数可能会退出程序。**
	; - `message_content`：要显示的消息内容，留空时显示“未提供更多信息。”；
	; - `dialog_title`：；要显示的标题文本，留空时显示“错误”；
	; - `function_name`：当前函数名，将改变“`dialog_title`”为“`dialog_title`（`function_name`）”，留空时不显示。
	; 实现参考：https://bitbucket.org/paclora_epo/snowbreak-helper/src/a6e8f9485a2750a274dfda607ee90f49f200f203/Quick%20Launch/prtl/UserInterface.ahk#lines-5 。
	static error_dialog(message_content := "", function_name := "", dialog_title := "") {
		full_title := (dialog_title  != "" ? dialog_title : "错误") .
		              (function_name == "" ? ""           : " at " function_name)
		full_message := (message_content != "" ? message_content : "未提供更多信息。") .
		                "`n`n——点击“确认”退出程序。"

		MsgBox(full_message, full_title, "IconX")
		ExitApp()
	} ; func error_dialog



	; 一组能发出哔声的简单函数。
	class beep {
		; 发出 G6 音调的哔声（近似于大写锁定按键被触发时的声调）。
		; **注意：此函数是同步的，阻塞时间同等于`duration`。**
		; - `duration`：声音持续的时长，单位为毫秒。
		; 详见：https://wyagd001.github.io/v2/docs/lib/SoundBeep.htm ，另见：https://learn.microsoft.com/zh-cn/windows/win32/api/utilapiset/nf-utilapiset-beep 。
		static g6(duration := 165) {
			SoundBeep(1568, duration)
		} ; func g6



		; 发出 G5 音调的哔声（近似于大写锁定按键被解除时的声调）。
		; **注意：此函数是同步的，阻塞时间同等于`duration`。**
		; - `duration`：声音持续的时长，单位为毫秒。
		; 详见：https://wyagd001.github.io/v2/docs/lib/SoundBeep.htm ，另见：https://learn.microsoft.com/zh-cn/windows/win32/api/utilapiset/nf-utilapiset-beep 。
		static g5(duration := 165) {
			SoundBeep(784, duration)
		} ; func g5
	} ; class beep



	; 使用默认方式打开网址。
	; 函数通过平台调用`Shell32.dll`中的`ShellExecute`（此处自动附带W）函数打开指定链接，出现错误时将弹出提示告知用户并将目标链接复制到用户剪切板。
	; 注意：无法预知用户浏览器本身的错误，如因文件缺失或损坏导致的“Couldn't load XPCOM.”等。
	; - `url`：目标链接，不能省略`http://`或`https://`头；
	; - 返回值：原生接口返回值，大于 32 时说明存在错误，否则为相关对应值。
	; 有关具体接口，详见：https://learn.microsoft.com/zh-cn/windows/win32/api/shellapi/nf-shellapi-shellexecutew 、https://learn.microsoft.com/zh-cn/windows/win32/api/winuser/nf-winuser-showwindow#parameters ；
	; 有关平台调用，详见：https://wyagd001.github.io/v2/docs/lib/DllCall.htm ，另见：https://learn.microsoft.com/en-us/windows/win32/winprog/windows-data-types 。
	static open_url(url, Self := dui) {
		res := DllCall("Shell32\ShellExecute",
			"Ptr", 0,      ; [in, optional] HWND      NULL
			"Str", "open", ; [in, optional] LPCWSTR
			"Str", url,    ; [in]           LPCWSTR
			"Ptr", 0,      ; [in, optional] LPCWSTR   NULL
			"Ptr", 0,      ; [in, optional] LPCWSTR   NULL
			"Int", 1,      ; [in]           INT       SW_NORMAL
			"Int"          ;                HINSTANCE
		)

		if res <= 32 {
			A_Clipboard := url
			Self.info_dialog(
				"未能打开链接（" res "）——`n"
				url "`n"
				"`n"
				"已经将它放入您的剪切板了。",
				A_ThisFunc
			)
		}

		return res
	} ; func open_url
} ; class UserInterface


; ---- ---- ---- ----   ---- ---- ---- ----   ---- ---- ---- ----   ---- ---- ---- ----


;@Ahk2Exe-IgnoreBegin
; 独立执行的单元测试。
try MAIN := MAIN
catch
{
	dui.info_dialog()
	dui.warning_dialog()
	dui.error_dialog()
	dui.info_dialog("此弹窗不应弹出。")
}
;@Ahk2Exe-IgnoreEnd

