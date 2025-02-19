" documents has a word list for each buffer.
" key is bufnr and value is a word list.
let s:documents = {}

function! asyncomplete#sources#buffer#completor(info, ctx)
  let l:bufnr = a:ctx['bufnr']
  if !has_key(s:documents, l:bufnr)
    " here is a workaround.
    " on_event triggered by BufEnter when openning a file does not work for now.
    " NOTE: check here for buffer size as well
    if !s:is_max_buffer_size_exceeded(a:info)
        call s:refresh_keywords(a:info, l:bufnr)
    endif
  endif

  let l:name = a:info['name']
  let l:col = a:ctx['col']
  let l:typed = a:ctx['typed']

  " \k represents iskeyword.
  let l:kw = matchstr(l:typed, '\k\+$')
  let l:kwlen = len(l:kw)
  
  " around: matching word in current buffer
  let l:matches = map(keys(s:documents[l:bufnr]), '{"word":v:val,"dup":1,"icase":1,"menu":"[A]"}')
  for [l:document_bufnr, l:words] in items(s:documents)
    if l:document_bufnr == l:bufnr
      continue
    endif
    " buffer: matching word in another buffer
    let l:matches += map(keys(l:words), '{"word":v:val,"dup":1,"icase":1,"menu":"[B]"}')
  endfor
  let l:startcol = l:col - l:kwlen

  call asyncomplete#complete(l:name, a:ctx, l:startcol, l:matches)
endfunction

function! asyncomplete#sources#buffer#get_source_options(opts)
  " events where the word lists gets updated
  " could add 'TextChangedI' but might cause performance problems and we
  " already have CursorHoldI which updates after cursor paused for
  " 'updatetime' amount
  return extend({
    \ 'priority': 10,
    \ 'events': ['CursorHold', 'CursorHoldI', 'BufWinEnter', 'BufWritePost'],
    \ 'on_event': function('s:on_event'),
    \}, a:opts)
endfunction

function! s:is_max_buffer_size_exceeded(info) abort
  let l:max_buffer_size = s:get_config_val(a:info, 'max_buffer_size', 5000000) " default 5mb

  if l:max_buffer_size != -1
    let l:buffer_size = line2byte(line('$') + 1)
    if l:buffer_size > l:max_buffer_size
      call asyncomplete#log('asyncomplete#sources#buffer', 'ignoring buffer autocomplete due to large size', expand('%:p'), l:buffer_size, l:max_buffer_size)
      return 1
    endif
  endif
  return 0
endfunction

function! s:on_event(info, ctx, event) abort
  if s:is_max_buffer_size_exceeded(a:info)
    return
  endif
  call s:refresh_keywords(a:info, a:ctx['bufnr'])
endfunction

function! s:refresh_keywords(info, bufnr) abort
  if s:get_config_val(a:info, 'clear_cache', 1) || !has_key(s:documents, a:bufnr)
    let s:documents[a:bufnr] = {}
  endif
  
  let l:text = join(getline(1, '$'), "\n")
  let l:min_word_len = s:get_config_val(a:info, 'min_word_len', 3)
  " \_s*\<
  " \< matches the beginning of a word, where 'iskeyword' specifies what a
  " word char is (we use \k to match the typed word so far) which is character
  " class based on 'iskeyword'
  " -> splits "away" whitespace (including \n, \s would not match that) between word chars
  " [^[:keyword:]]\+
  " -> splits on non-keyword chars
  " tags file with length 367418 ~804KB
  " 6391904 '[^[:keyword:]]\+' 0.6454s 0.636s
  " 7034876 '\_s*\<' 7124673 0.73s 0.71s
  " 6465483 '\W\+' 0.625019s 0.635
  " let t = reltime()
  for l:word in split(l:text, '[^[:keyword:]]\+')
    if len(l:word) < l:min_word_len
      continue
    endif

    let s:documents[a:bufnr][l:word] = 1
  endfor

  " echom 'refresh took ' . reltimestr(reltime(t))

  call asyncomplete#log('asyncomplete#sources#buffer', 's:refresh_keywords() complete', a:bufnr)
endfunction

function! s:get_config_val(info, key, defaultVal) abort
  if has_key(a:info, 'config') && has_key(a:info['config'], a:key)
    return a:info['config'][a:key]
  endif
  return a:defaultVal
endfunction
