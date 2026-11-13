# Eject Data

一个 macOS 菜单栏小工具：**一键退出占用外接硬盘的应用，然后安全弹出**。

Mac 的存储比金子还贵，很多人会把 Docker、微信、Codex、素材库等大块数据放到外接盘上。但每次拔盘前，都要手动把正在读这块盘的应用一个个 `⌘Q` 掉，再点弹出——步骤多、容易漏、漏了就弹出失败。

Eject Data 把这几步合成一个菜单栏按钮：点一下，退应用、等释放、弹出盘。

## 功能

- 菜单栏常驻，点一下完成「退出 + 弹出」
- **dry-run 预览**：先看谁会受影响，不动任何东西
- 用 `lsof` 自动找出正在读写该卷的进程
- Docker Desktop 特殊处理（VM 持有镜像，需要先退）
- 支持选择任意外接卷（默认 `/Volumes/Data`）
- 纯 Swift + zsh，无第三方依赖，MIT 开源

## 系统要求

- macOS 13 或更新版本
- 从源码构建需要 Xcode Command Line Tools（`xcode-select --install`）

## 安装

### 方式一：下载 Release

1. 下载 `EjectData-v1.0.0-macOS-arm64.zip`
2. 解压，把 `EjectData.app` 拖进「应用程序」
3. 首次打开如果被 Gatekeeper 拦截：右键 → 打开（本项目使用临时签名，未做 Apple 公证）

### 方式二：从源码构建

```bash
git clone https://github.com/lonelyness1/eject-data.git
cd eject-data
./build.sh
cp -R build/EjectData.app /Applications/
```

## 使用

1. 启动 `EjectData.app`
2. 菜单栏右上角出现一个**弹出图标**（三角形 + 下划线）
3. 第一次使用，先点「选择要弹出的卷…」选中你的外接盘
4. 点「仅预览占用 (dry-run)」确认列表
5. 点「退出应用并弹出」——完成后会弹窗显示结果

```
┌────────────────────────┐
│ 退出应用并弹出          │
│ 仅预览占用 (dry-run)    │
│ 选择要弹出的卷…        │
│ ────────────────────── │
│ 退出                   │
└────────────────────────┘
```

它没有 Dock 图标、没有窗口，是一个 `LSUIElement` 菜单栏 App。

### 命令行版本

`Resources/eject-data.sh` 可以单独使用：

```bash
./eject-data.sh --dry-run              # 只看谁在占用
./eject-data.sh                        # 退出应用并弹出 /Volumes/Data
./eject-data.sh /Volumes/MyDisk        # 指定卷
./eject-data.sh --force /Volumes/Data  # 对残留进程发 SIGTERM
```

## 工作原理

1. `lsof` 找出所有打开了该卷下文件的进程
2. 如果是 Docker，先退出 Docker Desktop（它的 VM 持有 `Docker.raw`）
3. 对检测到的 GUI 应用逐个发送 AppleScript `quit`
4. 等待文件释放（最多 20 秒）
5. `diskutil eject` 弹出；失败时打印仍占用该卷的进程

`--force` 会对仍然占用卷的非 GUI 进程发送 `SIGTERM`。

## 注意事项

- **有未保存文档的应用**被退出时可能弹出保存框，脚本会等待 20 秒；第一次使用建议先跑 dry-run
- 退出其他 App 需要 macOS 的「自动化」权限，首次会弹窗询问
- 只处理 GUI 应用；后台命令行进程需要 `--force`
- 拒绝弹出系统卷（`/`、`/System/Volumes/*`）
- 本项目使用 ad-hoc 签名，未经过 Apple 公证；分发二进制时用户需要右键打开
- 和硬盘盒/扩展坞的供电、枚举问题无关——那是硬件层的事

## 项目结构

```
eject-data/
├── Sources/
│   └── EjectData.swift      # 菜单栏 App
├── Resources/
│   ├── Info.plist
│   └── eject-data.sh        # 独立命令行脚本
├── build.sh                 # 构建 .app
├── README.md
├── README.en.md
├── CHANGELOG.md
└── LICENSE
```

## License

[MIT](LICENSE)
