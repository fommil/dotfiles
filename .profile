#!/bin/sh

function source_if_exists {
    if [ -f "$1" ] ; then
        source "$1"
    fi
}

# https://stackoverflow.com/a/820533/1041691
source_if_exists $HOME/.bashrc

# FIXME: I'm getting logged in twice in xmonad's shell and I don't know why
if [ -z "$FOMMIL_LOGGED_IN" ] ; then
    echo "DEBUG: was logged in already"
    return
fi
export FOMMIL_LOGGED_IN=t

export PATH=$HOME/.cabal/bin:$HOME/.ghcup/bin:$HOME/.local/bin:$HOME/.fommil/bin:$PATH

export EDITOR=emacs
export HISTCONTROL=ignoredups
export WINEARCH=win32
export WINEDEBUG=fixme-all,warn+cursor

export HTML_TIDY=$HOME/.tidyrc
export COWPATH=$HOME/.cows:/usr/share/cowsay/cows

# place local system fixes in here
source_if_exists $HOME/.profile.local
source_if_exists $HOME/.profile.sec

if [ ! -f ~/.inputrc ] && [ -f /etc/inputrc ] ; then
    export INPUTRC=/etc/inputrc
fi
