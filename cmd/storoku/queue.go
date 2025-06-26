package main

import (
	"context"
	"errors"

	"github.com/urfave/cli/v3"
)

var queueCmd = &cli.Command{
	Name:  "queue",
	Usage: "add and remove queues",
	Commands: []*cli.Command{
		queueAddCmd,
		queueRemoveCmd,
	},
}

var queueAddCmd = &cli.Command{
	Name: "add",
	Arguments: []cli.Argument{
		&cli.StringArg{
			Name: "queue",
		},
	},
	Flags: []cli.Flag{
		&cli.BoolFlag{
			Name:        "fifo",
			Value:       false,
			DefaultText: "specify if the queue will be fifo",
		},
		&cli.IntFlag{
			Name:        "msg-retention-seconds",
			Value:       0,
			DefaultText: "message retention period in seconds (default: 345600 (4 days), min: 60 (1 min), max: 1209600 (14 days))",
		},
	},
	Action: modifyAndRegenerate(func(ctx context.Context, cmd *cli.Command, c *Config) error {
		queueName := cmd.StringArg("queue")
		if queueName == "" {
			return errors.New("must specify queue")
		}
		for _, queue := range c.Queues {
			if queue.Name == queueName {
				return errors.New("cannot add queue: queue already exists")
			}
		}
		fifo := cmd.Bool("fifo")
		retention := cmd.Int("msg-retention-seconds")

		// Validate retention period
		if retention != 0 {
			if retention < 60 || retention > 1209600 {
				return errors.New("message retention must be between 60 seconds (1 min) and 1209600 seconds (14 days)")
			}
		}

		queue := Queue{
			Name:                    queueName,
			Fifo:                    fifo,
			MessageRetentionSeconds: retention,
		}

		c.Queues = append(c.Queues, queue)
		return nil
	}),
}

var queueRemoveCmd = &cli.Command{
	Name: "remove",
	Arguments: []cli.Argument{
		&cli.StringArg{
			Name: "queue",
		},
	},
	Action: modifyAndRegenerate(func(ctx context.Context, cmd *cli.Command, c *Config) error {
		queueName := cmd.StringArg("queue")
		if queueName == "" {
			return errors.New("must specify queue")
		}
		for i, queue := range c.Queues {
			if queue.Name == queueName {
				c.Queues = append(c.Queues[:i], c.Queues[i+1:]...)
				return nil
			}
		}
		return errors.New("cannot remove queue: queue does not exist")
	}),
}
