vim9script
scriptencoding utf-8

def IsCharUnderCursor(regexp: string, pos: list<number>, line = getline(pos[1])): bool # {{{
  # @param {string} regexp - regexp to check if the character under the cursor matches
  # @param {list<number>} pos - the cursor position returned by getcursorcharpos()
  # @param {string=} line - the line of the cursor position
  # @return {bool} - whether the character under the cursor is a keyword character
  return line[pos[2] - 1] =~# regexp
enddef # }}}
def GetWordUnderCursor(): string # {{{
  # @return {string} - <cword> or the selection in visual mode
  var cword: string
  if mode() !~# "[vV\<C-v>]"
    cword = expand('<cword>')
  else
    const RestoreReg_unnamed = function('setreg', ['', getreginfo('')])
    const RestoreReg_v = function('setreg', ['v', getreginfo('v')])
    try
      # visual mode is stopped
      normal! "vy
      cword = @v
    finally
      RestoreReg_unnamed()
      RestoreReg_v()
    endtry
  endif
  return cword
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
  # @param {'w' | 'b' | 'e' | 'ge' | "\<C-d>" | "\<C-u>" | "\<C-f>" | "\<C-b>" | 'n' | 'N' | '*' | '#' | 'g*' | 'g#' | '[n' | ']n' | '[N' | ']N'} motion
  # @return {bool} - return true if the motion is forward, or false if backward
  var isForward: bool
  if motion ==# 'w' || motion ==# 'e'
    isForward = true
  elseif motion ==# 'b' || motion ==# 'ge'
    isForward = false
  elseif motion ==# "\<C-d>" || motion ==# "\<C-f>"
    isForward = true
  elseif motion ==# "\<C-u>" || motion ==# "\<C-b>"
    isForward = false
  elseif motion ==# 'n' || motion ==# 'N'
    isForward = motion ==# (v:searchforward ? 'n' : 'N')
  elseif motion ==# '*' || motion ==# 'g*'
    isForward = true
  elseif motion ==# '#' || motion ==# 'g#'
    isForward = false
  elseif motion ==# '[n' || motion ==# '[N'
    isForward = false
  elseif motion ==# ']n' || motion ==# ']N'
    isForward = true
  else
    echoerr 'Unsupported motion:' motion
  endif
  return isForward
enddef # }}}
def IsExclusiveMotion(motion: string): bool # {{{
  # @param {'w' | 'b' | 'e' | 'ge' | "\<home>" | "\<end>" | 'n' | 'N' | '*' | '#' | 'g*' | 'g#' | '[n' | ']n' | '[N' | ']N'} motion
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
  elseif motion ==# 'n' || motion ==# 'N'
      || motion ==# '*' || motion ==# '#' || motion ==# 'g*' || motion ==# 'g#'
      || motion ==# '[n' || motion ==# ']n' || motion ==# '[N' || motion ==# ']N'
    isExMotion = true
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
def DoNormal(...cmds: list<any>): bool # {{{
  # @param {list<number | string>} cmds - the list of [count] and normal mode commands allowed to execute
  #   [count]: a number greater than 0
  #   left-right-motions: 'h' | 'l' | '0' | '^' | '$' | 'g_' | 'g0' | 'g$'
  #   up-down-motions: 'gk' | 'gj'
  #   word-motions: 'w' | 'b' | 'e' | 'ge'
  #   scrolling: '<C-e>' | '<C-y>' | 'zz'
  #   search-commands: 'n' | 'N'
  # @return {bool} - whether commands have been executed
  var isMoved: bool
  # check whether all commands in the list are allowed to be executed, and then simply join them into one string
  var cmdstr: string
  for cmd in cmds
    if type(cmd) == v:t_number
        || cmd ==# 'h' || cmd ==# 'l' || cmd ==# '0' || cmd ==# '^' || cmd ==# '$' || cmd ==# 'g_' || cmd ==# 'g0' || cmd ==# 'g$'
        || cmd ==# 'gk' || cmd ==# 'gj'
        || cmd ==# 'w' || cmd ==# 'b' || cmd ==# 'e' || cmd ==# 'ge'
        || cmd ==# "\<C-e>" || cmd ==# "\<C-y>" || cmd ==# 'zz'
        || cmd ==# 'n' || cmd ==# 'N'
      cmdstr ..= cmd
    else
      echoerr 'Unsupported command:' cmd
      return isMoved
    endif
  endfor
  try
    # execute all commands at once without changing the jumplist
    execute 'keepjumps normal!' cmdstr
    isMoved = true
  catch /^Vim\%((\a\+)\)\=:E/
    # catch all vim errors such as 'Pattern not found' (echo as a message)
    echohl ErrorMsg | echomsg substitute(v:exception, '^Vim\%((\a\+)\)\=:', '', '') | echohl None
  endtry
  return isMoved
