#!/usr/bin/env bash

set -euo pipefail

REMOTE_HOST="${REMOTE_HOST:?set REMOTE_HOST like ubuntu@1.2.3.4}"
SSH_KEY="${SSH_KEY:-$HOME/.ssh/id_rsa}"

ssh -i "$SSH_KEY" "$REMOTE_HOST" 'bash -s' < /Users/zhaoxiang/GolandProjects/rainbow/deploy/oracle/bootstrap-vm.sh
