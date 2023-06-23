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
def IsKwdChar(pos: list<number>): bool # {{{
  # @param {list<number>} pos - the cursor position returned by getcursorcharpos()
  # @return {bool} - whether the character under the cursor is a keyword character
  return getline(pos[1])[pos[2] - 1] =~# '\k'
enddef # }}}
def IsAtLineEnd(pos: list<number>): bool # {{{
  # @param {list<number>} pos - the cursor position returned by getcursorcharpos()
  # @return {bool} - whether the cursor is at the end of the line
  # return true if the characters to the right of the cursor are whitespaces only
  return getline(pos[1])[pos[2] :] =~# '^\s*$'
enddef # }}}
def IsAtLineStart(pos: list<number>): bool # {{{
  # @param {list<number>} pos - the cursor position returned by getcursorcharpos()
  # @return {bool} - whether the cursor is at the start of the line
  # return true if the characters to the left of the cursor are whitespaces only
  return (pos[2] == 1 ? '' : getline(pos[1])[0 : pos[2] - 2]) =~# '^\s*$'
enddef # }}}
def MoveToKwdChar(motion: string): bool # {{{
  # @param {'w' | 'b' | 'e' | 'ge'} motion
  # @return {bool} - whether the cursor has moved to a keyword character
  const isForward = IsForwardMotion(motion)
  var isMoved: bool
  var oldpos = getcursorcharpos() # [0, lnum, charcol, off, curswant]
  while 1
    execute 'normal!' motion
    const newpos = getcursorcharpos()
    if oldpos == newpos
      # abort if the cursor could not move
      isMoved = v:false
      break
    elseif oldpos[1] != newpos[1]
      if isForward ? IsAtLineEnd(oldpos) : IsAtLineStart(oldpos)
        # when the cursor moves from the edge of the line to another line
        if getline(newpos[1]) =~# '^\s*$'
          # skip blank lines
          oldpos = newpos
          continue
        endif
      else
        # move the cursor to the edge of the line
        setcharpos('.', oldpos)
        execute 'normal!' (isForward ? 'g_' : '^')
        isMoved = v:true
        break
      endif
    endif
    # when the cursor moved within the same line or from the edge of the line
    if IsKwdChar(newpos)
        || (isForward ? IsAtLineEnd(newpos) : IsAtLineStart(newpos))
      # stop moving if the character under the cursor was a keyword character
      # or if the cursor moved to the edge of the line
      isMoved = v:true
      break
    endif
    oldpos = newpos
  endwhile
  return isMoved
enddef # }}}

export def Word(motion: string)
  # @param {'w' | 'b' | 'e' | 'ge'} motion
  const cnt = v:count1
  for i in range(cnt)
    const isMoved = MoveToKwdChar(motion)
    if ! isMoved | break | endif
  endfor
enddef
