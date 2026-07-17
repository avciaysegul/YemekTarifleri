package main

import (
	"embed"

	"github.com/wailsapp/wails/v2"
	"github.com/wailsapp/wails/v2/pkg/options"
	"github.com/wailsapp/wails/v2/pkg/options/assetserver"
)

// Frontend dosyalarını göm
//
//go:embed all:frontend/dist
var assets embed.FS

func main() {

	app := NewApp()

	err := wails.Run(&options.App{

		Title:  "Animasyonlu Yemek Tarifleri",
		Width:  1200,
		Height: 800,

		MinWidth:  900,
		MinHeight: 650,

		BackgroundColour: &options.RGBA{
			R: 246,
			G: 241,
			B: 232,
			A: 1,
		},

		AssetServer: &assetserver.Options{
			Assets: assets,
		},

		OnStartup: app.startup,

		Bind: []interface{}{
			app,
		},
	})

	if err != nil {
		println(err.Error())
	}
}
