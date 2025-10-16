package main

import (
	"bufio"
	"context"
	"embed"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"io/fs"
	"os"
	"os/signal"
	"path/filepath"
	"strings"
	"syscall"
	"text/template"

	logging "github.com/ipfs/go-log/v2"
	"github.com/stoewer/go-strcase"
	"github.com/storacha/storoku/pkg/build"
	"github.com/urfave/cli/v3"
)

//go:embed all:template
var templates embed.FS
var log = logging.Logger("storoku/main")

func main() {
	logging.SetLogLevel("*", "info")

	// set up a context that is canceled when a command is interrupted
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	// set up a signal handler to cancel the context
	go func() {
		interrupt := make(chan os.Signal, 1)
		signal.Notify(interrupt, syscall.SIGTERM, syscall.SIGINT)

		select {
		case <-interrupt:
			fmt.Println()
			log.Info("received interrupt signal")
			cancel()
		case <-ctx.Done():
		}

		// Allow any further SIGTERM or SIGINT to kill process
		signal.Stop(interrupt)
	}()

	app := &cli.Command{
		Name:  "storoku",
		Usage: "generate storoku deployments",
		Commands: []*cli.Command{
			newCmd,
			regenCmd,
			bucketCmd,
			queueCmd,
			databaseCmd,
			topicCmd,
			secretCmd,
			cacheCmd,
			cloudflareCmd,
			domainCmd,
			didEnvCmd,
			portCmd,
			jsCmd,
			tableCmd,
			writeToContainerCmd,
			networkCmd,
		},
	}
	if err := app.Run(ctx, os.Args); err != nil {
		log.Fatal(err)
	}
}

var newCmd = &cli.Command{
	Name:  "new",
	Usage: "generate a new storacha deployment",
	Arguments: []cli.Argument{
		&cli.StringArg{
			Name: "app",
		},
	},
	Action: func(ctx context.Context, cmd *cli.Command) error {
		app := cmd.StringArg("app")
		if app == "" {
			return errors.New("must specify an app name")
		}
		config, found, err := getConfig()
		if err != nil {
			return err
		}
		if found {
			return fmt.Errorf("this project is already initialized with storoku run `storoku regen --app %s` to change the name", app)
		}
		fmt.Println("This will initialize this project with a Storoku deployment, which will add several files to your repository and possibly overwrite existing ones. Are you sure? (yes/no)")
		reader := bufio.NewReader(os.Stdin)
		response, err := reader.ReadString('\n')
		if err != nil {
			return fmt.Errorf("reading user input: %w", err)
		}
		response = strings.TrimSpace(strings.ToLower(response))
		if response != "yes" {
			return errors.New("operation aborted by user")
		}
		config.App = app
		err = regenerate(config)
		if err != nil {
			return err
		}
		return writeConfig(config)
	},
}

var regenCmd = &cli.Command{
	Name:  "regen",
	Usage: "regenerate a storacha deployment, or rename one",
	Flags: []cli.Flag{
		&cli.StringFlag{
			Name:  "app",
			Usage: "new name for the application",
		},
	},
	Action: modifyAndRegenerate(func(ctx context.Context, cmd *cli.Command, c *Config) error {
		if cmd.IsSet("app") {
			c.App = cmd.StringArg("app")
		}
		return nil
	}),
}

func modifyAndRegenerate(modify func(ctx context.Context, cmd *cli.Command, c *Config) error) cli.ActionFunc {
	return func(ctx context.Context, cmd *cli.Command) error {

		config, found, err := getConfig()
		if err != nil {
			return err
		}
		if !found {
			return errors.New("this project has not be initialized for storku please run storoku new")
		}
		err = modify(ctx, cmd, config)
		if err != nil {
			return err
		}
		err = regenerate(config)
		if err != nil {
			return err
		}
		return writeConfig(config)
	}
}
func getConfig() (*Config, bool, error) {
	var config Config
	var found bool
	if _, err := os.Stat("./.storoku.json"); err == nil {
		found = true
		f, err := os.Open("./.storoku.json")
		if err != nil {
			return nil, true, fmt.Errorf("opening config file: %w", err)
		}
		defer f.Close()
		jsonBytes, err := io.ReadAll(f)
		if err != nil {
			return nil, true, fmt.Errorf("reading config file: %w", err)
		}
		err = json.Unmarshal(jsonBytes, &config)
		if err != nil {
			return nil, true, fmt.Errorf("parsing config json: %w", err)
		}
	}
	return &config, found, nil
}

func writeConfig(config *Config) error {
	f, err := os.Create("./.storoku.json")
	if err != nil {
		return fmt.Errorf("creating config file %w", err)
	}
	defer f.Close()
	jsonBytes, err := json.MarshalIndent(config, "", "  ")
	if err != nil {
		return fmt.Errorf("encoding config json: %w", err)
	}
	_, err = f.Write(jsonBytes)
	if err != nil {
		return fmt.Errorf("writing config file: %w", err)
	}
	return nil
}

func regenerate(config *Config) error {

	parsedTemplates := map[string]*template.Template{}
	err := fs.WalkDir(templates, "template", func(path string, d fs.DirEntry, err error) error {
		if err != nil {
			log.Fatal(err)
		}
		if !d.IsDir() {
			pathSuffix := strings.SplitN(path, string(os.PathSeparator), 2)
			if len(pathSuffix) < 2 {
				return fmt.Errorf("invalid path: %s", path)
			}
			parsedTemplates[pathSuffix[1]], err = template.ParseFS(templates, path)
			if err != nil {
				return fmt.Errorf("parsing template '%s': %w", pathSuffix, err)
			}
		}
		return nil
	})
	if err != nil {
		return fmt.Errorf("scanning directory: %w", err)
	}
	for file, tmpl := range parsedTemplates {
		if (file == "Dockerfile") && config.JS == nil {
			continue
		}
		err := generateFile(file, tmpl, config)
		if err != nil {
			return err
		}
	}
	return nil
}

