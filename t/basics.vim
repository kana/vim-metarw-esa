source t/support/startup.vim

describe 'metarw-esa'
  before
    unlet! g:metarw_esa_default_team_name
  end

  after
    ResetContext
    %bdelete!
  end

  it 'enables to read an esa post via esa:{team}:{post}'
    call Set('s:curl', {-> json_encode({
    \   'full_name': 'poem/This is a test',
    \   'body_md': "DIN\nDON\nDAN",
    \   'wip': v:true,
    \ })})

    Expect bufname('%') ==# ''
    Expect getline(1, '$') ==# ['']
    Expect exists('b:metarw_esa_wip') to_be_false

    edit esa:test:1234

    Expect bufname('%') ==# 'esa:test:1234:poem/This is a test'
    Expect getline(1, '$') ==# ['DIN', 'DON', 'DAN']
    Expect b:metarw_esa_wip == v:true
  end

  it 'enables to read esa:{post} if configured'
    call Set('s:curl', {-> json_encode({
    \   'full_name': 'poem/This is a test 2.0',
    \   'body_md': "BIM\nBUM\nBAM",
    \   'wip': v:false,
    \ })})
    let g:metarw_esa_default_team_name = 'eurobeat'

    Expect bufname('%') ==# ''
    Expect getline(1, '$') ==# ['']
    Expect exists('b:metarw_esa_wip') to_be_false

    edit esa:1234

    Expect bufname('%') ==# 'esa:1234:poem/This is a test 2.0'
    Expect getline(1, '$') ==# ['BIM', 'BUM', 'BAM']
    Expect b:metarw_esa_wip == v:false
  end

  it 'is an error to open esa:{post} without configuration'
    call Set('s:curl', {-> 'nope'})

    Expect bufname('%') ==# ''
    Expect getline(1, '$') ==# ['']
    Expect exists('b:metarw_esa_wip') to_be_false

    silent! edit esa:1234

    Expect v:errmsg ==# 'Invalid path: esa:1234'
    Expect bufname('%') ==# 'esa:1234'
    Expect getline(1, '$') ==# ['']
    Expect exists('b:metarw_esa_wip') to_be_false
  end
end
