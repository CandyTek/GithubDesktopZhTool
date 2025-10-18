@echo off
chcp 65001 >nul

:: 同步当前目录的 git 仓库
echo === 开始同步 git 仓库 ===
git pull

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
    exit /b
)




echo === 启动 GithubDesktopZhTool.exe 并等待其关闭 ===
if exist "GithubDesktop汉化工具\GithubDesktopZhTool.exe" (
    start /wait "" "GithubDesktop汉化工具\GithubDesktopZhTool.exe"
    echo GithubDesktopZhTool.exe 已关闭
) else (
    echo 错误: 未找到 GithubDesktopZhTool.exe
    @REM pause
    exit /b
)
ping www.baidu.com -n 1

:: 删除 GithubDesktop汉化工具 文件夹
echo === 删除 GithubDesktop汉化工具 文件夹 ===
ping 
rmdir /s /q "GithubDesktop汉化工具"
echo 已删除 GithubDesktop汉化工具 文件夹

echo === 所有操作已完成 ===
@REM pause
exit