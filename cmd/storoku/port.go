package main

import (
	"context"
	"errors"

	"github.com/urfave/cli/v3"
)

var portCmd = &cli.Command{
	Name:  "port",
	Usage: "modify port settings",
	Commands: []*cli.Command{
		portCustomCmd,
		portStandardCmd,
	},
}

var portCustomCmd = &cli.Command{
	Name:  "custom",
	Usage: "set a custom port",
	Arguments: []cli.Argument{
		&cli.IntArg{
			Name: "port",
		},
	},
	Action: modifyAndRegenerate(func(ctx context.Context, cmd *cli.Command, c *Config) error {
		port := cmd.IntArg("port")
		if port == 0 {
			return errors.New("must specify a custom port")
		}
		c.Port = port
		return nil
	}),
}

var portStandardCmd = &cli.Command{
	Name:  "standard",
	Usage: "reset to standard port settings",
	Action: modifyAndRegenerate(func(ctx context.Context, cmd *cli.Command, c *Config) error {
		c.Port = 0
		return nil
	}),
}
