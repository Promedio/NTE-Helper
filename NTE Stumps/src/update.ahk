; Copyright 2026 Paclora Corporation. Licensed under the Apache License, Version 2.0.

; 更新检查。
; 包含检查自身更新的功能。


; ---- ---- ---- ----   ---- ---- ---- ----   ---- ---- ---- ----   ---- ---- ---- ----


#Requires AutoHotkey v2.0.0+ ; 最低限制。


; ---- ---- ---- ----   ---- ---- ---- ----   ---- ---- ---- ----   ---- ---- ---- ----


class Update {
	; 执行一次请求，判别当前项目是否有云端更新。
	; **注意：这是一个耗时函数。**
	; - `timeout`：请求全程的最大等待时间（单位为秒）；
	; - `assumed_local_version`：假定本地版本号，若给定可覆盖本地版本号；
	; - 返回值：有更新时返回`true`，其它情况返回`false`。
	static has_update(timeout, assumed_local_version := "", Self := Update) {
		finres := false

		local_version := Self.get_local_version()
		if assumed_local_version != "" {
			local_version := assumed_local_version
			OutputDebug(A_ThisFunc . "：已假定本地版本号为：" . assumed_local_version . "。`n")
		}
		if local_version == "" {
			OutputDebug(A_ThisFunc . "：未能取到本地版本号。`n")
			goto FINRES
		}

		cloud_version := Self.get_cloud_version(timeout)
		if cloud_version == "" {
			OutputDebug(A_ThisFunc . "：未能取到云端版本号。`n")
			goto FINRES
		}

		switch Self.compare_version(local_version, cloud_version) {
			case 1:
			finres := true
			OutputDebug(A_ThisFunc . "：检查到新版本：" . cloud_version . "。`n")

			case 0:
			finres := false
			OutputDebug(A_ThisFunc . "：没有更新版本。`n")

			case -1:
			finres := false
			OutputDebug(A_ThisFunc . "：本地版本更新。`n")

			default:
			finres := false
			OutputDebug(A_ThisFunc . "：意外更新分支。`n")
		}


		FINRES:
		return finres
	} ; func has_update



	; 对比两端版本号。
	; **注意：此函数不提供保证。**
	; - `current_version`：要对比的当前版本号；
	; - `latest_version`：要对比的最新版本号；
	; - 返回值：最新更大时返回`1`，两者相等时返回`0`，当前更大是返回`-1`，尚不确定是否可以出错。
	; 有关版本对比，详见：https://wyagd001.github.io/v2/docs/lib/VerCompare.htm 。
	static compare_version(current_version, latest_version) {
		compared_result := VerCompare(current_version, latest_version)

		; 最新版本更大，表示云端有更新。
		if compared_result < 0 {
			return 1
		}
		; 两者相等，表示没有更新。
		if compared_result == 0 {
			return 0
		}
		; 当前版本更大，表示本地正在使用体验版。
		if compared_result > 0 {
			return -1
		}
	} ; func compare_version



	; 获取自身项目在本地的版本号。
	; - 返回值：字符串形式的版本号，请求或解析失败时返回空字符串。
	; 有关文件版本，详见：https://wyagd001.github.io/v2/docs/lib/FileGetVersion.htm 。
	static get_local_version() {
		finres := ""

		try {
			finres := FileGetVersion(A_ScriptFullPath)
		}

		return finres
	} ; func get_local_version



	; 获取自身项目在云端的版本号。
	; **注意：这是一个耗时函数。**
	; - `timeout`：请求全程的最大等待时间（单位为秒）；
	; - 返回值：字符串形式的版本号，请求或解析失败时返回空字符串。
	static get_cloud_version(timeout, Self := Update) {
		finres := ""

		requested_content := Self.request_api_to_string("https://api.bitbucket.org/2.0/repositories/paclora_epo/nte-helper/src/dom/VERSION", timeout)
		if requested_content == "" {
			goto FINRES
		}

		finres := Self.parse_version_api_content(requested_content)

		FINRES:
		return finres
	} ; func get_cloud_version



	; 解析 VERSION 文件 API 的内容，取出自身项目在云端的最新版本号。
	; - `requested_content`：要解析的内容；
	; - 返回值：字符串形式的版本号，解析失败时返回空字符串。
	; 语法参考：https://wyagd001.github.io/v2/docs/lib/LoopParse.htm#ExFileRead 。
	static parse_version_api_content(requested_content) {
		finres := ""

		; 按换行符拆分成行处理。
		loop parse requested_content, "`n", "`r" {
			; 按空格拆分单行成组。
			single_line_content := []
			loop parse A_LoopField, " " {
				single_line_content.Push(A_LoopField)
			}

			; 每行至少要有 2 个元素。
			if single_line_content.Length <= 1 {
				continue
			}

			; 每行的第一个元素是项目标识符，第二个元素是具体是版本号，后续均为注释（使用前需插回空格）。
			if single_line_content.Get(1) != "019dd8f1-f5a6-750a-848a-12a5e4f9d3c5" {
				continue
			} else {
				finres := single_line_content.Get(2)
			}
		}

		return finres
	} ; func parse_version_api_content



	; 请求给定的 API 为字符串。
	; **注意：这是一个耗时函数。**
	; - `api_link`：HTTP 或 HTTPS 链接；
	; - `timeout`：请求全程的最大等待时间（单位为秒）；
	; - 返回值：字符串形式的返回内容，请求失败时返回空字符串。
	; 有关网络请求，详见：https://wyagd001.github.io/v2/docs/lib/Download.htm#ExWHR ，另见：https://learn.microsoft.com/zh-cn/windows/win32/winhttp/winhttprequest 。
	; 实现参考：https://bitbucket.org/paclora_epo/snowbreak-helper/src/a6e8f9485a2750a274dfda607ee90f49f200f203/Quick%20Launch/prtl/NetworkRequest.ahk#lines-7 。
	static request_api_to_string(api_link, timeout := -1) {
		finres := ""

		Sender := ComObject("WinHttp.WinHttpRequest.5.1")
		Sender.Open("GET", api_link, true)
		Sender.Send()

		try {
			Sender.WaitForResponse(timeout)
			finres := Sender.ResponseText
		}

		return finres
	} ; func request_api_to_string
} ; class Update

