let s:popup_winid = -1

function! claudecode#annotations#add(bufnr, line_num, comment) abort
  let ns = claudecode#utils#namespace()
  let annotations = getbufvar(a:bufnr, 'claudecode_annotations', {})

  call nvim_buf_set_extmark(a:bufnr, ns, a:line_num - 1, 0, {
        \ 'sign_text': 'CC',
        \ 'sign_hl_group': 'ClaudeCodeSign',
        \ })

  let annotations[string(a:line_num)] = a:comment
  call setbufvar(a:bufnr, 'claudecode_annotations', annotations)
endfunction

function! claudecode#annotations#show_popup(bufnr, line_num) abort
  let annotations = getbufvar(a:bufnr, 'claudecode_annotations', {})
  let comment = get(annotations, string(a:line_num), v:null)
  if comment is v:null
    echomsg 'No Claude annotation on this line'
    return
  endif

  call claudecode#annotations#close_popup()

  let lines = split(comment, "\n")
  let max_width = min([max(map(copy(lines), 'len(v:val)')), 80])
  let height = len(lines)

  let buf = nvim_create_buf(v:false, v:true)
  call nvim_buf_set_lines(buf, 0, -1, v:false, lines)
  call nvim_buf_set_option(buf, 'modifiable', v:false)

  let s:popup_winid = nvim_open_win(buf, v:false, {
        \ 'relative': 'cursor',
        \ 'row': 1,
        \ 'col': 0,
        \ 'width': max_width + 2,
        \ 'height': height,
        \ 'style': 'minimal',
        \ 'border': 'rounded',
        \ })

  call nvim_win_set_option(s:popup_winid, 'winhl',
        \ 'Normal:ClaudeCodePopup,FloatBorder:ClaudeCodePopupBorder')

  autocmd CursorMoved,BufLeave,InsertEnter * ++once call claudecode#annotations#close_popup()

  execute 'nnoremap <buffer> <nowait> q :call claudecode#annotations#close_popup()<CR>'
endfunction

function! claudecode#annotations#close_popup() abort
  if s:popup_winid >= 0 && nvim_win_is_valid(s:popup_winid)
    call nvim_win_close(s:popup_winid, v:true)
  endif
  let s:popup_winid = -1
endfunction

function! claudecode#annotations#clear(bufnr) abort
  let ns = claudecode#utils#namespace()
  if a:bufnr >= 0
    call nvim_buf_clear_namespace(a:bufnr, ns, 0, -1)
    call setbufvar(a:bufnr, 'claudecode_annotations', v:null)
  else
    for buf in nvim_list_bufs()
      if nvim_buf_is_valid(buf)
        call nvim_buf_clear_namespace(buf, ns, 0, -1)
        call setbufvar(buf, 'claudecode_annotations', v:null)
      endif
    endfor
  endif
endfunction
