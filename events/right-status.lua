local wezterm = require('wezterm')
local umath = require('utils.math')
local Cells = require('utils.cells')
local PaneData = require('utils.pane-data')
local OptsValidator = require('utils.opts-validator')

---@alias Event.RightStatusOptions { date_format?: string, cwd_max_width?: integer }

---Setup options for the right status bar
local EVENT_OPTS = {}

---@type OptsSchema
EVENT_OPTS.schema = {
   {
      name = 'date_format',
      type = 'string',
      default = '%a %H:%M:%S',
   },
   {
      name = 'cwd_max_width',
      type = 'number',
      default = 32,
   },
}
EVENT_OPTS.validator = OptsValidator:new(EVENT_OPTS.schema)

local nf = wezterm.nerdfonts
local attr = Cells.attr

local M = {}

local ICON_SEPARATOR = nf.oct_dash
local ICON_DATE = nf.fa_calendar
local ICON_FOLDER = nf.md_folder
local ICON_HOST = nf.md_server
local ICON_TMUX = nf.cod_terminal_tmux or 'tmux'

---@type string[]
local discharging_icons = {
   nf.md_battery_10,
   nf.md_battery_20,
   nf.md_battery_30,
   nf.md_battery_40,
   nf.md_battery_50,
   nf.md_battery_60,
   nf.md_battery_70,
   nf.md_battery_80,
   nf.md_battery_90,
   nf.md_battery,
}
---@type string[]
local charging_icons = {
   nf.md_battery_charging_10,
   nf.md_battery_charging_20,
   nf.md_battery_charging_30,
   nf.md_battery_charging_40,
   nf.md_battery_charging_50,
   nf.md_battery_charging_60,
   nf.md_battery_charging_70,
   nf.md_battery_charging_80,
   nf.md_battery_charging_90,
   nf.md_battery_charging,
}

---@type table<string, Cells.SegmentColors>
-- stylua: ignore
local colors = {
   cwd       = { fg = '#a6e3a1', bg = 'rgba(0, 0, 0, 0.4)' },
   host      = { fg = '#89b4fa', bg = 'rgba(0, 0, 0, 0.4)' },
   date      = { fg = '#fab387', bg = 'rgba(0, 0, 0, 0.4)' },
   battery   = { fg = '#f9e2af', bg = 'rgba(0, 0, 0, 0.4)' },
   separator = { fg = '#74c7ec', bg = 'rgba(0, 0, 0, 0.4)' }
}

local cells = Cells:new()

cells
   :add_segment('cwd_icon', ICON_FOLDER .. '  ', colors.cwd, attr(attr.intensity('Bold')))
   :add_segment('cwd_text', '', colors.cwd, attr(attr.intensity('Bold')))
   :add_segment('separator_cwd', ' ' .. ICON_SEPARATOR .. '  ', colors.separator)
   :add_segment('host_icon', ICON_HOST .. '  ', colors.host, attr(attr.intensity('Bold')))
   :add_segment('host_text', '', colors.host, attr(attr.intensity('Bold')))
   :add_segment('separator_host', ' ' .. ICON_SEPARATOR .. '  ', colors.separator)
   :add_segment('date_icon', ICON_DATE .. '  ', colors.date, attr(attr.intensity('Bold')))
   :add_segment('date_text', '', colors.date, attr(attr.intensity('Bold')))
   :add_segment('separator_date', ' ' .. ICON_SEPARATOR .. '  ', colors.separator)
   :add_segment('battery_icon', '', colors.battery)
   :add_segment('battery_text', '', colors.battery, attr(attr.intensity('Bold')))

---@return string, string
local function battery_info()
   -- ref: https://wezfurlong.org/wezterm/config/lua/wezterm/battery_info.html

   local charge = ''
   local icon = ''

   for _, b in ipairs(wezterm.battery_info()) do
      local idx = umath.clamp(umath.round(b.state_of_charge * 10), 1, 10)
      charge = string.format('%.0f%%', b.state_of_charge * 100)

      if b.state == 'Charging' then
         icon = charging_icons[idx]
      else
         icon = discharging_icons[idx]
      end
   end

   return charge, icon .. ' '
end

---@param opts? Event.RightStatusOptions Default: {date_format = '%a %H:%M:%S'}
M.setup = function(opts)
   local valid_opts, err = EVENT_OPTS.validator:validate(opts or {})

   if err then
      wezterm.log_error(err)
   end

   wezterm.on('update-right-status', function(window, pane)
      local battery_text, battery_icon = battery_info()
      local cwd = PaneData.cwd_info(pane)
      local identity = PaneData.identity(pane)
      local cwd_text = PaneData.truncate_left(cwd.display_path, valid_opts.cwd_max_width) or 'N/A'
      local host_text = identity.user and (identity.user .. '@' .. (identity.host or 'localhost'))
         or (identity.host or wezterm.hostname())

      if identity.in_tmux then
         host_text = host_text .. ' ' .. ICON_TMUX
      end

      cells
         :update_segment_text('cwd_text', cwd_text)
         :update_segment_text('host_text', host_text)
         :update_segment_text('date_text', wezterm.strftime(valid_opts.date_format))
         :update_segment_text('battery_icon', battery_icon)
         :update_segment_text('battery_text', battery_text)

      window:set_right_status(
         wezterm.format(
            cells:render({
               'cwd_icon',
               'cwd_text',
               'separator_cwd',
               'host_icon',
               'host_text',
               'separator_host',
               'date_icon',
               'date_text',
               'separator_date',
               'battery_icon',
               'battery_text',
            })
         )
      )
   end)
end

return M
