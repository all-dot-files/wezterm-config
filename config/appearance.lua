local wezterm = require('wezterm')
local colors = require('colors.custom')
local gpu_adapters = require('utils.gpu-adapter')

return {
   term = "wezterm",
   animation_fps = 60,
   max_fps = 60,
   front_end = 'WebGpu',
   webgpu_power_preference = 'HighPerformance',
   webgpu_preferred_adapter = gpu_adapters:pick_best(),
   underline_thickness = '1.5pt',

   -- color scheme
   -- colors = colors,
   -- color_scheme = "Gruvbox dark, medium (base16)",
   color_scheme = "Catppuccin Mocha",

   -- background
   window_background_opacity = 1,
   win32_system_backdrop = 'Acrylic',
   --background = {
   --   {
   --      source = { File = wezterm.config_dir .. 'XXXX.jpg' },
   --   },
   --   {
   --      source = { Color = colors.background },
   --      height = '100%',
   --      width = '100%',
   --      opacity = 0.85,
   --   },
   --},

   -- scrollbar
   enable_scroll_bar = true,
   min_scroll_bar_height = "3cell",
   colors = {
      scrollbar_thumb = '#454545',
      tab_bar = {
         background = '#090909',
         active_tab = {
            bg_color = '#8dcba5',
            fg_color = '#11111B',
         },
         inactive_tab = {
            bg_color = '#74C7EC',
            fg_color = '#1C1B19',
         },
         inactive_tab_hover = {
            bg_color = '#5D87A3',
            fg_color = '#1C1B19',
         },
         new_tab = {
            bg_color = '#090909',
            fg_color = '#CDD6F4',
         },
         new_tab_hover = {
            bg_color = '#5D87A3',
            fg_color = '#1C1B19',
         },
      },
   },

   -- tab bar
   enable_tab_bar = true,
   hide_tab_bar_if_only_one_tab = false,
   use_fancy_tab_bar = true,
   tab_max_width = 25,
   show_tab_index_in_tab_bar = true,
   switch_to_last_active_tab_when_closing_tab = true,

   -- cursor
   --  SteadyBlock, BlinkingBlock, SteadyUnderline, BlinkingUnderline, SteadyBar, and BlinkingBar
   default_cursor_style = "BlinkingBar",
   cursor_blink_ease_in = "Constant",
   cursor_blink_ease_out = "Constant",
   cursor_blink_rate = 700,

   -- window
   window_decorations = "INTEGRATED_BUTTONS|RESIZE",
   integrated_title_button_style = "Windows",
   integrated_title_button_color = "auto",
   integrated_title_button_alignment = "Right",
   initial_cols = 120,
   initial_rows = 24,
   window_padding = {
      left = 5,
      right = 10,
      top = 10,
      bottom = 7.5,
   },
   adjust_window_size_when_changing_font_size = false,
   window_close_confirmation = 'NeverPrompt',
   window_frame = {
      active_titlebar_bg = '#090909',
      -- font = fonts.font,
      -- font_size = fonts.font_size,
   },

   inactive_pane_hsb = {
      saturation = 1,
      brightness = 1,
   },

   visual_bell = {
      fade_in_function = 'EaseIn',
      fade_in_duration_ms = 250,
      fade_out_function = 'EaseOut',
      fade_out_duration_ms = 250,
      target = 'CursorColor',
   },
}
