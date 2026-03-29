let s:terminal_bufnr = -1
let s:terminal_dir = ''

function! claudecode#terminal#get_terminal_buf() abort
  if s:terminal_bufnr >= 0 && nvim_buf_is_valid(s:terminal_bufnr)
    return s:terminal_bufnr
  endif
  let s:terminal_bufnr = -1
  let s:terminal_dir = ''
  return -1
endfunction

function! claudecode#terminal#open(dir) abort
  let config = claudecode#config()
  let resolved_dir = a:dir !=# '' ? a:dir : (config.default_dir isnot v:null ? config.default_dir : getcwd())
  let resolved_dir = fnamemodify(resolved_dir, ':p')
  let resolved_dir = substitute(resolved_dir, '/$', '', '')

  let existing_buf = claudecode#terminal#get_terminal_buf()

  if existing_buf >= 0
    if a:dir !=# '' && s:terminal_dir !=# resolved_dir
      echohl ErrorMsg
      echomsg printf('Claude Code is already running in %s. Close it first or omit the directory argument to reopen it.', s:terminal_dir)
      echohl None
      return
    endif
    call s:OpenSplit()
    call nvim_set_current_buf(existing_buf)
    startinsert
    return
  endif

  call s:OpenSplit()
  execute 'lcd ' . fnameescape(resolved_dir)
  terminal claude
  let bufnr = nvim_get_current_buf()

  let s:terminal_bufnr = bufnr
  let s:terminal_dir = resolved_dir

  startinsert

  execute 'autocmd TermClose <buffer=' . bufnr . '> ++once call s:OnTermClose(' . bufnr . ')'
endfunction

function! s:OpenSplit() abort
  if &columns > &lines * 2.5
    vsplit
  else
    split
  endif
endfunction

function! s:OnTermClose(bufnr) abort
  if s:terminal_bufnr == a:bufnr
    let s:terminal_bufnr = -1
    let s:terminal_dir = ''
  endif
  call timer_start(100, {t -> nvim_buf_is_valid(a:bufnr) && nvim_buf_delete(a:bufnr, {'force': v:true})})
endfunction
