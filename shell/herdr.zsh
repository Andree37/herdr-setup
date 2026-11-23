# Sourced from ~/.zshrc. Only does anything inside a herdr pane.
#
# Claude runs in the pane's shell, so quitting claude drops you back to that
# shell. A Ctrl+D meant for claude would then exit the shell and close the tab;
# ignore it here (type `exit` to really close).
[[ -n $HERDR_PANE_ID ]] || return 0
setopt IGNORE_EOF
