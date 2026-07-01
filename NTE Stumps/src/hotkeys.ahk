; Copyright 2026 Paclora Corporation. Licensed under the Apache License, Version 2.0.

; 宏组热键。
; 包含热键及其宏的逻辑。


; ---- ---- ---- ----   ---- ---- ---- ----   ---- ---- ---- ----   ---- ---- ---- ----


#Requires AutoHotkey v2 ; 最低限制。


; ---- ---- ---- ----   ---- ---- ---- ----   ---- ---- ---- ----   ---- ---- ---- ----


; hotkeys.ahk\Hotkeys。
global hks := Hotkeys


; ---- ---- ---- ----   ---- ---- ---- ----   ---- ---- ---- ----   ---- ---- ---- ----


; 用作模块或命名空间：hks。
class Hotkeys {
	; 根据相关启用状态创建带有默认启用状态的热键。
	; 函数将自动应用`ACTIVE_TITLE_LIST`。
	static create(Self := hks) {
		for active_title in ACTIVE_TITLE_LIST {
			HotIfWinActive(active_title)

			; 因容许为空所以需要预先判断。
			if cfg.data.交互重复.映射按键.data != "" and cfg.data.交互重复.触发按键.data != "" {
				macro_rks := Self.macro.RepeatKeystrokeSingle(active_title, cfg.data.交互重复.触发按键.data, cfg.data.交互重复.映射按键.data)

				hotkey_rks_enable_state := cfg.data.交互重复.启用状态.data == true ? "On" : "Off"

				Hotkey(cfg.data.交互重复.映射按键.data, macro_rks, hotkey_rks_enable_state)

				macro_rks_call_up := ObjBindMethod(macro_rks, "CallUp")
				Hotkey(cfg.data.交互重复.映射按键.data " Up", macro_rks_call_up, hotkey_rks_enable_state)
			}

			; 列表自动支持空情形。
			for key_list in cfg.data.按键重复.按键列表.data {
				macro_rkm := Self.macro.RepeatKeystrokeMultiple(active_title, 1000 / 6.2)

				hotkey_rkm_enable_state := cfg.data.按键重复.启用状态.data == true ? "On" : "Off"

				for key_name in key_list {
					Hotkey(key_name, macro_rkm, hotkey_rkm_enable_state)

					macro_rkm_call_up := ObjBindMethod(macro_rkm, "CallUp", key_name)
					Hotkey(key_name " Up", macro_rkm_call_up, hotkey_rkm_enable_state)
				}
			}

			; 因容许为空所以需要预先判断。
			if cfg.data.杂项设置.全局按键.data != "" {
				macro_dktss := Self.macro.DoubleKeystrokeToSwitchSuspendState(cfg.data.杂项设置.全局按键.data)

				Hotkey("~" cfg.data.杂项设置.全局按键.data, macro_dktss, "S On") ; 穿透且豁免。

				macro_dktss_call_up := ObjBindMethod(macro_dktss, "CallUp")
				Hotkey("~" cfg.data.杂项设置.全局按键.data " Up", macro_dktss_call_up, "S On") ; 穿透且豁免。
			}
		}
		HotIfWinActive()
	} ; func create



	; 重新设置热键的启用状态。
	; 函数将自动应用`ACTIVE_TITLE_LIST`。
	; - `key_list`：要设置状态的按键列表；
	; - `enable_state`：要设置的状态，为`true`时设置为"On"，为`false`时设置为"Off"。
	static set_hotkeys_enable_state(key_list := [], enable_state := false) {
		for active_title in ACTIVE_TITLE_LIST {
			HotIfWinActive(active_title)

			for key_name in key_list {
				Hotkey(key_name, , enable_state == true ? "On" : "Off")
			}
		}
		HotIfWinActive()
	} ; func set_hotkeys_enable_state



	; 用于热键的宏。
	class macro {
		; 重复击键宏的基类。
		; **注意：此类仅作继承用途。**
		class RepeatKeystrokeBase {
			; 当前绑定热键所在变体的活动标题。
			active_title := ""



			; 按键重复的间隔。
			; 标示每次触发按键后再次触发时所要间隔的时间，单位是毫秒，无法小于 50（内部检查器间隔的 2 倍）。
			repeat_interval := 1000 / 6
			; 按键重复时的最大浮动倍率。
			; 决定每次触发按键间隔的随机浮动倍率，为`repeat_interval`的直接乘积，无法小于 0 且无法大于 0.5。
			; 该值仅被作为参考，无法因数值过大或过小引发按键抬按周期之间的重叠。
			floating_multiplier := 1 / 4



