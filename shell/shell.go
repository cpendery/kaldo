package shell

import (
	"fmt"
	"strings"
)

type Shell = string

const (
	Bash              Shell = "bash"
	Zsh               Shell = "zsh"
	WindowsPowershell Shell = "powershell"
	Powershell        Shell = "pwsh"
	Fish              Shell = "fish"
)

type ShellGroup = string

const (
	PowerGroup ShellGroup = "power"
	ShGroup    ShellGroup = "sh"
)

const (
	shInjection         = `which kaldo &> /dev/null && eval "$(kaldo -s %s)"`
	powershellInjection = `if (Get-Command "kaldo.exe" -ErrorAction SilentlyContinue) { $aliases = kaldo -s %s | Out-String ; . { Invoke-Expression $aliases } }`
)

var ValidShells = []Shell{Bash, Zsh, WindowsPowershell, Powershell, Fish}

func GenerateShellAliases(config *map[string]interface{}, shell Shell) string {
	aliases := extractAliases(config, shell)
	switch shell {
	case Bash, Zsh, Fish:
		return generateShAliases(aliases)
	case Powershell, WindowsPowershell:
		return generatePowershellAliases(aliases)
	}
	return ""
}

func extractAliases(config *map[string]interface{}, shell Shell) *map[string]string {
	aliases := map[string]string{}
	for key, cmd := range *config {
		switch key {
		case Bash, Zsh, WindowsPowershell, Powershell, Fish:
		default:
			aliases[key] = cmd.(string)
		}
	}
	if shellConfig, ok := (*config)[shell]; ok {
		for alias, cmd := range shellConfig.(map[string]string) {
			aliases[alias] = cmd
		}
	}
	return &aliases
}

func generateShAliases(aliases *map[string]string) string {
	builder := strings.Builder{}
	for alias, cmd := range *aliases {
		builder.WriteString(fmt.Sprintf("alias %s='%s'\n", alias, cmd))
	}
	return builder.String()
}

func generatePowershellAliases(aliases *map[string]string) string {
	builder := strings.Builder{}
	for alias, cmd := range *aliases {
		builder.WriteString(fmt.Sprintf("Remove-Item Alias:%s -Force -ErrorAction SilentlyContinue\n", alias))
		builder.WriteString(fmt.Sprintf("function kaldo-%s() {\n%s $args\n}\n", alias, cmd))
		builder.WriteString(fmt.Sprintf("Set-Alias -Name '%s' -Value 'kaldo-%s'\n\n", alias, alias))
	}
	return builder.String()
}

func GenerateShellInjection(shell Shell) string {
	switch shell {
	case Bash, Zsh, Fish:
		return fmt.Sprintf(shInjection, shell)
	case Powershell, WindowsPowershell:
		return fmt.Sprintf(powershellInjection, shell)
	}
	return ""
}
