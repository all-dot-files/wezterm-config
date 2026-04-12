local wezterm = require('wezterm')

local M = {}

local HOME = os.getenv('HOME')

---@param text string?
---@return string?
local function normalize_text(text)
   if not text or text == '' then
      return nil
   end

   local normalized = text:gsub('%s+', ' ')
   normalized = normalized:gsub('^%s+', ''):gsub('%s+$', '')

   if normalized == '' then
      return nil
   end

   return normalized
end

---@param path string?
---@return string?
local function basename(path)
   local normalized = normalize_text(path)
   if not normalized then
      return nil
   end

   local trimmed = normalized:gsub('/+$', '')
   if trimmed == '' then
      return '/'
   end

   return trimmed:match('([^/]+)$') or trimmed
end

---@param host string?
---@return string?
local function short_host(host)
   local normalized = normalize_text(host)
   if not normalized then
      return nil
   end

   local dot = normalized:find('[.]')
   if dot then
      return normalized:sub(1, dot - 1)
   end

   return normalized
end

---@param path string?
---@return string?
local function abbreviate_home(path)
   local normalized = normalize_text(path)
   if not normalized then
      return nil
   end

   if HOME and normalized:sub(1, #HOME) == HOME then
      return '~' .. normalized:sub(#HOME + 1)
   end

   return normalized
end

---@param uri string
---@return string?, string?
local function decode_file_uri(uri)
   if uri:sub(1, 7) ~= 'file://' then
      return nil, nil
   end

   local rest = uri:sub(8)
   local slash = rest:find('/')
   if not slash then
      return nil, nil
   end

   local host = rest:sub(1, slash - 1)
   local path = rest:sub(slash):gsub('%%(%x%x)', function(hex)
      return string.char(tonumber(hex, 16))
   end)

   return path, host
end

---@param pane Pane|PaneInformation
---@return table<string, string>
function M.user_vars(pane)
   if pane and pane.get_user_vars then
      return pane:get_user_vars() or {}
   end

   return pane and pane.user_vars or {}
end

---@param pane Pane|PaneInformation
---@return {path: string?, display_path: string?, basename: string?, host: string?}
function M.cwd_info(pane)
   local cwd_uri

   if pane and pane.get_current_working_dir then
      cwd_uri = pane:get_current_working_dir()
   elseif pane then
      cwd_uri = pane.current_working_dir
   end

   if not cwd_uri then
      return {
         path = nil,
         display_path = nil,
         basename = nil,
         host = nil,
      }
   end

   local path
   local host

   if type(cwd_uri) == 'userdata' then
      path = cwd_uri.file_path
      host = cwd_uri.host
   else
      path, host = decode_file_uri(cwd_uri)
   end

   path = normalize_text(path)
   host = short_host(host or wezterm.hostname())

   return {
      path = path,
      display_path = abbreviate_home(path),
      basename = basename(path),
      host = host,
   }
end

---@param pane Pane|PaneInformation
---@return string?
function M.current_command(pane)
   local vars = M.user_vars(pane)
   return normalize_text(vars.WEZTERM_PROG)
end

---@param pane Pane|PaneInformation
---@return {user: string?, host: string?, in_tmux: boolean}
function M.identity(pane)
   local vars = M.user_vars(pane)
   local cwd = M.cwd_info(pane)

   return {
      user = normalize_text(vars.WEZTERM_USER),
      host = short_host(vars.WEZTERM_HOST) or cwd.host or short_host(wezterm.hostname()),
      in_tmux = vars.WEZTERM_IN_TMUX == '1',
   }
end

---@param text string?
---@param max_width integer
---@return string?
function M.truncate_left(text, max_width)
   local normalized = normalize_text(text)
   if not normalized or #normalized <= max_width then
      return normalized
   end

   if max_width <= 1 then
      return normalized:sub(#normalized - max_width + 1)
   end

   return '…' .. normalized:sub(#normalized - max_width + 2)
end

return M
