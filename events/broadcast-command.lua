local wezterm = require('wezterm')

local act = wezterm.action
local gui = wezterm.gui

local M = {}

local EVENT_TAB = 'broadcast-command-to-tab'
local EVENT_WINDOW = 'broadcast-command-to-window'
local EVENT_SELECT_WINDOW = 'broadcast-command-to-selected-window'
local EVENT_SELECT_TABS = 'broadcast-command-to-selected-tabs'
local EVENT_SELECT_PANES = 'broadcast-command-to-selected-panes'

---@param text string?
---@return string?
local function normalize_command(text)
   if not text or text == '' then
      return nil
   end

   if not text:match('\n$') then
      return text .. '\n'
   end

   return text
end

---@param text string?
---@return string
local function compact_text(text)
   if not text or text == '' then
      return '未命名'
   end

   local normalized = text:gsub('%s+', ' ')
   if normalized == '' then
      return '未命名'
   end

   return normalized
end

---@param text string?
---@return string?
local function compact_selector_input(text)
   if not text or text == '' then
      return nil
   end

   local normalized = text:gsub('%s+', ''):lower()
   if normalized == '' then
      return nil
   end

   return normalized
end

---@param window Window
---@param message string
local function show_toast(window, message)
   local ok = pcall(function()
      window:toast_notification('广播命令', message, nil, 4000)
   end)

   if not ok then
      wezterm.log_info(message)
   end
end

---@param tab MuxTab
---@param command string
---@return integer
local function send_to_tab(tab, command)
   local pane_count = 0

   for _, target_pane in ipairs(tab:panes()) do
      target_pane:send_text(command)
      pane_count = pane_count + 1
   end

   return pane_count
end

---@param panes Pane[]
---@param command string
---@return integer
local function send_to_panes(panes, command)
   local pane_count = 0

   for _, target_pane in ipairs(panes) do
      target_pane:send_text(command)
      pane_count = pane_count + 1
   end

   return pane_count
end

---@param mux_window MuxWindow
---@param command string
---@return integer, integer
local function send_to_window(mux_window, command)
   local tab_count = 0
   local pane_count = 0

   for _, tab in ipairs(mux_window:tabs()) do
      tab_count = tab_count + 1
      pane_count = pane_count + send_to_tab(tab, command)
   end

   return tab_count, pane_count
end

---@param tabs MuxTab[]
---@param command string
---@return integer, integer
local function send_to_tabs(tabs, command)
   local tab_count = 0
   local pane_count = 0

   for _, tab in ipairs(tabs) do
      tab_count = tab_count + 1
      pane_count = pane_count + send_to_tab(tab, command)
   end

   return tab_count, pane_count
end

---@param window Window
---@param pane Pane
---@param description string
---@param on_submit fun(command: string, current_window: Window)
local function prompt_for_command(window, pane, description, on_submit)
   window:perform_action(
      act.PromptInputLine({
         description = description,
         action = wezterm.action_callback(function(current_window, _pane, line)
            local command = normalize_command(line)
            if not command then
               return
            end

            on_submit(command, current_window)
         end),
      }),
      pane
   )
end

---@param selector string?
---@param max_index integer
---@return integer[]?, string?
local function parse_index_selection(selector, max_index)
   local normalized = compact_selector_input(selector)
   if not normalized then
      return nil, '未输入编号'
   end

   if normalized == 'all' or normalized == '*' then
      local result = {}
      for index = 1, max_index, 1 do
         table.insert(result, index)
      end
      return result, nil
   end

   local seen = {}
   local result = {}

   for token in normalized:gmatch('[^,]+') do
      local range_start, range_end = token:match('^(%d+)%-(%d+)$')
      if range_start and range_end then
         local start_index = tonumber(range_start)
         local end_index = tonumber(range_end)
         if start_index > end_index then
            start_index, end_index = end_index, start_index
         end

         for index = start_index, end_index, 1 do
            if index < 1 or index > max_index then
               return nil, string.format('编号 %d 超出范围 1-%d', index, max_index)
            end
            if not seen[index] then
               seen[index] = true
               table.insert(result, index)
            end
         end
      else
         local index = tonumber(token)
         if not index then
            return nil, string.format('无法识别的编号表达式: %s', token)
         end
         if index < 1 or index > max_index then
            return nil, string.format('编号 %d 超出范围 1-%d', index, max_index)
         end
         if not seen[index] then
            seen[index] = true
            table.insert(result, index)
         end
      end
   end

   table.sort(result)

   if #result == 0 then
      return nil, '没有选中任何目标'
   end

   return result, nil
