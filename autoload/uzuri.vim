function! uzuri#fzf_run(labels, options, window) abort
	call fzf#run(fzf#wrap({
        \ 'source': a:labels,
        \ 'sink': funcref('uzuri#fzf_choice'),
        \ 'options': a:options,
        \ 'window': a:window,
        \}))
endfunction

function! uzuri#fzf_choice(label) abort
	call v:lua.uzuri_fzf_choice(a:label)
endfunction
