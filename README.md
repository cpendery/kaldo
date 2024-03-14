# kaldo

`kaldo` provides the ability to share aliases across all your shells. It supports Windows, Linux, & macOS along with `bash`, `zsh`, `fish`, `pwsh`, and `powershell` (Windows Powershell).

## Installation

### Go >= 1.17

```shell
go install github.com/cpendery/kaldo@latest
```

### Go < 1.17

```shell
go get github.com/cpendery/kaldo
```


## Initialize Shell Plugin

After installation, you need to initialize the shell plugin for each shell you want to share aliases with. After using your respective shell commands below, restart your shell to get shared aliases.

```shell
# bash
echo $(kaldo init bash) >> ~/.bashrc

# zsh
echo $(kaldo init zsh) >> ~/.zshrc

# fish
echo $(kaldo init fish) >> ~/.config/fish/config.fish

# pwsh
echo $(kaldo init pwsh) >> $profile

# powershell
echo $(kaldo init powershell) >> $profile
```

## Configure Aliases

All aliases are stored inside your `~/.kaldorc` toml file. Below is an example of how to define shell specific and cross shell aliases. The following tables result in custom aliases while no table results in an alias for every shell.

- `bash`: aliases for the bash shell
- `zsh`: aliases for the zsh shell
- `fish`: aliases for the fish shell
- `powershell`: aliases for Windows Powershell
- `pwsh`: aliases for Powershell Core

There are also 2 custom group tables that help reduce duplication across similar shells.

- `sh`: aliases for `bash`, `zsh`, and `fish`
- `power`: aliases for `powershell` and `pwsh`

```toml
# .kaldorc
ek = 'echo "kaldo"' # when outside of a table, the alias is loaded for all your shells

[bash]
ek = 'echo "kaldo on bash"' # inside the bash table, this alias is only provided for bash and overrides your shared alias
```