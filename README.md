# kaldo

`kaldo` provides the ability to share aliases across all your shells. It supports Windows, Linux, & macOS along with `bash`, `zsh`, `fish`, `pwsh`, and `powershell` (Windows Powershell).

## Installation

TODO

## Initialize Shell Plugin

After installation, you need to initialize the shell plugin for each shell you want to share aliases with. After using your respective shell commands below, restart your shell to get shared aliases.

```shell
# bash
echo "$(kaldo init bash)" >> ~/.bashrc

# zsh
echo "$(kaldo init zsh)" >> ~/.zshrc

# fish
echo "$(kaldo init fish)" >> ~/.config/fish/config.fish

# pwsh
echo "$(kaldo init pwsh)" >> $profile

# powershell
echo "$(kaldo init powershell)" >> $profile
```

## Configure Aliases

All aliases are stored inside your `~/.kaldorc` file. Below is an example of how to define shell specific and cross shell aliases.

```toml
# .kaldorc

ek = 'echo "kaldo"' # when outside of a table, the alias is loaded for all your shells

[bash]
ek = 'echo "kaldo on bash"' # inside the bash table, this alias is only provided for bash and overrides your shared alias
```