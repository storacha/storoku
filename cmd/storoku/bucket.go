package main

import (
	"context"
	"errors"

	"github.com/urfave/cli/v3"
)

var bucketCmd = &cli.Command{
	Name:  "bucket",
	Usage: "add and remove buckets",
	Commands: []*cli.Command{
		bucketAddCmd,
		bucketRemoveCmd,
	},
}

var bucketAddCmd = &cli.Command{
	Name: "add",
	Arguments: []cli.Argument{
		&cli.StringArg{
			Name: "bucket",
		},
	},
	Flags: []cli.Flag{
		&cli.BoolFlag{
			Name:        "public",
			Value:       false,
			DefaultText: "specify if the bucket will be public",
		},
	},
	Action: modifyAndRegenerate(func(ctx context.Context, cmd *cli.Command, c *Config) error {
		bucketName := cmd.StringArg("bucket")
		if bucketName == "" {
			return errors.New("must specify bucket")
		}
		for _, bucket := range c.Buckets {
			if bucket.Name == bucketName {
				return errors.New("cannot add bucket: bucket already exists")
			}
		}
		public := cmd.Bool("public")
		c.Buckets = append(c.Buckets, Bucket{
			Name:   bucketName,
			Public: public,
		})
		return nil
	}),
}

var bucketRemoveCmd = &cli.Command{
	Name: "remove",
	Arguments: []cli.Argument{
		&cli.StringArg{
			Name: "bucket",
		},
	},
	Action: modifyAndRegenerate(func(ctx context.Context, cmd *cli.Command, c *Config) error {
		bucketName := cmd.StringArg("bucket")
		if bucketName == "" {
			return errors.New("must specify bucket")
		}
		for i, bucket := range c.Buckets {
			if bucket.Name == bucketName {
				c.Buckets = append(c.Buckets[:i], c.Buckets[i+1:]...)
				return nil
			}
		}
		return errors.New("cannot remove bucket: bucket does not exist")
	}),
}