enddef # }}}
def SetJump(pos: list<number>) # {{{
  # @param {list<number>} pos - the position to be added to the jumplist
  # add the position to the jumplist by temporarily going to that position
  # (calling setcharpos("''", {pos}) sets the ' mark, but does not change the jumplist)
  const view = winsaveview()
  setcharpos('.', pos) | execute 'normal! m'''
  winrestview(view)
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
      if offsetToLeft > 0 | DoNormal(offsetToLeft, 'h') | endif
    endif
  endif
enddef # }}}
def DoMotion(motion: string, Move: func(number): bool, SpecialMove: func(list<number>) = null_function) # {{{
  # @param {string} motion - treat the movement like specified motion
  # @param {func(number): bool} Move
  #   the function that moves the cursor
  #     @param {number} - v:count
  # @param {func(list<number>)=} SpecialMove
  #   the function that adjusts the cursor position after moving in operator-pending mode
  #     @param {list<number>} - the cursor position before moving returned by getcursorcharpos()
  const cnt = v:count
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
  # @param {number} cnt - v:count
  # @return {bool} - whether the cursor has moved to a keyword character
  const isForward = IsForwardMotion(motion)
  const bufferEdge = isForward ? [line('$'), charcol('$')] : [1, 1]
  const IsOutsideLineEdge = isForward ? IsAfterLineEnd : IsBeforeLineStart
  var isMoved: bool
  for i in range(cnt ?? 1)
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
        isMoved = DoNormal('h')
      endif
      isMoved = DoNormal(motion)
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
          isMoved = DoNormal(isForward ? 'g_' : '^')
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
  # @param {number} cnt - v:count
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
  for i in range(cnt ?? 1)
    isMoved = search(pat, isForward ? 'W' : 'bW') > 0
    if isMoved
      const pos = getcursorcharpos()
      const isExSelEnd = IsExclusiveSelEnd(pos)
      # shift the motion 'e' one to the right at the end of the exclusive selection, like the word-motion 'e'
      if motion ==# 'e' && isExSelEnd
        isMoved = DoNormal('l')
      endif
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
  # @param {number} cnt - v:count
  # @return {bool} - whether the cursor has moved to first characters
  var isMoved: bool
  if cnt > 1
    # move to [count - 1] screen lines upward, then to the last character of the screen line
    # ('g0' does not support [count], but it is considered possible to go lines upward)
    isMoved = DoNormal(cnt - 1, 'gk', 'g$')
  endif
  final cols = {}
  cols.cursor = charcol('.')
  cols.start = 1
  cols.firstNonBlank = cols.start + strcharlen(matchstr(getline('.'), '^\s*'))
  if &wrap || get(g:, 'craftyjump#multistep_homeend', false)
    # the cursor moves sequentially to 'g0' positions, which are first or leftmost characters of the current screen line,
    # then cycles through the '^' and '0' positions
    if cols.firstNonBlank < cols.cursor
      isMoved = DoNormal('h', 'g0')
      if charcol('.') <= cols.firstNonBlank
        isMoved = DoNormal('^')
      endif
    elseif cols.start < cols.cursor
      isMoved = DoNormal('h', 'g0')
      if charcol('.') <= cols.start
        isMoved = DoNormal('0')
      endif
    else
      isMoved = DoNormal('^')
    endif
  else
    # the cursor cycles through the '^' and '0' positions
    if cols.firstNonBlank < cols.cursor
      isMoved = DoNormal('^')
    elseif cols.start < cols.cursor
      isMoved = DoNormal('0')
    else
      isMoved = DoNormal('^')
    endif
  endif
  return isMoved
