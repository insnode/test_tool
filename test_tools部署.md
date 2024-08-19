```shell
# 安装 git
# 在 Ubuntu/Debian 上安装 Git
 sudo apt install git -y

# 在 CentOS/RHEL 上安装 Git
 sudo yum install git -y

# 在 Fedora/Rocky 上安装 Git
 sudo dnf install git -y

# Windows 10 版本 1809 及以上内置了 winget
 winget install --id Git.Git -e --source winget
# 在CMD命令行输入后会显示下载并自动安装，速度可能会比较慢，2～3分钟左右
C:\Users\Administrator>winget install --id Git.Git -e --source winget
已找到 Git [Git.Git] 版本 2.46.0
此应用程序由其所有者授权给你。
Microsoft 对第三方程序包概不负责，也不向第三方程序包授予任何许可证。
正在下载 https://github.com/git-for-windows/git/releases/download/v2.46.0.windows.1/Git-2.46.0-64-bit.exe
  ██████████████████████████████  65.0 MB / 65.0 MB
已成功验证安装程序哈希
正在启动程序包安装...
已成功安装
# 验证
 git --version
#克隆文件
 git clone https://github.com/insnode/test_tool.git
```
