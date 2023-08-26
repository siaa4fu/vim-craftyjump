vim9script
scriptencoding utf-8

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
  return false
enddef # }}}

def IsForwardMotion(motion: string): bool # {{{
  # @param {'w' | 'b' | 'e' | 'ge' | "\<C-d>" | "\<C-u>" | "\<C-f>" | "\<C-b>"} motion
  # @return {bool} - return true if the motion is forward, or false if backward
  var isForward: bool
  if motion ==# 'w' || motion ==# 'e'
      || motion ==# "\<C-d>" || motion ==# "\<C-f>"
    isForward = true
  elseif motion ==# 'b' || motion ==# 'ge'
      || motion ==# "\<C-u>" || motion ==# "\<C-b>"
    isForward = false
  else
    echoerr 'Unsupported motion:' motion
  endif
  return isForward
enddef # }}}
def IsExclusiveMotion(motion: string): bool # {{{
  # @param {'w' | 'b' | 'e' | 'ge' | "\<home>" | "\<end>"} motion
  # @return {bool} - return true if the motion is exclusive, or false if inclusive
  var isExMotion: bool
  if motion ==# 'w' || motion ==# 'b'
    isExMotion = true
  elseif motion ==# 'e' || motion ==# 'ge'
    isExMotion = false
  elseif motion ==# "\<home>"
    isExMotion = true
  elseif motion ==# "\<end>"
    isExMotion = false
  else
    echoerr 'Unsupported motion:' motion
  endif
  return isExMotion
enddef # }}}
def GoToFoldEdge(isForward: bool, lnum: number): bool # {{{
  # @param {bool} isForward - position the cursor at the end of the closed fold if true, the start if false
  # @param {number} lnum - the number of the cursor line
  # @return {bool} - whether the cursor has been positioned at the edge of the closed fold
  var isMoved: bool
  if isForward
    const lastLnumInFold = foldclosedend(lnum)
    if lastLnumInFold > -1
      isMoved = setcursorcharpos(lastLnumInFold, charcol([lastLnumInFold, '$'])) > -1
    endif
  else
    const firstLnumInFold = foldclosed(lnum)
    if firstLnumInFold > -1
      isMoved = setcursorcharpos(firstLnumInFold, 1) > -1
    endif
  endif
  return isMoved
enddef # }}}
def DoSingleMotion(motion: string): bool # {{{
  # @param {'w' | 'b' | 'e' | 'ge' | '^' | 'g_' | '0' | 'hg0' | '$' | 'lg$' } motion
  # @return {bool} - whether the motion has been executed
  var isMoved: bool
  if motion ==# 'w' || motion ==# 'b' || motion ==# 'e' || motion ==# 'ge'
      || motion ==# '^' || motion ==# 'g_'
      || motion ==# '0' || motion ==# 'hg0' || motion ==# '$' || motion ==# 'lg$'
    execute 'normal!' motion
    isMoved = true
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
def DoMotion(motion: string, Move: func(number): bool, SpecialMove: func(list<number>) = null_function) # {{{
  # @param {string} motion - treat the movement like specified motion
  # @param {func(number): bool} Move
  #   the function that moves the cursor
  #     @param {number} - v:count1
  # @param {func(list<number>)=} SpecialMove
  #   the function that adjusts the cursor position after moving in operator-pending mode
  #     @param {list<number>} - the cursor position before moving returned by getcursorcharpos()
  const cnt = v:count1
  const mode = mode(true)
  if mode =~# '^no'
    # set the operator to be linewise, characterwise or blockwise (`forced-motion`)
    execute 'normal!' (mode[2] ?? 'v')
    # temporarily override &selection, then restore it after the operator is done
    const sel = &selection
    try
      &selection = IsExclusiveMotion(motion) ? 'exclusive' : 'inclusive'
      const posBeforeMoving = getcursorcharpos()
      const isMoved = Move(cnt)
      if isMoved && SpecialMove != null_function
        SpecialMove(posBeforeMoving)
      endif
    finally
      timer_start(100, (_) => {
        &selection = sel
      })
    endtry
  else
    # move the cursor in any mode except operator-pending mode
    const isMoved = Move(cnt)
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
def MoveToKwdChar(motion: string, cnt: number): bool # {{{
  # @param {'w' | 'b' | 'e' | 'ge'} motion
  # @param {number} cnt - v:count1
  # @return {bool} - whether the cursor has moved to a keyword character
  const isForward = IsForwardMotion(motion)
  const bufferEdge = isForward ? [line('$'), charcol('$')] : [1, 1]
  const IsOutsideLineEdge = isForward ? IsAfterLineEnd : IsBeforeLineStart
  var isMoved: bool
  for i in range(cnt)
    final prev = {}
    prev.pos = getcursorcharpos() # [0, lnum, charcol, off, curswant]
    prev.line = getline(prev.pos[1])
    prev.isExSelEnd = IsExclusiveSelEnd(prev.pos)
    while true
      if GoToFoldEdge(isForward, prev.pos[1])
        # go to the edge of a closed fold if the cursor is in the fold before moving
        prev.pos = getcursorcharpos() # [0, lnum, charcol, off, curswant]
        prev.line = getline(prev.pos[1])
        prev.isExSelEnd = IsExclusiveSelEnd(prev.pos)
      elseif motion ==# 'e' && prev.isExSelEnd
        # make the motion 'e' move from the original position if the cursor is at the end of the exclusive selection
        execute 'normal! h'
      endif
      isMoved = DoSingleMotion(motion)
      final pos = getcursorcharpos()
      if prev.pos == pos
        # abort if the cursor could not move
        isMoved = false
        break
      elseif GoToFoldEdge(false, pos[1])
        # always go to the start of a closed fold if the cursor is in the fold after moving
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
      # the motion 'e' always shifts one to the right at the end of the exclusive selection
      # this may cause the next position to be skipped, which feels strange. so fix it
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
    if ! isMoved | break | endif
  endfor
  return isMoved
