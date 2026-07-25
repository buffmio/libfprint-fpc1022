# FPC1022 源码与多发行版发布设计

## 目标

把现有 `buffmio/libfprint-fpc1022` 从仅含 AUR 元数据的仓库升级为完整源码发布仓库。首个实验版本为 `v0.1.0-wip`，发布完整源码，并为常用 Linux 发行版提供可复现的 x86_64/amd64 安装包。

支持范围：

- 硬件：USB ID `10a5:9200`（FPC Sensor Controller/FPC1022）
- Arch Linux：`.pkg.tar.zst`
- Ubuntu 24.04、Ubuntu 26.04、Debian 13：`.deb`
- Fedora 42、Fedora 43：`.rpm`
- 架构：x86_64/amd64

该项目是基于 libfprint 上游 MR !570 的实验分支，不代表上游 libfprint 的正式版本。README 和 Release 说明必须清楚标注实验性质、已验证硬件和风险。

## 仓库结构

GitHub 仓库默认分支保存完整 libfprint 源码以及 FPC match-on-host 驱动。现有仅含 AUR 文件的 GitHub `master` 历史可被完整源码历史替换；独立 AUR 仓库及其历史不受影响。

新增或整理以下目录：

```text
.github/workflows/
  build.yml
  release.yml
packaging/
  arch/
  debian/
  rpm/
docs/
README.md
COPYING
```

`packaging/arch` 保存并维护现有 `PKGBUILD`。AUR 仓库继续保持 AUR 所需的扁平结构，通过人工或同步脚本更新，不让 GitHub 发布流程直接推送 AUR。

## 版本与来源

项目版本从 `v0.1.0-wip` 开始。打包元数据使用与标签对应的 `0.1.0` 版本和发行版自己的 release revision。

源码仓库保留：

- libfprint 原始提交历史
- SIGFM 支持提交
- FPC match-on-host 驱动提交
- 项目自己的打包、文档和 CI 提交

Release 自动附带 GitHub 生成的源码归档。所有二进制包必须由对应标签的提交构建，包内版本信息或打包元数据必须能追溯到该标签和提交。

## 构建架构

GitHub Actions 使用矩阵任务，在对应发行版环境中安装原生构建依赖、编译、运行测试并制作安装包。

- Arch 使用 Arch 容器和 `makepkg`
- Debian/Ubuntu 使用对应发行版容器和 `dpkg-buildpackage`
- Fedora 使用对应发行版容器和 `rpmbuild`

每种包只替换系统的 `libfprint`，不捆绑 `fprintd`。包声明与发行版官方 libfprint 包的冲突、替换或 provides 关系，并依赖目标发行版提供的运行库。这样能继续使用发行版自带的 `fprintd`、PAM 和桌面集成。

安装包不跨发行版复用。Ubuntu、Debian 和 Fedora 的每个目标版本都在自己的环境中构建，以匹配其 ABI 和依赖版本。

## CI 与 Release 流程

普通分支和拉取请求运行构建与测试，但不发布：

1. 检出完整历史和子模块（如有）。
2. 安装目标发行版构建依赖。
3. 执行 Meson 配置、编译和可在无真实硬件环境运行的测试。
4. 执行发行版原生打包。
5. 校验包元数据、架构、依赖和文件列表。
6. 上传短期 CI artifact，便于检查。

推送匹配 `v*-wip` 的标签时，Release 工作流复用相同构建逻辑。只有所有矩阵任务成功后才创建公开 GitHub Release，并上传：

- Arch `.pkg.tar.zst`
- Ubuntu/Debian `.deb`
- Fedora `.rpm`
- 每个文件的 SHA-256 校验和

任何目标失败时不发布不完整 Release。可以保留失败日志，但必须修复并重新创建标签或发布一个递增版本，避免悄悄替换用户已下载的文件。

## 安装、安全与回滚

README 和 Release 说明按发行版给出安装命令，并明确：

- 安装会替换发行版官方 `libfprint`
- 驱动仍处于 WIP 状态
- 目前只对 `10a5:9200` 做过实机验证
- 登记指纹前先确认 `fprintd` 能发现设备
- SDDM 登录指纹认证不默认启用

回滚使用各发行版包管理器重新安装官方 `libfprint`，随后重启 `fprintd`。文档不自动修改 PAM、SDDM 或系统认证配置。

## 许可与署名

继续使用上游 libfprint 的 LGPL-2.1 许可，并保留 `COPYING`、原始提交历史和文件版权信息。README 和 Release 说明引用 libfprint 上游项目及 MR !570，并保留原驱动作者署名。项目名称和描述不得暗示是 libfprint 官方发行版。

## 验证标准

发布前必须满足：

- 完整源码能从干净检出构建
- 现有 libfprint 测试套件和 udev/hwdb 测试通过
- 每个目标发行版成功生成原生安装包
- 安装包只包含预期的 libfprint 库、驱动、规则和元数据
- 包管理器能识别对官方 libfprint 的替换/冲突关系
- GitHub Release 中每个文件都有 SHA-256
- Arch 包继续通过现有 `test-pkgbuild.sh` 和 `namcap`
- 实机验证流程记录设备发现、登记和至少两次指纹匹配

## 非目标

首版不包括：

- ARM/aarch64 安装包
- 自动推送 AUR
- Launchpad PPA、Fedora COPR 或 openSUSE Build Service
- Windows、macOS 或其他 BSD 系统
- 自动修改 PAM、SDDM、GDM 或 KDE 配置
- 声称支持 `10a5:9200` 之外的 FPC 设备