enddef # }}}
def MoveToLastChar(cnt: number): bool # {{{
  # @param {number} cnt - v:count
  # @return {bool} - whether the cursor has moved to last characters
  var isMoved: bool
  if cnt > 1
    # move to [count - 1] screen lines downward like g$, then to the first character of the screen line
    isMoved = DoNormal(cnt - 1, 'gj', 'g0')
  endif
  final cols = {}
  cols.cursor = charcol('.')
  cols.end = charcol('$') - 1
  cols.lastNonBlank = cols.end - strcharlen(matchstr(getline('.'), '\s*$'))
  if &wrap || get(g:, 'craftyjump#multistep_homeend', false)
    # the cursor moves sequentially to 'g$' positions, which are last or rightmost characters of the current screen line,
    # then cycles through the 'g_' and '$' positions
    if cols.cursor < cols.lastNonBlank
      isMoved = DoNormal('l', 'g$')
      if cols.lastNonBlank <= charcol('.')
        isMoved = DoNormal('g_')
      endif
    elseif cols.cursor < cols.end
      isMoved = DoNormal('l', 'g$')
      if cols.end <= charcol('.')
        isMoved = DoNormal('$')
      endif
    else
      isMoved = DoNormal('g_')
    endif
  else
    # the cursor cycles through the 'g_' and '$' positions
    if cols.cursor < cols.lastNonBlank
      isMoved = DoNormal('g_')
    elseif cols.cursor < cols.end
      isMoved = DoNormal('$')
    else
      isMoved = DoNormal('g_')
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
    DoNormal(keys[0])
    if getcursorcharpos() == pos
      # move the cursor if it still stays where it was
      DoNormal(keys[1])
    endif
    if n % step == 0
      redraw
    endif
  endwhile
  if &startofline
    # move the cursor to the first non-blank character of the line
    DoNormal('^')
  endif
enddef # }}}
var scrolltimerid: number
export def Scroll(motion: string)
  # @param {"\<C-d>" | "\<C-u>" | "\<C-f>" | "\<C-b>"} motion
  const cnt = v:count
  var lines: number
  if motion ==# "\<C-d>" || motion ==# "\<C-u>"
    # scroll [count] lines or half a screen as default
    lines = cnt ?? &scroll
  elseif motion ==# "\<C-f>" || motion ==# "\<C-b>"
    # scroll [count] screens
    lines = (cnt ?? 1) * winheight(0)
  endif
  # use a timer to activate only last key input on long press
  timer_stop(scrolltimerid) # no error even if a timer ID does not exist
  scrolltimerid = timer_start(10, function(SmoothScroll, [motion, lines]))
enddef

def RepeatSearch(motion: string, cnt: number): bool # {{{
  # @param {'n' | 'N'} motion
  # @param {number} cnt - v:count
  # @return {bool} - whether the cursor has moved to a match
  const isForward = IsForwardMotion(motion)
  var isMoved: bool
  const prevpos = getcursorcharpos()
  for i in range(cnt ?? 1)
    # skip a closed fold
    GoToFoldEdge(isForward, prevpos[1])
    isMoved = DoNormal(motion)
    if ! isMoved | break | endif
  endfor
  if isMoved
    const pos = getcursorcharpos()
    SetJump(prevpos)
    if prevpos[1] != pos[1] && pos[1] == (isForward ? line('w$') : line('w0'))
      # when the cursor moved to another line (which means at least 2 matches were found)
      # and that line is the first or last line visible in window
      isMoved = DoNormal('zz')
    endif
  else
    # move the cursor back if no pattern is found
    setcharpos('.', prevpos)
  endif
  return isMoved