func generateFile(file string, tmpl *template.Template, config *Config) error {
	filePath := filepath.Join(".", file)
	if _, err := os.Stat(filePath); err == nil {

		// never copy over .env.production.local.tpl or .dockerignore once they exist
		if file == "deploy/.env.production.local.tpl" || file == ".dockerignore" {
			return nil
		}

		f, err := os.Open(filePath)
		if err != nil {
			return fmt.Errorf("opening file '%s': %w", filePath, err)
		}
		reader := bufio.NewReader(f)
		firstLine, err := reader.ReadString('\n')
		if err != nil && err != io.EOF {
			f.Close()
			return fmt.Errorf("reading first line of file '%s': %w", filePath, err)
		}
		f.Close()

		if strings.TrimSpace(firstLine) == "# storoku:ignore" {
			log.Infof("skipping file '%s' due to ignore directive", filePath)
			return nil
		}
	}
	wdStat, err := os.Stat(".")
	if err != nil {
		return fmt.Errorf("getting current working directory permissions: %w", err)
	}
	if err := os.MkdirAll(filepath.Dir(filePath), wdStat.Mode()); err != nil {
		return fmt.Errorf("creating directories for '%s': %w", filePath, err)
	}
	outFile, err := os.Create(filePath)
	if err != nil {
		return fmt.Errorf("creating file '%s': %w", filePath, err)
	}
	defer outFile.Close()
	if err := tmpl.Execute(outFile, config); err != nil {
		return fmt.Errorf("executing template for '%s': %w", filePath, err)
	}
	// this is a terrible hack to main execution permissions on esh
	if filePath == "deploy/esh" {
		if err := outFile.Chmod(0755); err != nil {
			return fmt.Errorf("setting executable permissions for '%s': %w", filePath, err)
		}
	}
	return nil
}

type Config struct {
	App              string   `json:"app"`
	PrivateKeyEnvVar string   `json:"privateKeyEnvVar"`
	DIDEnvVar        string   `json:"didEnvVar"`
	Port             int      `json:"port"`
	JS               *JS      `json:"js"`
	DomainBase       string   `json:"domainBase"`
	Cloudflare       bool     `json:"cloudflare"`
	CreateDB         bool     `json:"createDB"`
	Caches           []string `json:"caches"`
	Topics           []string `json:"topics"`
	Queues           []Queue  `json:"queues"`
	Buckets          []Bucket `json:"buckets"`
	Secrets          []Secret `json:"secrets"`
	Tables           []Table  `json:"tables"`
	Networks         []string `json:"networks"`
	WriteToContainer bool     `json:"writeToContainer"`
}

func (c Config) Version() string {
	return build.Version
}

type JS struct {
	Next       bool       `json:"next"`
	EntryPoint CompiledJS `json:"entryPoint"`
	Scripts    []Script   `json:"scripts"`
}

type Script struct {
	Script  CompiledJS `json:"script"`
	RunInCI bool       `json:"runInCI"`
}

type CompiledJS string

func (c CompiledJS) OutputDir() string {
	return strings.TrimSuffix(string(c), filepath.Ext(string(c)))
}

func (c CompiledJS) Command() string {
	ext := filepath.Ext(string(c))
	if ext == ".ts" {
		ext = ".js"
	}
	return fmt.Sprintf("%s/index%s", c.OutputDir(), ext)
}

func (c CompiledJS) AsTask() string {
	return strings.TrimSuffix(filepath.Base(string(c)), filepath.Ext(string(c)))
}

type Queue struct {
	Name                    string `json:"name"`
	Fifo                    bool   `json:"fifo"`
	HighThroughput          bool   `json:"highThroughput"`
	MessageRetentionSeconds int    `json:"messageRetentionSeconds,omitempty"`
}

type Bucket struct {
	Name                 string `json:"name"`
	Public               bool   `json:"public"`
	ObjectExpirationDays int    `json:"objectExpirationDays,omitempty"`
}

type Secret struct {
	Name     string `json:"name"`
	Variable bool   `json:"variable"`
}

func (s Secret) Upper() string {
	return strings.ToUpper(s.Name)
}

func (s Secret) Lower() string {
	return strings.ToLower(s.Name)
}
func (s Secret) LowerKebab() string {
	return strcase.KebabCase(strings.ToLower(s.Name))
}

type Table struct {
	Name                   string                    `json:"name"`
	Attributes             []Attribute               `json:"attributes"`
	HashKey                string                    `json:"hashKey"`
	RangeKey               string                    `json:"rangeKey"`
	GlobalSecondaryIndexes map[string]SecondaryIndex `json:"globalSecondaryIndexes,omitempty"`
	LocalSecondaryIndexes  map[string]SecondaryIndex `json:"localSecondaryIndexes,omitempty"`
}

type Attribute struct {
	Name string `json:"name"`
	Type string `json:"type"`
}

type SecondaryIndex struct {
	Name             string   `json:"name"`
	HashKey          string   `json:"hashKey,omitempty"`
	RangeKey         string   `json:"rangeKey,omitempty"`
	ProjectionType   string   `json:"projectionType"`
	NonKeyAttributes []string `json:"nonKeyAttributes,omitempty"`
}
