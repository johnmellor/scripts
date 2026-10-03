git config --global merge.conflictstyle diff3

# git config --global diff.tool meld
# git config --global difftool.prompt false
#
# git config --global merge.tool p4merge
# git config --global mergetool.keepBackup false

# Experimenting with VS Code as difftool and mergetool
# https://code.visualstudio.com/docs/sourcecontrol/overview#_vs-code-as-git-difftool-and-mergetool:

git config --global diff.tool vscode
git config --global difftool.vscode.cmd 'code --wait --diff "$LOCAL" "$REMOTE"'

git config --global merge.tool vscode
git config --global mergetool.vscode.cmd 'code --wait --merge "$REMOTE" "$LOCAL" "$BASE" "$MERGED"'
