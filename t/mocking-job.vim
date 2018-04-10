describe 'job_start'
  it 'can be mocked like this'
    function! JobStart(command, callback)
      let job = job_start(a:command, {
      \   'mode': 'raw',
      \   'close_cb': {channel -> a:callback(Stringify(channel))},
      \ })
    endfunction

    function! Stringify(channel)
      let chunks = []
      while ch_status(a:channel, {'part': 'out'}) == 'buffered'
        call add(chunks, ch_read(a:channel))
      endwhile
      return join(chunks, '')
    endfunction

    function! Do(data)
      call append(line('$'), a:data)
    endfunction

    " Mock
    function! JobStart(command, callback)
      let timer = timer_start(2000, {-> a:callback(a:command)})
    endfunction

    call JobStart('/bin/bash -c "echo 1; sleep 1; echo 2; sleep 1; echo 3; sleep 1; echo 4;"', function('Do'))

    Expect getline(1, '$') ==# ['']

    sleep 2

    Expect getline(1, '$') ==# ['x']
  end
end
