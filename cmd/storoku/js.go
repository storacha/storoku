package main

import (
	"context"
	"errors"

	"github.com/urfave/cli/v3"
)

var jsCmd = &cli.Command{
	Name:  "js",
	Usage: "modify js settings",
	Commands: []*cli.Command{
		jsOnCmd,
		jsOffCmd,
		jsNextCmd,
		jsScriptCmd,
		jsEntrypointCmd,
	},
}

var jsOnCmd = &cli.Command{
	Name: "on",
	Action: modifyAndRegenerate(func(ctx context.Context, cmd *cli.Command, c *Config) error {
		if c.JS != nil {
			return errors.New("JS is already enabled")
		}
		c.JS = &JS{}
		return nil
	}),
}

var jsOffCmd = &cli.Command{
	Name: "off",
	Action: modifyAndRegenerate(func(ctx context.Context, cmd *cli.Command, c *Config) error {
		c.JS = nil
		return nil
	}),
}

var jsNextCmd = &cli.Command{
	Name:  "next",
	Usage: "modify next settings",
	Commands: []*cli.Command{
		jsNextOnCmd,
		jsNextOffCmd,
	},
}

var jsNextOnCmd = &cli.Command{
	Name: "on",
	Action: modifyAndRegenerate(func(ctx context.Context, cmd *cli.Command, c *Config) error {
		if c.JS == nil {
			return errors.New("JS is not enabled for this project")
		}
		c.JS.Next = true
		return nil
	}),
}

var jsNextOffCmd = &cli.Command{
	Name: "off",
	Action: modifyAndRegenerate(func(ctx context.Context, cmd *cli.Command, c *Config) error {
		if c.JS == nil {
			return errors.New("JS is not enabled for this project")
		}
		c.JS.Next = false
		return nil
	}),
}

var jsEntrypointCmd = &cli.Command{
	Name: "entrypoint",
	Arguments: []cli.Argument{
		&cli.StringArg{
			Name: "entrypoint",
		},
	},

	Action: modifyAndRegenerate(func(ctx context.Context, cmd *cli.Command, c *Config) error {
		entrypoint := cmd.StringArg("entrypoint")
		if entrypoint == "" {
			return errors.New("must specify a custom domain base")
		}
		if c.JS == nil {
			return errors.New("JS is not enabled for this project")
		}
		if c.JS.Next {
			return errors.New("entry point is only set for projects that do not use next")
		}
		c.JS.EntryPoint = CompiledJS(entrypoint)
		return nil
	}),
}
var jsScriptCmd = &cli.Command{
	Name:  "script",
	Usage: "add and remove scripts",
	Commands: []*cli.Command{
		jsScriptAddCmd,
		jsScriptRemoveCmd,
	},
}

var jsScriptAddCmd = &cli.Command{
	Name: "add",
	Arguments: []cli.Argument{
		&cli.StringArg{
			Name: "script",
		},
	},
	Flags: []cli.Flag{
		&cli.BoolFlag{
			Name:        "run-in-ci",
			Value:       false,
			DefaultText: "specify if this script will run automatically after a deployment",
		},
	},
	Action: modifyAndRegenerate(func(ctx context.Context, cmd *cli.Command, c *Config) error {
		scriptValue := CompiledJS(cmd.StringArg("script"))
		runInCI := cmd.Bool("run-in-ci")
		if scriptValue == "" {
			return errors.New("must specify script")
		}
		if c.JS == nil {
			return errors.New("JS is not enabled for this project")
		}
		for _, script := range c.JS.Scripts {
			if script.Script == scriptValue {
				return errors.New("cannot add script: script already exists")
			}
		}
		c.JS.Scripts = append(c.JS.Scripts, Script{Script: scriptValue, RunInCI: runInCI})
		return nil
	}),
}

var jsScriptRemoveCmd = &cli.Command{
	Name: "remove",
	Arguments: []cli.Argument{
		&cli.StringArg{
			Name: "script",
		},
	},
	Action: modifyAndRegenerate(func(ctx context.Context, cmd *cli.Command, c *Config) error {
		scriptValue := CompiledJS(cmd.StringArg("script"))
		if scriptValue == "" {
			return errors.New("must specify script")
		}
		if c.JS == nil {
			return errors.New("JS is not enabled for this project")
		}
		for i, script := range c.JS.Scripts {
			if script.Script == scriptValue {
				c.JS.Scripts = append(c.JS.Scripts[:i], c.JS.Scripts[i+1:]...)
				return nil
			}
		}
		return errors.New("cannot remove script: script does not exist")
	}),
}
