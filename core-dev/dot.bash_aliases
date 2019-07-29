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

# Shortcut directories
alias cddev="cd $HOME/iexecdev"
alias cdcor="cd $HOME/iexecdev/iexec-core"
alias cdwor="cd $HOME/iexecdev/iexec-worker"
alias cdcom="cd $HOME/iexecdev/iexec-common"
alias cdint="cd $HOME/iexecdev/iexec-core-integration-tests"
alias cdwal="cd $HOME/iexecdev/wallets"
alias cddep="cd $HOME/iexecdev/iexec-deploy"

# iExec-core dev
alias upstack="$HOME/iexecdev/iexec-deploy/core-dev/upstack"
alias rmstack="$HOME/iexecdev/iexec-deploy/core-dev/rmstack"
alias upcore="$HOME/iexecdev/iexec-deploy/core-dev/upcore"
alias rmcore="$HOME/iexecdev/iexec-deploy/core-dev/rmcore"
alias upworker="$HOME/iexecdev/iexec-deploy/core-dev/upworker"
alias rmworker="$HOME/iexecdev/iexec-deploy/core-dev/rmworker"
alias upworkers="$HOME/iexecdev/iexec-deploy/core-dev/upworkers"
alias rmworkers="$HOME/iexecdev/iexec-deploy/core-dev/rmworkers"
alias uppool="$HOME/iexecdev/iexec-deploy/core-dev/uppool"
alias rmpool="$HOME/iexecdev/iexec-deploy/core-dev/rmpool"
alias buy="$HOME/iexecdev/wallets/buy --workerpool=0xc0c288EC5242E7f53F6594DC7BADF417b69631Ba --app=0x63C8De22025a7A463acd6c89C50b27013eCa6472 --dataset=0x4b40D43da477bBcf69f5fd26467384355a1686d6"

alias rmimages="docker rmi -f $(docker images -f dangling=true -q); docker rmi -f $(docker images -a |  grep iexec-core); docker rmi -f $(docker images -a |  grep iexec-worker)"
alias rmvolumes="docker volume rm `docker volume ls -q -f dangling=true`"

# iExec-components
alias sde='docker run -it --rm -v $(pwd):/sde/files iexechub/iexec-sde'

# General
alias tophistory='history | sed "s/^ *//" | cut -d" " -f2- | sort | uniq -c | sort -nr | head -n 30'


