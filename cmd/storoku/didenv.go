package main

import (
	"context"
	"errors"

	"github.com/urfave/cli/v3"
)

var didEnvCmd = &cli.Command{
	Name:  "didenv",
	Usage: "set custom or standard env vars for did public and private key values",
	Commands: []*cli.Command{
		didEnvPrivateCmd,
		didEnvPublicCmd,
	},
}

var didEnvPublicCmd = &cli.Command{
	Name:  "public",
	Usage: "modify did environment public key environment variable name",
	Commands: []*cli.Command{
		didEnvPublicCustomCmd,
		didEnvPublicStandardCmd,
	},
}

var didEnvPublicCustomCmd = &cli.Command{
	Name:  "custom",
	Usage: "set a custom public key environment variable name",
	Arguments: []cli.Argument{
		&cli.StringArg{
			Name: "public-key-env-var",
		},
	},
	Action: modifyAndRegenerate(func(ctx context.Context, cmd *cli.Command, c *Config) error {
		publicKeyEnvVar := cmd.StringArg("public-key-env-var")
		if publicKeyEnvVar == "" {
			return errors.New("must specify a custom public key environment variable")
		}
		c.DIDEnvVar = publicKeyEnvVar
		return nil
	}),
}

var didEnvPublicStandardCmd = &cli.Command{
	Name:  "standard",
	Usage: "reset to standard public key environment variable name",
	Action: modifyAndRegenerate(func(ctx context.Context, cmd *cli.Command, c *Config) error {
		c.DIDEnvVar = ""
		return nil
	}),
}

var didEnvPrivateCmd = &cli.Command{
	Name:  "private",
	Usage: "modify did environment private key environment variable name",
	Commands: []*cli.Command{
		didEnvPrivateCustomCmd,
		didEnvPrivateStandardCmd,
	},
}

var didEnvPrivateCustomCmd = &cli.Command{
	Name:  "custom",
	Usage: "set a custom private key environment variable name",
	Arguments: []cli.Argument{
		&cli.StringArg{
			Name: "private-key-env-var",
		},
	},
	Action: modifyAndRegenerate(func(ctx context.Context, cmd *cli.Command, c *Config) error {
		privateKeyEnvVar := cmd.StringArg("private-key-env-var")
		if privateKeyEnvVar == "" {
			return errors.New("must specify a custom private key environment variable")
		}
		c.PrivateKeyEnvVar = privateKeyEnvVar
		return nil
	}),
}

var didEnvPrivateStandardCmd = &cli.Command{
	Name:  "standard",
	Usage: "reset to standard private key environment variable name",
	Action: modifyAndRegenerate(func(ctx context.Context, cmd *cli.Command, c *Config) error {
		c.PrivateKeyEnvVar = ""
		return nil
	}),
}
