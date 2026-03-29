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
7. 在 GitHub Actions 里直接看到完整构建和部署日志

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
