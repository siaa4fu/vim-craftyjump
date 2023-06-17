vim9script
scriptencoding utf-8

def MoveToKeywordChar(motion: string): bool # {{{
  # @param {string} motion
  # @return {bool} - whether the cursor has moved to a keyword character
  var isMoved: bool
  var oldpos = getcursorcharpos() # [0, lnum, charcol, off, curswant]
  while 1
    execute 'normal!' motion
    const newpos = getcursorcharpos()
    if oldpos == newpos
      # abort if the cursor could not be moved
      isMoved = v:false
      break
    elseif strcharpart(getline(newpos[1]), newpos[2] - 1, 1, v:true) =~# '\k'
      # stop moving if the character under the cursor was a keyword character
      # (by getting the character using character index, both single-byte and multi-byte characters are supported)
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
    const isMoved = MoveToKeywordChar(motion)
    if ! isMoved | break | endif
  endfor
enddef
