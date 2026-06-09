:: Copyright 2026 Paclora Corporation. Licensed under the Apache License, Version 2.0.

:: The text encoding is UTF-8.



@ECHO OFF & CHCP 65001 1>NUL


SET compiler_path=%PROGRAMFILES%\AutoHotkey\Compiler\Ahk2Exe.exe
SET base_path=%PROGRAMFILES%\AutoHotkey\v2\AutoHotkey64.exe

ECHO Compiler: %compiler_path%
ECHO Base Bin: %base_path%
ECHO Source: %~dp0src\main.ahk
ECHO Output: %~dp0NTE Stumps.exe

"%compiler_path%" /base "%base_path%" /in ".\src\main.ahk" /out ".\NTE Stumps.exe"



PAUSE

