package cmd

import (
	"errors"
	"fmt"
	"slices"
	"strings"

	"github.com/cpendery/kaldo/shell"
	"github.com/spf13/cobra"
)

var (
	initCmd = &cobra.Command{
		Use:   `init <shell>`,
		Short: "install kaldo's shell plugin",
		RunE:  initExec,
		Args: func(_ *cobra.Command, args []string) error {
			switch len(args) {
			case 1:
				shellArg := strings.ToLower(args[0])
				if !slices.Contains(shell.ValidShells, shellArg) {
					return fmt.Errorf("provide a valid shell to generate the shell plugin, received %s, valid shells: %q", rootShell, shell.ValidShells)
				}
				return nil
			default:
				return errors.New("requires a single shell to be provided to generate the shell plugin for")
			}
		},
		SilenceUsage: true,
	}
)

func init() {
	rootCmd.AddCommand(initCmd)
}

func initExec(_ *cobra.Command, args []string) error {
	fmt.Print("\n\n# ---------------- kaldo shell plugin ----------------\n" + shell.GenerateShellInjection(args[0]) + "\n")
	return nil
}