			; 创建类。
			; - `active_title`：要绑定的热键变体所指定的活动标题；
			; - `repeat_interval`：按键重复的间隔，单位是毫秒，可用范围是 50 ~ 50+；
			; - `floating_multiplier`：按键重复时的最大浮动倍率，为`repeat_interval`的直接乘积，可用范围是 0 ~ 0.5。
			__New(active_title, repeat_interval := 1000 / 6, floating_multiplier := 1 / 4) {
				this.active_title := active_title

				this.repeat_interval := Round(repeat_interval)

				this.floating_multiplier := floating_multiplier > 0.5 ? 0.5 : floating_multiplier < 0 ? 0 : floating_multiplier
			} ; func __New



			; `press_key_call`的绑定函数对象，绑定到此类的实例。
			; 有关绑定函数，请见：https://wyagd001.github.io/v2/docs/misc/Functor.htm#BoundFunc 。
			press_key_bind := ObjBindMethod(this, "press_key")

			; 触发和预定按键，作为`press_key`的源。
			press_key() {
				dui.error_dialog("未被覆盖。", A_ThisFunc, "内部错误")
			} ; func press_key



			; 获取下一次触发按键的间隔。
			; - 返回值：参照`repeat_interval`和`floating_multiplier`计算而出的随机数。
			get_the_next_press_interval() {
				; 浮动总值的一半，此处 / 2 是因后续随机需要平分此值才能保持基准。
				float := (this.repeat_interval * this.floating_multiplier) / 2

				return Round(Random(this.repeat_interval-float, this.repeat_interval+float))
			} ; func get_the_next_press_interval



			; 获取下一次释放按键的间隔（也就是释放当前按键的间隔）。
			; - `remaining`：可供按键释放的剩余时间（即计算后的距离下次击键的时间）；
			; - 返回值：参照`remaining`和`floating_multiplier`计算而出的随机数。
			get_the_next_release_interval(remaining) {
				; 剩余区间的二分之一处为释放时机的基准点。
				base := remaining / 2
				; 维持原浮动幅度，此处 / 2 是因后续随机需要平分此值才能保持基准。
				; 由于类内变量浮动倍率始终不超过 0.5，此处绝对不会产生重叠。
				float := (remaining * this.floating_multiplier) / 2

				return Round(Random(base-float, base+float))
			} ; func get_the_next_release_interval
		} ; class RepeatKeystrokeBase



		; 重复触发已按下按键的宏逻辑。
		; 此类为单个按键设计，保持按下时触发的第一个击键有更长延迟。
		; 实现参考：`RepeatKeystrokeMultiple`类和`DoubleKeystroke`类。
		class RepeatKeystrokeSingle extends Hotkeys.macro.RepeatKeystrokeBase {
			; 触发实例的按键。
			remap_key := ""
			; 实际模拟的按键。
			trigger_key := ""

			; 首次击键后的基准延迟。
			; 此处默认值为系统常见的默认设置。
			base_delay_of_first_keystroke := 500



			; 创建类。
			; - `active_title`：要绑定的热键变体所指定的活动标题；
			; - `trigger_key`：所要触发的按键名。
			; - `remap_key`：触发实例的无状态按键名。
			; - `repeat_interval`：按键重复的间隔，单位是毫秒，可用范围是 50 ~ 50+；
			; - `floating_multiplier`：按键重复时的最大浮动倍率，为`repeat_interval`的直接乘积，可用范围是 0 ~ 0.5。
			__New(active_title, trigger_key, remap_key, repeat_interval := 1000 / 6, floating_multiplier := 1 / 4) {
				super.__New(active_title, repeat_interval, floating_multiplier)

				this.trigger_key := trigger_key
				this.remap_key := remap_key

				this.base_delay_of_first_keystroke := this.calculate_base_delay_of_first_keystroke()
			} ; func __New



			; 计算首次击键后的基准延迟，参照系统设定的键盘字符重复延迟的 0.65 倍。
			; - 返回值：按倍率返回系统返回值，失败时返回 325。
			; 有关具体接口，请见：https://learn.microsoft.com/zh-cn/windows/win32/api/winuser/nf-winuser-systemparametersinfow 。
			calculate_base_delay_of_first_keystroke() {
				res := 1
				DllCall("SystemParametersInfo",
					"UInt", 0x0016, ; [in]      UINT  uiAction,
					"UInt", 0,      ; [in]      UINT  uiParam,
					"UInt*", &res,  ; [in, out] PVOID pvParam,
					"UInt", 0,      ; [in]      UINT  fWinIni
					"Int"           ;           BOOL
				)

				; 返回值为 0、1、2、3，0 为 250，3 为 1000。
				return Round(((res + 1) * 250) * 0.65)
			} ; func calculate_base_delay_of_first_keystroke



