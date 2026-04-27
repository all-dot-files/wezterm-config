return {
   -- behaviours
   automatically_reload_config = true,
   check_for_updates = false,
   -- exit_behavior = 'CloseOnCleanExit', -- if the shell program exited with a successful status
   exit_behavior = 'CloseOnCleanExit', -- if the shell program exited with a successful status
   -- 关闭 kitty keyboard，避免 Atuin TUI 兼容问题
   enable_kitty_keyboard = false,

   -- mac Option 保持输入字符，不作为 Meta
   send_composed_key_when_left_alt_is_pressed = true,
   send_composed_key_when_right_alt_is_pressed = true,

   status_update_interval = 1000,

   -- scrollbar
   scrollback_lines = 50000,

   -- paste behaviours
   canonicalize_pasted_newlines = 'CarriageReturn',

   hyperlink_rules = {
      -- Matches: a URL in parens: (URL)
      {
         regex = '\\((\\w+://\\S+)\\)',
         format = '$1',
         highlight = 1,
      },
      -- Matches: a URL in brackets: [URL]
      {
         regex = '\\[(\\w+://\\S+)\\]',
         format = '$1',
         highlight = 1,
      },
      -- Matches: a URL in curly braces: {URL}
      {
         regex = '\\{(\\w+://\\S+)\\}',
         format = '$1',
         highlight = 1,
      },
      -- Matches: a URL in angle brackets: <URL>
      {
         regex = '<(\\w+://\\S+)>',
         format = '$1',
         highlight = 1,
      },
      -- Then handle URLs not wrapped in brackets
      {
         regex = '\\b\\w+://\\S+[)/a-zA-Z0-9-]+',
         format = '$0',
      },
      -- implicit mailto link
      {
         regex = '\\b\\w+@[\\w-]+(\\.[\\w-]+)+\\b',
         format = 'mailto:$0',
      },
   },
}
