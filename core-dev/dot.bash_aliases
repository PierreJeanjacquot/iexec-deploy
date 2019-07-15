# Generic
alias mostUsedcommands='history | sed "s/^ *//" | cut -d" " -f2- | sort | uniq -c | sort -nr | head -n 30'
alias xml="xmllint --format -"
alias gdb='gradle clean build -Dtest.profile=skipDocker --refresh-dependencies'
alias gdr='gradle bootRun'

# Git
alias gs='git status'
alias gp='git pull && git fetch -p'
alias gm='git checkout master'
alias gd='git diff'
alias gl='git log'

# cd shortcuts
alias cddev="cd ~/iexecdev"
alias cdcor="cd ~/iexecdev/iexec-core"
alias cdwor="cd ~/iexecdev/iexec-worker"
alias cdcom="cd ~/iexecdev/iexec-common"
alias cdint="cd ~/iexecdev/iexec-core-integration-tests"
alias cdwal="cd ~/iexecdev/wallets"
alias cddep="cd ~/iexecdev/iexec-deploy"


# iExec core dev
alias upstack="~/iexecdev/iexec-deploy/core-dev/upstack"
alias rmstack="~/iexecdev/iexec-deploy/core-dev/rmstack"
alias upcore="~/iexecdev/iexec-deploy/core-dev/upcore"
alias rmcore="~/iexecdev/iexec-deploy/core-dev/rmcore"
alias upworker="~/iexecdev/iexec-deploy/core-dev/upworker"
alias rmworker="~/iexecdev/iexec-deploy/core-dev/rmworker"
alias upworkers="~/iexecdev/iexec-deploy/core-dev/upworkers"
alias rmworkers="~/iexecdev/iexec-deploy/core-dev/rmworkers"
alias uppool="~/iexecdev/iexec-deploy/core-dev/uppool"
alias rmpool="~/iexecdev/iexec-deploy/core-dev/rmpool"
alias buy="~/iexecdev/wallets/buy --workerpool=0xc0c288EC5242E7f53F6594DC7BADF417b69631Ba --app=0x63C8De22025a7A463acd6c89C50b27013eCa6472 --dataset=0x4b40D43da477bBcf69f5fd26467384355a1686d6"


