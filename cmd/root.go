package cmd

import (
	"fmt"
	"os"
	"slices"

	"github.com/cpendery/kaldo/config"
	"github.com/cpendery/kaldo/shell"
	"github.com/spf13/cobra"
)

var (
	rootCmd = &cobra.Command{
		Use:          `kaldo`,
		Short:        "shared aliases between shells",
		RunE:         rootExec,
		SilenceUsage: true,
	}
	rootShell string
)

func init() {
	rootCmd.Flags().StringVarP(&rootShell, "shell", "s", "", fmt.Sprintf("the shell to create completions for, valid shells: %q", shell.ValidShells))
}

func rootExec(cmd *cobra.Command, args []string) error {
	if rootShell == "" || !slices.Contains(shell.ValidShells, rootShell) {
		return fmt.Errorf("provide a valid shell to generate completions for via the --shell flag, received %s", rootShell)
	}

	config, err := config.Load()
	if err != nil {
		return fmt.Errorf("configs failed to load: %w", err)
	}

	aliasScript := shell.GenerateShellAliases(config, rootShell)
	fmt.Print(aliasScript)

	return nil
}

func Execute() {
	if err := rootCmd.Execute(); err != nil {
		os.Exit(1)
	}
}
