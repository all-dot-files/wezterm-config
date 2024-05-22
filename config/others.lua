local wezterm = require('wezterm')
local platform = require('utils.platform')

return {
    show_tab_index_in_tab_bar = true,
    skip_close_confirmation_for_processes_named = {'bash', 'sh', 'zsh', 'fish', 'tmux', 'nu', 'cmd.exe', 'pwsh.exe',
                                                   'powershell.exe'}
}
