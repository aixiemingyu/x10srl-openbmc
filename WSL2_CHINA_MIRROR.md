# WSL2 Ubuntu 国内镜像安装指南

## 方法1: 手动下载Ubuntu镜像

### 步骤1: 下载Ubuntu rootfs
从清华镜像站下载（快）：
```
https://mirrors.tuna.tsinghua.edu.cn/lxc-images/images/ubuntu/jammy/amd64/default/
```

找到最新的 `rootfs.tar.xz` 文件，例如：
```
20240826_07:42/rootfs.tar.xz
```

### 步骤2: 导入到WSL2
```powershell
# 创建安装目录
mkdir C:\WSL\Ubuntu-22.04

# 导入rootfs
wsl --import Ubuntu-22.04 C:\WSL\Ubuntu-22.04 C:\Users\eason\Downloads\rootfs.tar.xz

# 设置为默认
wsl --set-default Ubuntu-22.04

# 启动
wsl -d Ubuntu-22.04
```

## 方法2: 使用已有的WSL发行版

如果你已经安装了任何WSL发行版（Ubuntu, Debian等）：

```bash
# 启动已有的WSL
wsl

# 直接开始编译
cd /mnt/c/Users/eason/Downloads
mkdir -p ~/openbmc-build
cp -r openbmc ~/openbmc-build/
cd ~/openbmc-build/openbmc

# 安装依赖
sudo apt update
sudo apt install -y git build-essential python3 python3-distutils \
    gawk wget diffstat unzip texinfo chrpath socat cpio \
    python3-pip python3-pexpect xz-utils debianutils iputils-ping \
    libsdl1.2-dev xterm liblz4-tool zstd liblz4-dev libssl-dev \
    gcc-multilib g++-multilib

# 开始编译
. setup x10srl
bitbake obmc-phosphor-image
```

## 方法3: 等待GitHub Actions

当前仓库已配置CI，每次push自动编译：
- 访问：https://github.com/aixiemingyu/x10srl-openbmc/actions
- 等待编译完成
- 下载 artifacts

## 方法4: 使用Docker Desktop的WSL2后端

如果已安装Docker Desktop：
```bash
# Docker Desktop自带WSL2
docker run -it --rm -v C:\Users\eason\Downloads:/work ubuntu:22.04 bash

# 在容器内编译（不推荐，因为BitBake需要特权）
```

## 推荐做法

**优先使用GitHub Actions**，因为：
- ✅ 无需本地配置
- ✅ 不占用本地资源
- ✅ 结果可直接下载
- ✅ 已经验证可工作

或者：
- 晚上挂着让WSL2慢慢下载
- 第二天早上直接编译

需要我触发一次GitHub Actions编译吗？
