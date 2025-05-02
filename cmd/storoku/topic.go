package main

import (
	"context"
	"errors"

	"github.com/urfave/cli/v3"
)

var topicCmd = &cli.Command{
	Name:  "topic",
	Usage: "add and remove topics",
	Commands: []*cli.Command{
		topicAddCmd,
		topicRemoveCmd,
	},
}

var topicAddCmd = &cli.Command{
	Name: "add",
	Arguments: []cli.Argument{
		&cli.StringArg{
			Name: "topic",
		},
	},
	Action: modifyAndRegenerate(func(ctx context.Context, cmd *cli.Command, c *Config) error {
		topicValue := cmd.StringArg("topic")
		if topicValue == "" {
			return errors.New("must specify topic")
		}
		for _, topic := range c.Topics {
			if topic == topicValue {
				return errors.New("cannot add topic: topic already exists")
			}
		}
		c.Topics = append(c.Topics, topicValue)
		return nil
	}),
}

var topicRemoveCmd = &cli.Command{
	Name: "remove",
	Arguments: []cli.Argument{
		&cli.StringArg{
			Name: "topic",
		},
	},
	Action: modifyAndRegenerate(func(ctx context.Context, cmd *cli.Command, c *Config) error {
		topicValue := cmd.StringArg("topic")
		if topicValue == "" {
			return errors.New("must specify topic")
		}
		for i, topic := range c.Topics {
			if topic == topicValue {
				c.Topics = append(c.Topics[:i], c.Topics[i+1:]...)
				return nil
			}
		}
		return errors.New("cannot remove topic: topic does not exist")
	}),
}
