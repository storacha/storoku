package main

import (
	"context"

	"github.com/urfave/cli/v3"
)

var databaseCmd = &cli.Command{
	Name:  "database",
	Usage: "modify database settings",
	Commands: []*cli.Command{
		databaseOnCmd,
		databaseOffCmd,
	},
}

var databaseOnCmd = &cli.Command{
	Name: "on",
	Action: modifyAndRegenerate(func(ctx context.Context, cmd *cli.Command, c *Config) error {
		c.CreateDB = true
		return nil
	}),
}

var databaseOffCmd = &cli.Command{
	Name: "off",
	Action: modifyAndRegenerate(func(ctx context.Context, cmd *cli.Command, c *Config) error {
		c.CreateDB = false
		return nil
	}),
}
