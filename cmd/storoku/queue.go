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
	},
	Action: modifyAndRegenerate(func(ctx context.Context, cmd *cli.Command, c *Config) error {
		if cmd.Args().Len() < 1 {
			return errors.New("must specify queue")
		}
		queueName := cmd.StringArg("queue")
		for _, queue := range c.Queues {
			if queue.Name == queueName {
				return errors.New("cannot add queue: queue already exists")
			}
		}
		fifo := cmd.Bool("fifo")
		c.Queues = append(c.Queues, Queue{
			Name: queueName,
			Fifo: fifo,
		})
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
		if cmd.Args().Len() < 1 {
			return errors.New("must specify queue")
		}
		queueName := cmd.StringArg("queue")
		for i, queue := range c.Queues {
			if queue.Name == queueName {
				c.Queues = append(c.Queues[:i], c.Queues[i+1:]...)
				return nil
			}
		}
		return errors.New("cannot remove queue: queue does not exist")
	}),
}
