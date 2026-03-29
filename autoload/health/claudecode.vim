function! health#claudecode#check() abort
  call health#report_start('claudecode')

  if has('nvim-0.10')
    call health#report_ok('Neovim >= 0.10')
  else
    call health#report_warn('Neovim >= 0.10 recommended for full feature support')
  endif

  if claudecode#is_setup()
    call health#report_ok('Plugin is set up')
  else
    call health#report_error('Plugin not set up. Call claudecode#setup({}) or ensure plugin/ is in runtimepath')
  endif

  if executable('nvim-mcp-server')
    call health#report_ok('nvim-mcp-server executable found')
  else
    call health#report_error('nvim-mcp-server not found. Install with: pip install nvim-mcp-server')
  endif

  let nvim_socket = exists('$NVIM') ? $NVIM : (exists('$NVIM_LISTEN_ADDRESS') ? $NVIM_LISTEN_ADDRESS : '')
  if nvim_socket !=# ''
    call health#report_ok('$NVIM socket: ' . nvim_socket)
  else
    call health#report_info('$NVIM not set (normal when not running inside a nested terminal)')
  endif

  let settings_path = expand('~/.claude/settings.json')
  if filereadable(settings_path)
    let content = join(readfile(settings_path), "\n")
    if content =~# 'mcp__nvim'
      call health#report_ok('Claude Code settings.json has nvim MCP permission')
    else
      call health#report_warn('~/.claude/settings.json exists but no mcp__nvim permission found. Add: "mcp__nvim__*" to permissions.allow')
    endif
  else
    call health#report_warn('~/.claude/settings.json not found')
  endif
endfunction
