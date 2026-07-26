@echo off
chcp 65001 >nul
setlocal EnableExtensions EnableDelayedExpansion

:: 同步当前目录的 git 仓库
echo === 开始强制同步 git 仓库===

:: 确认当前目录是 git 仓库
if not exist ".git" (
    echo 错误: 当前目录不是 git 仓库（未找到 .git）
    exit /b 1
)

:: 获取远端最新
git fetch --all --prune
if errorlevel 1 (
    echo 错误: git fetch 失败
    exit /b 1
)

:: 丢弃所有本地变更（含暂存区/工作区）
git reset --hard
if errorlevel 1 (
    echo 错误: git reset --hard 失败
    exit /b 1
)

:: 删除未跟踪文件/目录（非常彻底，注意：会删掉所有未被 git 跟踪的文件）
git clean -fdx
if errorlevel 1 (
    echo 错误: git clean -fdx 失败
    exit /b 1
)

:: 强制与远端当前分支对齐
for /f "delims=" %%b in ('git rev-parse --abbrev-ref HEAD') do (
    set "BRANCH=%%b"
)

git reset --hard "origin/!BRANCH!"
if errorlevel 1 (
    echo 错误: reset 到 origin/!BRANCH! 失败
    exit /b 1
)


echo 已强制同步到 origin/%BRANCH%


:: 删除旧的 GithubDesktop汉化工具 文件夹
echo === 删除旧的 GithubDesktop汉化工具 文件夹 ===
if exist "GithubDesktop汉化工具" (
    rmdir /s /q "GithubDesktop汉化工具"
    echo 已删除旧的 GithubDesktop汉化工具 文件夹
) else (
    echo 未发现旧的 GithubDesktop汉化工具 文件夹，跳过删除
)

:: 解压新的 GithubDesktop汉化工具.7z
echo === 解压 GithubDesktop汉化工具.7z ===
if exist "GithubDesktop汉化工具.7z" (
    7z x -y "GithubDesktop汉化工具.7z"
    echo 解压完成
) else (
    echo 错误: 未找到 GithubDesktop汉化工具.7z
    pause
    exit /b 1
)

:: 启动 GithubDesktopZhTool.exe 并等待其关闭（工作路径切到工具目录）
echo === 启动 GithubDesktopZhTool.exe 并等待其关闭（工作路径切换到工具目录）===
if exist "GithubDesktop汉化工具\GithubDesktopZhTool.exe" (
    pushd "GithubDesktop汉化工具"
    start /wait "" "GithubDesktopZhTool.exe"
    popd
    echo GithubDesktopZhTool.exe 已关闭
) else (
    echo 错误: 未找到 GithubDesktop汉化工具\GithubDesktopZhTool.exe
    exit /b 1
)

timeout /t 1 >nul

:: 删除 GithubDesktop汉化工具 文件夹
echo === 删除 GithubDesktop汉化工具 文件夹 ===
rmdir /s /q "GithubDesktop汉化工具"
echo 已删除 GithubDesktop汉化工具 文件夹

echo === 所有操作已完成 ===
exit /b 0
