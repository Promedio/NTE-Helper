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
				macro_rks := Self.macro.RepeatKeystrokeSingle(cfg.data.交互重复.触发按键.data, cfg.data.交互重复.映射按键.data)
				hotkey_rks_enable_state := cfg.data.交互重复.启用状态.data == true ? "On" : "Off"
				Hotkey(cfg.data.交互重复.映射按键.data, macro_rks, hotkey_rks_enable_state)
			}

			; 列表自动支持空情形。
			for key_list in cfg.data.按键重复.按键列表.data {
				macro_rkm := Self.macro.RepeatKeystrokeMultiple(1000 / 6.2)
				hotkey_rkm_enable_state := cfg.data.按键重复.启用状态.data == true ? "On" : "Off"
				for key_name in key_list {
					Hotkey(key_name, macro_rkm, hotkey_rkm_enable_state)
				}
			}

			; 因容许为空所以需要预先判断。
			if cfg.data.杂项设置.全局按键.data != "" {
				macro_dktss := Self.macro.DoubleKeystrokeToSwitchSuspendState(cfg.data.杂项设置.全局按键.data)
				Hotkey("~" cfg.data.杂项设置.全局按键.data, macro_dktss, "S On") ; 穿透且豁免。
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
		; 所有宏的基类。
		; **注意：此类仅作继承用途。**
		class MacroBase {
			; 内部检查器的重复间隔。
			tick_interval := Round(1000 / 40)
		} ; class MacroBase



		; 重复击键宏的基类。
		; **注意：此类仅作继承用途。**
		class RepeatKeystrokeBase extends Hotkeys.macro.MacroBase {
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



			; `press_key_call`的绑定函数对象，绑定到此类的实例。
			; 有关绑定函数，请见：https://wyagd001.github.io/v2/docs/misc/Functor.htm#BoundFunc 。
			press_key := ObjBindMethod(this, "press_key_call")

			; 触发和预定按键，作为`press_key`的源。
			press_key_call() {
				dui.error_dialog("未被覆盖。", A_ThisFunc, "内部错误")
			} ; func press_key_call



			; `monitor_key_Call`的绑定函数对象，绑定到此类的实例。
			; 有关绑定函数，请见：https://wyagd001.github.io/v2/docs/misc/Functor.htm#BoundFunc 。
			monitor_key := ObjBindMethod(this, "monitor_key_Call") ; 间接绑定.

			; 监控和清除预定，作为`monitor_key`的源。
			monitor_key_call() {
				dui.error_dialog("未被覆盖。", A_ThisFunc, "内部错误")
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
			; 此处默认值配合函数`press_key_call`中参数`first_delay`的默认值，其为空字符串时不作首次延迟。
			base_delay_of_first_keystroke := ""



			; 创建类。
			; - `trigger_key`：所要触发的按键名。
			; - `remap_key`：已绑定实例的按键名。
			; - `repeat_interval`：按键重复的间隔，单位是毫秒，可用范围是 50 ~ 50+；
			; - `floating_multiplier`：按键重复时的最大浮动倍率，为`repeat_interval`的直接乘积，可用范围是 0 ~ 0.5。
			__New(trigger_key, remap_key, repeat_interval := 1000 / 6, floating_multiplier := 1 / 4) {
				super.__New(repeat_interval, floating_multiplier)

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
			; 按键每次抬起时，所有计时器都立刻停止，函数不再活动。
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

				; 执行到此处，说明按键无误，开启阻塞标记并订阅一个计时器，
				; 这个计时器将持续检测绑定按键的按下状态，抬起时将关闭阻塞并停止所有计时器。
				this.key_block := true
				SetTimer(this.monitor_key, this.tick_interval)

				; 立即触发击键，其中订阅了下次击键。这样设计是因为必须立刻响应新的击键，而不是等待下一次订阅再触发击键。
				; 此处传入值可使其拥有特殊延迟，行为类似 Windows 默认的自动重复击键，但延迟更短。
				this.press_key_call(this.get_the_first_press_delay())
			} ; func Call



			; 立即按下`trigger_key`，订阅一次抬起当前按键的计时器并同时订阅重复触发此函数的计时器。
			; 此处击键和抬起的时机包含一定程度的浮动，将使得击键序列不那么整齐。
			press_key_call(first_delay := "") {
				Send("{" this.trigger_key " Down}")

				next_press_interval := first_delay != "" ? first_delay : this.get_the_next_press_interval()
				next_release_interval := this.get_the_next_release_interval(next_press_interval)
			;	ToolTip(Format("Pt {:03}`nRt {:03}", next_press_interval, next_release_interval))

				; 订阅一次释放，不做任任何管理。
				; 这是考虑到不同按键之间有重叠比较正常，而因主动触发较快导致的重叠也不应该忽略抬起。
				SetTimer((*) => Send("{" this.trigger_key " Up}"), - next_release_interval)

				; 订阅下一次击键。此处可以不用负数，因为此订阅受持续计时器管理。
				SetTimer(this.press_key, - next_press_interval)
			} ; func press_key_call



			; 持续检测`remap_key`的按下状态，按键抬起时停止所有计时器并关闭`key_block`。
			monitor_key_call() {
				if GetKeyState(this.remap_key, "P") == false {
					SetTimer(this.press_key, 0)
					SetTimer(this.monitor_key, 0)

					this.key_block := false
				}
			} ; func monitor_key_call



			; 获取第一次触发按键后的延迟。
			; - 返回值：参照`base_delay_of_first_keystroke`和`floating_multiplier`计算而出的随机数。
			get_the_first_press_delay() {
				; 浮动总值的一半，此处 / 2 是因后续随机需要平分此值才能保持基准。
				float := (this.base_delay_of_first_keystroke * this.floating_multiplier) / 2

				return Round(Random(this.base_delay_of_first_keystroke-float, this.base_delay_of_first_keystroke+float))
			} ; func get_the_first_press_delay
		} ; class RepeatKeystrokeSingle



		; 重复触发已按下按键的宏逻辑。
		; 此类为多个按键设计，不同按键之间不会争强，若要同时触发请创建新的实例。
		; 实现参考：https://bitbucket.org/paclora_epo/3oostumps/src/fb6b63869c04e6e1ccdf038bf947447eee4e966c/%E6%BA%90%E7%A0%81/3ooStumps/.PARTIAL/MacroLogic.ahk#lines-192 。
		class RepeatKeystrokeMultiple extends Hotkeys.macro.RepeatKeystrokeBase {
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

				; 如果两值相等，必定是来自系统的自动重复击键，拒绝执行后续逻辑。
				; 这里之所以能如此判断，是因为函数开头先备份了当前按键到先前按键，而后续逻辑中，在当前按键释放时，
				; 当前按键的变量内容会被重置，又因为函数第一行先执行备份，空值自然流动至先前按键，故当前按键永远不可能为空。
				if this.current_key == this.previous_key {
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

				; 订阅一次释放，不做任任何管理。
				; 这是考虑到不同按键之间有重叠比较正常，而因主动触发较快导致的重叠也不应该忽略抬起。
				SetTimer((*) => Send("{" current_key " Up}"), - next_release_interval)

				; 订阅下一次击键。此处可以不用负数，因为此订阅受持续计时器管理。
				SetTimer(this.press_key, - next_press_interval)
			} ; func press_key_call



			; 持续检测`current_key`的按下状态，按键抬起时停止所有计时器并置空`current_key`。
			; 注意：`current_key`随时可能改变，因此计时器始终检测最后传入的按键；置空`current_key`是为了其能在下次传入新按键时自然流动给`previous_key`。
			monitor_key_call() {
				if GetKeyState(this.current_key, "P") == false {
					SetTimer(this.press_key, 0)
					SetTimer(this.monitor_key, 0)

					this.current_key := ""
				}
			} ; func monitor_key_call
		} ; class RepeatKeystrokeMultiple



		; 在一定时间内连续击键两次便可触发宏逻辑。
		; 此类被设计为不影响按键的原有功能，因此必须绑定腭化按键，除非不需要按键的原有功能。
		; 注意：不能将此类的实例绑定给多个按键。
		; 有关腭化按键，请见：https://wyagd001.github.io/v2/docs/Hotkeys.htm#Tilde 。
		class DoubleKeystroke extends Hotkeys.macro.MacroBase {
			; 宏所绑定的按键名。
			bound_key_name := ""

			; 两次连续击键的容许范围。
			; 有关系统默认，详见：https://learn.microsoft.com/zh-cn/windows/win32/api/winuser/nf-winuser-setdoubleclicktime 。
			trigger_range := 500



			; 创建类。
			; - `key_name`：所要检测的按键名。
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

				; 执行到此处，说明按键无误，开启阻塞标记并订阅一个计时器，
				; 这个计时器将持续检测绑定按键的按下状态，抬起时将关闭阻塞并停止自身。
				this.key_block := true
				SetTimer(this.monitor_key, this.tick_interval)

				; 此处判断双击状态——
				if this.key_flag == false {
					; 如果尚未进行第一次击键，标记一次并定时清除一次；
					this.key_flag := true
					SetTimer(this.clear_flag, - this.trigger_range)
				} else {
					; 否则，这里应当处于容许范围内（也就是还处于上方计时器执行之前），
					; 立即停止计时器并清除按键标记（也就是将倒计时提前到此刻，重置了击键状态，否则可能会把下次击键视为第二次），
					; 然后执行宏逻辑。
					SetTimer(this.clear_flag, 0)
					this.key_flag := false
					; 不过这里还有一些矛盾：这里的宏逻辑如果是耗时函数的话，会不会有问题？
					this.macro_logic()
				}
			} ; func Call



			; 要触发的宏逻辑，必须重新实现。
			macro_logic() {
				dui.error_dialog("未被覆盖。", A_ThisFunc, "内部错误")
			} ; func macro_logic



			; `monitor_key_call`的绑定函数对象，绑定到此类的实例。
			; 有关绑定函数，请见：https://wyagd001.github.io/v2/docs/misc/Functor.htm#BoundFunc 。
			monitor_key := ObjBindMethod(this, "monitor_key_call")

			; 清除缓存标志`key_block`并停止预定，作为`monitor_key`的源。
			monitor_key_call() {
				if GetKeyState(this.bound_key_name, "P") == false {
					SetTimer(this.monitor_key, 0)

					this.key_block := false
				}
			} ; func monitor_key_call



			; `clear_flag_call`的绑定函数对象，绑定到此类的实例。
			; 有关绑定函数，请见：https://wyagd001.github.io/v2/docs/misc/Functor.htm#BoundFunc 。
			clear_flag := ObjBindMethod(this, "clear_flag_call")

			; 清除缓存标志`key_flag`，作为`clear_flag`的源。
			clear_flag_call() {
				this.key_flag := false
			} ; func clear_flag_call
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

