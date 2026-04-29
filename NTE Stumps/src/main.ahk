; Copyright 2026 Paclora Corporation. Licensed under the Apache License, Version 2.0.

; 程序入口。
; 包含程序的主要逻辑和编译参数。


; ---- ---- ---- ----   ---- ---- ---- ----   ---- ---- ---- ----   ---- ---- ---- ----


#Requires AutoHotkey v2.0.25+ ; 限制解释器版本。实际上不需要这么高的要求，但以防万一。
#SingleInstance Force         ; 强制覆盖单例。重复启动相当于重新加载。

ProcessSetPriority("AboveNormal") ; 设优先级为“高于正常”。
ListLines(0)                      ; 关闭执行历史。
KeyHistory(!A_IsCompiled)         ; 编译状态下关闭按键历史。
Thread("Interrupt", 0)            ; 允许线程立即中断。

#MaxThreads 4       ; 此值应当设置为热键的实际数目，此处翻倍是为了容许热键线程的意外轮替。
SendMode("Input")   ; 设置发送模式为 Input。
A_MenuMaskKey := "" ; 防止遮盖控制键。


; ---- ---- ---- ----   ---- ---- ---- ----   ---- ---- ---- ----   ---- ---- ---- ----


#Include .\environment.ahk ; 环境保障。
env := Environment
#Include .\update.ahk      ; 更新检查。
upc := Update


; ---- ---- ---- ----   ---- ---- ---- ----   ---- ---- ---- ----   ---- ---- ---- ----


; 
env.ensurance()


; ---- ---- ---- ----   ---- ---- ---- ----   ---- ---- ---- ----   ---- ---- ---- ----


;@Ahk2Exe-UpdateManifest 1 ; UAC.

;@Ahk2Exe-SetDescription    NTE Stumps
;@Ahk2Exe-SetFileVersion    1.0.0
;@Ahk2Exe-SetProductName    NTE Stumps
;@Ahk2Exe-SetProductVersion 1.0.0
;@Ahk2Exe-SetCompanyName    Paclora Corporation
;@Ahk2Exe-SetCopyright      Apache-2.0 © 2026 Paclora Corporation.
;@Ahk2Exe-SetLanguage       0x0804 ; Chinese_PRC.
;@Ahk2Exe-SetOrigFilename   NTE Stumps.exe

;@Ahk2Exe-SetMainIcon  .\icon\i1.ico      ; Default icon.
;;@Ahk2Exe-AddResource .\icon\ix.ico, 160 ; The .ahk file icon.
;@Ahk2Exe-AddResource  .\icon\i2.ico, 206 ; "Suspend Hotkeys" status.
;;@Ahk2Exe-AddResource .\icon\ix.ico, 207 ; "Pause Script" status.
;;@Ahk2Exe-AddResource .\icon\ix.ico, 208 ; "Suspend Hotkeys" and "Pause Script".

