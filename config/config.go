package config

import (
	"fmt"
	"os"
	"path/filepath"
	"runtime"
	"strings"

	"github.com/BurntSushi/toml"
	"github.com/cpendery/kaldo/shell"
)

const configFilename = ".kaldorc"

func isWSL() (bool, error) {
	versionContents, err := os.ReadFile("/proc/version")
	if err != nil {
		return false, fmt.Errorf("unable to read /proc/version: %w", err)
	}
	if strings.Contains(strings.ToLower(string(versionContents)), "microsoft") {
		return true, nil
	}
	return false, nil
}

func getConfigPaths() ([]string, error) {
	homeDir, err := os.UserHomeDir()
	if err != nil {
		return nil, fmt.Errorf("unable to read user home directory: %w", err)
	}
	configPaths := []string{filepath.Join(homeDir, configFilename)}
	if runtime.GOOS == "linux" {
		wsl, err := isWSL()
		if err != nil {
			return nil, fmt.Errorf("unable to detect if running in WSL: %w", err)
		}
		if wsl {
			configPaths = append(configPaths, filepath.Join("mnt", "c", "Users", filepath.Base(homeDir), configFilename))
		}
	}
	return configPaths, nil
}

func Load() (*map[string]interface{}, error) {
	configPaths, err := getConfigPaths()
	if err != nil {
		return nil, fmt.Errorf("unable to determine config location: %w", err)
	}

	configs := []map[string]interface{}{}
	for _, configPath := range configPaths {
		if _, err := os.Stat(configPath); err == nil {
			config, err := os.ReadFile(configPath)
			if err != nil {
				return nil, fmt.Errorf("unable to read config: %w", err)
			}
			configToml := map[string]interface{}{}
			if _, err := toml.Decode(string(config), &configToml); err != nil {
				return nil, fmt.Errorf("unable to parse config: %w", err)
			}
			configs = append(configs, configToml)
		}
	}

	config := map[string]interface{}{}
	for idx, configToml := range configs {
		configPath := configPaths[idx]
		for key, value := range configToml {
			switch key {
			case shell.Powershell, shell.WindowsPowershell, shell.Bash, shell.Zsh, shell.Fish:
				switch aliasMap := value.(type) {
				case map[string]interface{}:
					for alias, value := range aliasMap {
						switch cmd := value.(type) {
						case string:
							if _, ok := config[key]; !ok {
								config[key] = map[string]string{}
							}
							if _, ok := config[key].(map[string]string)[alias]; ok {
								return nil, fmt.Errorf("duplicate entry for %s.%s", key, alias)
							} else {
								config[key].(map[string]string)[alias] = cmd
							}
						default:
							return nil, fmt.Errorf("invalid value for %s, expected string for alias comand: error in %s", alias, configPath)
						}
					}
				default:
					return nil, fmt.Errorf("invalid value for shell %s, expected an alias-command key-pair: error in %s", key, configPath)
				}
			default:
				switch cmd := value.(type) {
				case string:
					if _, ok := config[key]; ok {
						return nil, fmt.Errorf("duplicate entry for %s: error in %s", key, configPath)
					} else {
						config[key] = cmd
					}
				default:
					return nil, fmt.Errorf("invalid value for %s, expected string for alias command: error in %s", key, configPath)
				}
			}
		}
	}
	return &config, nil
}
