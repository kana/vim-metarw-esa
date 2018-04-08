filetype plugin indent on

runtime plugin/metarw.vim

call vspec#hint({'scope': 'metarw#esa#_scope()'})
call Set('s:get_esa_access_token', {-> 'xyzzy'})
SaveContext
