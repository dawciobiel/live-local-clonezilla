#!/bin/bash
# =============================================================================
# File: /etc/profile.d/aliases.sh
# Description:
#   Global aliases for all users (including root and user).
#   This file is sourced automatically by login shells.
# =============================================================================

# Enable color support for common commands
alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'

# Useful ls aliases
alias ll='ls -lah --color=auto'
alias la='ls -A --color=auto'
alias l='ls -CF --color=auto'

# Safety aliases
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# Clear screen shortcut
alias c='clear'

# Hardclone CLI
alias hardclone-cli='cd /opt/hardclone-cli; python3 hcli.py'
alias hcli='cd /opt/hardclone-cli; python3 hcli.py'
