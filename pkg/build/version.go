package build

import (
	"encoding/json"
	"os"
)

var (
	// version is the built version.
	// Set with ldflags in .goreleaser.yaml via -ldflags="-X github.com/storacha/storoku/pkg/build.version=v{{.Version}}".
	version string
	// Version returns the current version of the storoku application
	Version string
)

const (
	defaultVersion string = "v0.0.0"       // Default version if not set by ldflags
	versionFile    string = "version.json" // Version file path
)

func init() {
	if version == "" {
		// This is being ran in development, try to grab the latest known version from the version.json file
		var err error
		version, err = readVersionFromFile()
		if err != nil {
			// Use the default version
			version = defaultVersion
		}
	}

	Version = version
}

// versionJSON is used to read the local version.json file
type versionJSON struct {
	Version string `json:"version"`
}

// readVersionFromFile reads the version from the version.json file.
// Reading this should be fine in development since the version.json file
// should be present in the project, I hope :)
func readVersionFromFile() (string, error) {
	// Open file
	file, err := os.Open(versionFile)
	if err != nil {
		return "", err
	}
	defer file.Close()

	// Decode json into struct
	decoder := json.NewDecoder(file)
	var vJSON versionJSON
	err = decoder.Decode(&vJSON)
	if err != nil {
		return "", err
	}

	// Read version from json
	return vJSON.Version, nil
}
