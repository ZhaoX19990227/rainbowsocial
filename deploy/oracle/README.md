# Oracle Cloud Always Free Deploy

This path is intended for a long-running backend on an OCI Always Free Linux VM.

## What to create in OCI

1. Create an Always Free Linux compute instance in your home region.
2. Open inbound port `8088` in the instance security list or network security group.
3. SSH into the VM.

Oracle's official docs for this are:

- https://docs.oracle.com/en/learn/first-oci-linux-instance/index.html
- https://docs.oracle.com/iaas/Content/FreeTier/freetier_topic-Always_Free_Resources.htm

## Prepare environment on the VM

On the VM:

```bash
mkdir -p /opt/rainbowsocial/deploy/oracle
```

Copy `deploy/oracle/.env.example` to `deploy/oracle/.env` and fill in at least `JWT_SECRET`.

## Deploy

If the VM already has GitHub SSH access:

```bash
ssh ubuntu@YOUR_VM_IP
cd /opt
git clone git@github.com:ZhaoX19990227/rainbowsocial.git
cd /opt/rainbowsocial/deploy/oracle
cp .env.example .env
docker compose up -d --build
```

Or from your local machine:

```bash
export REMOTE_HOST=ubuntu@YOUR_VM_IP
export SSH_KEY=$HOME/.ssh/YOUR_ORACLE_KEY
bash /Users/zhaoxiang/GolandProjects/rainbow/deploy/oracle/deploy-remote.sh
```

## Notes

- This path keeps SQLite data in a Docker volume on the VM, so it survives container restarts.
- You still need a fixed domain and HTTPS later if you want polished mobile distribution.
- Oracle VM public IPs are stable only if you keep the reserved/public IP configuration stable in OCI.

## GitHub Actions 自动部署

仓库已经补了 `.github/workflows/deploy.yml`，当你 push 到 `master` 时会自动：

1. 跑后端 `go test ./...`
2. 跑前端 `flutter analyze`
3. 构建 Flutter Web
4. 把代码和 web 构建产物传到服务器
5. 在服务器上执行 `deploy/oracle/ci-redeploy.sh`
6. 自动重建并重启 `api`，如果 compose 里有 `web` 也会一起重建
7. 如果部署失败或健康检查失败，自动回滚到上一个可用版本
8. 在 GitHub Actions 里直接看到完整构建和部署日志

你需要在 GitHub 仓库里配置这些 Secrets：

- `DEPLOY_HOST`: 服务器 IP 或域名
- `DEPLOY_USER`: SSH 用户名
- `DEPLOY_SSH_KEY`: GitHub Actions 用的私钥
- `DEPLOY_PORT`: 可选，默认 `22`
- `DEPLOY_PATH`: 可选，默认 `/opt/rainbowsocial-deploy`

推荐做法：

- 为 GitHub Actions 单独生成一把部署用 SSH key
- 把公钥追加到服务器用户的 `~/.ssh/authorized_keys`
- 不要在 Actions 里直接使用 root 密码

### 怎么在 GitHub 上启用 Action

1. 打开你的仓库页面。
2. 进入 `Actions` 标签页。
3. 如果仓库第一次启用 Actions，点 `I understand my workflows, go ahead and enable them`。
4. 因为仓库里已经有 `.github/workflows/deploy.yml`，启用后它会自动识别，不需要在网页上再手写一份 workflow。
5. 之后你每次 push 到 `master`，或者在 `Actions -> Deploy To Server -> Run workflow` 手动触发，它都会跑。

### 怎么配置 GitHub Secrets

1. 打开仓库页面。
2. 进入 `Settings`。
3. 左侧点 `Secrets and variables`。
4. 点 `Actions`。
5. 点 `New repository secret`。
6. 分别新增下面这些值：

- `DEPLOY_HOST`: 你的服务器公网 IP 或域名，例如 `129.x.x.x`
- `DEPLOY_USER`: SSH 用户名，例如 `ubuntu`
- `DEPLOY_SSH_KEY`: GitHub Actions 要用的私钥全文，包含 `-----BEGIN OPENSSH PRIVATE KEY-----`
- `DEPLOY_PORT`: 可选，通常填 `22`
- `DEPLOY_PATH`: 可选，建议填 `/opt/rainbowsocial-deploy`

### GitHub Actions 部署 SSH key 怎么准备

先在你本地生成一把专门给 CI/CD 用的 key：

```bash
ssh-keygen -t ed25519 -C "github-actions-deploy" -f ~/.ssh/rainbow_actions
```

把公钥加到服务器：

```bash
ssh-copy-id -i ~/.ssh/rainbow_actions.pub ubuntu@YOUR_VM_IP
```

如果机器上没有 `ssh-copy-id`，也可以手动追加：

```bash
cat ~/.ssh/rainbow_actions.pub
```

把输出整段追加到服务器上的 `~/.ssh/authorized_keys`。

然后把私钥内容贴进 GitHub 的 `DEPLOY_SSH_KEY`：

```bash
cat ~/.ssh/rainbow_actions
```

### 怎么验证 workflow 已经能用

1. Secrets 配完后，提交并 push 一次代码到 `master`。
2. 打开 GitHub 仓库的 `Actions` 页面。
3. 点开最新一次 `Deploy To Server`。
4. 重点看这几段日志：

- `Run backend tests`
- `Analyze frontend`
- `Copy deploy artifacts`
- `Deploy on server`
- `health check`

如果最后显示成功，说明这套自动发布已经接通。

### 自动回滚现在的行为

- 发布开始前，会先备份当前服务器上的代码目录和静态站点目录
- 如果 `docker compose up -d --build` 失败，脚本会自动恢复旧代码并重新拉起旧版本容器
- 如果健康检查 `http://127.0.0.1:8088/health` 失败，也会触发同样的自动回滚
- SQLite 数据卷不会回滚，避免把已有用户数据倒退
