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
)



echo === 脚本执行完成 ===

:: 运行 GithubDesktop汉化工具/GithubDesktopZhTool.exe 并关闭 CMD
echo === 启动 GithubDesktopZhTool.exe ===
start "" /d "GithubDesktop汉化工具" GithubDesktopZhTool.exe & exit

