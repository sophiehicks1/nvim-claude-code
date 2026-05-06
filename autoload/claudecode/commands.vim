function! claudecode#commands#register(config) abort
  let keymaps = get(a:config, 'keymaps', {})

  if get(keymaps, 'annotation_show', '') !=# ''
    execute 'nnoremap ' . keymaps.annotation_show .
          \ ' :call claudecode#annotations#show_popup(bufnr(), line("."))<CR>'
  endif
endfunction
