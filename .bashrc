#!/bin/bash

# exit early if not interactive
#if [ -z "$PS1" ] ; then return ; fi

# copied here from .profile (I don't know why it's not available)
function source_if_exists {
    if [ -f "$1" ] ; then
        source "$1"
    fi
}

if [ -z "$BASH_COMPLETION" ] ; then
    source_if_exists /etc/bash_completion
fi

source_if_exists /usr/share/doc/pkgfile/command-not-found.bash

if [ -x "`which dircolors 2>/dev/null`" ] ; then
    if [ -f ~/.dircolours ] ; then
        eval `dircolors ~/.dircolours`
    elif [ -f /etc/dircolors ] ; then
        eval `dircolors /etc/dircolors`
    else
        eval `dircolors`
    fi
fi
if [ -x "`which fortune 2>/dev/null`" ] ; then
    if [ -x "`which cowsay 2>/dev/null`" ] ; then
        fortune | cowsay
    else
        fortune
    fi
fi

# PS1 Colours
Black="\[\033[0;30m\]"
Red="\[\033[0;31m\]"
Green="\[\033[0;32m\]"
Yellow="\[\033[0;33m\]"
Blue="\[\033[0;34m\]"
Purple="\[\033[0;35m\]"
Cyan="\[\033[0;36m\]"
White="\[\033[0;37m\]"
# Bold
BBlack="\[\033[1;30m\]"
BRed="\[\033[1;31m\]"
BGreen="\[\033[1;32m\]"
BYellow="\[\033[1;33m\]"
BBlue="\[\033[1;34m\]"
BPurple="\[\033[1;35m\]"
BCyan="\[\033[1;36m\]"
BWhite="\[\033[1;37m\]"
# High Intensty
IBlack="\[\033[0;90m\]"
IRed="\[\033[0;91m\]"
IGreen="\[\033[0;92m\]"
IYellow="\[\033[0;93m\]"
IBlue="\[\033[0;94m\]"
IPurple="\[\033[0;95m\]"
ICyan="\[\033[0;96m\]"
IWhite="\[\033[0;97m\]"
# Reset
Color_Off="\[\033[0m\]"

# adapted from http://stackoverflow.com/a/6086978/1041691
source_if_exists /usr/share/git/completion/git-prompt.sh
if [ "$USER" = "root" ] ; then
    __root_warning_ps1="${BRed}\u$Color_Off "
fi
if [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ] ; then
    __ssh_host_ps1="$Blue\h$Color_Off "
fi
function fommil_ps1 {
    GIT_PS1_SHOWDIRTYSTATE=true
    local __git_branch="$Purple"'$(__git_ps1 "%s ")'"$Color_Off"
    local __location="$IWhite\w$Color_Off"
    export PS1="$__root_warning_ps1$__ssh_host_ps1$__git_branch$__location "
}
if [ -z "$INSIDE_EMACS" ] && [ "$(type -t __git_ps1)" = "function" ] ; then
    fommil_ps1
fi

# complicated aliases
function docker-nuke {
    docker rm $(docker ps -aq)
    docker rmi $(docker images | grep '^<none>' | awk '{print $3}')
}

# Local settings and overrides
source_if_exists ~/.bashrc.local
source_if_exists ~/.aliases
source_if_exists ~/.aliases.local
source_if_exists ~/.aliases.sec
