#!/bin/bash

printf '%s
' 'Activating Nix shell environment...'

# 1. Source the Nix profile script from the *built derivation*.
# The path variable has been substituted here by the outer shell, so this line is a clean source command
# This command is the CRITICAL step that sets PATH, man pages, and other environment variables.
# This is also a shell command, equivalent to the source builtin
# Recommended fix for default.R (line ~204)
# This command is the CRITICAL step that sets PATH, man pages, and other environment variables.
true && source /nix/store/qryfby7sb4ikv5a28x992qyhfd93sa36-nix-shell/etc/profile.d/nix-shell.sh

# 2. Run environment activation hooks (if defined by Nix)
if declare -f __start_nix_shell_environment > /dev/null; then
    __start_nix_shell_environment
fi

# 3. Fix R Console Libraries: Ensure R finds the Nix-built packages.
# The R_LIB_PATH variable must still be escaped to prevent outer shell expansion here.
# DISABLED: This path doesn't exist - NIX_SHELL_PATH is the shell script, not a directory
# R_LIBS_USER should already be set by the Nix environment

# 4. Final confirmation before launch
printf '%s
' 'Nix environment fully sourced.'

# 5. Ensure readline is configured for history navigation
# Create a temporary .bashrc for this session with readline settings
echo '# Nix shell readline configuration' > ~/.nix-shell-bashrc
echo 'set -o emacs' >> ~/.nix-shell-bashrc
echo 'bind "\e[A": history-search-backward"' >> ~/.nix-shell-bashrc
echo 'bind "\e[B": history-search-forward"' >> ~/.nix-shell-bashrc
echo 'bind "\e[C": forward-char"' >> ~/.nix-shell-bashrc
echo 'bind "\e[D": backward-char"' >> ~/.nix-shell-bashrc
echo '' >> ~/.nix-shell-bashrc
echo '# Source user bashrc if it exists' >> ~/.nix-shell-bashrc
echo 'if [ -f ~/.bashrc ]; then source ~/.bashrc; fi' >> ~/.nix-shell-bashrc

# 6. Launch the interactive shell with custom bashrc
# exec replaces the current process with the new shell, making it the final terminal session.
exec /usr/bin/env bash --rcfile ~/.nix-shell-bashrc -i

