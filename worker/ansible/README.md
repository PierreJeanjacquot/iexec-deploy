# Create hosts file
```bash
# HOST WORKERNAME SSH_PORT SSH_KEY
54.67.123.212	ansible_workername=worker1	ansible_port=22	ansible_ssh_private_key_file=~/.ssh/worker-pool.pem
```

# Create variables file
```bash
# Setting variables
SCHEDULER_DOMAIN=xxxxx
SCHEDULER_IP=xxxxx

WORKER=worker-net

WORKER_DOCKER_IMAGE_VERSION=xxxxx
WORKER_HOSTNAME=hostname-worker-net-docker
WORKER_LOGIN=vworker
WORKER_PASSWORD=xxxxx
WORKER_LOGGERLEVEL=FINEST
WORKER_SHAREDPACKAGES=
WORKER_SHAREDAPPS=docker
WORKER_TMPDIR=/tmp/worker-net
WORKER_SANDBOX_ENABLED=true
```

# To deploy workers on specific hosts from file
```bash
ansible-playbook -i ./poolkovan/hosts -K deploy.yml -e "pool=poolkovan" -c paramiko
```

# To stop workers on specific hosts from file
```bash
ansible-playbook -i ./poolkovan/hosts -K destroy.yml -e "pool=poolkovan" -c paramiko
```
