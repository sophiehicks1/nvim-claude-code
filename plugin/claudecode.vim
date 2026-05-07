if exists('g:loaded_claudecode')
  finish
endif
let g:loaded_claudecode = 1

highlight default ClaudeCodeSign      guifg=#d4a373 gui=bold
highlight default link ClaudeCodePopup       NormalFloat
highlight default link ClaudeCodePopupBorder FloatBorder

if !exists('g:claude_show_annotations_mapping') && g:claude_show_annotations_mapping !=# ''
  execute 'nnoremap ' . g:claude_show_annotations_mapping .
        \ ' :call claudecode#annotations#show_popup(bufnr(), line("."))<CR>'
endif