			; 缓存标志，标示是否应当阻止按键传入。
			key_block := false

			; 缓存标志，记录了首个传入的按键名。
			first_key := ""



			; 外部按键传入——
			; 函数会根据实例创建时的按键名来过滤来自系统的自动重复击键；
			; 如果有不同于初次触发的按键传入，函数会立即显示错误消息提示框；
			; 函数通过计时器来重复触发击键，并通过计算浮动间隔来使得击键不那么整齐。
			; 每次按键按下的第一次击键都拥有更长延迟，以防止意外重复击键；
			; 按键每次抬起时，持续计时器也随即停止，函数不再活动。
			; - `key_name_from_call`：自然传入的按键名。
			; 有关计时调用，详见：https://wyagd001.github.io/v2/docs/lib/SetTimer.htm 。
			Call(key_name_from_call) {
				; 此处阻止标记随绑定按键的按下而生效并随释放而取消，
				; 也就是说，只要绑定按键正被按下就不接受任何按键，这是为了避免接受来自系统的自动重复击键。
				if this.key_block == true {
					return
				}

				; 若传入的按键与初次按键不同，要检查是否是第一次传入，如果不是则弹出错误提示，这是为了避免宏被绑定到多个按键上。
				if key_name_from_call != this.first_key {
					if this.first_key == "" {
						this.first_key := key_name_from_call
					} else {
						dui.error_dialog("该宏不能传入多个按键。", A_ThisFunc, "内部错误")
					}
				}

				; 执行到此处说明按键无误，开启阻塞标记。
				this.key_block := true

				; 判断击键条件并视情况立即触发并订阅下次击键。这是为了立刻响应新的击键而不是等到下一次订阅再触发。
				; 此处传入指示可使其拥有特殊延迟，行为类似 Windows 默认的自动重复击键，但延迟更短。
				this.press_key(true)
			} ; func Call



			; 立即停止当前订阅，如果`remap_key`正被按下，发送按下`trigger_key`并订阅抬起其的计时器。
			; 此处击键和抬起的时机包含一定程度的浮动，将使得击键序列不那么整齐。
			; - `is_first_keystroke`：指示函数是否为第一次击键（也就是物理按下的那次击键）。
			press_key(is_first_keystroke := false) {
				; 立即停止留存的订阅，防止旧按键订阅被如期触发。
				SetTimer(this.press_key_bind, 0)

				; 挂起时不应触发，这是为了避免在重复期间触发的挂起被忽视；
				; 未处于当前热键变体的窗口时不应触发，这是为了避免在重复期间的切换窗口仍持续重复。
				; 以上两种情况由于缺失了后续热键的触发条件，一旦放行则没有机会触发停止。
				; 此外，GetKeyState 为最后的保障，尽管可能不够可靠。
				; 有关窗口活动，详见：https://wyagd001.github.io/v2/docs/lib/WinActive.htm 。
				if A_IsSuspended == 1 or WinActive(this.active_title) == 0 or GetKeyState(this.remap_key, "P") == 0 {
					this.reset_status()
					return
				}

				; 立即发送按键。
				Send("{" this.trigger_key " Down}")

				; 计算下一次击键和本次释放的间隔。
				next_press_interval := this.get_the_next_press_interval()
				next_release_interval := this.get_the_next_release_interval(next_press_interval)

				; 订阅一次释放，不做任任何管理。
				; 这是考虑到不同按键之间有重叠比较正常，而因主动触发较快导致的重叠也不应该忽略抬起。
				SetTimer((*) => Send("{" this.trigger_key " Up}"), - next_release_interval)

				; 按需订阅一次滚轮，不做任任何管理。
				; 滚轮不会在第一次击键之后附加，这是为了保持首次击键的纯粹。
				; 目前此行为还不够仿真，因为没有人会在高速击键期间每次都精准地滚一次轮。
				if cfg.data.交互重复.附加滚轮.data == true and is_first_keystroke == false {
					; `get_the_next_release_interval`函数刚好可以计算出类似的间隔。嗯，屎山 +1 了。
					next_scroll_interval := this.get_the_next_release_interval(next_press_interval)
					SetTimer((*) => Send("{WheelDown}"), - next_scroll_interval)
				;	ToolTip(Format("Pt {:03}`nRt {:03}`nSt {:03}", next_press_interval, next_release_interval, next_scroll_interval))
				}

				; 如果为第一次击键，使其拥有特殊延迟。
				; 延迟到此处重新计算是为了让上方的两个一次性订阅能够与后续击键的延迟保持在同一基准上，
				; 尽管这样似乎不够拟真了，但更符合最初的设计。
				if is_first_keystroke == true {
					next_press_interval := this.get_the_first_press_delay()
				;	ToolTip(Format("Pt {:03}`nRt {:03}", next_press_interval, next_release_interval))
				}

				; 订阅下一次击键，只运行一次。这是为了避免意外的无限重复触发。
				SetTimer(this.press_key_bind, - next_press_interval)
			} ; func press_key



