" documents has a word list for each buffer.
" key is bufnr and value is a word list.
let s:documents = {}

function! asyncomplete#sources#buffer#completor(info, ctx)
  let l:bufnr = a:ctx['bufnr']
  if !has_key(s:documents, l:bufnr)
    " here is a workaround.
    " on_event triggered by BufEnter when openning a file does not work for now.
    call s:refresh_keywords(a:info, l:bufnr)
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
  return extend({
    \ 'priority': 10,
    \ 'events': ['BufEnter', 'BufWritePost'],
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
  let l:pos = 0
  let l:min_word_len = s:get_config_val(a:info, 'min_word_len', 3)
  while l:pos != -1
    let [l:word, l:_, l:pos] = s:matchstrpos(l:text, '\k\+', l:pos)
    if len(l:word) < l:min_word_len
      continue
    endif
    let s:documents[a:bufnr][l:word] = 1
  endwhile
  call asyncomplete#log('asyncomplete#sources#buffer', 's:refresh_keywords() complete', a:bufnr)
endfunction

function! s:get_config_val(info, key, defaultVal) abort
  if has_key(a:info, 'config') && has_key(a:info['config'], a:key)
    return a:info['config'][a:key]
  endif
  return a:defaultVal
endfunction

function! s:matchstrpos(expr, pattern, start) abort
  if exists('*matchstrpos')
    return matchstrpos(a:expr, a:pattern, a:start)
  else
    return [matchstr(a:expr, a:pattern, a:start), match(a:expr, a:pattern, a:start), matchend(a:expr, a:pattern, a:start)]
  endif
endfunction

