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

  it 'is an error to read esa:new:{title}'
    call Set('s:curl', {-> 'nope'})

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

  it 'enables to list recent esa posts'
    " Open the list

    function! Mock(args)
      let b:list_args = a:args
      return json_encode({
      \   'posts': [
      \     {
      \       'number': 123,
      \       'full_name': 'poem/BOOM BOOM GIRL',
      \       'wip': v:true,
      \       'updated_at': '2018-04-09T19:45:00+09:00',
      \       'updated_by': {'screen_name': 'SUZY LAZY'},
      \     },
      \     {
      \       'number': 456,
      \       'full_name': 'poem/BOOM BOOM FIRE',
      \       'wip': v:false,
      \       'updated_at': '2018-04-09T19:42:57+09:00',
      \       'updated_by': {'screen_name': 'D.ESSEX'},
      \     },
      \     {
      \       'number': 789,
      \       'full_name': 'poem/BOOM BOOM DJ',
      \       'wip': v:true,
      \       'updated_at': '2018-04-09T19:40:59+09:00',
      \       'updated_by': {'screen_name': 'MIRKA'},
      \     },
      \   ],
      \   'prev_page': v:null,
      \   'next_page': 2,
      \   'total_count': 30,
      \   'page': 1,
      \   'per_page': 20,
      \   'max_per_page': 100,
      \ })
    endfunction
    call Set('s:curl', {args -> Mock(args)})

    edit esa:recent

    Expect bufname('%') ==# 'esa:recent'
    Expect getline(1, '$') ==# [
    \   'metarw content browser',
    \   'esa:recent',
    \   '',
    \   'poem/BOOM BOOM GIRL',
    \   'poem/BOOM BOOM FIRE',
    \   'poem/BOOM BOOM DJ',
    \   '(next page)',
    \ ]
    Expect &l:filetype ==# 'metarw'
    Expect exists('b:metarw_esa_post_number') to_be_false
    Expect exists('b:metarw_esa_wip') to_be_false
    Expect b:list_args ==# [
    \   '--silent',
    \   '--header',
    \   'Authorization: Bearer xyzzy',
    \   'https://api.esa.io/v1/teams/myteam/posts?page=1',
    \ ]

    " Open an post in the list

    function! Mock(args)
      let b:read_args = a:args
      return json_encode({
      \   'full_name': 'poem/BOOM BOOM FIRE',
      \   'body_md': "Big\ndesire!",
      \   'wip': v:false,
      \ })
    endfunction
    call Set('s:curl', {args -> Mock(args)})

    $-2
    execute 'normal' "\<Return>"

    Expect bufname('%') ==# 'esa:456:poem/BOOM BOOM FIRE'
    Expect getline(1, '$') ==# [
    \   'Big',
    \   'desire!',
    \ ]
    Expect &l:filetype ==# 'markdown'
    Expect b:metarw_esa_post_number == 456
    Expect b:metarw_esa_wip == v:false
    Expect b:read_args ==# [
    \   '--silent',
    \   '--header',
    \   'Authorization: Bearer xyzzy',
    \   'https://api.esa.io/v1/teams/myteam/posts/456',
    \ ]
  end

  it 'shows prev page if it exist'
    " Open page 2

    function! Mock(args)
      let b:list_args = a:args
      return json_encode({
      \   'posts': [
      \     {
      \       'number': 123,
      \       'full_name': 'poem/BOOM BOOM GIRL',
      \       'wip': v:true,
      \       'updated_at': '2018-04-09T19:45:00+09:00',
      \       'updated_by': {'screen_name': 'SUZY LAZY'},
      \     },
      \     {
      \       'number': 456,
      \       'full_name': 'poem/BOOM BOOM FIRE',
      \       'wip': v:false,
      \       'updated_at': '2018-04-09T19:42:57+09:00',
      \       'updated_by': {'screen_name': 'D.ESSEX'},
      \     },
      \     {
      \       'number': 789,
      \       'full_name': 'poem/BOOM BOOM DJ',
      \       'wip': v:true,
      \       'updated_at': '2018-04-09T19:40:59+09:00',
      \       'updated_by': {'screen_name': 'MIRKA'},
      \     },
      \   ],
      \   'prev_page': 1,
      \   'next_page': 3,
      \   'total_count': 30,
      \   'page': 2,
      \   'per_page': 20,
      \   'max_per_page': 100,
      \ })
    endfunction
    call Set('s:curl', {args -> Mock(args)})

    edit esa:recent:2

    Expect bufname('%') ==# 'esa:recent:2'
    Expect getline(1, '$') ==# [
    \   'metarw content browser',
    \   'esa:recent:2',
    \   '',
    \   '(prev page)',
    \   'poem/BOOM BOOM GIRL',
    \   'poem/BOOM BOOM FIRE',
    \   'poem/BOOM BOOM DJ',
    \   '(next page)',
    \ ]
    Expect &l:filetype ==# 'metarw'
    Expect exists('b:metarw_esa_post_number') to_be_false
    Expect exists('b:metarw_esa_wip') to_be_false
    Expect b:list_args ==# [
    \   '--silent',
    \   '--header',
    \   'Authorization: Bearer xyzzy',
    \   'https://api.esa.io/v1/teams/myteam/posts?page=2',
    \ ]

    " Open prev page

    function! Mock(args)
      let b:list_args = a:args
      return json_encode({
      \   'posts': [
      \     {
      \       'number': 987,
      \       'full_name': 'poem/BOOM BOOM BODY TALK',
      \       'wip': v:true,
      \       'updated_at': '2018-04-09T20:36:28+09:00',
      \       'updated_by': {'screen_name': 'JOHNY BOMB!'},
      \     },
      \   ],
      \   'prev_page': v:null,
      \   'next_page': 2,
      \   'total_count': 30,
      \   'page': 1,
      \   'per_page': 20,
      \   'max_per_page': 100,
      \ })
    endfunction
    call Set('s:curl', {args -> Mock(args)})

    4
    execute 'normal' "\<Return>"

    Expect bufname('%') ==# 'esa:recent'
    Expect getline(1, '$') ==# [
    \   'metarw content browser',
    \   'esa:recent',
    \   '',
    \   'poem/BOOM BOOM BODY TALK',
    \   '(next page)',
    \ ]
    Expect &l:filetype ==# 'metarw'
    Expect exists('b:metarw_esa_post_number') to_be_false
    Expect exists('b:metarw_esa_wip') to_be_false
    Expect b:list_args ==# [
    \   '--silent',
    \   '--header',
    \   'Authorization: Bearer xyzzy',
    \   'https://api.esa.io/v1/teams/myteam/posts?page=1',
    \ ]
  end

  it 'shows next page if it exist'
    " Open page 1

    function! Mock(args)
      let b:list_args = a:args
      return json_encode({
      \   'posts': [
      \     {
      \       'number': 123,
      \       'full_name': 'poem/BOOM BOOM GIRL',
      \       'wip': v:true,
      \       'updated_at': '2018-04-09T19:45:00+09:00',
      \       'updated_by': {'screen_name': 'SUZY LAZY'},
      \     },
      \     {
      \       'number': 456,
      \       'full_name': 'poem/BOOM BOOM FIRE',
      \       'wip': v:false,
      \       'updated_at': '2018-04-09T19:42:57+09:00',
      \       'updated_by': {'screen_name': 'D.ESSEX'},
      \     },
      \     {
      \       'number': 789,
      \       'full_name': 'poem/BOOM BOOM DJ',
      \       'wip': v:true,
      \       'updated_at': '2018-04-09T19:40:59+09:00',
      \       'updated_by': {'screen_name': 'MIRKA'},
      \     },
      \   ],
      \   'prev_page': v:null,
      \   'next_page': 2,
      \   'total_count': 30,
      \   'page': 1,
      \   'per_page': 20,
      \   'max_per_page': 100,
      \ })
    endfunction
    call Set('s:curl', {args -> Mock(args)})

    edit esa:recent

    Expect bufname('%') ==# 'esa:recent'
    Expect getline(1, '$') ==# [
    \   'metarw content browser',
    \   'esa:recent',
    \   '',
    \   'poem/BOOM BOOM GIRL',
    \   'poem/BOOM BOOM FIRE',
    \   'poem/BOOM BOOM DJ',
    \   '(next page)',
    \ ]
    Expect &l:filetype ==# 'metarw'
    Expect exists('b:metarw_esa_post_number') to_be_false
    Expect exists('b:metarw_esa_wip') to_be_false
    Expect b:list_args ==# [
    \   '--silent',
    \   '--header',
    \   'Authorization: Bearer xyzzy',
    \   'https://api.esa.io/v1/teams/myteam/posts?page=1',
    \ ]

    " Open next page

    function! Mock(args)
      let b:list_args = a:args
      return json_encode({
      \   'posts': [
      \     {
      \       'number': 654,
      \       'full_name': 'poem/BOOM BOOM PARA PARA',
      \       'wip': v:true,
      \       'updated_at': '2018-04-09T20:40:26+09:00',
      \       'updated_by': {'screen_name': 'LOU GRANT'},
      \     },
      \   ],
      \   'prev_page': 1,
      \   'next_page': v:null,
      \   'total_count': 30,
      \   'page': 2,
      \   'per_page': 20,
      \   'max_per_page': 100,
      \ })
    endfunction
    call Set('s:curl', {args -> Mock(args)})

    $
    execute 'normal' "\<Return>"

    Expect bufname('%') ==# 'esa:recent:2'
    Expect getline(1, '$') ==# [
    \   'metarw content browser',
    \   'esa:recent:2',
    \   '',
    \   '(prev page)',
    \   'poem/BOOM BOOM PARA PARA',
    \ ]
    Expect &l:filetype ==# 'metarw'
    Expect exists('b:metarw_esa_post_number') to_be_false
    Expect exists('b:metarw_esa_wip') to_be_false
    Expect b:list_args ==# [
    \   '--silent',
    \   '--header',
    \   'Authorization: Bearer xyzzy',
    \   'https://api.esa.io/v1/teams/myteam/posts?page=2',
    \ ]
  end

  it 'is an error to use esa:recent:{non-page-stuff}'
    call Set('s:curl', {-> 'nope'})

    Expect bufname('%') ==# ''
    Expect getline(1, '$') ==# ['']
    Expect &l:filetype == ''
    Expect exists('b:metarw_esa_post_number') to_be_false
    Expect exists('b:metarw_esa_wip') to_be_false

    silent! edit esa:recent:xxxx

    Expect v:errmsg ==# 'Invalid path: esa:recent:xxxx'
    Expect bufname('%') ==# 'esa:recent:xxxx'
    Expect getline(1, '$') ==# ['']
    Expect &l:filetype == ''
    Expect exists('b:metarw_esa_post_number') to_be_false
    Expect exists('b:metarw_esa_wip') to_be_false
  end

  it 'is an error to write to esa:recent'
    call Set('s:curl', {-> 'nope'})

    Expect bufname('%') ==# ''
    Expect getline(1, '$') ==# ['']
    Expect &l:filetype == ''
    Expect exists('b:metarw_esa_post_number') to_be_false
    Expect exists('b:metarw_esa_wip') to_be_false

    silent! write esa:recent

    Expect v:errmsg ==# 'Invalid path: esa:recent'
    Expect bufname('%') ==# 'esa:recent'
    Expect getline(1, '$') ==# ['']
    Expect &l:filetype == ''
    Expect exists('b:metarw_esa_post_number') to_be_false
    Expect exists('b:metarw_esa_wip') to_be_false
  end

  it 'stops as soon as possible if an error occurs while listing esa posts'
    call Set('s:curl', {-> execute('echoerr "XYZZY"')})

    Expect bufname('%') ==# ''
    Expect getline(1, '$') ==# ['']
    Expect &l:filetype == ''
    Expect exists('b:metarw_esa_post_number') to_be_false
    Expect exists('b:metarw_esa_wip') to_be_false

    silent! edit esa:recent

    Expect v:errmsg == 'XYZZY: esa:recent'
    Expect bufname('%') ==# 'esa:recent'
    Expect getline(1, '$') ==# ['']
    Expect exists('b:metarw_esa_wip') to_be_false
    Expect &l:filetype == ''
    Expect exists('b:metarw_esa_post_number') to_be_false
    Expect exists('b:metarw_esa_wip') to_be_false
  end


  " TODO: Add tests on error response from esa API.
end