			; 外部按键传入——
			; 告知宏实例相关的按键已经放开并需要重置宏的状态。如果传入的按键确实为当前按键，立即重置宏的状态。
			CallUp(*) {
				this.reset_status()
			} ; func CallUp



			; 将宏实例重置到相当于没有任何按键按下时的状态，但不包含需要在多次之间记住的独立标记。
			; 每次试图重置宏状态时都应该调用此函数。
			reset_status() {
				this.key_block := false
			} ; func reset_status



			; 获取第一次触发按键后的延迟。
			; - 返回值：参照`base_delay_of_first_keystroke`和`floating_multiplier`计算而出的随机数。
			get_the_first_press_delay() {
				; 浮动总值的一半，此处 / 2 是因后续随机需要平分此值才能保持基准。
				float := (this.base_delay_of_first_keystroke * this.floating_multiplier) / 2

				return Round(Random(this.base_delay_of_first_keystroke-float, this.base_delay_of_first_keystroke+float))
			} ; func get_the_first_press_delay
		} ; class RepeatKeystrokeSingle



		; 重复触发已按下按键的宏逻辑。
		; 此类为多个按键设计，不同按键之间不会争抢，若要同时触发请创建新的实例。
		; 注意：此宏的实例必须额外绑定`CallUp`方法。
		; 实现参考：https://bitbucket.org/paclora_epo/3oostumps/src/fb6b63869c04e6e1ccdf038bf947447eee4e966c/%E6%BA%90%E7%A0%81/3ooStumps/.PARTIAL/MacroLogic.ahk#lines-192 。
		class RepeatKeystrokeMultiple extends Hotkeys.macro.RepeatKeystrokeBase {
			; 缓存标志，记录当前正使用的按键名。
			current_key := ""



			; 外部按键传入——
			; 函数会记录当前传入的按键，并据此识别和过滤掉来自系统的自动重复击键；
			; 函数通过计时器来重复触发击键，并通过计算浮动间隔来使得击键不那么整齐。
			; 新按键传入时，函数将立刻停止旧的击键计划并立即响应新的击键；
			; 当最后一个触发函数的按键抬起，持续计时器随即停止，函数不再活动。
			; - `key_name_from_call`：自然传入的按键名。
			; 有关计时调用，详见：https://wyagd001.github.io/v2/docs/lib/SetTimer.htm 。
			Call(key_name_from_call) {
				; 此类被设计为供多个按键绑定，因此需要注意每次调用都会启动一个当前函数的模拟线程。
				; 按键传入，可能是第一次触发，也可能是因持续按下而导致的自动连续击键（游戏中一般不会这样），还可能是绑定的其它按键以及其后续可能的自动连续击键。
				; 该宏通过一个简单的类内变量来指示当前实际使用的按键和控制是否应当过滤当前按键，而具体的击键的订阅是由其内部自动管理的。

				; 如果两值相等，必定是来自系统的自动重复击键，拒绝执行后续逻辑。
				; 这里之所以能如此判断，是因为当前按键默认为空，与传入按键不同时会立刻赋值，因此除非是传入了新按键，否则一定是来自系统的自动重复击键。
				; 一旦当前按键被物理抬起，当前按键的值会被置空，届时任何传入的按键都不会被判定为一致（也就意味着是物理击键），至此开始新一轮的赋值逻辑。
				if this.current_key == key_name_from_call {
					return
				}

				; 由于传入的按键随时可能变化，而宏整体又有异步时间性过程，此处立即共享到类内变量供该函数的所有线程使用。
				; 注意：此赋值意味着当前按键正被上方逻辑过滤。
				this.current_key := key_name_from_call

				; 判断击键条件并视情况立即触发并订阅下次击键。这是为了立刻响应新的击键而不是等到下一次订阅再触发。
				; 由于新按键会在当前按键还未释放时顶替为当前按键，所以必须停止旧的击键订阅。
				this.press_key()
			} ; func Call



