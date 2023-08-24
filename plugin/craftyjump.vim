vim9script
scriptencoding utf-8
if exists('g:loaded_craftyjump') | finish | endif
const g:loaded_craftyjump = 1

import autoload '../autoload/craftyjump.vim'

# NOTE: <SID> is required to run tests that work in the legacy context

# word-motions
nnoremap <Plug>(craftyjump-word-w)  <ScriptCmd><SID>craftyjump.Word('w')<CR>
nnoremap <Plug>(craftyjump-word-b)  <ScriptCmd><SID>craftyjump.Word('b')<CR>
nnoremap <Plug>(craftyjump-word-e)  <ScriptCmd><SID>craftyjump.Word('e')<CR>
nnoremap <Plug>(craftyjump-word-ge) <ScriptCmd><SID>craftyjump.Word('ge')<CR>
xnoremap <Plug>(craftyjump-word-w)  <ScriptCmd><SID>craftyjump.Word('w')<CR>
xnoremap <Plug>(craftyjump-word-b)  <ScriptCmd><SID>craftyjump.Word('b')<CR>
xnoremap <Plug>(craftyjump-word-e)  <ScriptCmd><SID>craftyjump.Word('e')<CR>
xnoremap <Plug>(craftyjump-word-ge) <ScriptCmd><SID>craftyjump.Word('ge')<CR>
onoremap <Plug>(craftyjump-word-w)  <ScriptCmd><SID>craftyjump.Word('w')<CR>
onoremap <Plug>(craftyjump-word-b)  <ScriptCmd><SID>craftyjump.Word('b')<CR>
onoremap <Plug>(craftyjump-word-e)  <ScriptCmd><SID>craftyjump.Word('e')<CR>
onoremap <Plug>(craftyjump-word-ge) <ScriptCmd><SID>craftyjump.Word('ge')<CR>
inoremap <Plug>(craftyjump-word-w)  <ScriptCmd><SID>craftyjump.Word('w')<CR>
inoremap <Plug>(craftyjump-word-b)  <ScriptCmd><SID>craftyjump.Word('b')<CR>
inoremap <Plug>(craftyjump-word-e)  <ScriptCmd><SID>craftyjump.Word('e')<CR>
inoremap <Plug>(craftyjump-word-ge) <ScriptCmd><SID>craftyjump.Word('ge')<CR>

# wiw-motions
nnoremap <Plug>(craftyjump-wiw-w)  <ScriptCmd><SID>craftyjump.WordInWord('w')<CR>
nnoremap <Plug>(craftyjump-wiw-b)  <ScriptCmd><SID>craftyjump.WordInWord('b')<CR>
nnoremap <Plug>(craftyjump-wiw-e)  <ScriptCmd><SID>craftyjump.WordInWord('e')<CR>
nnoremap <Plug>(craftyjump-wiw-ge) <ScriptCmd><SID>craftyjump.WordInWord('ge')<CR>
xnoremap <Plug>(craftyjump-wiw-w)  <ScriptCmd><SID>craftyjump.WordInWord('w')<CR>
xnoremap <Plug>(craftyjump-wiw-b)  <ScriptCmd><SID>craftyjump.WordInWord('b')<CR>
xnoremap <Plug>(craftyjump-wiw-e)  <ScriptCmd><SID>craftyjump.WordInWord('e')<CR>
xnoremap <Plug>(craftyjump-wiw-ge) <ScriptCmd><SID>craftyjump.WordInWord('ge')<CR>
onoremap <Plug>(craftyjump-wiw-w)  <ScriptCmd><SID>craftyjump.WordInWord('w')<CR>
onoremap <Plug>(craftyjump-wiw-b)  <ScriptCmd><SID>craftyjump.WordInWord('b')<CR>
onoremap <Plug>(craftyjump-wiw-e)  <ScriptCmd><SID>craftyjump.WordInWord('e')<CR>
onoremap <Plug>(craftyjump-wiw-ge) <ScriptCmd><SID>craftyjump.WordInWord('ge')<CR>
inoremap <Plug>(craftyjump-wiw-w)  <ScriptCmd><SID>craftyjump.WordInWord('w')<CR>
inoremap <Plug>(craftyjump-wiw-b)  <ScriptCmd><SID>craftyjump.WordInWord('b')<CR>
inoremap <Plug>(craftyjump-wiw-e)  <ScriptCmd><SID>craftyjump.WordInWord('e')<CR>
inoremap <Plug>(craftyjump-wiw-ge) <ScriptCmd><SID>craftyjump.WordInWord('ge')<CR>

# left-right-motions
nnoremap <Plug>(craftyjump-home) <ScriptCmd><SID>craftyjump.LeftRight("\<home>")<CR>
nnoremap <Plug>(craftyjump-end)  <ScriptCmd><SID>craftyjump.LeftRight("\<end>")<CR>
xnoremap <Plug>(craftyjump-home) <ScriptCmd><SID>craftyjump.LeftRight("\<home>")<CR>
xnoremap <Plug>(craftyjump-end)  <ScriptCmd><SID>craftyjump.LeftRight("\<end>")<CR>
onoremap <Plug>(craftyjump-home) <ScriptCmd><SID>craftyjump.LeftRight("\<home>")<CR>
onoremap <Plug>(craftyjump-end)  <ScriptCmd><SID>craftyjump.LeftRight("\<end>")<CR>
inoremap <Plug>(craftyjump-home) <ScriptCmd><SID>craftyjump.LeftRight("\<home>")<CR>
inoremap <Plug>(craftyjump-end)  <ScriptCmd><SID>craftyjump.LeftRight("\<end>")<CR>
