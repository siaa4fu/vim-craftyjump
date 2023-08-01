vim9script
scriptencoding utf-8

# `substring` `vim9-string-index`
# in vim9script, substrings are sliced using character indices and include coposing characters
# (therefore, both single-byte and multi-byte characters are supported)
# e.g., '12345'[1:3] is '234' (indices is inclusive)

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
  # @param {'w' | 'b' | 'e' | 'ge' | '^' | 'g_'} motion
  # @return {bool} - whether the motion has been executed
  var isMoved: bool
  if motion ==# 'w' || motion ==# 'b' || motion ==# 'e' || motion ==# 'ge'
      || motion ==# '^' || motion ==# 'g_'
    execute 'normal!' motion
    isMoved = v:true
  else
    echoerr 'Unsupported motion:' motion
  endif
  return isMoved
enddef # }}}
def IsCharUnderCursor(regexp: string, pos: list<number>, line = getline(pos[1])): bool # {{{
  # @param {string} regexp - regexp to check if the character under the cursor matches
  # @param {list<number>} pos - the cursor position returned by getcursorcharpos()
  # @param {string=} line - the line of the cursor position
  # @return {bool} - whether the character under the cursor is a keyword character
  return line[pos[2] - 1] =~# regexp
enddef # }}}
def IsAtLineEnd(pos: list<number>, line = getline(pos[1]), isExSelEnd = IsExclusiveSelEnd(pos)): bool # {{{
  # @param {list<number>} pos - the cursor position returned by getcursorcharpos()
  # @param {string=} line - the line of the cursor position
  # @param {bool=} isExSelEnd - whether the cursor is the end of the exclusive selection
  # @return {bool} - whether the cursor is at the end of the line
  # return true if the characters to the right of the cursor are whitespaces only
  return line[pos[2] - (isExSelEnd ? 1 : 0) :] =~# '^\s*$'
enddef # }}}
def IsAtLineStart(pos: list<number>, line = getline(pos[1]), ..._): bool # {{{
  # @param {list<number>} pos - the cursor position returned by getcursorcharpos()
  # @param {string=} line - the line of the cursor position
  # @return {bool} - whether the cursor is at the start of the line
  # return true if the characters to the left of the cursor are whitespaces only
  return (pos[2] == 1 ? '' : line[0 : pos[2] - 2]) =~# '^\s*$'
enddef # }}}
def IsExclusiveSelEnd(pos: list<number>): bool # {{{
  # @param {list<number>} pos - the cursor position returned by getcursorcharpos()
  # @return {bool} - whether the cursor is the end of the exclusive selection
  if &selection !=# 'exclusive' | return v:false | endif
  const mode = mode()
  if mode ==# 'v'
    # return true if the cursor is the end of the selection, not the start
    const vpos = getcharpos('v')
    return vpos[1] == pos[1] && vpos[2] < pos[2] || vpos[1] < pos[1]
  elseif mode ==# 'V'
    # always return true (always treat the cursor as the end)
    return v:true
  elseif mode ==# "\<C-v>"
    # return true if the cursor column is greater than the column of the opposite position
    const vpos = getcharpos('v')
    return vpos[2] < pos[2]
  endif
  return v:false
enddef # }}}
def MoveToKwdChar(motion: string): bool # {{{
  # @param {'w' | 'b' | 'e' | 'ge'} motion
  # @return {bool} - whether the cursor has moved to a keyword character
  const isForward = IsForwardMotion(motion)
  const bufferEdge = isForward ? [line('$'), charcol('$')] : [1, 1]
  const IsAtLineEdge = isForward ? IsAtLineEnd : IsAtLineStart
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
      if IsAtLineEdge(prev.pos, prev.line, prev.isExSelEnd)
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
    if IsCharUnderCursor('\k', pos, line) || IsAtLineEdge(pos, line, isExSelEnd)
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
      const oldpos = getcursorcharpos()
      for i in range(cnt)
        isMoved = MoveToKwdChar(motion)
        if ! isMoved | break | endif
      endfor
      # treat 'cw' like 'ce' if the cursor has moved from a non-blank character (`WORD`)
      if isMoved && v:operator ==# 'c' && motion ==# 'w' && IsCharUnderCursor('\S', oldpos)
        # if the character before the cursor ends with a whitespace, move backward to a non-blank character
        const pos = getcursorcharpos()
        if pos[2] > 1
          # get characters that the cursor has passed through while moving, but only on the cursor line
          const passedChars = getline(pos[1])[(oldpos[1] == pos[1] ? oldpos[2] - 1 : 0) : pos[2] - 2]
          const leftoffset = strcharlen(matchstr(passedChars, '\s\+\%(\S\&[^[:keyword:]]\)*$'))
          if leftoffset > 0 | execute 'normal!' leftoffset .. 'h' | endif
        endif
      endif
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
