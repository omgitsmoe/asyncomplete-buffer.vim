Buffer source for asyncomplete.vim
==================================

Provide buffer autocompletion source for [asyncomplete.vim](https://github.com/prabirshrestha/asyncomplete.vim)

### Installing

```vim
Plug 'prabirshrestha/asyncomplete.vim'
Plug 'prabirshrestha/asyncomplete-buffer.vim'
```

#### Registration

```vim
call asyncomplete#register_source(asyncomplete#sources#buffer#get_source_options({
    \ 'name': 'buffer',
    \ 'whitelist': ['*'],
    \ 'blacklist': ['go'],
    \ 'completor': function('asyncomplete#sources#buffer#completor'),
    \ 'config': {
    \    'max_buffer_size': 5000000,
    \    'clear_cache': 1,
    \    'min_word_len': 3,
    \  },
    \ }))
```

Note: config is optional.  
- `max_buffer_size` defaults to 5000000 (5mb). If the buffer size exceeds `max_buffer_size`, completion that buffer is ignored. Set `max_buffer_size` to -1 for unlimited buffer size.
- `clear_cache` defaults to 1. Set `clear_cache` to 0 for disabled cache clear.
- `min_word_len` defaults to 3. Word with `min_word_len` or more letters are subject to completion.

### Credits
All the credit goes to the following projects
* [https://github.com/roxma/nvim-complete-manager](https://github.com/roxma/nvim-complete-manager)
