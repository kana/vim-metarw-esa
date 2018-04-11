source t/support/startup.vim

describe 'metarw-esa'
  before
    let g:metarw_esa_default_team_name = 'myteam'
  end

  after
    ResetContext
    %bdelete!
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

  it 'is an error when esa responds so while listing'
    call Set('s:curl', {-> json_encode({
    \   'error': 'not_found',
    \   'message': 'Not found',
    \ })})

    Expect bufname('%') ==# ''
    Expect getline(1, '$') ==# ['']
    Expect &l:filetype == ''
    Expect exists('b:metarw_esa_post_number') to_be_false
    Expect exists('b:metarw_esa_wip') to_be_false

    silent! edit esa:recent

    Expect v:errmsg == 'esa.io: Not found: esa:recent'
    Expect bufname('%') ==# 'esa:recent'
    Expect getline(1, '$') ==# ['']
    Expect exists('b:metarw_esa_wip') to_be_false
    Expect &l:filetype == ''
    Expect exists('b:metarw_esa_post_number') to_be_false
    Expect exists('b:metarw_esa_wip') to_be_false
  end
end
