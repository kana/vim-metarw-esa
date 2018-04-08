source t/support/startup.vim

describe 'metarw-esa'
  before
    let g:metarw_esa_default_team_name = 'myteam'
  end

  after
    ResetContext
    %bdelete!
  end

  it 'enables to read an esa post as markdown via esa:{post}'
    function! Mock(args)
      let b:read_args = a:args
      return json_encode({
      \   'full_name': 'poem/This is a test',
      \   'body_md': "DIN\nDON\nDAN",
      \   'wip': v:true,
      \ })
    endfunction
    call Set('s:curl', {args -> Mock(args)})

    Expect bufname('%') ==# ''
    Expect getline(1, '$') ==# ['']
    Expect &l:filetype == ''
    Expect exists('b:metarw_esa_post_number') to_be_false
    Expect exists('b:metarw_esa_wip') to_be_false

    edit esa:1234

    Expect bufname('%') ==# 'esa:1234:poem/This is a test'
    Expect getline(1, '$') ==# ['DIN', 'DON', 'DAN']
    Expect &l:filetype ==# 'markdown'
    Expect b:metarw_esa_post_number == 1234
    Expect b:metarw_esa_wip == v:true
    Expect b:read_args ==# [
    \   '--silent',
    \   '--header',
    \   'Authorization: Bearer xyzzy',
    \   'https://api.esa.io/v1/teams/myteam/posts/1234',
    \ ]
  end

  it 'enables also to insert an esa post into the current buffer'
    function! Mock(args)
      let b:read_args = a:args
      return json_encode({
      \   'full_name': 'poem/This is a test',
      \   'body_md': "DIN\nDON\nDAN",
      \   'wip': v:true,
      \ })
    endfunction
    call Set('s:curl', {args -> Mock(args)})

    put =['MY', 'ONLY', 'STAR']
    1 delete _

    Expect bufname('%') ==# ''
    Expect getline(1, '$') ==# ['MY', 'ONLY', 'STAR']
    Expect &l:filetype == ''
    Expect exists('b:metarw_esa_post_number') to_be_false
    Expect exists('b:metarw_esa_wip') to_be_false

    2
    read esa:1234

    Expect bufname('%') ==# ''
    Expect getline(1, '$') ==# ['MY', 'ONLY', 'DIN', 'DON', 'DAN', 'STAR']
    Expect &l:filetype ==# ''
    Expect exists('b:metarw_esa_post_number') to_be_false
    Expect exists('b:metarw_esa_wip') to_be_false
    Expect b:read_args ==# [
    \   '--silent',
    \   '--header',
    \   'Authorization: Bearer xyzzy',
    \   'https://api.esa.io/v1/teams/myteam/posts/1234',
    \ ]
  end

  it 'does not support multi-team at the moment'
    call Set('s:curl', {-> 'nope'})

    Expect bufname('%') ==# ''
    Expect getline(1, '$') ==# ['']
    Expect &l:filetype == ''
    Expect exists('b:metarw_esa_post_number') to_be_false
    Expect exists('b:metarw_esa_wip') to_be_false

    silent! edit esa:anotherteam:1234

    Expect v:errmsg ==# 'Invalid path: esa:anotherteam:1234'
    Expect bufname('%') ==# 'esa:anotherteam:1234'
    Expect getline(1, '$') ==# ['']
    Expect &l:filetype == ''
    Expect exists('b:metarw_esa_post_number') to_be_false
    Expect exists('b:metarw_esa_wip') to_be_false
  end

  it 'is an error to open esa:{post} without configuration'
    unlet! g:metarw_esa_default_team_name
    call Set('s:curl', {-> 'nope'})

    Expect bufname('%') ==# ''
    Expect getline(1, '$') ==# ['']
    Expect &l:filetype == ''
    Expect exists('b:metarw_esa_post_number') to_be_false
    Expect exists('b:metarw_esa_wip') to_be_false

    silent! edit esa:1234

    Expect v:errmsg ==# 'Invalid path: esa:1234'
    Expect bufname('%') ==# 'esa:1234'
    Expect getline(1, '$') ==# ['']
    Expect &l:filetype == ''
    Expect exists('b:metarw_esa_post_number') to_be_false
    Expect exists('b:metarw_esa_wip') to_be_false
  end

  it 'stops as soon as possible if an error occurs while reading an esa post'
    call Set('s:curl', {-> execute('echoerr "XYZZY"')})

    Expect bufname('%') ==# ''
    Expect getline(1, '$') ==# ['']
    Expect &l:filetype == ''
    Expect exists('b:metarw_esa_post_number') to_be_false
    Expect exists('b:metarw_esa_wip') to_be_false

    silent! edit esa:5678

    Expect v:errmsg == 'XYZZY'
    Expect bufname('%') ==# 'esa:5678'
    Expect getline(1, '$') ==# ['']
    Expect exists('b:metarw_esa_wip') to_be_false
    Expect &l:filetype == ''
    Expect exists('b:metarw_esa_post_number') to_be_false
    Expect exists('b:metarw_esa_wip') to_be_false
  end

  it 'enables to write an esa post via esa:{post}:{title}'
    call Set('s:curl', {-> json_encode({
    \   'full_name': 'poem/This is a test',
    \   'body_md': "DIN\nDON\nDAN",
    \   'wip': v:true,
    \ })})
    edit esa:1234

    Expect bufname('%') ==# 'esa:1234:poem/This is a test'
    Expect getline(1, '$') ==# ['DIN', 'DON', 'DAN']
    Expect &l:filetype ==# 'markdown'
    Expect &l:modified to_be_false
    Expect b:metarw_esa_post_number == 1234
    Expect b:metarw_esa_wip == v:true

    $ put ='WOO'

    Expect &l:modified to_be_true

    call Set('s:curl', {args -> execute('let b:write_args = args')})

    write

    Expect &l:modified to_be_false
    Expect b:write_args ==# [
    \   '--silent',
    \   '--request',
    \   'PATCH',
    \   '--header',
    \   'Authorization: Bearer xyzzy',
    \   '--header',
    \   'Content-Type: application/json',
    \   '--data',
    \   json_encode({'post': {
    \     'name': 'This is a test',
    \     'category': 'poem',
    \     'body_md': "DIN\nDON\nDAN\nWOO",
    \     'wip': v:true,
    \   }}),
    \   'https://api.esa.io/v1/teams/myteam/posts/1234',
    \ ]
  end

  it 'keeps WIP status of an esa post with :write'
    call Set('s:curl', {-> json_encode({
    \   'full_name': 'poem/This is a test',
    \   'body_md': "DIN\nDON\nDAN",
    \   'wip': v:false,
    \ })})
    edit esa:1234

    Expect b:metarw_esa_wip == v:false

    call Set('s:curl', {args -> execute('let b:write_args = args')})

    write

    Expect b:metarw_esa_wip == v:false
    Expect b:write_args ==# [
    \   '--silent',
    \   '--request',
    \   'PATCH',
    \   '--header',
    \   'Authorization: Bearer xyzzy',
    \   '--header',
    \   'Content-Type: application/json',
    \   '--data',
    \   json_encode({'post': {
    \     'name': 'This is a test',
    \     'category': 'poem',
    \     'body_md': "DIN\nDON\nDAN",
    \     'wip': v:false,
    \   }}),
    \   'https://api.esa.io/v1/teams/myteam/posts/1234',
    \ ]
  end

  it 'enables to publish an esa post with :write!'
    call Set('s:curl', {-> json_encode({
    \   'full_name': 'poem/This is a test',
    \   'body_md': "DIN\nDON\nDAN",
    \   'wip': v:true,
    \ })})
    edit esa:1234

    Expect b:metarw_esa_wip == v:true

    call Set('s:curl', {args -> execute('let b:write_args = args')})

    write!

    Expect b:metarw_esa_wip == v:false
    Expect b:write_args ==# [
    \   '--silent',
    \   '--request',
    \   'PATCH',
    \   '--header',
    \   'Authorization: Bearer xyzzy',
    \   '--header',
    \   'Content-Type: application/json',
    \   '--data',
    \   json_encode({'post': {
    \     'name': 'This is a test',
    \     'category': 'poem',
    \     'body_md': "DIN\nDON\nDAN",
    \     'wip': v:false,
    \   }}),
    \   'https://api.esa.io/v1/teams/myteam/posts/1234',
    \ ]
  end

  it 'does not support writing to an esa post without opening it'
    call Set('s:curl', {args -> execute('let b:write_args = args')})

    silent! write esa:1234:poem/What

    Expect v:errmsg =~# 'Writing to another esa post is not supported'
    Expect exists('b:write_args') to_be_false
  end

  it 'does not support writing to an esa post from another esa post'
    call Set('s:curl', {-> json_encode({
    \   'full_name': 'poem/This is a test 2.0',
    \   'body_md': "BIM\nBUM\nBAM",
    \   'wip': v:false,
    \ })})

    edit esa:5678

    call Set('s:curl', {args -> execute('let b:write_args = args')})

    silent! write esa:1234:poem/What

    Expect v:errmsg =~# 'Writing to another esa post is not supported'
    Expect exists('b:write_args') to_be_false
  end

  it 'refuses writing to an esa post without title'
    call Set('s:curl', {-> json_encode({
    \   'full_name': 'poem/This is a test 2.0',
    \   'body_md': "BIM\nBUM\nBAM",
    \   'wip': v:false,
    \ })})

    edit esa:5678

    call Set('s:curl', {args -> execute('let b:write_args = args')})

    file esa:5678
    silent! write

    Expect v:errmsg =~# 'Cannot save without title'
    Expect exists('b:write_args') to_be_false
  end

  it 'stops as soon as possible if an error occurs while writing an esa post'
    call Set('s:curl', {-> json_encode({
    \   'full_name': 'poem/This is a test',
    \   'body_md': "DIN\nDON\nDAN",
    \   'wip': v:true,
    \ })})
    edit esa:1234

    Expect b:metarw_esa_wip == v:true

    call Set('s:curl', {-> execute('echoerr "XYZZY"')})

    silent! write!

    Expect v:errmsg =~# 'XYZZY'
    " This is set to v:false if writing steps did not stop by an error.
    Expect b:metarw_esa_wip == v:true
  end
end
