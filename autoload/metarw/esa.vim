" vim-metarw-esa - metarw scheme: esa
" Version: 0.0.0
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
function! metarw#esa#complete(arglead, cmdline, cursorpos)  "{{{2
  return []
endfunction




function! metarw#esa#read(fakepath)  "{{{2
  let tokens = s:parse_fakepath(a:fakepath)
  if tokens is 0
    return ['error', 'Invalid path']
  endif

  let [team_name, post_number] = tokens

  return ['read', {-> s:read(team_name, post_number)}]
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
function! s:get_esa_access_token()  "{{{2
  return readfile('.esa')[0]
endfunction




function! s:parse_fakepath(fakepath)  "{{{2
  " TODO: esa:{post_number}
  " esa:{team_name}:{post_number}
  " esa:{team_name}:{post_number}:{title}

  let tokens = matchlist(a:fakepath, '\v^esa:([^:]+):(\d+)%(:(.*))?')

  return [tokens[1], tokens[2], tokens[3]]
endfunction




function! s:read(team_name, post_number)  "{{{2
  let fetch_command = printf(
  \   'curl --header "Authorization: Bearer %s" "https://api.esa.io/v1/teams/%s/posts/%s"',
  \   s:get_esa_access_token(),
  \   a:team_name,
  \   a:post_number
  \ )
  let markdown_content = json_decode(system(fetch_command)).body_md
  return split(markdown_content, '\r\?\n', 1)
endfunction




function! s:write(team_name, post_number, title, lines)  "{{{2
  let tokens = split(a:title, '.*\zs/')
  if 2 <= len(tokens)
    let category = tokens[0]
    let name = tokens[1]
  else
    let category = ''
    let name = tokens[0]
  endif
  let body_md = join(a:lines, "\n")

  " Note: wip is not supported.
  let json = {
  \   'post': {
  \     'name': name,
  \     'category': category,
  \     'body_md': body_md,
  \   }
  \ }

  let fetch_command = printf(
  \   'curl --request "PATCH" --header "Authorization: Bearer %s" --header "Content-Type: application/json" --data %s "https://api.esa.io/v1/teams/%s/posts/%s"',
  \   s:get_esa_access_token(),
  \   shellescape(json_encode(json)),
  \   a:team_name,
  \   a:post_number
  \ )
  call system(fetch_command)
endfunction








" __END__  "{{{1
" vim: foldmethod=marker
