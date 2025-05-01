package main

import (
	"context"
	"errors"

	"github.com/urfave/cli/v3"
)

var domainCmd = &cli.Command{
	Name:  "domain",
	Usage: "modify domain settings",
	Commands: []*cli.Command{
		domainCustomCmd,
		domainStandardCmd,
	},
}

var domainCustomCmd = &cli.Command{
	Name:  "custom",
	Usage: "set a custom domain base",
	Arguments: []cli.Argument{
		&cli.StringArg{
			Name: "domain-base",
		},
	},
	Action: modifyAndRegenerate(func(ctx context.Context, cmd *cli.Command, c *Config) error {
		if cmd.Args().Len() < 1 {
			return errors.New("must specify a custom domain base")
		}
		c.DomainBase = cmd.StringArg("domain-base")
		return nil
	}),
}

var domainStandardCmd = &cli.Command{
	Name:  "standard",
	Usage: "reset to standard domain settings",
	Action: modifyAndRegenerate(func(ctx context.Context, cmd *cli.Command, c *Config) error {
		c.DomainBase = ""
		return nil
	}),
}
