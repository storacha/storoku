package main

import (
	"context"
	"errors"
	"fmt"

	"github.com/urfave/cli/v3"
)

var networkCmd = &cli.Command{
	Name:  "network",
	Usage: "add and remove networks",
	Commands: []*cli.Command{
		networkAddCmd,
		networkRemoveCmd,
	},
}

var networkAddCmd = &cli.Command{
	Name: "add",
	Arguments: []cli.Argument{
		&cli.StringArg{
			Name: "name",
		},
	},
	Action: modifyAndRegenerate(func(ctx context.Context, cmd *cli.Command, c *Config) error {
		networkName := cmd.StringArg("name")
		if networkName == "" {
			return errors.New("must specify network name")
		}
		if networkName == "hot" {
			return errors.New("cannot add 'hot' network - it's the default and always exists")
		}
		for _, net := range c.Networks {
			if net == networkName {
				return fmt.Errorf("cannot add network: network '%s' already exists", networkName)
			}
		}
		c.Networks = append(c.Networks, networkName)
		return nil
	}),
}

var networkRemoveCmd = &cli.Command{
	Name: "remove",
	Arguments: []cli.Argument{
		&cli.StringArg{
			Name: "name",
		},
	},
	Action: modifyAndRegenerate(func(ctx context.Context, cmd *cli.Command, c *Config) error {
		networkName := cmd.StringArg("name")
		if networkName == "" {
			return errors.New("must specify network name")
		}
		if networkName == "hot" {
			return errors.New("cannot remove 'hot' network - it's the default and always exists")
		}
		for i, net := range c.Networks {
			if net == networkName {
				c.Networks = append(c.Networks[:i], c.Networks[i+1:]...)
				return nil
			}
		}
		return fmt.Errorf("cannot remove network: network '%s' does not exist", networkName)
	}),
}
