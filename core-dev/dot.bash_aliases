###############################################################################################
#
#
# Import this bash_aliases file to yours with:
#
# echo -e "\n#iExec-core dev\nsource $HOME/iexecdev/iexec-deploy/core-dev/dot.bash_aliases" >> $HOME/.bash_aliases
#
# (and restart your terminal)
#
###############################################################################################

IEXECDEV=${IEXEC_DEV:-"$HOME/iexecdev"}

# Git
alias gs='git status'
alias gp='git pull && git fetch -p'
alias gm='git checkout master'
alias gd='git diff'
alias gl='git log'

# Gradle
alias gdb='gradle clean build -Dtest.profile=skipDocker --refresh-dependencies' # gradle build
alias gdbd='gradle clean build -Dtest.profile=skipDocker --refresh-dependencies buildImage -PforceDockerBuild' #gradle & docker build
alias gdr='gradle bootRun'
alias gdt='gradle test -i --test'

# Shortcut directories
alias cddev="cd $IEXECDEV"
alias cdcor="cd $IEXECDEV/iexec-core"
alias cdwor="cd $IEXECDEV/iexec-worker"
alias cdcom="cd $IEXECDEV/iexec-common"
alias cdint="cd $IEXECDEV/iexec-core-integration-tests"
alias cdwal="cd $IEXECDEV/wallets"
alias cddep="cd $IEXECDEV/iexec-deploy"
alias cdsms="cd $IEXECDEV/iexec-sms"

# iExec-core dev
alias upstack="$IEXECDEV/iexec-deploy/core-dev/upstack"
alias rmstack="$IEXECDEV/iexec-deploy/core-dev/rmstack"
alias upcore="$IEXECDEV/iexec-deploy/core-dev/upcore"
alias rmcore="$IEXECDEV/iexec-deploy/core-dev/rmcore"
alias upworker="$IEXECDEV/iexec-deploy/core-dev/upworker"
alias rmworker="$IEXECDEV/iexec-deploy/core-dev/rmworker"
alias upworkers="$IEXECDEV/iexec-deploy/core-dev/upworkers"
alias rmworkers="$IEXECDEV/iexec-deploy/core-dev/rmworkers"
alias uppool="$IEXECDEV/iexec-deploy/core-dev/uppool"
alias rmpool="$IEXECDEV/iexec-deploy/core-dev/rmpool"
alias deploy="$IEXECDEV/wallets/deploy --workerpool=yes --app=docker.io/iexechub/vanityeth:1.1.1 --dataset=http://icons.iconarchive.com/icons/cjdowner/cryptocurrency-flat/512/iExec-RLC-RLC-icon.png"
alias buy="$IEXECDEV/wallets/buy --workerpool=0xc0c288EC5242E7f53F6594DC7BADF417b69631Ba --app=0x63C8De22025a7A463acd6c89C50b27013eCa6472 --dataset=0x4b40D43da477bBcf69f5fd26467384355a1686d6"

alias rmimages="docker rmi -f $(docker images -f dangling=true -q); docker rmi -f $(docker images -a |  grep iexec-core); docker rmi -f $(docker images -a |  grep iexec-worker)"
alias rmvolumes="docker volume rm `docker volume ls -q -f dangling=true`"

# iExec-components
alias sde='docker run -it --rm -v $(pwd):/sde/files -v ~/.ssh/id_rsa:/sde/ssh/id_rsa:ro iexechub/iexec-sde:1.0.4'
alias iexec-src="node $IEXEC_DEV/iexec-sdk/src/iexec.js"

# General
alias tophistory='history | sed "s/^ *//" | cut -d" " -f2- | sort | uniq -c | sort -nr | head -n 30'

# chain
lastblock() {
    curl -X POST \
        --header "Content-Type: application/json" \
        --data '{"jsonrpc":"2.0", "method":"eth_getBlockByNumber", "params":["latest", false], "id":1}' \
        $1 | jq .result.numbe | xargs printf '%d\n'
}
issyncing() {
    curl -X POST \
        --header "Content-Type: application/json" \
        --data '{"jsonrpc":"2.0", "method":"eth_syncing", "params":[], "id":1}' \
        $1 | jq .result
}