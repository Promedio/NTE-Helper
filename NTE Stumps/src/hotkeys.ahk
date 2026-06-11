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

			macro_rk_1 := Self.macro.RepeatKeystroke()
			hotkey_rk_1_enable_state := cfg.data.交互重复.启用状态.data == true ? "On" : "Off"
			Hotkey(cfg.data.交互重复.映射按键.data, macro_rk_1, hotkey_rk_1_enable_state)

			for key_list in cfg.data.按键重复.按键列表.data {
				macro_rk_2 := Self.macro.RepeatKeystroke()
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



	; 
	class macro {
		; 
		class RepeatKeystroke {
			Call(*) {
				ToolTip("Ok") ; =============================== todo
				; 妈的，配置验证有了问题，运行中同步就不应该检查重复了，或者说不应该重新读取，否则验证会有问题，而且初始化实际上也不应该强行写入，完全多此一举。
			}
		} ; class RepeatKeystroke



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
				this.trigger_range := this.calculate_trigger_range_from_system_double_click_time()
			} ; func __New



			; 计算两次连续击键的容许范围，参照系统设定的鼠标双击间隔的 1.15 倍。
			; 有关具体接口，请见：https://learn.microsoft.com/zh-cn/windows/win32/api/winuser/nf-winuser-getdoubleclicktime 。
			calculate_trigger_range_from_system_double_click_time() {
				call_res := DllCall("GetDoubleClickTime", "Int")
				return (call_res == 0 ? this.trigger_range : call_res) * 1.15
			} ; func calculate_trigger_range_from_system_double_click_time



			; 缓存标志，记录上一个传入的按键名。
			flag_for_previous_key := ""



			; 外部按键传入——
			; 如果当前按键名与前次按键名不同，储存此名为前次按键名，然后创建一个计时器，在一定倒计时后清除前次按键名；
			; 如果当前按键名与前次按键名相同，立即停止相关计时器，然后清除前次按键名，最后执行宏逻辑。
			; 也就是说，一个新按键的传入会开始一次倒计时，倒计时内如果是传入了相同的按键，则触发宏逻辑并停止计时器，否则被视为新按键。
			; 有关计时调用，详见：https://wyagd001.github.io/v2/docs/lib/SetTimer.htm 。
			Call(key_name_from_call) {
				if this.flag_for_previous_key != key_name_from_call {
					this.flag_for_previous_key := key_name_from_call
					SetTimer(this.clear_flag, -this.trigger_range)
				} else {
					SetTimer(this.clear_flag, 0)
					this.flag_for_previous_key := ""
					this.macro_logic()
				}
			} ; func Call



			; 要触发的宏逻辑，必须重新实现。
			macro_logic() {
				dui.error_dialog("未被覆盖。", A_ThisFunc, "内部错误")
			} ; func macro_logic



			; `clear_flag_call`的绑定函数对象，绑定到此类的示例。
			; 有关绑定函数，请见：https://wyagd001.github.io/v2/docs/misc/Functor.htm#BoundFunc 。
			clear_flag := ObjBindMethod(this, "clear_flag_call")



			; 清除缓存标志，作为`clear_flag`的源。
			clear_flag_call() {
				this.flag_for_previous_key := ""
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

