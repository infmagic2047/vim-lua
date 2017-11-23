" Vim indent file
" Language: Lua
" URL: https://github.com/tbastos/vim-lua

" Initialization ------------------------------------------{{{1

if exists("b:did_indent")
  finish
endif
let b:did_indent = 1

setlocal autoindent
setlocal nosmartindent

setlocal indentexpr=GetLuaIndent()
setlocal indentkeys+=0=end,0=until,0=elseif,0=else

" Only define the function once.
if exists("*GetLuaIndent")
  finish
endif

" Variables -----------------------------------------------{{{1

let s:open_patt = '\C\%(\<\%(function\|if\|repeat\|do\)\>\|(\|{\)'
let s:middle_patt = '\C\<\%(else\|elseif\)\>'
let s:close_patt = '\C\%(\<\%(end\|until\)\>\|)\|}\)'

let s:starts_with_end = '^\s*\%(' . s:close_patt . '\|' . s:middle_patt . '\)'

" Expression used to check whether we should skip a match with searchpair().
let s:skip_expr = "synIDattr(synID(line('.'),col('.'),1),'name') =~# 'luaComment\\|luaString'"

" Auxiliary Functions -------------------------------------{{{1

function s:IsInCommentOrString(lnum, col)
  return synIDattr(synID(a:lnum, a:col, 1), 'name') =~# 'luaCommentLong\|luaStringLong'
        \ && !(getline(a:lnum) =~# '^\s*\%(--\)\?\[=*\[') " opening tag is not considered 'in'
endfunction

" Find line above 'lnum' that isn't blank, in a comment or string.
function s:PrevLineOfCode(lnum)
  let lnum = prevnonblank(a:lnum)
  while s:IsInCommentOrString(lnum, 1)
    let lnum = prevnonblank(lnum - 1)
  endwhile
  return lnum
endfunction

" Gets line contents, excluding trailing comments.
function s:GetContents(lnum)
  return substitute(getline(a:lnum), '\v\m--.*$', '', '')
endfunction

" GetLuaIndent Function -----------------------------------{{{1

function GetLuaIndent()
  " if the line is in a long comment or string, don't change the indent
  if s:IsInCommentOrString(v:lnum, 1)
    return -1
  endif

  let prev_line = s:PrevLineOfCode(v:lnum - 1)
  if prev_line == 0
    " this is the first non-empty line
    return 0
  endif

  let contents_cur = s:GetContents(v:lnum)
  let contents_prev = s:GetContents(prev_line)

  let original_cursor_pos = getpos(".")

  " count how many blocks the previous line opens
  call cursor(v:lnum, 1)
  let num_prev_opens = searchpair(s:open_patt, s:middle_patt, s:close_patt,
        \ 'mb', s:skip_expr, prev_line)

  " count how many blocks the current line closes
  call cursor(prev_line, col([prev_line,'$']))
  let num_cur_closes = searchpair(s:open_patt, s:middle_patt, s:close_patt,
        \ 'm', s:skip_expr, v:lnum)

  " count how many blocks the previous line closes
  call cursor(prev_line - 1, col([prev_line - 1, '$']))
  let num_prev_closes = searchpair(s:open_patt, s:middle_patt, s:close_patt,
        \ 'm', s:skip_expr, prev_line)

  let i = num_prev_opens
  if num_cur_closes && contents_cur =~# s:starts_with_end
    let i -= 1
  endif
  if num_prev_closes && contents_prev !~# s:starts_with_end
    let i -= 1
  endif

  " restore cursor
  call setpos(".", original_cursor_pos)

  return indent(prev_line) + (&sw * i)

endfunction
