vim9script
scriptencoding utf-8

# `substring` `vim9-string-index`
# in vim9script, substrings are sliced using character indices and include coposing characters
# (therefore, both single-byte and multi-byte characters are supported)
# e.g., '12345'[1:3] is '234' (indices is inclusive)

def IsCharUnderCursor(regexp: string, pos: list<number>, line = getline(pos[1])): bool # {{{
  # @param {string} regexp - regexp to check if the character under the cursor matches
  # @param {list<number>} pos - the cursor position returned by getcursorcharpos()
  # @param {string=} line - the line of the cursor position
  # @return {bool} - whether the character under the cursor is a keyword character
  return line[pos[2] - 1] =~# regexp
enddef # }}}
def IsExclusiveSelEnd(pos: list<number>): bool # {{{
  # @param {list<number>} pos - the cursor position returned by getcursorcharpos()
  # @return {bool} - whether the cursor is the end of the exclusive selection
  if &selection ==# 'exclusive' && mode() =~# "[vV\<C-v>]"
    # return true if the cursor is the end of the selection, not the start
    const vpos = getcharpos('v')
    return vpos[1] == pos[1] && vpos[2] < pos[2] || vpos[1] < pos[1]
  endif
  return v:false
enddef # }}}

def IsForwardMotion(motion: string): bool # {{{
  # @param {'w' | 'b' | 'e' | 'ge'} motion
  # @return {bool} - return true if the motion is forward, or false if backward
  var isForward: bool
  if motion ==# 'w' || motion ==# 'e'
    isForward = v:true
  elseif motion ==# 'b' || motion ==# 'ge'
    isForward = v:false
  else
    echoerr 'Unsupported motion:' motion
  endif
  return isForward
enddef # }}}
def DoSingleMotion(motion: string): bool # {{{
  # @param {'w' | 'b' | 'e' | 'ge' | '^' | 'g_' | '0' | 'hg0' | '$' | 'lg$' } motion
  # @return {bool} - whether the motion has been executed
  var isMoved: bool
  if motion ==# 'w' || motion ==# 'b' || motion ==# 'e' || motion ==# 'ge'
      || motion ==# '^' || motion ==# 'g_'
      || motion ==# '0' || motion ==# 'hg0' || motion ==# '$' || motion ==# 'lg$'
    execute 'normal!' motion
    isMoved = v:true
  else
    echoerr 'Unsupported motion:' motion
  endif
  return isMoved
enddef # }}}
def DoSpecialMotion(motion: string, prevpos: list<number>) # {{{
  # @param {string} motion
  # @param {list<number>} prevpos - the cursor position before moving returned by getcursorcharpos()
  # treat 'cw' like 'ce' if the cursor has moved from a non-blank character (`WORD`)
  if v:operator ==# 'c' && motion ==# 'w' && IsCharUnderCursor('\S', prevpos)
    # if the character before the cursor ends with a whitespace, move backward to a non-blank character
    const pos = getcursorcharpos()
    if pos[2] > 1
      # get characters that the cursor has passed through while moving, but only on the cursor line
      const passedChars = getline(pos[1])[(prevpos[1] == pos[1] ? prevpos[2] - 1 : 0) : pos[2] - 2]
      const offsetToLeft = strcharlen(matchstr(passedChars, '\s\+\%(\S\&[^[:keyword:]]\)*$'))
      if offsetToLeft > 0 | execute 'normal!' offsetToLeft .. 'h' | endif
    endif
  endif
enddef # }}}

def IsAfterLineEnd(pos: list<number>, line = getline(pos[1]), isExSelEnd = IsExclusiveSelEnd(pos)): bool # {{{
  # @param {list<number>} pos - the cursor position returned by getcursorcharpos()
  # @param {string=} line - the line of the cursor position
  # @param {bool=} isExSelEnd - whether the cursor is the end of the exclusive selection
  # @return {bool} - whether the cursor is on or after the end of the line
  # return true if the characters to the right of the cursor are whitespaces only
  return line[pos[2] - (isExSelEnd ? 1 : 0) :] =~# '^\s*$'
enddef # }}}
def IsBeforeLineStart(pos: list<number>, line = getline(pos[1]), ..._): bool # {{{
  # @param {list<number>} pos - the cursor position returned by getcursorcharpos()
  # @param {string=} line - the line of the cursor position
  # @return {bool} - whether the cursor is on or before the start of the line
  # return true if the characters to the left of the cursor are whitespaces only
  return (pos[2] == 1 ? '' : line[0 : pos[2] - 2]) =~# '^\s*$'
