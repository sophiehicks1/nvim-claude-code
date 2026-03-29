if exists('g:loaded_claudecode')
  finish
endif
let g:loaded_claudecode = 1

autocmd VimEnter * ++once call s:Bootstrap()

function! s:Bootstrap() abort
  if !claudecode#is_setup()
    call claudecode#setup({})
  endif
endfunction
