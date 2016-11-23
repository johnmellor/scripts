# scripts
Miscellaneous Bash and Python scripts

## Installation

```bash
$ mkdir ~/Code
$ cd ~/Code
$ git clone https://github.com/johnmellor/scripts.git
$ scripts/setup.sh
$ echo 'source ~/Code/scripts/main.bash' >> ~/.bashrc
$ echo 'export PATH="$PATH:$HOME/Code/scripts/bin"' >> ~/.profile
```

On [WSL](https://msdn.microsoft.com/commandline/wsl), you'll also need to append `--login` to the "Bash on Ubuntu on Windows" shortcut command line (resulting in `C:\Windows\System32\bash.exe ~ --login`) or else [Bash won't source ~/.profile](https://wpdev.uservoice.com/forums/266908-command-prompt-console-bash-on-ubuntu-on-windo/suggestions/14825565-open-bash-as-a-login-shell-by-default).

## Tested on

- Ubuntu Trusty (64-bit) + Bash 4.3.11(1)-release
- Windows 7 (64-bit) + [MSYS2](https://msys2.github.io/) + Bash 4.3.33(3)-release
- Windows 7 (64-bit) + [Cygwin](https://www.cygwin.com/) + Bash 4.3.33(1)-release
- Windows 10 (64-bit) + [WSL](https://msdn.microsoft.com/commandline/wsl) + Bash 4.3.11(1)-release
