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
		&cli.IntFlag{
			Name:        "object-expiration-days",
			Value:       0,
			DefaultText: "number of days after which objects will expire (0 = no expiration, min: 1, max: 2147483647)",
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
		expirationDays := cmd.Int("object-expiration-days")

		// Validate expiration days
		if expirationDays < 0 || expirationDays > 2147483647 {
			return errors.New("object-expiration-days must be 0 (no expiration) or between 1 and 2147483647 days")
		}

		c.Buckets = append(c.Buckets, Bucket{
			Name:                 bucketName,
			Public:               public,
			ObjectExpirationDays: expirationDays,
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
