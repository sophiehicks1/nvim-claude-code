function! claudecode#chat#open_compose() abort
  if claudecode#terminal#get_terminal_buf() < 0
    echohl WarningMsg
    echomsg 'No Claude Code terminal running. Use :ClaudeCode first.'
    echohl None
    return
  endif

  botright 8split
  let buf = nvim_create_buf(v:false, v:true)
  call nvim_set_current_buf(buf)

  call setbufvar(buf, '&buftype', 'nofile')
  call setbufvar(buf, '&bufhidden', 'wipe')
  call setbufvar(buf, '&filetype', 'markdown')

  execute 'nnoremap <buffer> <nowait> <CR> :call claudecode#chat#send_and_close(' . buf . ')<CR>'
  execute 'nnoremap <buffer> <nowait> q :call claudecode#chat#close(' . buf . ')<CR>'

  startinsert
endfunction

function! claudecode#chat#send_and_close(buf) abort
  let term_buf = claudecode#terminal#get_terminal_buf()
  if term_buf < 0
    echohl WarningMsg
    echomsg 'No Claude Code terminal running. Use :ClaudeCode first.'
    echohl None
    return
  endif

  let lines = nvim_buf_get_lines(a:buf, 0, -1, v:false)
  let text = join(lines, "\n")
  if text =~# '^\s*$'
    echomsg 'Empty message, not sent'
    return
  endif

  let chan = getbufvar(term_buf, '&channel')
  if !chan || chan <= 0
    echohl ErrorMsg
    echomsg 'Claude terminal channel not available'
    echohl None
    return
  endif

  call chansend(chan, text . "\n")
  call claudecode#chat#close(a:buf)
  echomsg 'Sent to Claude'
endfunction

function! claudecode#chat#close(buf) abort
  if nvim_buf_is_valid(a:buf)
    call nvim_buf_delete(a:buf, {'force': v:true})
  endif
endfunction
