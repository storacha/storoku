package main

import (
	"context"
	"errors"

	"github.com/urfave/cli/v3"
)

var secretCmd = &cli.Command{
	Name:  "secret",
	Usage: "add and remove secrets",
	Commands: []*cli.Command{
		secretAddCmd,
		secretRemoveCmd,
	},
}

var secretAddCmd = &cli.Command{
	Name: "add",
	Arguments: []cli.Argument{
		&cli.StringArg{
			Name: "secret",
		},
	},
	Action: modifyAndRegenerate(func(ctx context.Context, cmd *cli.Command, c *Config) error {
		if cmd.Args().Len() < 1 {
			return errors.New("must specify secret")
		}
		secretValue := Secret(cmd.StringArg("secret"))
		for _, secret := range c.Secrets {
			if secret == secretValue {
				return errors.New("cannot add secret: secret already exists")
			}
		}
		c.Secrets = append(c.Secrets, secretValue)
		return nil
	}),
}

var secretRemoveCmd = &cli.Command{
	Name: "remove",
	Arguments: []cli.Argument{
		&cli.StringArg{
			Name: "secret",
		},
	},
	Action: modifyAndRegenerate(func(ctx context.Context, cmd *cli.Command, c *Config) error {
		if cmd.Args().Len() < 1 {
			return errors.New("must specify secret")
		}
		secretValue := Secret(cmd.StringArg("secret"))
		for i, secret := range c.Secrets {
			if secret == secretValue {
				c.Secrets = append(c.Secrets[:i], c.Secrets[i+1:]...)
				return nil
			}
		}
		return errors.New("cannot remove secret: secret does not exist")
	}),
}
