# X10SRL OpenBMC 部署指南 (Windows 用户)

## 当前环境

✅ 项目已创建完成！
📁 项目位置: `C:\Users\eason\Downloads\openbmc-x10srl\`

## 🚨 重要提示

OpenBMC 编译需要 **Linux 环境**。Windows 下无法直接编译。

您有以下三种选择：

---

## 方案 1: 使用 WSL2 (推荐) ⭐

### 步骤 1: 安装 WSL2 Ubuntu

在 PowerShell (管理员) 中运行:

```powershell
wsl --install -d Ubuntu-22.04
```

重启电脑后，设置 Ubuntu 用户名和密码。

### 步骤 2: 在 WSL2 中访问项目

```bash
# 在 WSL2 Ubuntu 终端中
cd /mnt/c/Users/eason/Downloads/openbmc-x10srl

# 运行部署脚本
./deploy.sh
```

### 步骤 3: 安装依赖

```bash
sudo apt-get update
sudo apt-get install -y git build-essential python3 python3-distutils \
    gawk wget diffstat unzip texinfo gcc chrpath socat cpio \
    python3-pip python3-pexpect xz-utils debianutils iputils-ping \
    python3-git python3-jinja2 libegl1-mesa libsdl1.2-dev pylint3 \
    xterm python3-subunit mesa-common-dev zstd liblz4-tool
```

### 步骤 4: 开始编译

```bash
cd /mnt/c/Users/eason/Downloads/openbmc-x10srl
./deploy.sh
```

---

## 方案 2: 使用 Linux 虚拟机

### 步骤 1: 安装虚拟机软件

- 下载 [VirtualBox](https://www.virtualbox.org/) 或 [VMware Workstation Player](https://www.vmware.com/products/workstation-player.html)

### 步骤 2: 创建 Ubuntu 虚拟机

- 下载 [Ubuntu 22.04 LTS](https://ubuntu.com/download/desktop)
- 创建虚拟机:
  - **CPU**: 至少 4 核
  - **内存**: 至少 8GB
  - **硬盘**: 至少 100GB

### 步骤 3: 传输项目到虚拟机

在虚拟机中:

```bash
# 方法1: 使用共享文件夹
# 在 VirtualBox 中设置共享文件夹指向 C:\Users\eason\Downloads\openbmc-x10srl

# 方法2: 使用 git
cd ~
git clone <your-repo-url>  # 如果你上传到了 GitHub

# 方法3: 使用 scp
# 在 Windows 上打包
# 在虚拟机中下载
```

### 步骤 4: 编译

```bash
cd openbmc-x10srl
./deploy.sh
```

---

## 方案 3: 使用云服务器 (最简单)

### 推荐服务

- **阿里云 ECS**: 按量付费，使用完后释放
- **腾讯云 CVM**: 新用户有优惠
- **AWS EC2**: 有免费套餐

### 配置要求

- **系统**: Ubuntu 22.04 LTS
- **CPU**: 4核以上
- **内存**: 8GB以上
- **硬盘**: 100GB以上
- **预计费用**: 编译一次约 5-10 元 (2-4小时)

### 步骤

1. 创建云服务器
2. SSH 连接到服务器
3. 上传项目文件

```bash
# 在本地 Windows
scp -r openbmc-x10srl root@<服务器IP>:~/

# 或使用 WinSCP 图形化工具上传
```

4. 在服务器上编译

```bash
cd ~/openbmc-x10srl
./deploy.sh
```

5. 下载编译好的固件

```bash
# 在本地 Windows
scp root@<服务器IP>:~/openbmc-x10srl/firmware/*.mtd ./
```

---

## 📦 项目文件说明

### 已包含的内容

```
openbmc-x10srl/
├── meta-supermicro-x10srl/      # OpenBMC 配置层 (21个文件)
│   ├── conf/                     # Layer 和机器配置
│   ├── recipes-kernel/           # 设备树和内核配置
│   ├── recipes-phosphor/         # 传感器、IPMI、风扇等配置
│   └── recipes-core/             # 网络配置
│
├── 工具脚本/ (9个)
│   ├── deploy.sh                 # 自动部署脚本
│   ├── build.sh                  # 快速编译脚本
│   ├── flash-firmware.sh         # 固件刷写工具
│   ├── backup-bmc.sh             # BMC 备份工具
│   ├── test-system.sh            # 系统测试
│   ├── test-ipmi.sh              # IPMI 测试
│   ├── monitor-bmc.sh            # 状态监控
│   ├── compare-firmware.sh       # 固件比较
│   └── make-release.sh           # 打包脚本
│
└── 文档/ (6个)
    ├── README.md                 # 完整说明
    ├── 快速开始.md               # 快速入门
    ├── TROUBLESHOOTING.md        # 故障排除
    ├── CHANGELOG.md              # 更新日志
    └── 其他文档...
```

---

## 🎯 推荐流程 (WSL2)

### 1. 安装 WSL2

```powershell
# PowerShell (管理员)
wsl --install -d Ubuntu-22.04
```

### 2. 重启电脑

### 3. 配置 Ubuntu

首次启动会要求设置用户名和密码

### 4. 进入项目目录

```bash
cd /mnt/c/Users/eason/Downloads/openbmc-x10srl
```

### 5. 运行部署

```bash
./deploy.sh
```

脚本会自动:
- ✅ 检查依赖
- ✅ 下载 OpenBMC 源码
- ✅ 安装配置层
- ✅ 编译固件 (2-4小时)
- ✅ 生成固件文件

### 6. 编译完成后

固件位置: `firmware/x10srl-openbmc-YYYYMMDD.mtd`

---

## 📋 编译完成后的步骤

### 1. 备份当前 BMC 固件

```bash
./backup-bmc.sh -i 192.168.1.100
```

### 2. 刷写新固件

```bash
./flash-firmware.sh -f firmware/x10srl-openbmc-*.mtd -m network -i 192.168.1.100
```

### 3. 等待重启 (2-3分钟)

### 4. 测试验证

```bash
./test-system.sh
./test-ipmi.sh 192.168.1.100
```

---

## ⚡ 快速命令参考

```bash
# 在 WSL2 中
cd /mnt/c/Users/eason/Downloads/openbmc-x10srl

# 编译固件
./deploy.sh

# 备份 BMC
./backup-bmc.sh -i <BMC_IP>

# 刷写固件
./flash-firmware.sh -f firmware/*.mtd -m network -i <BMC_IP>

# 测试
./test-ipmi.sh <BMC_IP>

# 监控
./monitor-bmc.sh -i <BMC_IP>
```

---

## ❓ 常见问题

### Q: 必须用 Linux 吗？
A: 是的，OpenBMC 基于 Yocto/BitBake，只支持 Linux。

### Q: WSL2 和虚拟机哪个更好？
A: WSL2 更轻量快速，推荐使用。

### Q: 编译需要多长时间？
A: 首次编译 2-4 小时，后续增量编译 10-30 分钟。

### Q: 需要多少磁盘空间？
A: 至少 50GB，推荐 100GB。

### Q: 编译失败怎么办？
A: 查看 TROUBLESHOOTING.md，或重新运行 deploy.sh。

---

## 📞 获取帮助

- 📖 查看完整文档: `README.md`
- 🔧 故障排除: `TROUBLESHOOTING.md`
- 💬 OpenBMC 社区: https://discord.gg/69Km47zH98

---

## ✅ 项目状态

**所有配置文件已准备就绪！** 只需在 Linux 环境中运行 `./deploy.sh` 即可开始编译。

**建议**: 使用 WSL2，最简单快捷！
