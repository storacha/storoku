package main

import (
	"context"
	"errors"
	"strings"

	"github.com/urfave/cli/v3"
)

var tableCmd = &cli.Command{
	Name:  "table",
	Usage: "add and remove tables",
	Commands: []*cli.Command{
		tableAddCmd,
		tableRemoveCmd,
		attributeCmd,
		gsiCmd,
		lsiCmd,
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

var attributeCmd = &cli.Command{
	Name:  "attribute",
	Usage: "add and remove attributes",
	Commands: []*cli.Command{
		attributeAddCmd,
		attributeRemoveCmd,
	},
}

var attributeAddCmd = &cli.Command{
	Name: "add",
	Arguments: []cli.Argument{
		&cli.StringArg{
			Name: "attribute",
		},
	},
	Flags: []cli.Flag{
		&cli.StringFlag{
			Name:     "table",
			Required: true,
		},
		&cli.StringFlag{
			Name:        "type",
			Required:    true,
			DefaultText: "specify the attribute type (S = String, B = Binary, N = Number)",
		},
	},
	Action: modifyAndRegenerate(func(ctx context.Context, cmd *cli.Command, c *Config) error {
		tableName := cmd.String("table")
		attributeName := cmd.StringArg("attribute")
		if tableName == "" || attributeName == "" {
			return errors.New("must specify table and attribute")
		}
		for i, table := range c.Tables {
			if table.Name == tableName {
				for _, attr := range table.Attributes {
					if attr.Name == attributeName {
						return errors.New("cannot add attribute: attribute already exists")
					}
				}
				attrType := cmd.String("type")
				c.Tables[i].Attributes = append(c.Tables[i].Attributes, Attribute{
					Name: attributeName,
					Type: attrType,
				})
				return nil
			}
		}
		return errors.New("cannot add attribute: table does not exist")
	}),
}

var attributeRemoveCmd = &cli.Command{
	Name: "remove",
	Arguments: []cli.Argument{
		&cli.StringArg{
			Name: "attribute",
		},
	},
	Flags: []cli.Flag{
		&cli.StringFlag{
			Name: "table",
		},
	},
	Action: modifyAndRegenerate(func(ctx context.Context, cmd *cli.Command, c *Config) error {
		tableName := cmd.String("table")
		attributeName := cmd.StringArg("attribute")
		if tableName == "" || attributeName == "" {
			return errors.New("must specify table and attribute")
		}
		for i, table := range c.Tables {
			if table.Name == tableName {
				for j, attr := range table.Attributes {
					if attr.Name == attributeName {
						c.Tables[i].Attributes = append(c.Tables[i].Attributes[:j], c.Tables[i].Attributes[j+1:]...)
						return nil
					}
				}
				return errors.New("cannot remove attribute: attribute does not exist")
			}
		}
		return errors.New("cannot remove attribute: table does not exist")
	}),
}

var gsiCmd = &cli.Command{
	Name:  "gsi",
	Usage: "add and remove global secondary indexes",
	Commands: []*cli.Command{
		gsiAddCmd,
		gsiRemoveCmd,
	},
}

var gsiAddCmd = &cli.Command{
	Name: "add",
	Arguments: []cli.Argument{
		&cli.StringArg{
			Name: "index",
		},
	},
	Flags: []cli.Flag{
		&cli.StringFlag{
			Name:     "table",
			Required: true,
		},
		&cli.StringFlag{
			Name:     "hash-key",
			Required: true,
		},
		&cli.StringFlag{
			Name: "range-key",
		},
		&cli.StringFlag{
			Name:        "projection-type",
			Required:    true,
			DefaultText: "specify projection type (ALL, INCLUDE, KEYS_ONLY)",
		},
		&cli.StringFlag{
			Name:        "non-key-attributes",
			DefaultText: "comma-separated list of non-key attributes (required when projection-type is INCLUDE)",
		},
	},
	Action: modifyAndRegenerate(func(ctx context.Context, cmd *cli.Command, c *Config) error {
		tableName := cmd.String("table")
		indexName := cmd.StringArg("index")
		if tableName == "" || indexName == "" {
			return errors.New("must specify table and index")
		}

		projectionType := cmd.String("projection-type")
		if projectionType != "ALL" && projectionType != "INCLUDE" && projectionType != "KEYS_ONLY" {
			return errors.New("projection-type must be one of: ALL, INCLUDE, KEYS_ONLY")
		}

		nonKeyAttrsStr := cmd.String("non-key-attributes")
		if projectionType == "INCLUDE" && nonKeyAttrsStr == "" {
			return errors.New("non-key-attributes is required when projection-type is INCLUDE")
		}
		if projectionType != "INCLUDE" && nonKeyAttrsStr != "" {
			return errors.New("non-key-attributes can only be specified when projection-type is INCLUDE")
		}

		var nonKeyAttributes []string
		if nonKeyAttrsStr != "" {
			nonKeyAttributes = strings.Split(nonKeyAttrsStr, ",")
			for i := range nonKeyAttributes {
				nonKeyAttributes[i] = strings.TrimSpace(nonKeyAttributes[i])
			}
		}

		hashKey := cmd.String("hash-key")
		rangeKey := cmd.String("range-key")

		for i, table := range c.Tables {
			if table.Name == tableName {
				// Initialize map if nil
				if c.Tables[i].GlobalSecondaryIndexes == nil {
					c.Tables[i].GlobalSecondaryIndexes = make(map[string]SecondaryIndex)
				}

				// Check if index already exists
				if _, exists := c.Tables[i].GlobalSecondaryIndexes[indexName]; exists {
					return errors.New("cannot add GSI: index already exists")
				}

				// Check if hash-key exists in table attributes
				hashKeyExists := false
				for _, attr := range table.Attributes {
					if attr.Name == hashKey {
						hashKeyExists = true
						break
					}
				}
				if !hashKeyExists {
					return errors.New("hash-key attribute does not exist in table, add it first with 'storoku table attribute add'")
				}

				// Check if range-key exists in table attributes (if specified)
				if rangeKey != "" {
					rangeKeyExists := false
					for _, attr := range table.Attributes {
						if attr.Name == rangeKey {
							rangeKeyExists = true
							break
						}
					}
					if !rangeKeyExists {
						return errors.New("range-key attribute does not exist in table, add it first with 'storoku table attribute add'")
					}
				}

				c.Tables[i].GlobalSecondaryIndexes[indexName] = SecondaryIndex{
					Name:             indexName,
					HashKey:          hashKey,
					RangeKey:         rangeKey,
					ProjectionType:   projectionType,
					NonKeyAttributes: nonKeyAttributes,
				}
				return nil
			}
		}
		return errors.New("cannot add GSI: table does not exist")
	}),
}

var gsiRemoveCmd = &cli.Command{
	Name: "remove",
	Arguments: []cli.Argument{
		&cli.StringArg{
			Name: "index",
		},
	},
	Flags: []cli.Flag{
		&cli.StringFlag{
			Name:     "table",
			Required: true,
		},
	},
	Action: modifyAndRegenerate(func(ctx context.Context, cmd *cli.Command, c *Config) error {
		tableName := cmd.String("table")
		indexName := cmd.StringArg("index")
		if tableName == "" || indexName == "" {
			return errors.New("must specify table and index")
		}
		for i, table := range c.Tables {
			if table.Name == tableName {
				if _, exists := c.Tables[i].GlobalSecondaryIndexes[indexName]; !exists {
					return errors.New("cannot remove GSI: index does not exist")
				}
				delete(c.Tables[i].GlobalSecondaryIndexes, indexName)
				return nil
			}
		}
		return errors.New("cannot remove GSI: table does not exist")
	}),
}

var lsiCmd = &cli.Command{
	Name:  "lsi",
	Usage: "add and remove local secondary indexes",
	Commands: []*cli.Command{
		lsiAddCmd,
		lsiRemoveCmd,
	},
}

var lsiAddCmd = &cli.Command{
	Name: "add",
	Arguments: []cli.Argument{
		&cli.StringArg{
			Name: "index",
		},
	},
	Flags: []cli.Flag{
		&cli.StringFlag{
			Name:     "table",
			Required: true,
		},
		&cli.StringFlag{
			Name:     "range-key",
			Required: true,
		},
		&cli.StringFlag{
			Name:     "projection-type",
			Required: true,
			Usage:    "specify projection type (ALL, INCLUDE, KEYS_ONLY)",
		},
		&cli.StringFlag{
			Name:  "non-key-attributes",
			Usage: "comma-separated list of non-key attributes (required when projection-type is INCLUDE)",
		},
	},
	Action: modifyAndRegenerate(func(ctx context.Context, cmd *cli.Command, c *Config) error {
		tableName := cmd.String("table")
		indexName := cmd.StringArg("index")
		if tableName == "" || indexName == "" {
			return errors.New("must specify table and index")
		}

		projectionType := cmd.String("projection-type")
		if projectionType != "ALL" && projectionType != "INCLUDE" && projectionType != "KEYS_ONLY" {
			return errors.New("projection-type must be one of: ALL, INCLUDE, KEYS_ONLY")
		}

		nonKeyAttrsStr := cmd.String("non-key-attributes")
		if projectionType == "INCLUDE" && nonKeyAttrsStr == "" {
			return errors.New("non-key-attributes is required when projection-type is INCLUDE")
		}
		if projectionType != "INCLUDE" && nonKeyAttrsStr != "" {
			return errors.New("non-key-attributes can only be specified when projection-type is INCLUDE")
		}

		var nonKeyAttributes []string
		if nonKeyAttrsStr != "" {
			nonKeyAttributes = strings.Split(nonKeyAttrsStr, ",")
			for i := range nonKeyAttributes {
				nonKeyAttributes[i] = strings.TrimSpace(nonKeyAttributes[i])
			}
		}

		rangeKey := cmd.String("range-key")

		for i, table := range c.Tables {
			if table.Name == tableName {
				// Initialize map if nil
				if c.Tables[i].LocalSecondaryIndexes == nil {
					c.Tables[i].LocalSecondaryIndexes = make(map[string]SecondaryIndex)
				}

				// Check if index already exists
				if _, exists := c.Tables[i].LocalSecondaryIndexes[indexName]; exists {
					return errors.New("cannot add LSI: index already exists")
				}

				// Check if range-key exists in table attributes
				rangeKeyExists := false
				for _, attr := range table.Attributes {
					if attr.Name == rangeKey {
						rangeKeyExists = true
						break
					}
				}
				if !rangeKeyExists {
					return errors.New("range-key attribute does not exist in table, add it first with 'storoku table attribute add'")
				}

				c.Tables[i].LocalSecondaryIndexes[indexName] = SecondaryIndex{
					Name:             indexName,
					RangeKey:         rangeKey,
					ProjectionType:   projectionType,
					NonKeyAttributes: nonKeyAttributes,
				}
				return nil
			}
		}
		return errors.New("cannot add LSI: table does not exist")
	}),
}

var lsiRemoveCmd = &cli.Command{
	Name: "remove",
	Arguments: []cli.Argument{
		&cli.StringArg{
			Name: "index",
		},
	},
	Flags: []cli.Flag{
		&cli.StringFlag{
			Name:     "table",
			Required: true,
		},
	},
	Action: modifyAndRegenerate(func(ctx context.Context, cmd *cli.Command, c *Config) error {
		tableName := cmd.String("table")
		indexName := cmd.StringArg("index")
		if tableName == "" || indexName == "" {
			return errors.New("must specify table and index")
		}
		for i, table := range c.Tables {
			if table.Name == tableName {
				if _, exists := c.Tables[i].LocalSecondaryIndexes[indexName]; !exists {
					return errors.New("cannot remove LSI: index does not exist")
				}
				delete(c.Tables[i].LocalSecondaryIndexes, indexName)
				return nil
			}
		}
		return errors.New("cannot remove LSI: table does not exist")
	}),
}
