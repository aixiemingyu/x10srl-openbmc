IMAGE_INSTALL:append = " \
    x10srl-config \
    x10srl-led-manager \
    phosphor-pid-control \
    x86-power-control \
    ipmitool \
    ethtool \
    i2c-tools \
    lmsensors-sensors \
    memtester \
    stress-ng \
    "

# 启用额外功能
EXTRA_IMAGE_FEATURES += "ssh-server-openssh"

# U-Boot 环境变量
UBOOT_ENV_SUFFIX = "bin"
