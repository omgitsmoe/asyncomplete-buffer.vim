let s:words = {}
let s:last_word = ''
let g:asyncomplete_buffer_clear_cache = get(g:, 'asyncomplete_buffer_clear_cache', 1)
let g:asyncomplete_buffer_identify_words_regex = get(g:, 'asyncomplete_buffer_identify_words_regex', '\w\+')

function! asyncomplete#sources#buffer#completor(opt, ctx)
    let l:typed = a:ctx['typed']

    call s:refresh_keyword_incremental(l:typed)

    if empty(s:words)
        return
    endif

    let l:matches = []

    let l:col = a:ctx['col']

    let l:kw = matchstr(l:typed, g:asyncomplete_buffer_identify_words_regex.'$')
    let l:kwlen = len(l:kw)

    let l:matches = map(keys(s:words),'{"word":v:val,"dup":1,"icase":1,"menu": "[buffer]"}')
    let l:startcol = l:col - l:kwlen

    call asyncomplete#complete(a:opt['name'], a:ctx, l:startcol, l:matches)
endfunction

function! asyncomplete#sources#buffer#get_source_options(opts)
    return extend({
        \ 'events': ['VimEnter', 'BufWinEnter'],
        \ 'on_event': function('s:on_event'),
        \}, a:opts)
endfunction

function! s:should_ignore(opt) abort
    let l:max_buffer_size = 5000000 " 5mb
    if has_key(a:opt, 'config') && has_key(a:opt['config'], 'max_buffer_size')
        let l:max_buffer_size = a:opt['config']['max_buffer_size']
    endif
    if l:max_buffer_size != -1
        let l:buffer_size = line2byte(line('$') + 1)
        if l:buffer_size > l:max_buffer_size
            call asyncomplete#log('asyncomplete#sources#buffer', 'ignoring buffer autocomplete due to large size', expand('%:p'), l:buffer_size)
            return 1
        endif
    endif

    return 0
endfunction

let s:last_ctx = {}
function! s:on_event(opt, ctx, event) abort
    if s:should_ignore(a:opt) | return | endif
    call s:refresh_keywords()
endfunction

function! s:refresh_keywords() abort
    if g:asyncomplete_buffer_clear_cache
        let s:words = {}
    endif
    let l:text = join(getline(1, '$'), "\n")
    for l:word in map(split(l:text, g:asyncomplete_buffer_identify_words_regex.'\zs'),'matchstr(v:val,g:asyncomplete_buffer_identify_words_regex)')
        if len(l:word) > 1
            let s:words[l:word] = 1
        endif
    endfor
    call asyncomplete#log('asyncomplete#buffer', 's:refresh_keywords() complete')
endfunction

function! s:refresh_keyword_incremental(typed) abort
    call asyncomplete#log('asyncomplete#sources#buffer', 'typed words ', a:typed)
    let l:words = map(split(a:typed, g:asyncomplete_buffer_identify_words_regex.'\zs'),'matchstr(v:val,g:asyncomplete_buffer_identify_words_regex)')
    call asyncomplete#log('asyncomplete#sources#buffer', 'refreshing words with ', l:words)
    for l:word in l:words
        " if len(l:word) > 1
            let s:words[l:word] = 1
        " endif
    endfor
endfunction
