# Koyeb Deploy

This backend can be deployed to Koyeb from GitHub using the Dockerfile in `rainbow-social-backend/`.

## Before you run

1. Make sure the repository is pushed to GitHub.
2. Install the Koyeb GitHub app and grant it access to `ZhaoX19990227/rainbowsocial`.
3. Install and log in to the Koyeb CLI.

## Deploy

```bash
export JWT_SECRET='replace-with-a-long-random-secret'
bash /Users/zhaoxiang/GolandProjects/rainbow/deploy/koyeb/deploy.sh
```

## Notes

- The service listens on `PORT`, which Koyeb sets automatically for web services.
- Koyeb provides HTTPS on the generated `*.koyeb.app` domain.
- This configuration uses SQLite inside the container, so filesystem data is ephemeral on redeploy/restart. It is suitable for demo/testing, not long-term production persistence.