enddef # }}}
export def Word(motion: string)
  # @param {'w' | 'b' | 'e' | 'ge'} motion
  DoMotion(motion,
    function(MoveToKwdChar, [motion]),
    function(DoSpecialMotion, [motion]))
enddef

def MoveToCharInWord(motion: string, cnt: number): bool # {{{
  # @param {'w' | 'b' | 'e' | 'ge'} motion
  # @param {number} cnt - v:count1
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
  endif
  var isMoved: bool
  for i in range(cnt)
    isMoved = search(pat, isForward ? 'W' : 'bW') > 0
    if isMoved
      const pos = getcursorcharpos()
      const isExSelEnd = IsExclusiveSelEnd(pos)
      # shift the motion 'e' one to the right at the end of the exclusive selection, like the word-motion 'e'
      if motion ==# 'e' && isExSelEnd | execute 'normal! l' | endif
    else
      break
    endif
  endfor
  return isMoved
enddef # }}}
export def WordInWord(motion: string)
  # @param {'w' | 'b' | 'e' | 'ge'} motion
  DoMotion(motion,
    function(MoveToCharInWord, [motion]),
    function(DoSpecialMotion, [motion]))
enddef

def MoveToFirstChar(cnt: number): bool # {{{
  # @param {number} cnt - v:count1
  # @return {bool} - whether the cursor has moved to first characters
  var isMoved: bool
  if cnt > 1
    # move to [count - 1] screen lines upward, then to the last character of the screen line
    # ('g0' does not support [count], but it is considered possible to go lines upward)
    execute 'normal!' (cnt - 1) .. 'gkg$'
  endif
  final cols = {}
  cols.cursor = charcol('.')
  cols.start = 1
  cols.firstNonBlank = cols.start + strcharlen(matchstr(getline('.'), '^\s*'))
  if &wrap || get(g:, 'craftyjump#multistep_homeend', false)
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
def MoveToLastChar(cnt: number): bool # {{{
  # @param {number} cnt - v:count1
  # @return {bool} - whether the cursor has moved to last characters
  var isMoved: bool
  if cnt > 1
    # move to [count - 1] screen lines downward like g$, then to the first character of the screen line
    execute 'normal!' (cnt - 1) .. 'gjg0'
  endif
  final cols = {}
  cols.cursor = charcol('.')
  cols.end = charcol('$') - 1
  cols.lastNonBlank = cols.end - strcharlen(matchstr(getline('.'), '\s*$'))
  if &wrap || get(g:, 'craftyjump#multistep_homeend', false)
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
export def LeftRight(motion: string)
  # @param {"\<home>" | "\<end>"} motion
  var MoveToEdgeChar: func(number): bool
  if motion ==# "\<home>"
    MoveToEdgeChar = MoveToFirstChar
  elseif motion ==# "\<end>"
    MoveToEdgeChar = MoveToLastChar
  endif
  DoMotion(motion, MoveToEdgeChar)
enddef

def SmoothScroll(motion: string, lines: number, _) # {{{
  # @param {"\<C-d>" | "\<C-u>" | "\<C-f>" | "\<C-b>"} motion
  # @param {number} lines - the number of lines to scroll
  const isForward = IsForwardMotion(motion)
  var n: number
  var keys: list<string>
  if isForward
    n = min([lines, line('$') - line('w$')])
    keys = ["\<C-e>", 'gj']
  else
    n = min([lines, line('w0') - 1])
    keys = ["\<C-y>", 'gk']
  endif
  const step = get(g:, 'craftyjump#scroll_step', 3)
  while n > 0
    n -= 1
    # the cursor may move when scrolling window in the following cases
    #   the cursor is at the first line visible in window when scrolling downward
    #   the cursor is at the last line visible in window when scrolling upward
    #   &scrolloff is greater than 0
    const pos = getcursorcharpos() # [0, lnum, charcol, off, curswant]
    execute 'normal!' keys[0]
    if getcursorcharpos() == pos
      # move the cursor if it still stays where it was
      execute 'normal!' keys[1]
    endif
    if n % step == 0
      redraw
    endif
  endwhile
enddef # }}}
var scrolltimerid: number
export def Scroll(motion: string)
  # @param {"\<C-d>" | "\<C-u>" | "\<C-f>" | "\<C-b>"} motion
  var lines: number
  if motion ==# "\<C-d>" || motion ==# "\<C-u>"
    # scroll [count] lines or half a screen as default
    lines = v:count > 0 ? v:count : &scroll
  elseif motion ==# "\<C-f>" || motion ==# "\<C-b>"
    # scroll [count] screens
    lines = v:count1 * winheight(0)
  endif
  # use a timer to activate only last key input on long press
  timer_stop(scrolltimerid) # no error even if a timer ID does not exist
  scrolltimerid = timer_start(10, function(SmoothScroll, [motion, lines]))
enddef
