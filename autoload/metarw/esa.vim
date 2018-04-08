" vim-metarw-esa - metarw scheme: esa
" Version: 0.1.0
" Copyright (C) 2018 Kana Natsuno <https://whileimautomaton.net/>
" License: MIT license  {{{
"     Permission is hereby granted, free of charge, to any person obtaining
"     a copy of this software and associated documentation files (the
"     "Software"), to deal in the Software without restriction, including
"     without limitation the rights to use, copy, modify, merge, publish,
"     distribute, sublicense, and/or sell copies of the Software, and to
"     permit persons to whom the Software is furnished to do so, subject to
"     the following conditions:
"
"     The above copyright notice and this permission notice shall be included
"     in all copies or substantial portions of the Software.
"
"     THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
"     OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
"     MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
"     IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
"     CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
"     TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
"     SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
" }}}
" Interface  "{{{1
function! metarw#esa#_scope()  "{{{2
  return s:
endfunction




function! metarw#esa#complete(arglead, cmdline, cursorpos)  "{{{2
  return []
endfunction




function! metarw#esa#read(fakepath)  "{{{2
  let tokens = s:parse_fakepath(a:fakepath)
  if tokens is 0
    return ['error', 'Invalid path']
  endif

  return ['read', {-> s:read(a:fakepath)}]
endfunction




function! metarw#esa#write(fakepath, line1, line2, append_p)  "{{{2
  " Note: append_p is not supported.
  let tokens = s:parse_fakepath(a:fakepath)
  if tokens is 0
    return ['error', 'Invalid path']
  endif

  let [team_name, post_number, title] = tokens

  return ['write', {-> s:write(team_name, post_number, title, getline(a:line1, a:line2))}]
endfunction








" Misc.  "{{{1
function! s:.curl(args)  "{{{2
  let command = 'curl ' . join(map(a:args, {_, v -> shellescape(v)}), ' ')
  return system(command)
endfunction




function! s:.get_esa_access_token()  "{{{2
  return readfile(expand('~/.esa-token'))[0]
endfunction




function! s:parse_fakepath(fakepath)  "{{{2
  " esa:{post_number}
  " esa:{post_number}:{title}
  " esa:{team_name}:{post_number}
  " esa:{team_name}:{post_number}:{title}

  let tokens = matchlist(a:fakepath, '\v^esa%(:([^:]+))?:(\d+)%(:(.*))?')

  if tokens[1] != ''
    let team_name = tokens[1]
  elseif exists('g:metarw_esa_default_team_name')
    let team_name = g:metarw_esa_default_team_name
  else
    return 0
  endif
  let post_number = tokens[2]
  let title = tokens[3]

  return [team_name, post_number, title]
endfunction




function! s:read(fakepath)  "{{{2
  try
    return s:_read(a:fakepath)
  catch
    let e = v:exception
  endtry

  echoerr substitute(e, '^Vim(echoerr):', '', '')
  return []
endfunction

function! s:_read(fakepath) abort
  let [team_name, post_number, title] = s:parse_fakepath(a:fakepath)

  let json = json_decode(s:.curl([
  \   '--silent',
  \   '--header',
  \   printf('Authorization: Bearer %s', s:.get_esa_access_token()),
  \   printf('https://api.esa.io/v1/teams/%s/posts/%s', team_name, post_number),
  \ ]))
  let markdown_content = json.body_md

  " TODO: This is ad hoc.  This should be determined by what Ex command is
  " used to invoke s:read.
  if bufname('%') ==# a:fakepath && title == ''
    silent file `=a:fakepath . ':' . json.full_name`
    setfiletype markdown
    let b:metarw_esa_wip = json.wip
    let b:metarw_esa_post_number = str2nr(post_number)
  endif

  return split(markdown_content, '\r\?\n', 1)
endfunction




function! s:write(team_name, post_number, title, lines)  "{{{2
  try
    call s:_write(a:team_name, a:post_number, a:title, a:lines)
    return
  catch
    let e = v:exception
  endtry

  echoerr substitute(e, '^Vim(echoerr):', '', '')
endfunction

function! s:_write(team_name, post_number, title, lines) abort
  if !exists('b:metarw_esa_post_number') || b:metarw_esa_post_number != a:post_number
    echoerr 'Writing to another esa post is not supported'
    " Because it seems to be a mistaking to do so.
    return
  endif
  if a:title == ''
    echoerr 'Cannot save without title'
    " Because there is something wrong to encounter this situation.
    return
  endif
  let tokens = split(a:title, '.*\zs/')
  if 2 <= len(tokens)
    let category = tokens[0]
    let name = tokens[1]
  else
    let category = ''
    let name = tokens[0]
  endif
  let body_md = join(a:lines, "\n")
  let wip = v:cmdbang ? v:false : b:metarw_esa_wip

  let json = {
  \   'post': {
  \     'name': name,
  \     'category': category,
  \     'body_md': body_md,
  \     'wip': wip,
  \   }
  \ }

  call s:.curl([
  \   '--silent',
  \   '--request',
  \   'PATCH',
  \   '--header',
  \   printf('Authorization: Bearer %s', s:.get_esa_access_token()),
  \   '--header',
  \   'Content-Type: application/json',
  \   '--data',
  \   json_encode(json),
  \   printf('https://api.esa.io/v1/teams/%s/posts/%s', a:team_name, a:post_number),
  \ ])

  let b:metarw_esa_wip = wip
endfunction








" __END__  "{{{1
" vim: foldmethod=marker
