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
