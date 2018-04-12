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
    function! Mock(args, callback)
      let b:read_args = a:args
      call timer_start(0, {-> a:callback(json_encode({
      \   'full_name': 'poem/This is a test',
      \   'body_md': "DIN\nDON\nDAN",
      \   'wip': v:true,
      \ }))})
      return 'Now loading...'
    endfunction
    call Set('s:curl_async', {args, callback -> Mock(args, callback)})

    Expect bufname('%') ==# ''
    Expect getline(1, '$') ==# ['']
    Expect &l:filetype == ''
    Expect exists('b:metarw_esa_post_number') to_be_false
    Expect exists('b:metarw_esa_wip') to_be_false

    edit esa:1234

    Expect bufname('%') ==# 'esa:1234'
    Expect getline(1, '$') ==# ['Now loading...']
    Expect &l:filetype == ''
    Expect exists('b:metarw_esa_post_number') to_be_false
    Expect exists('b:metarw_esa_wip') to_be_false

    sleep 1m

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

  it 'fetches a post in background even if the buffer is closed'
    function! Mock(args, callback)
      let b:read_args = a:args
      call timer_start(0, {-> a:callback(json_encode({
      \   'full_name': 'poem/This is a test',
      \   'body_md': "DIN\nDON\nDAN",
      \   'wip': v:true,
      \ }))})
      return 'Now loading...'
    endfunction
    call Set('s:curl_async', {args, callback -> Mock(args, callback)})

    Expect bufname('%') ==# ''
    Expect getline(1, '$') ==# ['']
    Expect &l:filetype == ''
    Expect exists('b:metarw_esa_post_number') to_be_false
    Expect exists('b:metarw_esa_wip') to_be_false

    edit esa:1234
    let bufnr = bufnr('')

    Expect bufname('%') ==# 'esa:1234'
    Expect getline(1, '$') ==# ['Now loading...']
    Expect &l:filetype == ''
    Expect exists('b:metarw_esa_post_number') to_be_false
    Expect exists('b:metarw_esa_wip') to_be_false

    enew

    Expect bufnr('') != bufnr
    Expect getbufline(bufnr, 1, '$') ==# ['Now loading...']

    sleep 1m

    Expect getbufline(bufnr, 1, '$') ==# ['DIN', 'DON', 'DAN']

    execute bufnr 'buffer'

    Expect bufnr('') == bufnr
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

  it 'reuses existing esa:{post}:{title} buffer if opening esa:{post}'
    function! Mock(args, callback)
      let b:read_args = a:args
      call timer_start(0, {-> a:callback(json_encode({
      \   'full_name': 'poem/This is a test',
      \   'body_md': "DIN\nDON\nDAN",
      \   'wip': v:true,
      \ }))})
      return 'Now loading...'
    endfunction
    call Set('s:curl_async', {args, callback -> Mock(args, callback)})

    Expect bufname('%') ==# ''
    Expect getline(1, '$') ==# ['']
    Expect &l:filetype == ''
    Expect exists('b:metarw_esa_post_number') to_be_false
    Expect exists('b:metarw_esa_wip') to_be_false

    edit esa:1234
    let bufnr = bufnr('')

    Expect bufname('%') ==# 'esa:1234'
    Expect getline(1, '$') ==# ['Now loading...']
    Expect &l:filetype == ''
    Expect exists('b:metarw_esa_post_number') to_be_false
    Expect exists('b:metarw_esa_wip') to_be_false

    sleep 1m

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

    edit esa:1234

    Expect bufnr('') == bufnr
    Expect bufname('%') ==# 'esa:1234:poem/This is a test'
    Expect getline(1, '$') ==# ['Now loading...']
    Expect &l:filetype ==# 'markdown'
    Expect b:metarw_esa_post_number == 1234
    Expect b:metarw_esa_wip == v:true

    sleep 1m

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
    call Set('s:curl_async', {-> 'nope'})

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
    call Set('s:curl_async', {-> 'nope'})

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
    call Set('s:curl_async', {-> execute('echoerr "XYZZY"')})

    Expect bufname('%') ==# ''
    Expect getline(1, '$') ==# ['']
    Expect &l:filetype == ''
    Expect exists('b:metarw_esa_post_number') to_be_false
    Expect exists('b:metarw_esa_wip') to_be_false

    silent! edit esa:5678

    Expect v:errmsg ==# 'XYZZY'
    Expect bufname('%') ==# 'esa:5678'
    Expect getline(1, '$') ==# ['']
    Expect exists('b:metarw_esa_wip') to_be_false
    Expect &l:filetype == ''
    Expect exists('b:metarw_esa_post_number') to_be_false
    Expect exists('b:metarw_esa_wip') to_be_false
  end

  it 'is an error when esa responds so while reading'
    function! Mock(args, callback)
      let b:read_args = a:args
      call timer_start(0, {-> a:callback(json_encode({
      \   'error': 'not_found',
      \   'message': 'Not found',
      \ }))})
      return 'Now loading...'
    endfunction
    call Set('s:curl_async', {args, callback -> Mock(args, callback)})

    Expect bufname('%') ==# ''
    Expect getline(1, '$') ==# ['']
    Expect &l:filetype == ''
    Expect exists('b:metarw_esa_post_number') to_be_false
    Expect exists('b:metarw_esa_wip') to_be_false

    let v:errmsg = 'hjkl'
    silent! edit esa:5678
    sleep 1m

    Expect v:errmsg ==# 'esa.io: Not found'
    Expect bufname('%') ==# 'esa:5678'
    Expect getline(1, '$') ==# ['Now loading...']
    Expect exists('b:metarw_esa_wip') to_be_false
    Expect &l:filetype == ''
    Expect exists('b:metarw_esa_post_number') to_be_false
    Expect exists('b:metarw_esa_wip') to_be_false
  end
end
