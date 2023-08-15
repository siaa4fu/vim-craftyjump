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

" wiw-motions
nnoremap <Plug>(craftyjump-wiw-w)  <Cmd>call craftyjump#WordInWord('w')<CR>
nnoremap <Plug>(craftyjump-wiw-b)  <Cmd>call craftyjump#WordInWord('b')<CR>
nnoremap <Plug>(craftyjump-wiw-e)  <Cmd>call craftyjump#WordInWord('e')<CR>
nnoremap <Plug>(craftyjump-wiw-ge) <Cmd>call craftyjump#WordInWord('ge')<CR>
xnoremap <Plug>(craftyjump-wiw-w)  <Cmd>call craftyjump#WordInWord('w')<CR>
xnoremap <Plug>(craftyjump-wiw-b)  <Cmd>call craftyjump#WordInWord('b')<CR>
xnoremap <Plug>(craftyjump-wiw-e)  <Cmd>call craftyjump#WordInWord('e')<CR>
xnoremap <Plug>(craftyjump-wiw-ge) <Cmd>call craftyjump#WordInWord('ge')<CR>
onoremap <Plug>(craftyjump-wiw-w)  <Cmd>call craftyjump#WordInWord('w')<CR>
onoremap <Plug>(craftyjump-wiw-b)  <Cmd>call craftyjump#WordInWord('b')<CR>
onoremap <Plug>(craftyjump-wiw-e)  <Cmd>call craftyjump#WordInWord('e')<CR>
onoremap <Plug>(craftyjump-wiw-ge) <Cmd>call craftyjump#WordInWord('ge')<CR>
inoremap <Plug>(craftyjump-wiw-w)  <Cmd>call craftyjump#WordInWord('w')<CR>
inoremap <Plug>(craftyjump-wiw-b)  <Cmd>call craftyjump#WordInWord('b')<CR>
inoremap <Plug>(craftyjump-wiw-e)  <Cmd>call craftyjump#WordInWord('e')<CR>
inoremap <Plug>(craftyjump-wiw-ge) <Cmd>call craftyjump#WordInWord('ge')<CR>

" left-right-motions
nnoremap <Plug>(craftyjump-home) <Cmd>call craftyjump#LeftRight('home')<CR>
nnoremap <Plug>(craftyjump-end)  <Cmd>call craftyjump#LeftRight('end')<CR>
xnoremap <Plug>(craftyjump-home) <Cmd>call craftyjump#LeftRight('home')<CR>
xnoremap <Plug>(craftyjump-end)  <Cmd>call craftyjump#LeftRight('end')<CR>
onoremap <Plug>(craftyjump-home) <Cmd>call craftyjump#LeftRight('home')<CR>
onoremap <Plug>(craftyjump-end)  <Cmd>call craftyjump#LeftRight('end')<CR>
inoremap <Plug>(craftyjump-home) <Cmd>call craftyjump#LeftRight('home')<CR>
inoremap <Plug>(craftyjump-end)  <Cmd>call craftyjump#LeftRight('end')<CR>
