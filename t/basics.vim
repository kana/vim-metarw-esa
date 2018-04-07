source t/support/startup.vim

describe 'metarw-esa'
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

    edit esa:test:1234

    Expect bufname('%') ==# 'esa:test:1234:poem/This is a test'
    Expect getline(1, '$') ==# ['DIN', 'DON', 'DAN']
  end
end
