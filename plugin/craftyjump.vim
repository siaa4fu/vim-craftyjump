scriptencoding utf-8
if exists('g:loaded_craftyjump') | finish | endif
let g:loaded_craftyjump = 1

" word-motions
nnoremap <Plug>(craftyjump-word-w)  <Cmd>call craftyjump#Word('w')<CR>
nnoremap <Plug>(craftyjump-word-b)  <Cmd>call craftyjump#Word('b')<CR>
nnoremap <Plug>(craftyjump-word-e)  <Cmd>call craftyjump#Word('e')<CR>
nnoremap <Plug>(craftyjump-word-ge) <Cmd>call craftyjump#Word('ge')<CR>
