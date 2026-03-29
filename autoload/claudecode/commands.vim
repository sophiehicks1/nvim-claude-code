function! claudecode#commands#register(config) abort
  let keymaps = get(a:config, 'keymaps', {})

  if get(keymaps, 'annotation_show', '') !=# ''
    execute 'nnoremap ' . keymaps.annotation_show .
          \ ' :call claudecode#annotations#show_popup(bufnr(), line("."))<CR>'
  endif

  command! -nargs=? -complete=dir ClaudeCode call claudecode#terminal#open(<q-args>)

  if get(keymaps, 'compose_open', '') !=# ''
    execute 'nnoremap ' . keymaps.compose_open .
          \ ' :call claudecode#chat#open_compose()<CR>'
  endif

  if get(keymaps, 'send_selection', '') !=# ''
    execute 'vnoremap ' . keymaps.send_selection . ' :<C-u>call s:SendSelection()<CR>'
  endif
endfunction

function! s:SendSelection() abort
  normal! "zy
  let text = @z
  let term_buf = claudecode#terminal#get_terminal_buf()
  if term_buf < 0
    echohl WarningMsg
    echomsg 'No Claude Code terminal running. Use :ClaudeCode first.'
    echohl None
    return
  endif
  let chan = getbufvar(term_buf, '&channel')
  if chan && chan > 0
    call chansend(chan, text . "\n")
    echomsg 'Sent selection to Claude'
  endif
endfunction
