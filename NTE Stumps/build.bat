:: Copyright 2026 Paclora Corporation. Licensed under the Apache License, Version 2.0.

:: The text encoding is UTF-8.


:: ---- ---- ---- ----   ---- ---- ---- ----   ---- ---- ---- ----   ---- ---- ---- ----


@ECHO OFF & CHCP 65001 1>NUL


:: ---- ---- ---- ----   ---- ---- ---- ----   ---- ---- ---- ----   ---- ---- ---- ----


:: 尝试获取 AutoHotkey 的安装目录，失败时使用默认安装路径。  
:: 有关安装目录，详见：https://wyagd001.github.io/v2/docs/Variables.htm#AhkPath 。  
:: 实现参考：https://bitbucket.org/paclora_epo/calabiyau-helper/src/fa24e76a76685652e968d9fdb33c64aa251a3f20/Clean%20User%20Cache/Clean%20User%20Cache%20for%20CalabiYau%20-%201.3.2.bat#lines-18 。  
SET ahk_dir=%PROGRAMFILES%\AutoHotkey
SET ad_reg_path=HKLM\SOFTWARE\AutoHotkey & SET ad_reg_name=InstallDir
REG QUERY "%ad_reg_path%" /V "%ad_reg_name%" 1>NUL 2>NUL
IF %ERRORLEVEL% EQU 0 (FOR /F "tokens=1,2 delims=:" %%a IN ('REG QUERY "%ad_reg_path%" /V "%ad_reg_name%"') DO (SET "str_l=%%a" & SET "str_r=%%b"))
IF DEFINED str_l (SET "ahk_dir=%str_l:~-1%:%str_r%")

:: 声明所有预置变量。  
SET compiler_path=%ahk_dir%\Compiler\Ahk2Exe.exe
SET base_path=%ahk_dir%\v2\AutoHotkey64.exe
SET source_path=%~dp0src\main.ahk
SET output_path=%~dp0NTE Stumps.exe
SET upx_path=%ahk_dir%\Compiler\Upx.exe

:: 显示使用的预置变量。  
ECHO Compiler: %compiler_path%
ECHO Base Bin: %base_path%
ECHO Source: %source_path%
ECHO Output: %output_path%

:: 执行构建。  
:: 有关编译命令，详见：https://wyagd001.github.io/v2/docs/Scripts.htm#ahk2exe-run 。  
"%compiler_path%" /base "%base_path%" /in "%source_path%" /out "%output_path%" || GOTO EXIT

:: 如果发现了 UPX，也执行加壳。  
IF EXIST "%upx_path%" (
	ECHO Upx: %upx_path%
	"%upx_path%" --ultra-brute --no-lzma "%output_path%" || GOTO EXIT
)


:: ---- ---- ---- ----   ---- ---- ---- ----   ---- ---- ---- ----   ---- ---- ---- ----


:EXIT
IF ERRORLEVEL 1 (
	ECHO Build failed, press any key to exit . . . 
) ELSE (
	ECHO Build complete, press any key to exit . . . 
)

PAUSE >NUL

