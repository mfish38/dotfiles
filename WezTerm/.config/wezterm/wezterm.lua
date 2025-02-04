-- Pull in the wezterm API
local wezterm = require("wezterm")

-- This will hold the configuration.
local config = wezterm.config_builder()

-- This is where you actually apply your config choices
-- For example, changing the color scheme:
-- config.color_scheme = 'AdventureTime'

config.font = wezterm.font("GohuFont14 Nerd Font Mono")
config.font_size = 10.5

config.initial_cols = 120
config.initial_rows = 100

-- and finally, return the configuration to wezterm
return config
