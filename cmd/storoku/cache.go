package main

import (
	"context"
	"errors"

	"github.com/urfave/cli/v3"
)

var cacheCmd = &cli.Command{
	Name:  "cache",
	Usage: "add and remove caches",
	Commands: []*cli.Command{
		cacheAddCmd,
		cacheRemoveCmd,
	},
}

var cacheAddCmd = &cli.Command{
	Name: "add",
	Arguments: []cli.Argument{
		&cli.StringArg{
			Name: "cache",
		},
	},
	Action: modifyAndRegenerate(func(ctx context.Context, cmd *cli.Command, c *Config) error {
		cacheValue := cmd.StringArg("cache")
		if cacheValue == "" {
			return errors.New("must specify cache")
		}
		for _, cache := range c.Caches {
			if cache == cacheValue {
				return errors.New("cannot add cache: cache already exists")
			}
		}
		c.Caches = append(c.Caches, cacheValue)
		return nil
	}),
}

var cacheRemoveCmd = &cli.Command{
	Name: "remove",
	Arguments: []cli.Argument{
		&cli.StringArg{
			Name: "cache",
		},
	},
	Action: modifyAndRegenerate(func(ctx context.Context, cmd *cli.Command, c *Config) error {
		cacheValue := cmd.StringArg("cache")
		if cacheValue == "" {
			return errors.New("must specify cache")
		}
		for i, cache := range c.Caches {
			if cache == cacheValue {
				c.Caches = append(c.Caches[:i], c.Caches[i+1:]...)
				return nil
			}
		}
		return errors.New("cannot remove cache: cache does not exist")
	}),
}
