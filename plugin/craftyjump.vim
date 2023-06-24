scriptencoding utf-8
if exists('g:loaded_craftyjump') | finish | endif
let g:loaded_craftyjump = 1

" word-motions
nnoremap <Plug>(craftyjump-word-w)  <Cmd>call craftyjump#Word('w')<CR>
nnoremap <Plug>(craftyjump-word-b)  <Cmd>call craftyjump#Word('b')<CR>
nnoremap <Plug>(craftyjump-word-e)  <Cmd>call craftyjump#Word('e')<CR>
nnoremap <Plug>(craftyjump-word-ge) <Cmd>call craftyjump#Word('ge')<CR>
xnoremap <Plug>(craftyjump-word-w)  <Cmd>call craftyjump#Word('w')<CR>
xnoremap <Plug>(craftyjump-word-b)  <Cmd>call craftyjump#Word('b')<CR>
xnoremap <Plug>(craftyjump-word-e)  <Cmd>call craftyjump#Word('e')<CR>
xnoremap <Plug>(craftyjump-word-ge) <Cmd>call craftyjump#Word('ge')<CR>
onoremap <Plug>(craftyjump-word-w)  <Cmd>call craftyjump#Word('w')<CR>
onoremap <Plug>(craftyjump-word-b)  <Cmd>call craftyjump#Word('b')<CR>
onoremap <Plug>(craftyjump-word-e)  <Cmd>call craftyjump#Word('e')<CR>
onoremap <Plug>(craftyjump-word-ge) <Cmd>call craftyjump#Word('ge')<CR>
inoremap <Plug>(craftyjump-word-w)  <Cmd>call craftyjump#Word('w')<CR>
inoremap <Plug>(craftyjump-word-b)  <Cmd>call craftyjump#Word('b')<CR>
inoremap <Plug>(craftyjump-word-e)  <Cmd>call craftyjump#Word('e')<CR>
inoremap <Plug>(craftyjump-word-ge) <Cmd>call craftyjump#Word('ge')<CR>
