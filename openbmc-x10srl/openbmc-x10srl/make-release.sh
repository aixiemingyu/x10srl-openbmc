#!/bin/bash
# 创建项目发布包

VERSION="1.0.0"
RELEASE_NAME="x10srl-openbmc-v${VERSION}"
RELEASE_DIR="releases"

echo "======================================"
echo "创建发布包: $RELEASE_NAME"
echo "======================================"
echo ""

# 创建发布目录
mkdir -p "$RELEASE_DIR"
PACKAGE_DIR="$RELEASE_DIR/$RELEASE_NAME"
rm -rf "$PACKAGE_DIR"
mkdir -p "$PACKAGE_DIR"

# 复制文件
echo "复制文件..."

# 机器层
cp -r meta-supermicro-x10srl "$PACKAGE_DIR/"

# 脚本
for script in *.sh; do
    cp "$script" "$PACKAGE_DIR/"
done

# 文档
for doc in *.md; do
    cp "$doc" "$PACKAGE_DIR/"
done

# 创建版本信息
cat > "$PACKAGE_DIR/VERSION" << EOF
X10SRL OpenBMC
版本: $VERSION
日期: $(date +%Y-%m-%d)
适配固件: x10srl-f-ipmi.bin (32MB)
EOF

# 创建安装说明
cat > "$PACKAGE_DIR/INSTALL.txt" << EOF
X10SRL OpenBMC 安装说明
========================

快速开始:
---------
1. 运行部署脚本:
   ./deploy.sh

   或者手动执行:

2. 下载 OpenBMC:
   git clone https://github.com/openbmc/openbmc.git
   cd openbmc

3. 复制机器层:
   cp -r /path/to/$RELEASE_NAME/meta-supermicro-x10srl ./

4. 设置环境:
   . setup x10srl
   echo 'BBLAYERS += "\${BSPDIR}/meta-supermicro-x10srl"' >> conf/bblayers.conf

5. 编译固件:
   bitbake obmc-phosphor-image

6. 刷写固件:
   ./flash-firmware.sh -f <固件路径> -m network -i <BMC_IP>

详细说明请参考 README.md
EOF

# 创建 tar.gz 包
echo "打包..."
cd "$RELEASE_DIR"
tar czf "${RELEASE_NAME}.tar.gz" "$RELEASE_NAME"
cd ..

# 计算校验和
echo "计算校验和..."
cd "$RELEASE_DIR"
sha256sum "${RELEASE_NAME}.tar.gz" > "${RELEASE_NAME}.tar.gz.sha256"
cd ..

# 清理临时目录
rm -rf "$PACKAGE_DIR"

# 显示结果
echo ""
echo "======================================"
echo "发布包创建完成！"
echo "======================================"
echo ""
echo "文件:"
ls -lh "$RELEASE_DIR/${RELEASE_NAME}.tar.gz"
echo ""
echo "SHA256:"
cat "$RELEASE_DIR/${RELEASE_NAME}.tar.gz.sha256"
echo ""
echo "发布包位置: $RELEASE_DIR/${RELEASE_NAME}.tar.gz"