			; 立即停止当前订阅，如果`current_key`正被按下，发送按下`current_key`并订阅抬起其的计时器。
			; 此处击键和抬起的时机包含一定程度的浮动，将使得击键序列不那么整齐。
			; 注意：此抬起的按键在内部被缓存，因此不受`current_key`变化的影响。
			press_key() {
				; 立即停止留存的订阅，防止被顶替的旧按键订阅被如期触发。
				SetTimer(this.press_key_bind, 0)

				; 挂起时不应触发，这是为了避免在重复期间触发的挂起被忽视；
				; 未处于当前热键变体的窗口时不应触发，这是为了避免在重复期间的切换窗口仍持续重复。
				; 以上两种情况由于缺失了后续热键的触发条件，一旦放行则没有机会触发停止。
				; 此外，GetKeyState 为最后的保障，尽管可能不够可靠。`current_key`为空时说明实例已被重置，此时无法判断按键状态。
				; 有关窗口活动，详见：https://wyagd001.github.io/v2/docs/lib/WinActive.htm 。
				if A_IsSuspended == 1 or WinActive(this.active_title) == 0 or this.current_key == "" or GetKeyState(this.current_key, "P") == 0 {
					this.reset_status()
					return
				}

				; 立刻缓存按键，因为后续可能存在有延迟的发送。
				current_key := this.current_key

				; 立即发送按键。
				Send("{" current_key " Down}")

				; 计算下一次击键和本次释放的间隔。
				next_press_interval := this.get_the_next_press_interval()
				next_release_interval := this.get_the_next_release_interval(next_press_interval)
			;	ToolTip(Format("Pt {:03}`nRt {:03}", next_press_interval, next_release_interval))

				; 订阅一次释放，不做任任何管理。
				; 这是考虑到不同按键之间有重叠比较正常，并且因主动触发较快而导致的重叠也不应忽略抬起。
				SetTimer((*) => Send("{" current_key " Up}"), - next_release_interval)

				; 订阅下一次击键，只运行一次。这是为了避免意外的无限重复触发。
				SetTimer(this.press_key_bind, - next_press_interval)
			} ; func press_key



			; 外部按键传入——
			; 告知宏实例相关的按键已经放开并需要重置宏的状态。如果传入的按键确实为当前按键，立即重置宏的状态。
			; 注意：此函数不接受自然按键传入。
			; - `key_name_from_bind_call`：触发此调用的无状态按键名。
			CallUp(key_name_from_bind_call, *) {
				if key_name_from_bind_call == this.current_key {
					this.reset_status()
				}
			} ; func CallUp



			; 将宏实例重置到相当于没有任何按键按下时的状态，但不包含需要在多次之间记住的独立标记。
			; 每次试图重置宏状态时都应该调用此函数。
			reset_status() {
				this.current_key := ""
			} ; func reset_status
		} ; class RepeatKeystrokeMultiple



		; 在一定时间内连续击键两次便可触发宏逻辑。
		; 此类被设计为不影响按键的原有功能，因此必须绑定腭化按键，除非不需要按键的原有功能。
		; 注意：不能将此类的实例绑定给多个按键；此宏的实例必须额外绑定`CallUp`方法。
		; 有关腭化按键，请见：https://wyagd001.github.io/v2/docs/Hotkeys.htm#Tilde 。
		class DoubleKeystroke {
			; 宏所绑定的按键名。
			bound_key_name := ""

			; 两次连续击键的容许范围。
			; 有关系统默认，详见：https://learn.microsoft.com/zh-cn/windows/win32/api/winuser/nf-winuser-setdoubleclicktime 。
			trigger_range := 500



			; 创建类。
			; - `key_name`：触发实例的无状态按键名。
			__New(key_name) {
				this.bound_key_name := key_name
				this.trigger_range := this.calculate_trigger_range_from_system_double_click_time(this.trigger_range)
			} ; func __New



