@echo off
chcp 65001 >nul
setlocal EnableExtensions DisableDelayedExpansion

:: 图形客户端可以克隆仓库，但不一定提供命令行 Git。
git --version >nul 2>&1
if errorlevel 1 (
    echo 错误: 未找到可用的命令行 Git，无法执行自动更新。
    echo 使用其他客户端克隆仓库后，仍需安装 Git 并将其加入 PATH。
    echo 下载地址: https://git-scm.com/download/win
    echo 安装完成后，请关闭此窗口，再重新双击 update.cmd。
    echo.
    pause
    exit /b 1
)

if "%~1"=="--update-worker" goto worker

:: CMD 会按位置继续读取脚本；git reset 覆盖当前脚本会导致后续命令错位。
:: 先复制到仓库外，再由临时副本执行同步及后续操作。
set "UPDATE_REPOSITORY=%~dp0"
set "RUNNER_DIR=%TEMP%\GithubDesktopZhTool-update-%RANDOM%-%RANDOM%"
mkdir "%RUNNER_DIR%" 2>nul
if errorlevel 1 (
    echo 错误: 无法创建临时脚本目录
    exit /b 1
)
copy /y "%~f0" "%RUNNER_DIR%\update.cmd" >nul
if errorlevel 1 (
    rmdir "%RUNNER_DIR%" 2>nul
    echo 错误: 无法复制更新脚本
    exit /b 1
)

:: 不使用 CALL：将控制权直接交给临时副本，避免再读取原脚本。
"%RUNNER_DIR%\update.cmd" --update-worker

:worker
call :update
set "UPDATE_EXIT_CODE=%ERRORLEVEL%"
:: 先退出批处理上下文，再删除临时副本并返回更新结果。
(goto) 2>nul & del /q "%~f0" & rmdir "%RUNNER_DIR%" & exit /b %UPDATE_EXIT_CODE%

:update
cd /d "%UPDATE_REPOSITORY%"
if errorlevel 1 exit /b 1

set "ARCHIVE_CANDIDATES="GithubDesktop汉化工具.7z" "GithubDesktopZhTool.7z""
set "TOOL_DIR_CANDIDATES="GithubDesktop汉化工具" "GithubDesktopZhTool""
set "EXE_NAME=GithubDesktopZhTool.exe"

echo === 开始强制同步 git 仓库 ===
if not exist ".git" (
    echo 未检测到 .git，正在将 ZIP 解压目录初始化为本仓库...
    git init --initial-branch=main .
    if errorlevel 1 (
        echo 错误: 无法初始化 Git 仓库
        exit /b 1
    )
    git remote add origin https://github.com/CandyTek/GithubDesktopZhTool.git
    if errorlevel 1 (
        echo 错误: 无法配置远端仓库
        exit /b 1
    )
)

set "BRANCH="
for /f "delims=" %%b in ('git symbolic-ref --quiet --short HEAD') do set "BRANCH=%%b"
if not defined BRANCH (
    echo 错误: 当前处于分离 HEAD 状态，无法确定待同步分支
    exit /b 1
)

:: 只拉取当前分支的最新快照，兼容远端每次同步后重写历史。
git fetch --depth 1 --no-tags --prune origin "+refs/heads/%BRANCH%:refs/remotes/origin/%BRANCH%"
if errorlevel 1 (
    echo 错误: git fetch 失败，请确认已安装 Git 且网络连接正常
    exit /b 1
)
git rev-parse --verify "refs/remotes/origin/%BRANCH%" >nul 2>&1
if errorlevel 1 (
    echo 错误: 未找到远端分支 origin/%BRANCH%
    exit /b 1
)

:: 强制同步会丢弃本地修改，并删除所有未跟踪及被忽略的文件。
git reset --hard "origin/%BRANCH%"
if errorlevel 1 (
    echo 错误: reset 到 origin/%BRANCH% 失败
    exit /b 1
)
git branch --set-upstream-to="origin/%BRANCH%" "%BRANCH%"
if errorlevel 1 (
    echo 错误: 无法设置分支跟踪关系
    exit /b 1
)
git clean -fdx
if errorlevel 1 (
    echo 错误: git clean -fdx 失败
    exit /b 1
)
echo 已强制同步到 origin/%BRANCH%

:: 优先使用仓库附带的 7-Zip。
set "SEVEN_ZIP=7z.exe"
if exist "%CD%\7z.exe" set "SEVEN_ZIP=%CD%\7z.exe"

for %%D in (%TOOL_DIR_CANDIDATES%) do (
    if exist "%%~D\" (
        echo === 删除旧的 %%~D 文件夹 ===
        rmdir /s /q "%%~D"
        if exist "%%~D\" (
            echo 错误: 无法删除旧的 %%~D 文件夹
            exit /b 1
        )
    )
)

echo === 查找并解压压缩包 ===
set "TARGET_ARCHIVE="
for %%F in (%ARCHIVE_CANDIDATES%) do (
    if exist "%%~F" (
        set "TARGET_ARCHIVE=%%~F"
        goto archive_found
    )
)
echo 错误: 未找到任何有效的压缩包
exit /b 1

:archive_found
echo 匹配到压缩包: %TARGET_ARCHIVE%，开始解压...
"%SEVEN_ZIP%" x -y "%TARGET_ARCHIVE%"
if errorlevel 1 (
    echo 错误: 7z 解压失败
    exit /b 1
)
echo 解压完成

:: 以压缩包内实际的目录为准，同时兼容新旧目录名称。
set "TOOL_DIR="
for %%D in (%TOOL_DIR_CANDIDATES%) do (
    if exist "%%~D\%EXE_NAME%" (
        set "TOOL_DIR=%%~D"
        goto tool_found
    )
)
echo 错误: 解压后未找到 %EXE_NAME%
exit /b 1

:tool_found
echo === 启动 %EXE_NAME% 并等待其关闭 ===
pushd "%TOOL_DIR%"
if errorlevel 1 exit /b 1
start "" /wait ".\%EXE_NAME%"
set "TOOL_EXIT_CODE=%ERRORLEVEL%"
popd
if not "%TOOL_EXIT_CODE%"=="0" (
    echo 错误: %EXE_NAME% 退出码为 %TOOL_EXIT_CODE%
    exit /b 1
)
echo %EXE_NAME% 已关闭

echo === 删除 %TOOL_DIR% 文件夹 ===
rmdir /s /q "%TOOL_DIR%"
if exist "%TOOL_DIR%\" (
    echo 错误: 无法删除 %TOOL_DIR% 文件夹
    exit /b 1
)
echo === 所有操作已完成 ===
exit /b 0
