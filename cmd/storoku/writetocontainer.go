package main

import (
	"context"

	"github.com/urfave/cli/v3"
)

var writeToContainerCmd = &cli.Command{
	Name:  "write-to-container",
	Usage: "modify write-to-container settings",
	Commands: []*cli.Command{
		writeToContainerOnCmd,
		writeToContainerOffCmd,
	},
}

var writeToContainerOnCmd = &cli.Command{
	Name: "on",
	Action: modifyAndRegenerate(func(ctx context.Context, cmd *cli.Command, c *Config) error {
		c.WriteToContainer = true
		return nil
	}),
}

var writeToContainerOffCmd = &cli.Command{
	Name: "off",
	Action: modifyAndRegenerate(func(ctx context.Context, cmd *cli.Command, c *Config) error {
		c.WriteToContainer = false
		return nil
	}),
}