enddef # }}}
def MoveToKwdChar(motion: string): bool # {{{
  # @param {'w' | 'b' | 'e' | 'ge'} motion
  # @return {bool} - whether the cursor has moved to a keyword character
  const isForward = IsForwardMotion(motion)
  const bufferEdge = isForward ? [line('$'), charcol('$')] : [1, 1]
  const IsOutsideLineEdge = isForward ? IsAfterLineEnd : IsBeforeLineStart
  var isMoved: bool
  final prev = {}
  prev.pos = getcursorcharpos() # [0, lnum, charcol, off, curswant]
  prev.line = getline(prev.pos[1])
  prev.isExSelEnd = IsExclusiveSelEnd(prev.pos)
  while v:true
    isMoved = DoSingleMotion(motion)
    final pos = getcursorcharpos()
    if prev.pos == pos
      # abort if the cursor could not move
      isMoved = v:false
      break
    endif
    const line = getline(pos[1])
    const isExSelEnd = IsExclusiveSelEnd(pos)
    if prev.pos[1] != pos[1] || pos[1 : 2] == bufferEdge
      if IsOutsideLineEdge(prev.pos, prev.line, prev.isExSelEnd)
        # when the cursor moves from the edge of the line to another line
        if line =~# '^\s*$'
          # skip blank lines
          prev.pos = pos
          prev.line = line
          prev.isExSelEnd = isExSelEnd
          continue
        endif
      else
        # move the cursor to the edge of the line
        setcharpos('.', prev.pos)
        isMoved = DoSingleMotion(isForward ? 'g_' : '^')
        break
      endif
    endif
    # the motion 'e' shifts one to the right at the end of the exclusive selection, so fix to the original position
    if motion ==# 'e' && isExSelEnd | pos[2] -= 1 | endif
    # when the cursor moved within the same line or from the edge of the line
    if IsCharUnderCursor('\k', pos, line) || IsOutsideLineEdge(pos, line, isExSelEnd)
      # stop moving if the character under the cursor was a keyword character
      # or the cursor moved to a non-keyword character at the edge of the line
      break
    endif
    prev.pos = pos
    prev.line = line
    prev.isExSelEnd = isExSelEnd
  endwhile
  return isMoved
enddef # }}}
export def Word(motion: string)
  # @param {'w' | 'b' | 'e' | 'ge'} motion
  const cnt = v:count1
  const mode = mode(v:true)
  if mode =~# '^no'
    # set the operator to be linewise, characterwise or blockwise (`forced-motion`)
    execute 'normal!' (mode[2] ?? 'v')
    # temporarily override &selection, then restore it after the operator is done
    const sel = &selection
    try
      if motion ==# 'w' || motion ==# 'b'
        &selection = 'exclusive'
      elseif motion ==# 'e' || motion ==# 'ge'
        &selection = 'inclusive'
      endif
      var isMoved: bool
      const prevpos = getcursorcharpos()
      for i in range(cnt)
        isMoved = MoveToKwdChar(motion)
        if ! isMoved | break | endif
      endfor
      if isMoved | DoSpecialMotion(motion, prevpos) | endif
    finally
      timer_start(100, (_) => {
        &selection = sel
      })
    endtry
  else
    # move the cursor in any mode except operator-pending mode
    for i in range(cnt)
      const isMoved = MoveToKwdChar(motion)
      if ! isMoved | break | endif
    endfor
  endif
enddef

def MoveToCharInWord(motion: string): bool # {{{
  # @param {'w' | 'b' | 'e' | 'ge'} motion
  # @return {bool} - whether the cursor has moved to a word in a word (wiw)
  const isForward = IsForwardMotion(motion)
  var pat: string
  if motion ==# 'w' || motion ==# 'b'
    # wiw-head
    #   the start of a word
    #   uppercase before or after lowercase
    #   alphabet after non-alphabet
    pat = '\<.\|\u\l\|\l\zs\u\|\A\zs\a'
  elseif motion ==# 'e' || motion ==# 'ge'
    # wiw-tail
    #   the end of a word
    #   lowercase before uppercase
    #   uppercase before uppercase and lowercase
    #   alphabet before non-alphabet
    pat = '.\>\|\l\u\|\u\u\l\|\a\A'
  else
    echoerr 'Unsupported motion:' motion
  endif
  const isMoved = search(pat, isForward ? 'W' : 'bW') > 0
  if isMoved
    const pos = getcursorcharpos()
    const isExSelEnd = IsExclusiveSelEnd(pos)
    # shift the motion 'e' one to the right at the end of the exclusive selection, like the word-motion 'e'
    if motion ==# 'e' && isExSelEnd | execute 'normal! l' | endif
  endif
  return isMoved
