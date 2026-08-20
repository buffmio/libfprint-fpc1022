# Upstream MR !570 自动同步与编译设计

## 目标

在上游 GitLab `libfprint` 的 MR !570 仍处于开放状态时，定期检查其最新提交；有更新时同步到 GitHub 自动 PR，并让现有跨发行版构建流程编译该 PR。MR 被合并或关闭后，自动停止同步和编译，不删除已有 Release。

## 当前问题

当前每周 Release workflow 只重新编译 GitHub 仓库当前提交，不会查询或拉取 GitLab MR !570。因此上游 MR 即使有新提交，Release 仍然使用旧源码。当前 `Build packages` workflow 也不会为自动同步分支提供完整的 PR 构建入口。

## 设计

### 1. 上游状态检查

新增 `.github/workflows/sync-upstream.yml`，使用每周定时任务和 `workflow_dispatch` 触发。工作流通过 GitLab REST API 查询项目 `libfprint/libfprint` 的 MR !570，读取 `state` 和 `diff_refs.head_sha`。

- `state=opened`：继续同步流程。
- `state=merged` 或 `state=closed`：输出停止原因并成功结束，不创建新 PR。
- API 请求失败或返回未知状态：工作流失败，避免误判为已结束。

### 2. 源码同步

同步工作流使用完整 Git 历史，从 GitLab 获取 `refs/merge-requests/570/head`，以当前 `master` 为基础创建固定分支 `automation/mr-570`，合并 MR 最新提交，并把已处理的 `head_sha` 写入 `packaging/upstream-mr.env`。

同步分支不会直接修改 `master`。如果 Git 合并产生冲突，工作流失败并保留现有分支和源码，不自动制造不完整的源码提交。

### 3. 自动 PR

工作流使用 GitHub Actions 内置 token 推送 `automation/mr-570`，并创建或更新一个指向 `master` 的 PR。PR 标题固定为 `chore: sync upstream MR !570`，正文包含 MR 状态、最新 SHA 和验证说明。

同一个固定分支保证重复定时运行不会产生多个 PR；MR 新提交到来时更新现有 PR。

由于 GitHub 使用 `GITHUB_TOKEN` 推送分支不会自动触发后续 workflow，同步 workflow 在推送并创建或更新 PR 后，显式执行 `gh workflow run build.yml --ref automation/mr-570`。该手动派发使用自动同步分支作为构建 ref，确保三种容器实际编译最新 MR 源码。

### 4. 自动编译

`.github/workflows/build.yml` 增加针对 `master` 的 `pull_request` 触发器。自动同步 PR 创建或更新后，现有 Ubuntu、Debian、Fedora 矩阵会编译并运行契约测试。构建失败只会使 PR 检查失败，不会发布包。

显式派发的构建只上传 Actions artifact，不调用 Release workflow；只有同步 PR 合并到 `master` 后，后续 Release 构建才会发布新源码对应的包。

现有每周 `Publish release` workflow 保持发布职责：只有同步 PR 合并到 `master` 后，下一次 Release 构建才会发布新源码对应的包。

### 5. 终止条件

每次检查都先判断 MR 状态。状态为 `merged` 或 `closed` 时，不再同步、推送分支或创建 PR。已有 `v0.1.0-wip` Release 和历史包保留，避免破坏用户已有安装来源。

## 测试与验证

- 新增同步脚本契约测试，验证 GitLab API 字段、状态分支、固定分支名、MR SHA 记录和失败退出行为。
- 更新 workflow 契约测试，验证定时触发、`pull_request` 构建、权限最小化和停止条件存在。
- 本地运行所有现有 Arch、Debian、RPM、文档、Release workflow 契约测试。
- 通过 `workflow_dispatch` 使用测试分支验证三种容器构建；不会在测试运行中上传 Release。

## 安全与范围

- GitLab API 只读访问不需要密钥。
- GitHub token 仅授予 `contents: write`、`pull-requests: write` 和派发构建所需的 Actions 权限，不授予仓库管理权限。
- 不自动修改 `master`，不自动关闭或合并 PR，不删除 Release。
- 本设计只处理源码同步和编译，不改变驱动算法、SELinux 策略、PAM 配置或发行版依赖。

## 非目标

- 不在 MR 合并后继续追踪上游主分支。
- 不声称任意未来 `libfprint` ABI/API 都兼容当前驱动。
- 不自动把 GitLab MR 的每个提交直接发布为稳定包。
