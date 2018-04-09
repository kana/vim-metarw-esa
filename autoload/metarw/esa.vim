" vim-metarw-esa - metarw scheme: esa
" Version: 0.3.0
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
  if tokens is 0 || tokens[1] ==# 'new'
    return ['error', 'Invalid path']
  endif

  if tokens[1] ==# 'recent'
    return s:browse(tokens[0], tokens[2])
  else
    return ['read', {-> s:read(a:fakepath)}]
  endif
endfunction




function! metarw#esa#write(fakepath, line1, line2, append_p)  "{{{2
  " Note: append_p is not supported.
  let tokens = s:parse_fakepath(a:fakepath)
  if tokens is 0 || tokens[1] ==# 'recent'
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




function! s:browse(team_name, page)  "{{{2
  try
    return ['browse', s:_browse(a:team_name, a:page)]
  catch
    let e = v:exception
  endtry

  return ['error', substitute(e, '^Vim(echoerr):', '', '')]
endfunction

function! s:_browse(team_name, page) abort
  let json = json_decode(s:.curl([
  \   '--silent',
  \   '--header',
  \   printf('Authorization: Bearer %s', s:.get_esa_access_token()),
  \   printf('https://api.esa.io/v1/teams/%s/posts?page=%d', a:team_name, a:page),
  \ ]))
  if has_key(json, 'error')
    echoerr 'esa.io:' json.message
    return
  endif

  let prev_page_items = json.prev_page != v:null ? [{
  \   'label': '(prev page)',
  \   'fakepath': json.prev_page == 1 ? 'esa:recent' : 'esa:recent:' . json.prev_page,
  \ }] : []
  let next_page_items = json.next_page != v:null ? [{
  \   'label': '(next page)',
  \   'fakepath': 'esa:recent:' . json.next_page,
  \ }] : []
  let post_items = map(json.posts, {_, v -> {
  \   'label': v.full_name,
  \   'fakepath': 'esa:' . v.number,
  \ }})
  return prev_page_items + post_items + next_page_items
endfunction




function! s:parse_fakepath(fakepath)  "{{{2
  " esa:{post_number}
  " esa:{post_number}:{title}
  " esa:new:{title}
  " esa:recent
  " esa:recent:{page}

  let tokens = matchlist(a:fakepath, '\v^esa:(\d+|new|recent)%(:(.*))?')
  if tokens == []
    return 0
  endif

  if !exists('g:metarw_esa_default_team_name')
    return 0
  endif

  if tokens[1] ==# 'recent'
    let page = tokens[2]
    if page !~# '^\d*$'
      return 0
    endif

    return [g:metarw_esa_default_team_name, 'recent', page != '' ? page : 1]
  else
    let post_number = tokens[1]
    let title = tokens[2]

    return [g:metarw_esa_default_team_name, post_number, title]
  endif
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

  let b:metarw_esa_state = 'loading'
  " TODO: Make it mockable.
  let b:metarw_esa_job = job_start([
  \   'curl',
  \   '--silent',
  \   '--header',
  \   printf('Authorization: Bearer %s', s:.get_esa_access_token()),
  \   printf('https://api.esa.io/v1/teams/%s/posts/%s', team_name, post_number),
  \ ], {
  \   'close_cb': {channel -> s:_read_after_curl(channel, a:fakepath, bufnr(''))}
  \ } )
  return ['Now loading...']
endfunction

function! s:_read_after_curl(channel, fakepath, bufnr) abort
  " TODO: Use bufnr to buffer-local operations.
  let lines = []
  while ch_status(a:channel, {'part': 'out'}) ==# 'buffered'
    call add(lines, ch_read(a:channel))
  endwhile
  let response = join(lines, "\n")

  let json = json_decode(response)
  if has_key(json, 'error')
    echoerr 'esa.io:' json.message
    return
  endif

  let [team_name, post_number, title] = s:parse_fakepath(a:fakepath)

  " TODO: This is ad hoc.  This should be determined by what Ex command is
  " used to invoke s:read.
  if bufname('%') ==# a:fakepath && title == ''
    silent file `=a:fakepath . ':' . json.full_name`
    let b:metarw_esa_wip = json.wip
    let b:metarw_esa_post_number = str2nr(post_number)
  endif

  " Replace tofu with the actual content.
  % delete _
  1 put =split(json.body_md, '\r\?\n', 1)
  1 delete _

  " Clear undo history to avoid undoing to nothing.
  let undolevels = &l:undolevels
  let &l:undolevels = -1
  execute 'normal!' "a \<BS>\<Esc>"
  let &l:undolevels = undolevels
  setlocal nomodified

  " For some reason, reloading esa content disables syntax highlighting.
  setfiletype markdown
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
  if exists('b:metarw_esa_post_number') ? b:metarw_esa_post_number != a:post_number : a:post_number !=# 'new'
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
  let wip = v:cmdbang ? v:false
  \       : exists('b:metarw_esa_wip') ? b:metarw_esa_wip
  \       : v:true

  let json = {
  \   'post': {
  \     'name': name,
  \     'category': category,
  \     'body_md': body_md,
  \     'wip': wip,
  \   }
  \ }

  if a:post_number ==# 'new'
    let method = 'POST'
    let url = printf('https://api.esa.io/v1/teams/%s/posts', a:team_name)
  else
    let method = 'PATCH'
    let url = printf('https://api.esa.io/v1/teams/%s/posts/%s', a:team_name, a:post_number)
  endif

  let json = json_decode(s:.curl([
  \   '--silent',
  \   '--request',
  \   method,
  \   '--header',
  \   printf('Authorization: Bearer %s', s:.get_esa_access_token()),
  \   '--header',
  \   'Content-Type: application/json',
  \   '--data',
  \   json_encode(json),
  \   url,
  \ ]))
  if has_key(json, 'error')
    echoerr 'esa.io:' json.message
    return
  endif

  let b:metarw_esa_wip = wip
  if a:post_number ==# 'new'
    let b:metarw_esa_post_number = json.number
    silent file `='esa:' . json.number . ':' . json.full_name`
    setfiletype markdown
  endif
  let v:errmsg = ''
endfunction








" __END__  "{{{1
" vim: foldmethod=marker
