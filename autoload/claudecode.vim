let s:config = {
      \ 'default_dir': v:null,
      \ 'ex_command': v:true,
      \ 'keymaps': {
      \   'annotation_show': '',
      \   'compose_open': '',
      \   'send_selection': '',
      \ }
      \ }

function! claudecode#setup(opts) abort
  if has_key(a:opts, 'default_dir')
    let s:config.default_dir = a:opts.default_dir
  endif
  if has_key(a:opts, 'ex_command')
    let s:config.ex_command = a:opts.ex_command
  endif
  if has_key(a:opts, 'keymaps')
    call extend(s:config.keymaps, a:opts.keymaps)
  endif

  highlight default ClaudeCodeSign      guifg=#d4a373 gui=bold
  highlight default link ClaudeCodePopup       NormalFloat
  highlight default link ClaudeCodePopupBorder FloatBorder

  call claudecode#commands#register(s:config)
endfunction

function! claudecode#config() abort
  return s:config
endfunction
