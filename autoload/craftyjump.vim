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
  # @return {bool} - return true if the motion is inclusive, or false if exclusive
  var isInclusive: bool
  if motion ==# 'w' || motion ==# 'b' || motion ==# '^'
    isInclusive = v:false
  elseif motion ==# 'e' || motion ==# 'ge' || motion ==# 'g_'
    isInclusive = v:true
  else
    echoerr 'Unsupported motion:' motion
  endif
  # execute a motion command, then return whether it is inclusive or exclusive
  execute 'normal!' motion
  return isInclusive
enddef # }}}
def IsCharUnderCursor(regexp: string, pos: list<number>, line = getline(pos[1])): bool # {{{
  # @param {string} regexp - regexp to check if the character under the cursor matches
  # @param {list<number>} pos - the cursor position returned by getcursorcharpos()
  # @param {string=} line - the line of the cursor position
  # @return {bool} - whether the character under the cursor is a keyword character
  return line[pos[2] - 1] =~# regexp
enddef # }}}
def IsAtLineEnd(pos: list<number>, line = getline(pos[1])): bool # {{{
  # @param {list<number>} pos - the cursor position returned by getcursorcharpos()
  # @param {string=} line - the line of the cursor position
  # @return {bool} - whether the cursor is at the end of the line
  # return true if the characters to the right of the cursor are whitespaces only
  return line[pos[2] :] =~# '^\s*$'
enddef # }}}
def IsAtLineStart(pos: list<number>, line = getline(pos[1])): bool # {{{
  # @param {list<number>} pos - the cursor position returned by getcursorcharpos()
  # @param {string=} line - the line of the cursor position
  # @return {bool} - whether the cursor is at the start of the line
  # return true if the characters to the left of the cursor are whitespaces only
  return (pos[2] == 1 ? '' : line[0 : pos[2] - 2]) =~# '^\s*$'
enddef # }}}
def MoveToKwdChar(motion: string, isExclusiveSelection: bool): bool # {{{
  # @param {'w' | 'b' | 'e' | 'ge'} motion
  # @param {bool} isExclusiveSelection - in the visual-mode, whether the selection is exclusive
  #                                      if true, move the cursor to the correct position
  # @return {bool} - whether the cursor has moved to a keyword character
  const isForward = IsForwardMotion(motion)
  const IsAtLineEdge = isForward ? IsAtLineEnd : IsAtLineStart
  var isMoved: bool
  var usedInclusiveMotion: bool
  const sel = &selection
  try
    # temporarily set &selection and always move inclusively
    # (because &selection may move motions to different positions, e.g. 'e')
    &selection = 'inclusive'
    var oldpos = getcursorcharpos() # [0, lnum, charcol, off, curswant]
    var oldline = getline(oldpos[1])
    while v:true
      usedInclusiveMotion = DoSingleMotion(motion)
      const pos = getcursorcharpos()
      if oldpos == pos
        # abort if the cursor could not move
        isMoved = v:false
        break
      endif
      const line = getline(pos[1])
      if oldpos[1] != pos[1]
        if IsAtLineEdge(oldpos, oldline)
          # when the cursor moves from the edge of the line to another line
          if line =~# '^\s*$'
            # skip blank lines
            oldpos = pos
            oldline = line
            continue
          endif
        else
          # move the cursor to the edge of the line
          setcharpos('.', oldpos)
          usedInclusiveMotion = DoSingleMotion(isForward ? 'g_' : '^')
          isMoved = v:true
          break
        endif
      endif
      # when the cursor moved within the same line or from the edge of the line
      if IsCharUnderCursor('\k', pos, line)
        # stop moving if the character under the cursor was a keyword character
        isMoved = v:true
        break
      elseif IsAtLineEdge(pos, line)
        # stop moving if the cursor moved to a non-keyword character at the edge of the line
        # (force the motion to be inclusive to include the last character of the motion)
        isMoved = v:true
        usedInclusiveMotion = v:true
        break
      endif
      oldpos = pos
      oldline = line
    endwhile
  finally
    &selection = sel
    if isForward && isExclusiveSelection && usedInclusiveMotion
      # in the visual-mode, move the cursor to the correct position
      # if the last character of the selection is excluded in an operation and the inclusive motion was last-used
      normal! l
    endif
  endtry
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
      const isExclusive = &selection ==# 'exclusive'
      const oldpos = getcursorcharpos()
      for i in range(cnt)
        isMoved = MoveToKwdChar(motion, isExclusive)
        if ! isMoved | break | endif
      endfor
      # treat 'cw' like 'ce' if the cursor has moved from a non-blank character (`WORD`)
      if isMoved && v:operator ==# 'c' && motion ==# 'w' && IsCharUnderCursor('\S', oldpos)
        const pos = getcursorcharpos()
        if pos[2] > 1
          # if the character before the cursor ends with a whitespace, move backward to a non-blank character
          const movedThroughChars = getline(pos[1])[(oldpos[1] == pos[1] ? oldpos[2] - 1 : 0) : pos[2] - 2]
          const leftoffset = strcharlen(matchstr(movedThroughChars, '\s\+[^[:keyword:]]*$'))
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
    const isExclusive = mode =~# "[vV\<C-v>]" && &selection ==# 'exclusive'
    for i in range(cnt)
      const isMoved = MoveToKwdChar(motion, isExclusive)
      if ! isMoved | break | endif
    endfor
  endif
enddef
