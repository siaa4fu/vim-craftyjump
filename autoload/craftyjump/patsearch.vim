vim9script
scriptencoding utf-8

import autoload '../craftyjump.vim'

# initialize plugkeys
const plugkey = '<Plug>(craftyjump-patsearch)'
execute 'nnoremap' plugkey '<Nop>'
execute 'nnoremap' plugkey .. 'a <Nop>'
execute 'nnoremap' plugkey .. 'i <Nop>'
execute 'nnoremap' plugkey .. '<CR> <ScriptCmd>v:hlsearch = v:hlsearch ? 0 : 1<CR>'

final patsets = {}
export def DefinePatternSet(name: string, keys: list<string>, patset: list<string>)
  # @param {string} name - a unique name for a pattern set
  # @param {list<string>} keys - select the pattern set by typing one of the items in the list
  # @param {list<string>} patset - a set of regexp patterns to search for
  #   @param {string} [0] - if [1] is omitted, simply search for matches of [0]
  #   @param {string=} [1] - or, search for matches of pairs that start with [0] and end with [1]
  try
    if has_key(patsets, name)
      throw 'A pattern set is already defined: ' .. name
    endif
    for key in keys
      # turn <> notations into special characters
      const chars = substitute(key, '<[^<>]\+>', (m) => eval('"\' .. m[0] .. '"'), 'g')
      if chars =~# "[\<Esc>\<C-c>]"
        throw '<Esc> and <C-c> cannot be used to select pattern sets.'
      endif
      var lhs: string
      for char in split(chars, '\zs')
        lhs ..= char
        if ! empty(maparg(plugkey .. lhs, 'n'))
          # the mapping that searches for another set is already defined
          throw 'The key that selects a pattern set must be unique: ' .. key
        endif
      endfor
      # define mappings if no error occurs
      patsets[name] = patset
      execute 'nnoremap' plugkey .. lhs '<ScriptCmd>Patsearch(' .. string(name) .. ')<CR>'
      if len(patset) > 1
        execute 'nnoremap' plugkey .. 'a' .. lhs '<ScriptCmd>Patsearch(' .. string(name) .. ', ''a'')<CR>'
        execute 'nnoremap' plugkey .. 'i' .. lhs '<ScriptCmd>Patsearch(' .. string(name) .. ', ''i'')<CR>'
      endif
    endfor
  catch
    echoerr substitute(v:exception, '^Vim\%((\a\+)\)\=:', '', '')
  endtry
enddef
def Patsearch(name: string, asBlock = '')
  # @param {string} name - the name of a pattern set to search for
  # @param {string=} asBlock
  #   ''  - separately search for matches of the start and end of the pattern set
  #   'a' - search for matches of 'a' block surrounded by pattern set like text-objects
  #   'i' - search for matches of an 'inner' block surrounded by pattern set like text-objects
  const cnt = v:count
  const patset = patsets[name]
  var pat: string
  if asBlock ==# ''
    pat = '\V\%(' .. join(patset, '\|') .. '\)\+'
  elseif asBlock ==# 'a'
    pat = '\V' .. patset[0] .. '\%(\%(' .. patset[1] .. '\)\@!\.\)\*' .. patset[1]
  elseif asBlock ==# 'i'
    pat = '\V' .. patset[0] .. '\zs\%(\%(' .. patset[1] .. '\)\@!\.\)\*\ze' .. patset[1]
  endif
  craftyjump.SearchPattern(true, pat, cnt)
enddef
