:: Copyright 2026 Paclora Corporation. Licensed under the Apache License, Version 2.0.

:: The text encoding is UTF-8.



@ECHO OFF & CHCP 65001 1>NUL


SET compiler_path=%PROGRAMFILES%\AutoHotkey\Compiler\Ahk2Exe.exe
SET base_path=%PROGRAMFILES%\AutoHotkey\v2\AutoHotkey64.exe
SET upx_path=%PROGRAMFILES%\AutoHotkey\Compiler\Upx.exe

ECHO Compiler: %compiler_path%
ECHO Base Bin: %base_path%
ECHO Source: %~dp0src\main.ahk
ECHO Output: %~dp0NTE Stumps.exe

"%compiler_path%" /base "%base_path%" /in ".\src\main.ahk" /out ".\NTE Stumps.exe" || GOTO EXIT

IF EXIST "%upx_path%" (
	ECHO Upx: %upx_path%
	"%upx_path%" --ultra-brute --no-lzma ".\NTE Stumps.exe" || GOTO EXIT
)



:EXIT
IF ERRORLEVEL 1 (
	ECHO Build failed, press any key to exit . . . 
) ELSE (
	ECHO Build complete, press any key to exit . . . 
)

PAUSE >NUL