end

---@param entries table[]
---@param indices integer[]
---@return table[]
local function pick_entries(entries, indices)
   local selected = {}

   for _, index in ipairs(indices) do
      table.insert(selected, entries[index])
   end

   return selected
end

---@param entry_type string
---@param entries table[]
---@return string
local function build_multi_select_description(entry_type, entries)
   local lines = {
      string.format('选择要广播的%s编号，支持 1,3-5,all', entry_type),
   }

   for _, entry in ipairs(entries) do
      table.insert(lines, entry.prompt_label)
   end

   return table.concat(lines, '\n')
end

---@param window Window
---@param pane Pane
---@param entry_type string
---@param entries table[]
---@param on_submit fun(selected_entries: table[], current_window: Window, current_pane: Pane)
local function prompt_for_multi_selection(window, pane, entry_type, entries, on_submit)
   local description = build_multi_select_description(entry_type, entries)

   local function ask(current_window, current_pane)
      current_window:perform_action(
         act.PromptInputLine({
            description = description,
            action = wezterm.action_callback(function(next_window, next_pane, line)
               local indices, err = parse_index_selection(line, #entries)
               if err then
                  show_toast(next_window, err)
                  ask(next_window, next_pane)
                  return
               end

               on_submit(pick_entries(entries, indices), next_window, next_pane)
            end),
         }),
         current_pane
      )
   end

   ask(window, pane)
end

---@param window Window
---@return InputSelectorChoice[], table<string, Window>
local function build_window_choices(window)
   local current_window_id = window:window_id()
   local current_workspace = window:active_workspace()
   local windows = {}
   local choices = {}
   local choice_map = {}

   if gui and gui.gui_windows then
      for _, gui_window in ipairs(gui.gui_windows()) do
         if gui_window:active_workspace() == current_workspace then
            table.insert(windows, gui_window)
         end
      end
   end

   if #windows == 0 then
      table.insert(windows, window)
   end

   table.sort(windows, function(left, right)
      if left:window_id() == current_window_id then
         return true
      end

      if right:window_id() == current_window_id then
         return false
      end

      return left:window_id() < right:window_id()
   end)

   for index, gui_window in ipairs(windows) do
      local mux_window = gui_window:mux_window()
      local active_pane = mux_window:active_pane()
      local title = compact_text(active_pane and active_pane:get_title() or nil)
      local label = string.format(
         '%s 窗口 #%d [%s] %s',
         gui_window:window_id() == current_window_id and '[当前]' or '[其它]',
         gui_window:window_id(),
         gui_window:active_workspace(),
         title
      )

      local id = tostring(index)
      table.insert(choices, {
         id = id,
         label = label,
      })
      choice_map[id] = gui_window
   end

   return choices, choice_map
end

---@param window Window
---@return table[]
local function build_tab_entries(window)
   local entries = {}
   local mux_window = window:mux_window()

   for _, item in ipairs(mux_window:tabs_with_info()) do
      local tab = item.tab
      table.insert(entries, {
         tab = tab,
         prompt_label = string.format(
            '%d %s %s (%d 个窗格)',
            item.index + 1,
            item.is_active and '[当前]' or '[其它]',
            compact_text(tab:get_title()),
            #tab:panes()
         ),
      })
   end

   return entries
end

---@param tab MuxTab
---@return table[]
local function build_pane_entries(tab)
   local entries = {}

   for _, item in ipairs(tab:panes_with_info()) do
      table.insert(entries, {
         pane = item.pane,
         prompt_label = string.format(
            '%d %s %s (%dx%d)',
            item.index + 1,
            item.is_active and '[当前]' or '[其它]',
            compact_text(item.pane:get_title()),
            item.width,
            item.height
         ),
      })
   end

   return entries
end

M.setup = function()
   wezterm.on(EVENT_TAB, function(window, pane)
      prompt_for_command(window, pane, '向当前标签页的所有窗格发送命令', function(command, current_window)
         local target_tab = current_window:active_tab()
         if not target_tab then
            show_toast(current_window, '当前窗口没有可用的标签页')
            return
         end

         local pane_count = send_to_tab(target_tab, command)
         show_toast(current_window, string.format('已向当前标签页的 %d 个窗格发送命令', pane_count))
      end)
   end)

   wezterm.on(EVENT_WINDOW, function(window, pane)
      prompt_for_command(window, pane, '向当前窗口的所有窗格发送命令', function(command, current_window)
         local target_window = current_window:mux_window()
         local tab_count, pane_count = send_to_window(target_window, command)
         show_toast(
            current_window,
            string.format('已向当前窗口的 %d 个标签页 / %d 个窗格发送命令', tab_count, pane_count)
         )
      end)
   end)

   wezterm.on(EVENT_SELECT_WINDOW, function(window, pane)
      local choices, choice_map = build_window_choices(window)

      window:perform_action(
         act.InputSelector({
            title = '选择目标窗口',
            choices = choices,
            fuzzy = true,
            fuzzy_description = '选择一个窗口后，再输入要广播的命令',
            action = wezterm.action_callback(function(current_window, current_pane, id, _label)
               local target_window = id and choice_map[id] or nil
               if not target_window then
                  return
               end

               prompt_for_command(
                  current_window,
                  current_pane,
                  string.format('向窗口 #%d 的所有窗格发送命令', target_window:window_id()),
                  function(command, toast_window)
                     local tab_count, pane_count = send_to_window(target_window:mux_window(), command)
                     show_toast(
                        toast_window,
                        string.format(
                           '已向窗口 #%d 的 %d 个标签页 / %d 个窗格发送命令',
                           target_window:window_id(),
                           tab_count,
                           pane_count
                        )
                     )
                  end
               )
            end),
         }),
         pane
      )
   end)

   wezterm.on(EVENT_SELECT_TABS, function(window, pane)
      local entries = build_tab_entries(window)

      prompt_for_multi_selection(window, pane, '标签页', entries, function(selected_entries, current_window, current_pane)
         prompt_for_command(
            current_window,
            current_pane,
            string.format('向选中的 %d 个标签页广播命令', #selected_entries),
            function(command, toast_window)
               local selected_tabs = {}
               for _, entry in ipairs(selected_entries) do
                  table.insert(selected_tabs, entry.tab)
               end

               local tab_count, pane_count = send_to_tabs(selected_tabs, command)
               show_toast(
                  toast_window,
                  string.format('已向选中的 %d 个标签页 / %d 个窗格发送命令', tab_count, pane_count)
               )
            end
         )
      end)
   end)

   wezterm.on(EVENT_SELECT_PANES, function(window, pane)
      local target_tab = window:active_tab()
      if not target_tab then
         show_toast(window, '当前窗口没有可用的标签页')
         return
      end

      local entries = build_pane_entries(target_tab)

      prompt_for_multi_selection(window, pane, '窗格', entries, function(selected_entries, current_window, current_pane)
         prompt_for_command(
            current_window,
            current_pane,
            string.format('向选中的 %d 个窗格广播命令', #selected_entries),
            function(command, toast_window)
               local selected_panes = {}
               for _, entry in ipairs(selected_entries) do
                  table.insert(selected_panes, entry.pane)
               end

               local pane_count = send_to_panes(selected_panes, command)
               show_toast(toast_window, string.format('已向选中的 %d 个窗格发送命令', pane_count))
            end
         )
      end)
   end)
end

return M
