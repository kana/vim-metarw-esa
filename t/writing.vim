source t/support/startup.vim

describe 'metarw-esa'
  before
    let g:metarw_esa_default_team_name = 'myteam'
  end

  after
    ResetContext
    %bwipeout!
  end

  it 'enables to write an esa post via esa:{post}:{title}'
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
    edit esa:1234
    sleep 1m

    Expect bufname('%') ==# 'esa:1234:poem/This is a test'
    Expect getline(1, '$') ==# ['DIN', 'DON', 'DAN']
    Expect &l:filetype ==# 'markdown'
    Expect &l:modified to_be_false
    Expect b:metarw_esa_post_number == 1234
    Expect b:metarw_esa_wip == v:true

    $ put ='WOO'

    Expect &l:modified to_be_true

    function! Mock(args)
      let b:write_args = a:args
      return json_encode({})
    endfunction
    call Set('s:curl', {args -> Mock(args)})

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
    function! Mock(args, callback)
      let b:read_args = a:args
      call timer_start(0, {-> a:callback(json_encode({
      \   'full_name': 'poem/This is a test',
      \   'body_md': "DIN\nDON\nDAN",
      \   'wip': v:false,
      \ }))})
      return 'Now loading...'
    endfunction
    call Set('s:curl_async', {args, callback -> Mock(args, callback)})
    edit esa:1234
    sleep 1m

    Expect b:metarw_esa_wip == v:false

    function! Mock(args)
      let b:write_args = a:args
      return json_encode({})
    endfunction
    call Set('s:curl', {args -> Mock(args)})

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
    edit esa:1234
    sleep 1m

    Expect b:metarw_esa_wip == v:true

    function! Mock(args)
      let b:write_args = a:args
      return json_encode({})
    endfunction
    call Set('s:curl', {args -> Mock(args)})

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
    function! Mock(args, callback)
      let b:read_args = a:args
      call timer_start(0, {-> a:callback(json_encode({
      \   'full_name': 'poem/This is a test 2.0',
      \   'body_md': "BIM\nBUM\nBAM",
      \   'wip': v:false,
      \ }))})
      return 'Now loading...'
    endfunction
    call Set('s:curl_async', {args, callback -> Mock(args, callback)})

    edit esa:5678
    sleep 1m

    call Set('s:curl', {args -> execute('let b:write_args = args')})

    silent! write esa:1234:poem/What

    Expect v:errmsg =~# 'Writing to another esa post is not supported'
    Expect exists('b:write_args') to_be_false
  end

  it 'refuses writing to an esa post without title'
    function! Mock(args, callback)
      let b:read_args = a:args
      call timer_start(0, {-> a:callback(json_encode({
      \   'full_name': 'poem/This is a test 2.0',
      \   'body_md': "BIM\nBUM\nBAM",
      \   'wip': v:false,
      \ }))})
      return 'Now loading...'
    endfunction
    call Set('s:curl_async', {args, callback -> Mock(args, callback)})

    edit esa:5678
    sleep 1m

    call Set('s:curl', {args -> execute('let b:write_args = args')})

    file esa:5678
    silent! write

    Expect v:errmsg =~# 'Cannot save without title'
    Expect exists('b:write_args') to_be_false
  end

  it 'stops as soon as possible if an error occurs while writing an esa post'
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
    edit esa:1234
    sleep 1m

    Expect b:metarw_esa_wip == v:true

    call Set('s:curl', {-> execute('echoerr "XYZZY"')})

    silent! write!

    Expect v:errmsg =~# 'XYZZY'
    " This is set to v:false if writing steps did not stop by an error.
    Expect b:metarw_esa_wip == v:true
  end

  it 'is an error when esa responds so while writing'
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

    edit esa:1234
    sleep 1m
    $ put =['WOO']

    Expect &l:modified to_be_true
    Expect b:metarw_esa_wip == v:true

    call Set('s:curl', {-> json_encode({
    \   'error': 'not_found',
    \   'message': 'Not found',
    \ })})

    silent! write!

    Expect v:errmsg ==# 'Failed to write: esa.io: Not found: esa:1234:poem/This is a test'
    " This is set to a truthy value if writing steps did not stop by an error.
    Expect &l:modified to_be_true
    " This is set to v:false if writing steps did not stop by an error.
    Expect b:metarw_esa_wip == v:true
  end

  it 'enables to create a new esa post via esa:new:{title}'
    put =['BACK', 'TO', 'THE', 'NIGHT']
    1 delete _

    Expect bufname('%') ==# ''
    Expect getline(1, '$') ==# ['BACK', 'TO', 'THE', 'NIGHT']
    Expect &l:filetype ==# ''
    Expect &l:modified to_be_true
    Expect exists('b:metarw_esa_post_number') to_be_false
    Expect exists('b:metarw_esa_wip') to_be_false

    function! Mock(args)
      let b:write_args = a:args
      return json_encode({
      \   'number': 888,
      \   'full_name': 'dev/log/FOO bar BAZ',
      \ })
    endfunction
    call Set('s:curl', {args -> Mock(args)})

    write `='esa:new:dev/log/FOO bar BAZ'`

    Expect bufname('%') ==# 'esa:888:dev/log/FOO bar BAZ'
    Expect getline(1, '$') ==# ['BACK', 'TO', 'THE', 'NIGHT']
    Expect &l:filetype ==# 'markdown'
    Expect &l:modified to_be_false
    Expect b:metarw_esa_post_number == 888
    Expect b:metarw_esa_wip == v:true
    Expect b:write_args ==# [
    \   '--silent',
    \   '--request',
    \   'POST',
    \   '--header',
    \   'Authorization: Bearer xyzzy',
    \   '--header',
    \   'Content-Type: application/json',
    \   '--data',
    \   json_encode({'post': {
    \     'name': 'FOO bar BAZ',
    \     'category': 'dev/log',
    \     'body_md': "BACK\nTO\nTHE\nNIGHT",
    \     'wip': v:true,
    \   }}),
    \   'https://api.esa.io/v1/teams/myteam/posts',
    \ ]
  end

  it 'is an error to read esa:new:{title}'
    call Set('s:curl_async', {-> 'nope'})

    Expect bufname('%') ==# ''
    Expect getline(1, '$') ==# ['']
    Expect &l:filetype == ''
    Expect exists('b:metarw_esa_post_number') to_be_false
    Expect exists('b:metarw_esa_wip') to_be_false

    silent! edit esa:new:Hi

    Expect v:errmsg ==# 'Invalid path: esa:new:Hi'
    Expect bufname('%') ==# 'esa:new:Hi'
    Expect getline(1, '$') ==# ['']
    Expect &l:filetype == ''
    Expect exists('b:metarw_esa_post_number') to_be_false
    Expect exists('b:metarw_esa_wip') to_be_false
  end
end
