@echo off
chcp 65001 >nul
setlocal EnableExtensions EnableDelayedExpansion

rem ============================================================
rem  PSP 3000 专用视频转换器
rem  批量把常见视频转换为 PSP-3000 可直接播放的 MAQxxxxx.MP4
rem  依赖: FFmpeg (需要 libopenh264 与 aac 编码器)
rem ============================================================

rem ---- 可选：本机私有配置（已被 .gitignore 忽略，不会提交）----
if exist "%~dp0local.cmd" call "%~dp0local.cmd"

set "INPUT=%~dp0input"
set "OUTPUT=%~dp0output"

rem ---- 查找 FFmpeg：环境变量 > 脚本目录 > 系统 PATH ----
if not defined FFMPEG if exist "%~dp0ffmpeg\bin\ffmpeg.exe" set "FFMPEG=%~dp0ffmpeg\bin\ffmpeg.exe"
if not defined FFMPEG if exist "%~dp0ffmpeg.exe" set "FFMPEG=%~dp0ffmpeg.exe"
if not defined FFMPEG for %%I in (ffmpeg.exe) do if exist "%%~$PATH:I" set "FFMPEG=%%~$PATH:I"

if not defined FFMPEG (
    echo [ERROR] FFmpeg not found.
    echo         1^) 把 ffmpeg.exe 放到 "%~dp0ffmpeg\bin\" 或 "%~dp0" 下
    echo         2^) 把 ffmpeg 所在目录加入系统 PATH
    echo         3^) 在本目录新建 local.cmd 并写入: set "FFMPEG=D:\path\to\ffmpeg.exe"
    pause
    exit /b 1
)

if not exist "%INPUT%" mkdir "%INPUT%"
if not exist "%OUTPUT%" mkdir "%OUTPUT%"

echo ==========================================
echo PSP-3000 Batch Converter
echo ==========================================
echo FFmpeg : %FFMPEG%
echo Input  : %INPUT%
echo Output : %OUTPUT%
echo.

set /a NUM=0

for %%F in ("%INPUT%\*.mp4" "%INPUT%\*.mkv" "%INPUT%\*.avi" "%INPUT%\*.mov" "%INPUT%\*.m4v" "%INPUT%\*.ts") do (
    if exist "%%~fF" (
        set /a NUM+=1
        set "N=00000!NUM!"
        set "N=!N:~-5!"
        set "OUT=%OUTPUT%\MAQ!N!.MP4"

        echo.
        echo ------------------------------------------
        echo [!NUM!] %%~nxF
        echo Output: MAQ!N!.MP4
        echo ------------------------------------------

        "%FFMPEG%" -y -i "%%~fF" ^
        -map 0:v:0 -map 0:a:0? ^
        -vf "scale=480:272,setsar=1" ^
        -c:v libopenh264 ^
        -profile:v constrained_baseline ^
        -level 3.0 ^
        -pix_fmt yuv420p ^
        -b:v 384k ^
        -r 24000/1001 ^
        -c:a aac ^
        -b:a 96k ^
        -ar 48000 ^
        -ac 2 ^
        -f psp "!OUT!"

        if errorlevel 1 (
            echo FAILED: %%~nxF
        ) else (
            echo DONE: MAQ!N!.MP4
        )
    )
)

echo.
echo ==========================================
echo Finished. Files found: !NUM!
echo Output: %OUTPUT%
echo ==========================================

pause