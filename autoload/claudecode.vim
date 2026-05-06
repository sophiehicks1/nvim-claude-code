let s:config = {
      \ 'keymaps': {
      \   'annotation_show': '',
      \ }
      \ }

function! claudecode#setup(opts) abort
  if has_key(a:opts, 'keymaps')
    call extend(s:config.keymaps, a:opts.keymaps)
  endif

  highlight default ClaudeCodeSign      guifg=#d4a373 gui=bold
  highlight default link ClaudeCodePopup       NormalFloat
  highlight default link ClaudeCodePopupBorder FloatBorder

  call claudecode#commands#register(s:config)
endfunction
