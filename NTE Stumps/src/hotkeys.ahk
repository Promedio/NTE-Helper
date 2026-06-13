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

			macro_rk_1 := Self.macro.RepeatKeystrokeSingle()
			hotkey_rk_1_enable_state := cfg.data.交互重复.启用状态.data == true ? "On" : "Off"
			Hotkey(cfg.data.交互重复.映射按键.data, macro_rk_1, hotkey_rk_1_enable_state)

			for key_list in cfg.data.按键重复.按键列表.data {
				macro_rk_2 := Self.macro.RepeatKeystrokeMultiple(1000 / 6.2)
				hotkey_rk_2_enable_state := cfg.data.按键重复.启用状态.data == true ? "On" : "Off"
				for key_name in key_list {
					Hotkey(key_name, macro_rk_2, hotkey_rk_2_enable_state)
				}
			}

			macro_dktss_1 := Self.macro.DoubleKeystrokeToSwitchSuspendState()
			Hotkey("~" cfg.data.杂项设置.全局按键.data, macro_dktss_1, "S") ; 穿透且豁免。
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
		; 
		; https://gemini.google.com/app/ee6ba2e285ca6eaa
		; https://learn.microsoft.com/zh-cn/windows/win32/api/winuser/nf-winuser-systemparametersinfow
		class RepeatKeystrokeSingle {
			Call(*) {

			}
		} ; class RepeatKeystrokeSingle



		; 重复触发已按下按键的宏逻辑。
		; 此类为多个按键设计，不同按键之间不会争强，若要同时触发请创建新的实例。
		; 实现参考：https://bitbucket.org/paclora_epo/3oostumps/src/fb6b63869c04e6e1ccdf038bf947447eee4e966c/%E6%BA%90%E7%A0%81/3ooStumps/.PARTIAL/MacroLogic.ahk#lines-192 。
		class RepeatKeystrokeMultiple {
			; 内部检查器的重复间隔。
			tick_interval := Round(1000 / 40)

			; 按键重复的间隔。
			; 标示每次触发按键后再次触发时所要间隔的时间，单位是毫秒，无法小于 50（内部检查器间隔的 2 倍）。
			repeat_interval := 1000 / 6
			; 按键重复时的最大浮动倍率。
			; 决定每次触发按键间隔的随机浮动倍率，为`repeat_interval`的直接乘积，无法小于 0 且无法大于 0.5。
			; 该值仅被作为参考，无法因数值过大或过小引发按键抬按周期之间的重叠。
			floating_multiplier := 1 / 4



			; 创建类。
			; - `repeat_interval`：按键重复的间隔，单位是毫秒，可用范围是 50 ~ 50+；
			; - `floating_multiplier`：按键重复时的最大浮动倍率，为`repeat_interval`的直接乘积，可用范围是 0 ~ 0.5。
			__New(repeat_interval := 1000 / 6, floating_multiplier := 1 / 4) {
				tick_interval_multiple := this.tick_interval * 2
				this.repeat_interval := repeat_interval < tick_interval_multiple ? tick_interval_multiple : Round(repeat_interval)

				this.floating_multiplier := floating_multiplier > 0.5 ? 0.5 : floating_multiplier < 0 ? 0 : floating_multiplier
			} ; func __New



			; 缓存标志，记录上一个使用的按键名。
			previous_key := ""
			; 缓存标志，记录当前正使用的按键名。
			current_key := ""



			; 外部按键传入——
			; 函数会记录至多两个传入的历史按键，并根据此识别和过滤掉来自系统的自动重复击键；
			; 函数通过计时器来重复触发击键，并通过计算浮动间隔来使得击键不那么整齐。
			; 新按键传入时，函数将立刻停止旧的击键计划并立即响应新击键；
			; 当最后一个触发函数的按键抬起，所有计时器都立刻停止，函数不再活动。
			; 有关计时调用，详见：https://wyagd001.github.io/v2/docs/lib/SetTimer.htm 。
			Call(key_name_from_call) {
				; 此类被设计为供多个按键绑定，因此需要注意每次调用都会启动一个当前函数的模拟线程。
				; 按键传入，可能是第一次触发，也可能是因持续按下而导致的自动连续击键（游戏中一般不会这样），还可能是绑定的其它按键以及其后续可能的连续击键。
				; 该宏通过两个简单的类内变量来区分和处理真实击键，并用一个快速计时器来控制所有订阅。
				; 此宏逻辑设计于2022年末，并于2023年二季度完成改进，此处为旧函数的复刻。

				; 此两变量为简易队列，每次调用都立即储存传入的按键。
				this.previous_key := this.current_key
				; 由于传入的按键随时可能变化，而宏整体又有异步时间性过程，此处立即共享到类内变量供该函数的所有线程使用。
				this.current_key := key_name_from_call

				; 如果两值相等，必定是来自系统的自动重复击键，拒绝执行后续立即。
				; 这里之所以能如此判断，是因为函数开头先备份了当前按键到先前按键，而后续逻辑中，在当前按键释放时，
				; 当前按键的变量内容会被重置，又因为函数第一行先执行备份，空值自然流动至先前按键，故当前按键永远不可能为空。
				if (this.current_key == this.previous_key) {
					return
				}

				; 开始订阅或重新订阅计时器（以每秒 40 次的速率）。
				; 此计时器会持续检测当前按键的按下状态，由于当前按键可能变化，故始终检查的是最后一个触发此函数的按键，
				; 当前按键一旦抬起，此计时器将停止所有订阅（也就是自身和按键重复的计时器），并置空当前按键，
				; 由于函数第一行先执行备份，空值自然流动至先前按键，故此处检测的永远是新传入而顶替为当前按键的有效按键。
				SetTimer(this.monitor_key, 1000 / 40)

				; 停止正在执行的计时器订阅。
				; 由于新按键会在当前按键还未释放时顶替为当前按键（也就是队列更迭了），所以必须停止旧的击键订阅。
				SetTimer(this.press_key, 0)
				; 接着立即触发击键，其中订阅了下次击键。这样设计是因为必须立刻响应新的击键，而不是等待下一次订阅再触发击键。
				this.press_key_call()
			} ; func Call



			; `press_key_call`的绑定函数对象，绑定到此类的实例。
			; 有关绑定函数，请见：https://wyagd001.github.io/v2/docs/misc/Functor.htm#BoundFunc 。
			press_key := ObjBindMethod(this, "press_key_call")



			; 触发和预定按键，作为`press_key`的源。
			; 立即按下`current_key`，订阅一次抬起当前按键的计时器并同时订阅重复触发此函数的计时器。
			; 此处击键和抬起的时机包含一定程度的浮动，将使得击键序列不那么整齐。
			; 注意：此抬起的按键在内部被缓存，因此不受`current_key`变化的影响。
			press_key_call() {
				Send("{" this.current_key " Down}")

				; 立刻缓存已发送的按键供释放使用。
				current_key := this.current_key

				next_press_interval := this.get_the_next_press_interval()
				next_release_interval := this.get_the_next_release_interval(next_press_interval)
			;	ToolTip(Format("Pt {:03}`nRt {:03}", next_press_interval, next_release_interval))

				; 订阅一次释放，不做任任何管理。不同按键直接的释放重叠是极为正常的。
				SetTimer((*) => Send("{" current_key " Up}"), - next_release_interval)

				; 订阅下一次击键。此处可以不用负数，因为此订阅受持续计时器管理。
				SetTimer(this.press_key, - next_press_interval)
			} ; func press_key_call



			; `monitor_key_Call`的绑定函数对象，绑定到此类的实例。
			; 有关绑定函数，请见：https://wyagd001.github.io/v2/docs/misc/Functor.htm#BoundFunc 。
			monitor_key := ObjBindMethod(this, "monitor_key_Call") ; 间接绑定.



			; 监控和清除预定，作为`monitor_key`的源。
			; 持续检测`current_key`的按下状态，按键抬起时停止所有计时器并置空`current_key`。
			; 注意：`current_key`随时可能改变，因此计时器始终检测最后传入的按键；置空`current_key`是为了其能在下次传入新按键时自然流动给`previous_key`。
			monitor_key_call() {
				if (GetKeyState(this.current_key, "P") == false) {
					SetTimer(this.press_key, 0)
					SetTimer(this.monitor_key, 0)

					this.current_key := ""
				}
			} ; func monitor_key_call



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
		} ; class RepeatKeystrokeMultiple



		; 在一定时间内连续击键两次便可触发宏逻辑。
		; 此类被设计为不影响按键的原有功能，因此必须绑定腭化按键，除非不需要按键的原有功能。
		; 注意：不建议将此类的实例绑定给多个按键，如果绑定的按键中带有控制键，则可能在某些快速击键中被意外触发（测试的按键是RShift和RCtrl，快速轮替时经常无法正常交替触发）。
		; 有关腭化按键，请见：https://wyagd001.github.io/v2/docs/Hotkeys.htm#Tilde 。
		class DoubleKeystroke {
			; 两次连续击键的容许范围。
			; 有关系统默认，详见：https://learn.microsoft.com/zh-cn/windows/win32/api/winuser/nf-winuser-setdoubleclicktime 。
			trigger_range := 500



			; 创建类。
			; 此类无需提供具体按键名，因未设计原键触发或异键宏逻辑，传入的按键即是触发的按键，因此必须绑定腭化按键，除非不需要按键的原有功能。
			; 有关腭化按键，请见：https://wyagd001.github.io/v2/docs/Hotkeys.htm#Tilde 。
			__New() {
				this.trigger_range := this.calculate_trigger_range_from_system_double_click_time(this.trigger_range)
			} ; func __New



			; 计算两次连续击键的容许范围，参照系统设定的鼠标双击间隔的 1.15 倍。
			; - `default_value`：失败时所用的默认值；
			; - 返回值：按倍率返回系统返回值，失败时返回`default_value`。
			; 有关具体接口，请见：https://learn.microsoft.com/zh-cn/windows/win32/api/winuser/nf-winuser-getdoubleclicktime 。
			calculate_trigger_range_from_system_double_click_time(default_value) {
				call_res := DllCall("GetDoubleClickTime", "Int")
				return (call_res == 0 ? default_value : call_res) * 1.15
			} ; func calculate_trigger_range_from_system_double_click_time



			; 缓存标志，记录上一个传入的按键名。
			previous_key := ""



			; 外部按键传入——
			; 如果当前按键名与前次按键名不同，储存此名为前次按键名，然后创建一个计时器，在一定倒计时后清除前次按键名；
			; 如果当前按键名与前次按键名相同，立即停止相关计时器，然后清除前次按键名，最后执行宏逻辑。
			; 也就是说，一个新按键的传入会开始一次倒计时，倒计时内如果是传入了相同的按键，则触发宏逻辑并停止计时器，否则被视为新按键。
			; 有关计时调用，详见：https://wyagd001.github.io/v2/docs/lib/SetTimer.htm 。
			Call(key_name_from_call) {
				if this.previous_key != key_name_from_call {
					this.previous_key := key_name_from_call
					SetTimer(this.clear_flag, - this.trigger_range)
				} else {
					SetTimer(this.clear_flag, 0)
					this.previous_key := ""
					this.macro_logic()
				}
			} ; func Call



			; 要触发的宏逻辑，必须重新实现。
			macro_logic() {
				dui.error_dialog("未被覆盖。", A_ThisFunc, "内部错误")
			} ; func macro_logic



			; `clear_flag_call`的绑定函数对象，绑定到此类的实例。
			; 有关绑定函数，请见：https://wyagd001.github.io/v2/docs/misc/Functor.htm#BoundFunc 。
			clear_flag := ObjBindMethod(this, "clear_flag_call")



			; 清除缓存标志，作为`clear_flag`的源。
			clear_flag_call() {
				this.previous_key := ""
			} ; func clear_flag_call
		} ; class DoubleKeyPress



		; 在一定时间内连续击键两次便可挂起所有热键（也就是调用了`tra.cal.全局功能启用状态`），同时还将根据具体状态播放一声短促的声音。
		; 此类必须绑定腭化按键，详见`hks.macro.DoubleKeystroke`的说明。
		class DoubleKeystrokeToSwitchSuspendState extends Hotkeys.macro.DoubleKeystroke {
			; 重新实现的宏逻辑，将调用`tra.cal.全局功能启用状态`，如果触发结果为启用则发出 G6 哔声，为挂起则发出 G5 哔声。
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

