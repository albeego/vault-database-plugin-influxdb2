package main

import (
	"github.com/hashicorp/go-hclog"
	influxdbv2 "github.com/hashicorp/vault-plugin-database-influxdbv2"
	"github.com/hashicorp/vault/sdk/database/dbplugin/v5"
	"os"
)

func main() {
	err := Run()
	if err != nil {
		logger := hclog.New(&hclog.LoggerOptions{})

		logger.Error("plugin shutting down", "error", err)
		os.Exit(1)
	}
}

// Run instantiates a RedisDB object, and runs the RPC server for the plugin
func Run() error {
	dbplugin.ServeMultiplex(influxdbv2.New)

	return nil
}
