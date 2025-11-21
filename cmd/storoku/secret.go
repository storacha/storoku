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
	Flags: []cli.Flag{
		&cli.BoolFlag{
			Name:        "variable",
			Value:       false,
			DefaultText: "specifies whether this value is specified through a terraform variable or auto generated",
		},
		&cli.BoolFlag{
			Name:        "external",
			Value:       false,
			DefaultText: "specifies whether this secret is provisioned externally (out-of-band) in AWS Secrets Manager",
		},
	},
	Action: modifyAndRegenerate(func(ctx context.Context, cmd *cli.Command, c *Config) error {
		secretValue := cmd.StringArg("secret")
		variable := cmd.Bool("variable")
		external := cmd.Bool("external")

		if secretValue == "" {
			return errors.New("must specify secret")
		}
		if external && variable {
			return errors.New("cannot specify both --external and --variable flags")
		}
		for _, secret := range c.Secrets {
			if secret.Name == secretValue {
				return errors.New("cannot add secret: secret already exists")
			}
		}
		c.Secrets = append(c.Secrets, Secret{Name: secretValue, Variable: variable, External: external})
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
		secretValue := cmd.StringArg("secret")
		if secretValue == "" {
			return errors.New("must specify secret")
		}
		for i, secret := range c.Secrets {
			if secret.Name == secretValue {
				c.Secrets = append(c.Secrets[:i], c.Secrets[i+1:]...)
				return nil
			}
		}
		return errors.New("cannot remove secret: secret does not exist")
	}),
}
