package main

import (
	"context"

	"github.com/urfave/cli/v3"
)

var cloudflareCmd = &cli.Command{
	Name:  "cloudflare",
	Usage: "modify cloudflare settings",
	Commands: []*cli.Command{
		cloudflareOnCmd,
		cloudflareOffCmd,
	},
}

var cloudflareOnCmd = &cli.Command{
	Name: "on",
	Action: modifyAndRegenerate(func(ctx context.Context, cmd *cli.Command, c *Config) error {
		c.Cloudflare = true
		return nil
	}),
}

var cloudflareOffCmd = &cli.Command{
	Name: "off",
	Action: modifyAndRegenerate(func(ctx context.Context, cmd *cli.Command, c *Config) error {
		c.Cloudflare = false
		return nil
	}),
}
