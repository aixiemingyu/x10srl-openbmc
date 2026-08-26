# WSL2 OpenBMC 编译指南

## 步骤 1: 打开WSL2终端

在Windows开始菜单中搜索并打开 **Ubuntu** 或 **Debian** (你的WSL2发行版)

或者在PowerShell/CMD中运行：
```powershell
wsl
```

## 步骤 2: 安装编译依赖

```bash
# 更新包列表
sudo apt update

# 安装OpenBMC编译依赖
sudo apt install -y git build-essential python3 python3-distutils \
    gawk wget diffstat unzip texinfo chrpath socat cpio \
    python3-pip python3-pexpect xz-utils debianutils iputils-ping \
    libsdl1.2-dev xterm liblz4-tool zstd liblz4-dev libssl-dev \
    gcc-multilib g++-multilib
```

## 步骤 3: 访问Windows目录并复制源码

**重要**: 不要直接在 `/mnt/c/` 下编译，性能很差！

```bash
# 创建工作目录（在WSL2原生文件系统）
mkdir -p ~/openbmc-build
cd ~/openbmc-build

# 复制OpenBMC源码（从Windows目录）
cp -r /mnt/c/Users/eason/Downloads/openbmc .
cd openbmc

# 确认X10SRL layer已存在
ls -la meta-supermicro-x10srl
```

如果meta-supermicro-x10srl不存在：
```bash
cp -r /mnt/c/Users/eason/Downloads/openbmc-x10srl/meta-supermicro-x10srl .
```

## 步骤 4: 初始化构建环境

```bash
# 必须使用 source (或 .)
. setup x10srl
```

你会看到：
```
Machine x10srl found in meta-supermicro-x10srl
...
Common targets are:
  obmc-phosphor-image
```

现在你会自动进入 `build/` 目录。

## 步骤 5: 配置编译选项（可选但推荐）

```bash
# 编辑配置
vi conf/local.conf

# 或使用nano
nano conf/local.conf
```

在文件末尾添加：
```
# 根据CPU核心数调整（例如8核）
BB_NUMBER_THREADS = "8"
PARALLEL_MAKE = "-j 8"

# 构建后自动清理临时文件（节省磁盘空间）
INHERIT += "rm_work"

# 使用ccache加速重复编译
INHERIT += "ccache"
```

保存并退出。

## 步骤 6: 开始编译

```bash
# 完整镜像编译（首次2-4小时）
bitbake obmc-phosphor-image
```

编译过程中你会看到：
```
Parsing recipes: 100% |████████████████████| Time: 0:05:23
...
Currently  5 running tasks (2413 of 6147)
```

## 步骤 7: 查看编译结果

编译成功后：
```bash
# 查看生成的镜像
ls -lh tmp/deploy/images/x10srl/

# 主要文件
ls -lh tmp/deploy/images/x10srl/*.mtd
```

输出示例：
```
-rw-r--r-- 2 user user 32M Aug 26 14:00 obmc-phosphor-image-x10srl.static.mtd
-rw-r--r-- 2 user user 32M Aug 26 14:00 obmc-phosphor-image-x10srl.ubi.mtd
-rw-r--r-- 2 user user 8.2M Aug 26 13:58 fitImage-x10srl.bin
```

## 步骤 8: 复制结果到Windows

```bash
# 复制到Windows Downloads目录
cp tmp/deploy/images/x10srl/*.mtd /mnt/c/Users/eason/Downloads/
cp tmp/deploy/images/x10srl/fitImage-*.bin /mnt/c/Users/eason/Downloads/
```

## 常见问题

### 1. 磁盘空间不足

```bash
# 检查磁盘使用
df -h

# 清理构建临时文件
bitbake -c cleanall obmc-phosphor-image
rm -rf tmp/
```

### 2. 编译失败

```bash
# 查看错误日志
less tmp/work/x10srl-openbmc-linux-gnueabi/linux-aspeed/*/temp/log.do_compile.*

# 重新编译特定包
bitbake -c clean linux-aspeed
bitbake linux-aspeed
```

### 3. 网络下载慢

在 `conf/local.conf` 中添加镜像：
```
PREMIRRORS:prepend = " \
    git://.*/.* http://mirrors.ustc.edu.cn/openbmc/downloads/MIRRORNAME \n \
"
```

## 增量编译

修改设备树后：
```bash
# 1. 修改DTS文件（在Windows中用编辑器）
# 2. 回到WSL2

cd ~/openbmc-build/openbmc

# 3. 重新source环境
. setup x10srl

# 4. 只重新编译内核
bitbake -c clean linux-aspeed
bitbake linux-aspeed

# 5. 重新打包镜像
bitbake obmc-phosphor-image
```

## 快速测试（只编译内核和设备树）

如果只想验证设备树语法：
```bash
bitbake -c clean linux-aspeed
bitbake linux-aspeed
```

这只需要10-20分钟，而不是几小时。

## 性能优化

### WSL2内存配置

创建或编辑 `C:\Users\eason\.wslconfig`:
```ini
[wsl2]
memory=16GB
processors=8
swap=8GB
```

然后重启WSL2：
```powershell
# 在PowerShell中
wsl --shutdown
wsl
```

### 使用本地镜像

在 `conf/local.conf` 中添加：
```
# 共享下载目录（多次编译复用）
DL_DIR = "${HOME}/openbmc-downloads"
SSTATE_DIR = "${HOME}/openbmc-sstate-cache"
```

## 监控编译进度

在另一个WSL2终端窗口：
```bash
# 监控构建进度
watch -n 5 'ps aux | grep bitbake'

# 查看磁盘使用
watch -n 10 'df -h | grep sda'

# 查看编译日志
tail -f ~/openbmc-build/openbmc/build/tmp/log/cooker/*/console-latest.log
```

## 完成后

⚠️ **重要提醒**：
- 这是 skeleton 版本
- **不要刷写到真实硬件**
- 用于测试构建系统和设备树语法
- 等待硬件信息后再完善配置

## 下一步

1. 验证镜像大小（应该是32MB）
2. 提取fitImage中的设备树查看
3. 继续收集硬件信息
4. 完善设备树配置
