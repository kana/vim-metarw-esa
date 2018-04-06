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
  return ['error', 'TODO']
endfunction








" Misc.  "{{{1
function! s:get_esa_access_token()  "{{{2
  return readfile('.esa')[0]
endfunction




function! s:parse_fakepath(fakepath)  "{{{2
  " TODO: esa:{post_number}
  " esa:{team_name}:{post_number}

  let tokens = split(a:fakepath, ':')
  if len(tokens) != 3
    return 0
  endif

  return tokens[1:]
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








" __END__  "{{{1
" vim: foldmethod=marker