			; 计算两次连续击键的容许范围，参照系统设定的鼠标双击间隔的 1.15 倍。
			; - `default_value`：失败时所用的默认值；
			; - 返回值：按倍率返回系统返回值，失败时返回`default_value`。
			; 有关具体接口，请见：https://learn.microsoft.com/zh-cn/windows/win32/api/winuser/nf-winuser-getdoubleclicktime 。
			calculate_trigger_range_from_system_double_click_time(default_value) {
				call_res := DllCall("GetDoubleClickTime", "Int")
				return Round((call_res == 0 ? default_value : call_res) * 1.15)
			} ; func calculate_trigger_range_from_system_double_click_time



			; 缓存标志，标示是否应当阻止按键传入。
			key_block := false
			; 缓存标志，标示是否已经准备好接受第二次击键。
			key_flag := false

			; 缓存标志，记录了首个传入的按键名。
			first_key := ""



			; 外部按键传入——
			; 函数会根据实例创建时的按键名来过滤来自系统的自动重复击键；
			; 如果有不同于初次触发的按键传入，函数会立即显示错误消息提示框。
			; 在函数被触发后的一段时间内，再次触发即可执行具体宏逻辑。
			; 有关计时调用，详见：https://wyagd001.github.io/v2/docs/lib/SetTimer.htm 。
			Call(key_name_from_call) {
				; 此处阻止标记随绑定按键的按下而生效并随释放而取消，
				; 也就是说，只要绑定按键正被按下就不接受任何按键，这是为了避免接受来自系统的自动重复击键。
				if this.key_block == true {
					return
				}

				; 若传入的按键与初次按键不同，要检查是否是第一次传入，如果不是则弹出错误提示，这是为了避免宏被绑定到多个按键上。
				if key_name_from_call != this.first_key {
					if this.first_key == "" {
						this.first_key := key_name_from_call
					} else {
						dui.error_dialog("该宏不能传入多个按键。", A_ThisFunc, "内部错误")
					}
				}

				; 执行到此处，说明按键无误，开启阻塞标记。
				this.key_block := true

				; 此处判断双击状态——
				if this.key_flag == false {
					; 如果尚未进行第一次击键，标记一次并定时清除一次；
					this.key_flag := true
					SetTimer(this.clear_flag_bind, - this.trigger_range)
				} else {
					; 否则，这里应当处于容许范围内（也就是上方计时器还未清除标记），
					; 立即停止计时器并清除按键标记（也就是将倒计时提前到此刻触发，否则可能会把下次击键视为第二次），
					; 然后执行宏逻辑。
					SetTimer(this.clear_flag_bind, 0)
					this.clear_flag()
					; 如果此处的行为较为耗时，会出现相应时间的无响应情况。
					this.macro_logic()
				}
			} ; func Call



			; 要触发的宏逻辑，必须重新实现。
			macro_logic() {
				dui.error_dialog("未被覆盖。", A_ThisFunc, "内部错误")
			} ; func macro_logic



			; `clear_flag`的绑定函数对象，绑定到此类的实例。
			clear_flag_bind := ObjBindMethod(this, "clear_flag")

			; 清除缓存标志`key_flag`，作为`clear_flag`的源。
			clear_flag() {
				this.key_flag := false
			} ; func clear_flag



			; 外部按键传入——
			; 告知宏实例相关的按键已经放开并需要重置宏的状态。
			CallUp(*) {
				this.reset_status()
			} ; func CallUp



			; 将宏实例重置到相当于没有任何按键按下时的状态，但不包含需要在多次之间记住的独立标记。
			; 每次试图重置宏状态时都应该调用此函数。
			reset_status() {
				this.key_block := false
			} ; func reset_status
		} ; class DoubleKeyPress



		; 在一定时间内连续击键两次便可挂起所有热键（也就是调用了`tra.cal.全局功能启用状态`），同时还将根据具体状态播放一声短促的声音。
		; 此类建议绑定腭化按键，详见`hks.macro.DoubleKeystroke`的说明。
		class DoubleKeystrokeToSwitchSuspendState extends Hotkeys.macro.DoubleKeystroke {
			; 重新实现的宏逻辑，将调用`tra.cal.全局功能启用状态`，如果触发结果为启用则发出 G6 哔声，为挂起则发出 G5 哔声。
			; 注意：此函数在系统层面是阻塞的，因此可能会影响连续击键的流程度，比如在连续四次击键时可能无法连续响应两次逻辑，而需要在听到声音时停止一些时间。
			macro_logic() {
				tra.cal.全局功能启用状态()
				if A_IsSuspended == false {
					dui.beep.g6()
				} else {
					dui.beep.g5()
				}
			} ; func macro_logic
		} ; class DoubleKeystrokeToSwitchSuspendState
	} ; class macro
} ; class Hotkeys

