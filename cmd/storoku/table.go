package main

import (
	"context"
	"errors"

	"github.com/urfave/cli/v3"
)

var tableCmd = &cli.Command{
	Name:  "table",
	Usage: "add and remove tables",
	Commands: []*cli.Command{
		tableAddCmd,
		tableRemoveCmd,
	},
}

var tableAddCmd = &cli.Command{
	Name: "add",
	Arguments: []cli.Argument{
		&cli.StringArg{
			Name: "table",
		},
	},
	Flags: []cli.Flag{
		&cli.StringFlag{
			Name:        "hash-key-name",
			Required:    true,
			DefaultText: "specify the hash key name for the table",
		},
		&cli.StringFlag{
			Name:        "hash-key-kind",
			Value:       "S",
			DefaultText: "specify the hash key kind for the table (S = String, B = Binary, N = Number)",
		},
	},
	Action: modifyAndRegenerate(func(ctx context.Context, cmd *cli.Command, c *Config) error {
		tableName := cmd.StringArg("table")
		if tableName == "" {
			return errors.New("must specify table")
		}
		for _, table := range c.Tables {
			if table.Name == tableName {
				return errors.New("cannot add table: table already exists")
			}
		}
		hashKey := cmd.String("hash-key-name")
		hashKeyKind := cmd.String("hash-key-kind")
		c.Tables = append(c.Tables, Table{
			Name:    tableName,
			HashKey: hashKey,
			Attributes: []Attribute{
				{
					Name: hashKey,
					Type: hashKeyKind,
				},
			},
		})
		return nil
	}),
}

var tableRemoveCmd = &cli.Command{
	Name: "remove",
	Arguments: []cli.Argument{
		&cli.StringArg{
			Name: "table",
		},
	},
	Action: modifyAndRegenerate(func(ctx context.Context, cmd *cli.Command, c *Config) error {
		tableName := cmd.StringArg("table")
		if tableName == "" {
			return errors.New("must specify table")
		}
		for i, table := range c.Tables {
			if table.Name == tableName {
				c.Tables = append(c.Tables[:i], c.Tables[i+1:]...)
				return nil
			}
		}
		return errors.New("cannot remove table: table does not exist")
	}),
}