enddef # }}}
export def WordInWord(motion: string)
  # @param {'w' | 'b' | 'e' | 'ge'} motion
  const cnt = v:count1
  const mode = mode(v:true)
  if mode =~# '^no'
    # set the operator to be linewise, characterwise or blockwise (`forced-motion`)
    execute 'normal!' (mode[2] ?? 'v')
    # temporarily override &selection, then restore it after the operator is done
    const sel = &selection
    try
      if motion ==# 'w' || motion ==# 'b'
        &selection = 'exclusive'
      elseif motion ==# 'e' || motion ==# 'ge'
        &selection = 'inclusive'
      endif
      var isMoved: bool
      const prevpos = getcursorcharpos()
      for i in range(cnt)
        isMoved = MoveToCharInWord(motion)
        if ! isMoved | break | endif
      endfor
      if isMoved | DoSpecialMotion(motion, prevpos) | endif
    finally
      timer_start(100, (_) => {
        &selection = sel
      })
    endtry
  else
    # move the cursor in any mode except operator-pending mode
    for i in range(cnt)
      const isMoved = MoveToCharInWord(motion)
      if ! isMoved | break | endif
    endfor
  endif
enddef

def MoveToFirstChar(): bool # {{{
  # @return {bool} - whether the cursor has moved to first characters
  var isMoved: bool
  final cols = {}
  cols.cursor = charcol('.')
  cols.start = 1
  cols.firstNonBlank = cols.start + strcharlen(matchstr(getline('.'), '^\s*'))
  if &wrap
    # the cursor moves sequentially to 'g0' positions, which are first or leftmost characters of the current screen line,
    # then cycles through the '^' and '0' positions
    if cols.firstNonBlank < cols.cursor
      isMoved = DoSingleMotion('hg0')
      if charcol('.') <= cols.firstNonBlank
        isMoved = DoSingleMotion('^')
      endif
    elseif cols.start < cols.cursor
      isMoved = DoSingleMotion('hg0')
      if charcol('.') <= cols.start
        isMoved = DoSingleMotion('0')
      endif
    else
      isMoved = DoSingleMotion('^')
    endif
  else
    # the cursor cycles through the '^' and '0' positions
    if cols.firstNonBlank < cols.cursor
      isMoved = DoSingleMotion('^')
    elseif cols.start < cols.cursor
      isMoved = DoSingleMotion('0')
    else
      isMoved = DoSingleMotion('^')
    endif
  endif
  return isMoved
enddef # }}}
def MoveToLastChar(): bool # {{{
  # @return {bool} - whether the cursor has moved to last characters
  var isMoved: bool
  final cols = {}
  cols.cursor = charcol('.')
  cols.end = charcol('$') - 1
  cols.lastNonBlank = cols.end - strcharlen(matchstr(getline('.'), '\s*$'))
  if &wrap
    # the cursor moves sequentially to 'g$' positions, which are last or rightmost characters of the current screen line,
    # then cycles through the 'g_' and '$' positions
    if cols.cursor < cols.lastNonBlank
      isMoved = DoSingleMotion('lg$')
      if cols.lastNonBlank <= charcol('.')
        isMoved = DoSingleMotion('g_')
      endif
    elseif cols.cursor < cols.end
      isMoved = DoSingleMotion('lg$')
      if cols.end <= charcol('.')
        isMoved = DoSingleMotion('$')
      endif
    else
      isMoved = DoSingleMotion('g_')
    endif
  else
    # the cursor cycles through the 'g_' and '$' positions
    if cols.cursor < cols.lastNonBlank
      isMoved = DoSingleMotion('g_')
    elseif cols.cursor < cols.end
      isMoved = DoSingleMotion('$')
    else
      isMoved = DoSingleMotion('g_')
    endif
  endif
  return isMoved
enddef # }}}
export def Home()
  const cnt = v:count1
  const mode = mode(v:true)
  if mode =~# '^no'
    # set the operator to be linewise, characterwise or blockwise (`forced-motion`)
    execute 'normal!' (mode[2] ?? 'v')
    # temporarily override &selection, then restore it after the operator is done
    const sel = &selection
    try
      &selection = 'exclusive'
      var isMoved: bool
      for i in range(cnt)
        isMoved = MoveToFirstChar()
        if ! isMoved | break | endif
      endfor
    finally
      timer_start(100, (_) => {
        &selection = sel
      })
    endtry
  else
    # move the cursor in any mode except operator-pending mode
    for i in range(cnt)
      const isMoved = MoveToFirstChar()
      if ! isMoved | break | endif
    endfor
  endif
enddef
export def End()
  const cnt = v:count1
  const mode = mode(v:true)
  if mode =~# '^no'
    # set the operator to be linewise, characterwise or blockwise (`forced-motion`)
    execute 'normal!' (mode[2] ?? 'v')
    # temporarily override &selection, then restore it after the operator is done
    const sel = &selection
    try
      &selection = 'inclusive'
      var isMoved: bool
      # const prevpos = getcursorcharpos()
      for i in range(cnt)
        isMoved = MoveToLastChar()
        if ! isMoved | break | endif
      endfor
      # if isMoved | DoSpecialMotion(motion, prevpos) | endif
    finally
      timer_start(100, (_) => {
        &selection = sel
      })
    endtry
  else
    # move the cursor in any mode except operator-pending mode
    for i in range(cnt)
      const isMoved = MoveToLastChar()
      if ! isMoved | break | endif
    endfor
  endif
enddef