enddef # }}}
def StarSearch(motion: string): bool # {{{
  # @param {'*' | '#' | 'g*' | 'g#'} motion
  # @return {bool} - whether the pattern has found
  const cnt = v:count
  const isForward = IsForwardMotion(motion)
  var pat: string
  const cword = escape(GetWordUnderCursor(), '\/')
  if motion ==# '*' || motion ==# '#'
    pat = '\V' .. (cword =~# '^\k' ? '\<' : '') .. cword .. (cword =~# '\k$' ? '\>' : '')
  elseif motion ==# 'g*' || motion ==# 'g#'
    pat = '\V' .. cword
  endif
  const isMoved = SearchPattern(isForward, substitute(pat, '\n', '\\n', 'g'), cnt)
  return isMoved
enddef # }}}
def SearchJump(motion: string, cnt: number): bool # {{{
  # @param {'[n' | ']n' | '[N' | ']N'} motion
  # @param {number} cnt - v:count
  # @return {bool} - whether the cursor has moved to a match
  var isMoved: bool
  var searchresult: dict<any>
  try
    searchresult = searchcount({maxcount: 0})
  catch /^Vim\%((\a\+)\)\=:E/
    # probably an invalid regular expression was used, so abort (echo as a message)
    echohl ErrorMsg | echomsg substitute(v:exception, '^Vim\%((\a\+)\)\=:', '', '') | echohl None
    return isMoved
  endtry
  var steps: number
  const isForward = IsForwardMotion(motion)
  var searchflags: string
  if motion ==# '[n' || motion ==# ']n'
    # jump to the [count] previous or next match
    steps = cnt ?? 1
    searchflags = isForward ? '' : 'b'
  elseif motion ==# '[N' || motion ==# ']N'
    # jump to the [count]th match, or the first or last match as default
    const nth = cnt ?? isForward ? searchresult.total : 1
    if searchresult.current < nth
      steps = nth - searchresult.current
      searchflags = 'W'
    else
      # move the cursor to the start position of the current match
      search(@/, 'bc')
      steps = searchresult.current - nth
      searchflags = 'bW'
    endif
  endif
  for i in range(steps)
    isMoved = search(@/, searchflags) > 0
    if ! isMoved | break | endif
  endfor
  return isMoved
enddef # }}}
export def Search(motion: string)
  # @param {'n' | 'N' | '*' | '#' | 'g*' | 'g#' | '[n' | ']n' | '[N' | ']N'} motion
  if motion ==# 'n' || motion ==# 'N'
    DoMotion(motion,
      function(RepeatSearch, [motion]))
  elseif motion ==# '*' || motion ==# '#' || motion ==# 'g*' || motion ==# 'g#'
    StarSearch(motion)
  elseif motion ==# '[n' || motion ==# ']n' || motion ==# '[N' || motion ==# ']N'
    DoMotion(motion,
      function(SearchJump, [motion]))
  endif
  # avoid `function-search-undo` (do not use the 'x' flag)
  feedkeys("\<ScriptCmd>v:hlsearch = 1\<CR>", 'n')
enddef

export def SearchPattern(isForward: bool, pat: string, cnt = v:count): bool # {{{
  # @param {bool} isForward - search forward if true, backward if false
  # @param {string} pat - the regexp pattern
  # @param {number=} cnt - v:count
  # @return {bool} - whether the pattern has found
  # adding a pattern to the search history is the same as searching forward without moving the cursor
  @/ = pat # v:searchforward is reset to true
  histadd('/', pat)
  var isMoved: bool
  if cnt < 2
    # check if the pattern is found (do not move the cursor)
    isMoved = search(pat, isForward ? 'nW' : 'nbW') > 0
  else
    # go to the [count - 1]th match
    const prevpos = getcursorcharpos()
    isMoved = RepeatSearch(isForward == IsForwardMotion('n') ? 'n' : 'N', cnt - 1)
    if isMoved | SetJump(prevpos) | endif
  endif
  # avoid `function-search-undo` (do not use the 'x' flag)
  feedkeys("\<ScriptCmd>v:searchforward = " .. (isForward ? 1 : 0) .. "\<CR>")
  return isMoved
enddef # }}}
