"TODO print messages when on visual mode. I only see VISUAL, not the messages.

" Function interface phylosophy:
"
" - functions take arbitrary line numbers as parameters.
"    Current cursor line is only a suitable default parameter.
"
" - only functions that bind directly to user actions:
"
"    - print error messages.
"       All intermediate functions limit themselves return `0` to indicate an error.
"
"    - move the cursor. All other functions do not move the cursor.
"
" This is how you should view headers for the header mappings:
"
"   |BUFFER
"   |
"   |Outside any header
"   |
" a-+# a
"   |
"   |Inside a
"   |
" a-+
" b-+## b
"   |
"   |inside b
"   |
" b-+
" c-+### c
"   |
"   |Inside c
"   |
" c-+
" d-|# d
"   |
"   |Inside d
"   |
" d-+
" e-|e
"   |====
"   |
"   |Inside e
"   |
" e-+

" For each level, contains the regexp that matches at that level only.
"
let s:levelRegexpDict = {
    \ 1: '\v^(#[^#]@=|.+\n\=+$)',
    \ 2: '\v^(##[^#]@=|.+\n-+$)',
    \ 3: '\v^###[^#]@=',
    \ 4: '\v^####[^#]@=',
    \ 5: '\v^#####[^#]@=',
    \ 6: '\v^######[^#]@='
\ }

" Maches any header level of any type.
"
" This could be deduced from `s:levelRegexpDict`, but it is more
" efficient to have a single regexp for this.
"
let s:headersRegexp = '\v^(#|.+\n(\=+|-+)$)'

" Returns the line number of the first header before `line`, called the
" current header.
"
" If there is no current header, return `0`.
"
" @param a:1 The line to look the header of. Default value: `getpos('.')`.
"
function! s:GetHeaderLineNum(...)
    if a:0 == 0
        let l:l = line('.')
    else
        let l:l = a:1
    endif
    while(l:l > 0)
        if join(getline(l:l, l:l + 1), "\n") =~ s:headersRegexp
            return l:l
        endif
        let l:l -= 1
    endwhile
    return 0
endfunction

" -  if inside a header goes to it.
"    Return its line number.
"
" -  if on top level outside any headers,
"    print a warning
"    Return `0`.
"
function! s:MoveToCurHeader()
    let l:lineNum = s:GetHeaderLineNum()
    if l:lineNum != 0
        call cursor(l:lineNum, 1)
    else
        echo 'outside any header'
        "normal! gg
    endif
    return l:lineNum
endfunction

" Move cursor to next header of any level.
"
" If there are no more headers, print a warning.
"
function! s:MoveToNextHeader()
    if search(s:headersRegexp, 'W') == 0
        "normal! G
        echo 'no next header'
    endif
endfunction

" Move cursor to previous header (before current) of any level.
"
" If it does not exist, print a warning.
"
function! s:MoveToPreviousHeader()
    let l:curHeaderLineNumber = s:GetHeaderLineNum()
    let l:noPreviousHeader = 0
    if l:curHeaderLineNumber <= 1
        let l:noPreviousHeader = 1
    else
        let l:previousHeaderLineNumber = s:GetHeaderLineNum(l:curHeaderLineNumber - 1)
        if l:previousHeaderLineNumber == 0
            let l:noPreviousHeader = 1
        else
            call cursor(l:previousHeaderLineNumber, 1)
        endif
    endif
    if l:noPreviousHeader
        echo 'no previous header'
    endif
endfunction

" - if line is inside a header, return the header level (h1 -> 1, h2 -> 2, etc.).
"
" - if line is at top level outside any headers, return `0`.
"
function! s:GetHeaderLevel(...)
    if a:0 == 0
        let l:line = line('.')
    else
        let l:line = a:1
    endif
    let l:linenum = s:GetHeaderLineNum(l:line)
    if l:linenum != 0
        return s:GetLevelOfHeaderAtLine(l:linenum)
    else
        return 0
    endif
endfunction

" Returns the level of the header at the given line.
"
" If there is no header at the given line, returns `0`.
"
function! s:GetLevelOfHeaderAtLine(linenum)
    let l:lines = join(getline(a:linenum, a:linenum + 1), "\n")
    for l:key in keys(s:levelRegexpDict)
        if l:lines =~ get(s:levelRegexpDict, l:key)
            return l:key
        endif
    endfor
    return 0
endfunction

" Move cursor to parent header of the current header.
"
" If it does not exit, print a warning and do nothing.
"
function! s:MoveToParentHeader()
    let l:linenum = s:GetParentHeaderLineNumber()
    if l:linenum != 0
        call cursor(l:linenum, 1)
    else
        echo 'no parent header'
    endif
endfunction

" Return the line number of the parent header of line `line`.
"
" If it has no parent, return `0`.
"
function! s:GetParentHeaderLineNumber(...)
    if a:0 == 0
        let l:line = line('.')
    else
        let l:line = a:1
    endif
    let l:level = s:GetHeaderLevel(l:line)
    if l:level > 1
        let l:linenum = s:GetPreviousHeaderLineNumberAtLevel(l:level - 1, l:line)
        return l:linenum
    endif
    return 0
endfunction

" Return the line number of the previous header of given level.
" in relation to line `a:1`. If not given, `a:1 = getline()`
"
" `a:1` line is included, and this may return the current header.
"
" If none return 0.
"
function! s:GetNextHeaderLineNumberAtLevel(level, ...)
    if a:0 < 1
        let l:line = line('.')
    else
        let l:line = a:1
    endif
    let l:l = l:line
    while(l:l <= line('$'))
        if join(getline(l:l, l:l + 1), "\n") =~ get(s:levelRegexpDict, a:level)
            return l:l
        endif
        let l:l += 1
    endwhile
    return 0
endfunction

" Return the line number of the previous header of given level.
" in relation to line `a:1`. If not given, `a:1 = getline()`
"
" `a:1` line is included, and this may return the current header.
"
" If none return 0.
"
function! s:GetPreviousHeaderLineNumberAtLevel(level, ...)
    if a:0 == 0
        let l:line = line('.')
    else
        let l:line = a:1
    endif
    let l:l = l:line
    while(l:l > 0)
        if join(getline(l:l, l:l + 1), "\n") =~ get(s:levelRegexpDict, a:level)
            return l:l
        endif
        let l:l -= 1
    endwhile
    return 0
endfunction

" Move cursor to next sibling header.
"
" If there is no next siblings, print a warning and don't move.
"
function! s:MoveToNextSiblingHeader()
    let l:curHeaderLineNumber = s:GetHeaderLineNum()
    let l:curHeaderLevel = s:GetLevelOfHeaderAtLine(l:curHeaderLineNumber)
    let l:curHeaderParentLineNumber = s:GetParentHeaderLineNumber()
    let l:nextHeaderSameLevelLineNumber = s:GetNextHeaderLineNumberAtLevel(l:curHeaderLevel, l:curHeaderLineNumber + 1)
    let l:noNextSibling = 0
    if l:nextHeaderSameLevelLineNumber == 0
        let l:noNextSibling = 1
    else
        let l:nextHeaderSameLevelParentLineNumber = s:GetParentHeaderLineNumber(l:nextHeaderSameLevelLineNumber)
        if l:curHeaderParentLineNumber == l:nextHeaderSameLevelParentLineNumber
            call cursor(l:nextHeaderSameLevelLineNumber, 1)
        else
            let l:noNextSibling = 1
        endif
    endif
    if l:noNextSibling
        echo 'no next sibling header'
    endif
endfunction

" Move cursor to previous sibling header.
"
" If there is no previous siblings, print a warning and do nothing.
"
function! s:MoveToPreviousSiblingHeader()
    let l:curHeaderLineNumber = s:GetHeaderLineNum()
    let l:curHeaderLevel = s:GetLevelOfHeaderAtLine(l:curHeaderLineNumber)
    let l:curHeaderParentLineNumber = s:GetParentHeaderLineNumber()
    let l:previousHeaderSameLevelLineNumber = s:GetPreviousHeaderLineNumberAtLevel(l:curHeaderLevel, l:curHeaderLineNumber - 1)
    let l:noPreviousSibling = 0
    if l:previousHeaderSameLevelLineNumber == 0
        let l:noPreviousSibling = 1
    else
        let l:previousHeaderSameLevelParentLineNumber = s:GetParentHeaderLineNumber(l:previousHeaderSameLevelLineNumber)
        if l:curHeaderParentLineNumber == l:previousHeaderSameLevelParentLineNumber
            call cursor(l:previousHeaderSameLevelLineNumber, 1)
        else
            let l:noPreviousSibling = 1
        endif
    endif
    if l:noPreviousSibling
        echo 'no previous sibling header'
    endif
endfunction


fun! markdown#CloseTocWindow()
    exe 'bwipeout ' . bufnr()
endfun

function! s:Toc(...)
    if a:0 > 0
        let l:window_type = a:1
    else
        let l:window_type = 'vertical'
    endif


    let l:bufnr = bufnr('%')
    let l:cursor_line = line('.')
    let l:cursor_header = 0
    let l:fenced_block = 0
    let l:front_matter = 0
    let l:header_list = []
    let l:header_max_len = 0
    let l:vim_markdown_toc_autofit = get(g:, "vim_markdown_toc_autofit", 0)
    let l:vim_markdown_frontmatter = get(g:, "vim_markdown_frontmatter", 0)
    for i in range(1, line('$'))
        let l:lineraw = getline(i)
        let l:l1 = getline(i+1)
        let l:line = substitute(l:lineraw, "#", "\\\#", "g")
        if l:line =~ '````*' || l:line =~ '\~\~\~\~*'
            if l:fenced_block == 0
                let l:fenced_block = 1
            elseif l:fenced_block == 1
                let l:fenced_block = 0
            endif
        elseif l:vim_markdown_frontmatter == 1
            if l:front_matter == 1
                if l:line == '---'
                    let l:front_matter = 0
                endif
            elseif i == 1
                if l:line == '---'
                    let l:front_matter = 1
                endif
            endif
        endif
        if l:line =~ '^#\+' || (l:l1 =~ '^=\+\s*$' || l:l1 =~ '^-\+\s*$') && l:line =~ '^\S'
            let l:is_header = 1
        else
            let l:is_header = 0
        endif
        if l:is_header == 1 && l:fenced_block == 0 && l:front_matter == 0
            " append line to location list
            let l:item = {'lnum': i, 'text': l:line, 'valid': 1, 'bufnr': l:bufnr, 'col': 1}
            let l:header_list = l:header_list + [l:item]
            " set header number of the cursor position
            if l:cursor_header == 0
                if i == l:cursor_line
                    let l:cursor_header = len(l:header_list)
                elseif i > l:cursor_line
                    let l:cursor_header = len(l:header_list) - 1
                endif
            endif
            " keep track of the longest header size (heading level + title)
            let l:total_len = stridx(l:line, ' ') + strdisplaywidth(l:line)
            if l:total_len > l:header_max_len
                let l:header_max_len = l:total_len
            endif
        endif
    endfor
    call setloclist(0, l:header_list)
    if len(l:header_list) == 0
        echom "Toc: No headers."
        return
    endif

    if l:window_type ==# 'horizontal'
        lopen
    elseif l:window_type ==# 'vertical'
        vertical lopen
        " auto-fit toc window when possible to shrink it
        if (&columns/2) > l:header_max_len && l:vim_markdown_toc_autofit == 1
            execute 'vertical resize ' . (l:header_max_len + 1)
        else
            " execute 'vertical resize ' . (&columns/2)
            execute 'vertical resize ' . '30'
        endif
    elseif l:window_type ==# 'tab'
        tab lopen
    else
        lopen
    endif
    setlocal modifiable
    for i in range(1, line('$'))
        " this is the location-list data for the current item
        let d = getloclist(0)[i-1]
        " atx headers
        if match(d.text, "^#") > -1
            let l:level = len(matchstr(d.text, '#*', 'g'))-1
            let d.text = substitute(d.text, '\v^#*[ ]*', '', '')
            let d.text = substitute(d.text, '\v[ ]*#*$', '', '')
        " setex headers
        else
            let l:next_line = getbufline(d.bufnr, d.lnum+1)
            if match(l:next_line, "=") > -1
                let l:level = 0
            elseif match(l:next_line, "-") > -1
                let l:level = 1
            endif
        endif
        call setline(i, repeat('  ', l:level). d.text)
    endfor
    setlocal nomodified
    setlocal nomodifiable
    execute 'normal! ' . l:cursor_header . 'G'

    let w:markdown_toc_window='yes'
    setlocal nowrap
    " setlocal filetype=markdown

    autocmd! BufLeave <buffer> call markdown#CloseTocWindow()
    map <silent> <buffer> <ESC> :call markdown#CloseTocWindow()<cr>
    map <silent> <buffer> q <ESC>
    map <silent> <buffer> <Leader>w <ESC>
endfunction

" Convert Setex headers in range `line1 .. line2` to Atx.
"
" Return the number of conversions.
"
function! s:SetexToAtx(line1, line2)
    let l:originalNumLines = line('$')
    execute 'silent! ' . a:line1 . ',' . a:line2 . 'substitute/\v(.*\S.*)\n\=+$/# \1/'
    execute 'silent! ' . a:line1 . ',' . a:line2 . 'substitute/\v(.*\S.*)\n-+$/## \1/'
    return l:originalNumLines - line('$')
endfunction

" If `a:1` is 0, decrease the level of all headers in range `line1 .. line2`.
"
" Otherwise, increase the level. `a:1` defaults to `0`.
"
function! s:HeaderDecrease(line1, line2, ...)
    if a:0 > 0
        let l:increase = a:1
    else
        let l:increase = 0
    endif
    if l:increase
        let l:forbiddenLevel = 6
        let l:replaceLevels = [5, 1]
        let l:levelDelta = 1
    else
        let l:forbiddenLevel = 1
        let l:replaceLevels = [2, 6]
        let l:levelDelta = -1
    endif
    for l:line in range(a:line1, a:line2)
        if join(getline(l:line, l:line + 1), "\n") =~ s:levelRegexpDict[l:forbiddenLevel]
            echomsg 'There is an h' . l:forbiddenLevel . ' at line ' . l:line . '. Aborting.'
            return
        endif
    endfor
    let l:numSubstitutions = s:SetexToAtx(a:line1, a:line2)
    let l:flags = (&gdefault ? '' : 'g')
    for l:level in range(replaceLevels[0], replaceLevels[1], -l:levelDelta)
        execute 'silent! ' . a:line1 . ',' . (a:line2 - l:numSubstitutions) . 'substitute/' . s:levelRegexpDict[l:level] . '/' . repeat('#', l:level + l:levelDelta) . '/' . l:flags
    endfor
endfunction

" Format table under cursor.
"
" Depends on Tabularize.
"
function! s:TableFormat()
    let l:pos = getpos('.')
    normal! {
    " Search instead of `normal! j` because of the table at beginning of file edge case.
    call search('|')
    normal! j
    " Remove everything that is not a pipe, colon or hyphen next to a colon othewise
    " well formated tables would grow because of addition of 2 spaces on the separator
    " line by Tabularize /|.
    let l:flags = (&gdefault ? '' : 'g')
    execute 's/\(:\@<!-:\@!\|[^|:-]\)//e' . l:flags
    execute 's/--/-/e' . l:flags
    Tabularize /|
    " Move colons for alignment to left or right side of the cell.
    execute 's/:\( \+\)|/\1:|/e' . l:flags
    execute 's/|\( \+\):/|:\1/e' . l:flags
    execute 's/ /-/' . l:flags
    call setpos('.', l:pos)
endfunction

" Wrapper to do move commands in visual mode.
"
function! s:VisMove(f)
    norm! gv
    call function(a:f)()
endfunction

" Map in both normal and visual modes.
"
function! s:MapNormVis(rhs,lhs)
    execute 'nn <buffer><silent> ' . a:rhs . ' :call ' . a:lhs . '()<cr>'
    execute 'vn <buffer><silent> ' . a:rhs . ' <esc>:call <sid>VisMove(''' . a:lhs . ''')<cr>'
endfunction

" Parameters:
"
" - step +1 for right, -1 for left
"
" TODO: multiple lines.
"
function! s:FindCornerOfSyntax(lnum, col, step)
    let l:col = a:col
    let l:syn = synIDattr(synID(a:lnum, l:col, 1), 'name')
    while synIDattr(synID(a:lnum, l:col, 1), 'name') ==# l:syn
        let l:col += a:step
    endwhile
    return l:col - a:step
endfunction

" Return the next position of the given syntax name,
" inclusive on the given position.
"
" TODO: multiple lines
"
function! s:FindNextSyntax(lnum, col, name)
    let l:col = a:col
    let l:step = 1
    while synIDattr(synID(a:lnum, l:col, 1), 'name') !=# a:name
        let l:col += l:step
    endwhile
    return [a:lnum, l:col]
endfunction

function! s:FindCornersOfSyntax(lnum, col)
    return [<sid>FindLeftOfSyntax(a:lnum, a:col), <sid>FindRightOfSyntax(a:lnum, a:col)]
endfunction

function! s:FindRightOfSyntax(lnum, col)
    return <sid>FindCornerOfSyntax(a:lnum, a:col, 1)
endfunction

function! s:FindLeftOfSyntax(lnum, col)
    return <sid>FindCornerOfSyntax(a:lnum, a:col, -1)
endfunction

" Returns:
"
" - a string with the the URL for the link under the cursor
" - an empty string if the cursor is not on a link
"
" TODO
"
" - multiline support
" - give an error if the separator does is not on a link
"
function! s:Markdown_GetUrlForPosition(lnum, col)
    let l:lnum = a:lnum
    let l:col = a:col
    let l:syn = synIDattr(synID(l:lnum, l:col, 1), 'name')

    if l:syn ==# 'mkdInlineURL' || l:syn ==# 'mkdURL' || l:syn ==# 'mkdLinkDefTarget'
        " Do nothing.
    elseif l:syn ==# 'mkdLink'
        let [l:lnum, l:col] = <sid>FindNextSyntax(l:lnum, l:col, 'mkdURL')
        let l:syn = 'mkdURL'
    elseif l:syn ==# 'mkdDelimiter'
        let l:line = getline(l:lnum)
        let l:char = l:line[col - 1]
        if l:char ==# '<'
            let l:col += 1
        elseif l:char ==# '>' || l:char ==# ')'
            let l:col -= 1
        elseif l:char ==# '[' || l:char ==# ']' || l:char ==# '('
            let [l:lnum, l:col] = <sid>FindNextSyntax(l:lnum, l:col, 'mkdURL')
        else
            return ''
        endif
    else
        return ''
    endif

    let [l:left, l:right] = <sid>FindCornersOfSyntax(l:lnum, l:col)
    return getline(l:lnum)[l:left - 1 : l:right - 1]
endfunction

" Front end for GetUrlForPosition.
"
function! s:OpenUrlUnderCursor()
    let l:url = s:Markdown_GetUrlForPosition(line('.'), col('.'))
    if l:url != ''
        call s:VersionAwareNetrwBrowseX(l:url)
    else
        echomsg 'The cursor is not on a link.'
    endif
endfunction

" We need a definition guard because we invoke 'edit' which will reload this
" script while this function is running. We must not replace it.
if !exists('*s:EditUrlUnderCursor')
    function s:EditUrlUnderCursor()
        let l:url = s:Markdown_GetUrlForPosition(line('.'), col('.'))
        if l:url != ''
            if get(g:, 'vim_markdown_autowrite', 0)
                write
            endif
            let l:anchor = ''
            if get(g:, 'vim_markdown_follow_anchor', 0)
                let l:parts = split(l:url, '#', 1)
                if len(l:parts) == 2
                    let [l:url, l:anchor] = parts
                    let l:anchorexpr = get(g:, 'vim_markdown_anchorexpr', '')
                    if l:anchorexpr != ''
                        let l:anchor = eval(substitute(
                            \ l:anchorexpr, 'v:anchor',
                            \ escape('"'.l:anchor.'"', '"'), ''))
                    endif
                endif
            endif
            if l:url != ''
                if get(g:, 'vim_markdown_no_extensions_in_markdown', 0)
                    let l:url .= '.md'
                endif
                let l:url = fnamemodify(expand('%:h').'/'.l:url, ':.')
                execute 'edit' l:url
            endif
            if l:anchor != ''
                silent! execute '/'.l:anchor
            endif
        else
            echomsg 'The cursor is not on a link.'
        endif
    endfunction
endif

function! s:VersionAwareNetrwBrowseX(url)
    if has('patch-7.4.567')
        call netrw#BrowseX(a:url, 0)
    else
        call netrw#NetrwBrowseX(a:url, 0)
    endif
endf

function! s:MapNotHasmapto(lhs, rhs)
    if !hasmapto('<Plug>' . a:rhs)
        execute 'nmap <buffer>' . a:lhs . ' <Plug>' . a:rhs
        execute 'vmap <buffer>' . a:lhs . ' <Plug>' . a:rhs
    endif
endfunction

call <sid>MapNormVis('<Plug>Markdown_MoveToNextHeader', '<sid>MoveToNextHeader')
call <sid>MapNormVis('<Plug>Markdown_MoveToPreviousHeader', '<sid>MoveToPreviousHeader')
call <sid>MapNormVis('<Plug>Markdown_MoveToNextSiblingHeader', '<sid>MoveToNextSiblingHeader')
call <sid>MapNormVis('<Plug>Markdown_MoveToPreviousSiblingHeader', '<sid>MoveToPreviousSiblingHeader')
call <sid>MapNormVis('<Plug>Markdown_MoveToParentHeader', '<sid>MoveToParentHeader')
call <sid>MapNormVis('<Plug>Markdown_MoveToCurHeader', '<sid>MoveToCurHeader')
nnoremap <Plug>Markdown_OpenUrlUnderCursor :call <sid>OpenUrlUnderCursor()<cr>
nnoremap <Plug>Markdown_EditUrlUnderCursor :call <sid>EditUrlUnderCursor()<cr>

if !get(g:, 'vim_markdown_no_default_key_mappings', 0)
    call <sid>MapNotHasmapto(']]', 'Markdown_MoveToNextHeader')
    call <sid>MapNotHasmapto('[[', 'Markdown_MoveToPreviousHeader')
    call <sid>MapNotHasmapto('][', 'Markdown_MoveToNextSiblingHeader')
    call <sid>MapNotHasmapto('[]', 'Markdown_MoveToPreviousSiblingHeader')
    call <sid>MapNotHasmapto(']u', 'Markdown_MoveToParentHeader')
    call <sid>MapNotHasmapto(']c', 'Markdown_MoveToCurHeader')
    call <sid>MapNotHasmapto('gx', 'Markdown_OpenUrlUnderCursor')
    call <sid>MapNotHasmapto('ge', 'Markdown_EditUrlUnderCursor')
endif

command! -buffer -range=% HeaderDecrease call s:HeaderDecrease(<line1>, <line2>)
command! -buffer -range=% HeaderIncrease call s:HeaderDecrease(<line1>, <line2>, 1)
command! -buffer -range=% SetexToAtx call s:SetexToAtx(<line1>, <line2>)
command! -buffer TableFormat call s:TableFormat()
command! -buffer Toc call s:Toc()
command! -buffer Toch call s:Toc('horizontal')
command! -buffer Tocv call s:Toc('vertical')
command! -buffer Toct call s:Toc('tab')

" Heavily based on vim-notes - http://peterodding.com/code/vim/notes/
if exists('g:vim_markdown_fenced_languages')
    let s:filetype_dict = {}
    for s:filetype in g:vim_markdown_fenced_languages
        let key = matchstr(s:filetype, "[^=]*")
        let val = matchstr(s:filetype, "[^=]*$")
        let s:filetype_dict[key] = val
    endfor
else
    let s:filetype_dict = {
        \ 'c++': 'cpp',
        \ 'viml': 'vim',
        \ 'bash': 'sh',
        \ 'ini': 'dosini'
    \ }
endif

function! s:MarkdownHighlightSources(force)
    " Syntax highlight source code embedded in notes.
    " Look for code blocks in the current file
    let filetypes = {}
    for line in getline(1, '$')
        let ft = matchstr(line, '```\s*\zs[0-9A-Za-z_+-]*')
        if !empty(ft) && ft !~ '^\d*$' | let filetypes[ft] = 1 | endif
    endfor
    if !exists('b:mkd_known_filetypes')
        let b:mkd_known_filetypes = {}
    endif
    if !exists('b:mkd_included_filetypes')
        " set syntax file name included
        let b:mkd_included_filetypes = {}
    endif
    if !a:force && (b:mkd_known_filetypes == filetypes || empty(filetypes))
        return
    endif

    " Now we're ready to actually highlight the code blocks.
    let startgroup = 'mkdCodeStart'
    let endgroup = 'mkdCodeEnd'
    for ft in keys(filetypes)
        if a:force || !has_key(b:mkd_known_filetypes, ft)
            if has_key(s:filetype_dict, ft)
                let filetype = s:filetype_dict[ft]
            else
                let filetype = ft
            endif
            let group = 'mkdSnippet' . toupper(substitute(filetype, "[+-]", "_", "g"))
            if !has_key(b:mkd_included_filetypes, filetype)
                let include = s:SyntaxInclude(filetype)
                let b:mkd_included_filetypes[filetype] = 1
            else
                let include = '@' . toupper(filetype)
            endif
            let command = 'syntax region %s matchgroup=%s start="^\s*```\s*%s$" matchgroup=%s end="\s*```$" keepend contains=%s%s'
            execute printf(command, group, startgroup, ft, endgroup, include, has('conceal') && get(g:, 'vim_markdown_conceal', 1) ? ' concealends' : '')
            execute printf('syntax cluster mkdNonListItem add=%s', group)

            let b:mkd_known_filetypes[ft] = 1
        endif
    endfor
endfunction

function! s:SyntaxInclude(filetype)
    " Include the syntax highlighting of another {filetype}.
    let grouplistname = '@' . toupper(a:filetype)
    " Unset the name of the current syntax while including the other syntax
    " because some syntax scripts do nothing when "b:current_syntax" is set
    if exists('b:current_syntax')
        let syntax_save = b:current_syntax
        unlet b:current_syntax
    endif
    try
        execute 'syntax include' grouplistname 'syntax/' . a:filetype . '.vim'
        execute 'syntax include' grouplistname 'after/syntax/' . a:filetype . '.vim'
    catch /E484/
        " Ignore missing scripts
    endtry
    " Restore the name of the current syntax
    if exists('syntax_save')
        let b:current_syntax = syntax_save
    elseif exists('b:current_syntax')
        unlet b:current_syntax
    endif
    return grouplistname
endfunction


function! s:MarkdownRefreshSyntax(force)
    if &filetype == 'markdown' && line('$') > 1
        call s:MarkdownHighlightSources(a:force)
    endif
endfunction

function! s:MarkdownClearSyntaxVariables()
    if &filetype == 'markdown'
        unlet! b:mkd_included_filetypes
    endif
endfunction

augroup Mkd
    autocmd!
    au BufWinEnter * call s:MarkdownRefreshSyntax(1)
    au BufUnload * call s:MarkdownClearSyntaxVariables()
    au BufWritePost * call s:MarkdownRefreshSyntax(0)
    au InsertEnter,InsertLeave * call s:MarkdownRefreshSyntax(0)
    au CursorHold,CursorHoldI * call s:MarkdownRefreshSyntax(0)
augroup END


"""""""""""""""""""""""""""""""""""""""""""""""""""""""
command! -buffer EditMdByLink call s:EditMdByLink(0)
command! -buffer EditMdByLinkLine call s:EditMdByLink(1)
command! -buffer TocToggle call s:TocToggle()
command! -buffer MdTocToggle call MdTocToggle()
command! -buffer ToggleZoom call s:ToggleZoom()
command! -buffer PanBuildAndRun call s:PanBuildAndRun()
command! -buffer AutoExpandLinkFile call s:AutoExpandLink(1)
command! -buffer AutoExpandLinkDir call s:AutoExpandLink(0)
command! -buffer AutoOpenUrlByLinkLine call s:OpenUrlByLinkLine()
command! -buffer DeleteMdByLink call s:DeleteMdByLink()

if exists("*s:EditMdByLink") 
    finish
endif

func! s:OpenUrlByLinkLine()
    let l:lineBuffer = getline('.')
    let l:localLink = substitute(l:lineBuffer, '.*\](\(.*\)).*', '\1', "g")
    " echo l:localLink
    if(g:iswindows==1)
        let cmd = '!start firefox "'.l:localLink.'"'
        let cmd = iconv(cmd, "utf-8", "cp936")
    else
        let cmd = '!firefox "'.l:localLink.'" &'
    endif
    silent exec cmd
endfunc

" 按回车键自动跳到光标所在的站内wiki链接(光标需要放在链接xxx/xxxx.html上)
func! s:EditMdByLink(lineMode)
    if a:lineMode == 1
        let l:lineBuffer = getline('.')
    else
        let l:lineBuffer = expand("<cWORD>")                                                " 获取光标所在处的链接字符串
    endif
    if match(l:lineBuffer, '.*\](\(http\|https\)://.*)') == 0
        echohl WarningMsg | echo "This is a link, not edittable." | echohl None
        return
    endif
    let l:localLink = substitute(l:lineBuffer, '.*\](\(.*\)\.\(html\|md\)).*', '\1.md', "g")    " 将链接中的.html改为.md.
    " echo l:localLink
    let l:hasLink = match(l:localLink, '.\+\.\(html\|md\)')                                     " 匹配是否存在.html...
    if l:hasLink == 0                                                                   " ...如果存在才跳转
        " 检测目标文件所在文件夹是否存在, 如果不存在则创建
        let l:localLinkDir=fnamemodify(l:localLink, ':h')
        let l:localLinkDirExist = isdirectory(l:localLinkDir)
        if !l:localLinkDirExist
            call mkdir(l:localLinkDir, "p")
        endif

        " exec "e ".l:localLink 
        let dir=expand("%:p:h")
        call s:TocOpenFile(dir.'/'.l:localLink)
    endif
endfunc

" 更新日期: 会将.md文件中的<!---LastModify-->或者<!---LastModify:yyyy.mm.dd-->替换为当前日期
func! s:UpdateMdDatetime()
    if &modified
        let savpos = getpos(".")
        " exec "norm mz"
        " ^ 如果需要时间可以加上 %H:%M:%S
        " exec '%s/^<!---LastModify\(.*\)-->.*/<!---LastModify:'.strftime("%Y.%m.%d")."-->"."/e"
        exec '$s/^Created:\(.*\)LastModify:\(.*\)/Created:\1LastModify:'.strftime("%Y.%m.%d %H:%M")."/e"
        " exec "norm `z"
        "call cursor(savpos[1:])
        call setpos(".", savpos) 
    endif
endfunc
au BufWritePre *.{md,mdown,mkd,mkdn,markdown,mdwn} call s:UpdateMdDatetime()

func! s:TocToggle()
    call s:FindMdTocPath() 
    call s:TocWindowToggle() 
endfunc

func! s:TocWindowToggle()
    if !exists("t:mdTocPath")
        echohl WarningMsg | echo "No Toc found." | echohl None
        return
    endif

    let g:Toc_WinWidth = 30
    " let g:Toc_title = 'Toc'
    let g:Toc_title = t:mdTocPath
    let win_dir = 'topleft vertical'
    let win_size = g:Toc_WinWidth

    let winnum = bufwinnr(g:Toc_title)
    if winnum != -1
        call s:TocWindowClose()
        return
    endif

    let bufnum = bufnr(g:Toc_title)
    if bufnum == -1
        " Create a new buffer
        " let wcmd = g:Toc_title
        let wcmd = t:mdTocPath
    else
        " Edit the existing buffer
        let wcmd = '+buffer' . bufnum
    endif

    exe 'silent! ' . win_dir . ' ' . win_size . 'split ' . wcmd

    " set property
    " setlocal filetype=toc
    " silent! setlocal buftype=nofile
    if v:version >= 601
        silent! setlocal nobuflisted
    endif
    silent! setlocal nowrap
    silent! setlocal noswapfile

    let w:toc_window = "yes"
    nmap <Leader>aa :ToggleZoom<CR>
endfunc

function! s:FindMdTocPath()
    let dir=expand("%:p:h")
    if exists("t:mdTocPath")
        return
    endif

    " let prefixPath="/.KingConfig"
    let prefixPath = g:prefixPath
    let tocName="Toc.md"
    if exists('g:tocFileName')
        let tocName = g:tocFileName
    endif
    let dirLen=len(dir)
    let iswindows = 0
    if(has("win32") || has("win95") || has("win64") || has("win16"))
        let iswindows = 1
    endif
    while (iswindows==1 && dirLen>3) || (iswindows!=1 && dirLen>1)
        if isdirectory(dir.prefixPath) && filereadable(dir."/".tocName)
           let t:mdTocPath = dir."/".tocName
           return 
        endif
        let dir=fnamemodify(dir, ':h')
        let dirLen=len(dir)
    endwhile
endfunction

function! s:TocWindowClose()
    " Make sure the taglist window exists
    let winnum = bufwinnr(t:mdTocPath)
    if winnum == -1
        echohl WarningMsg | echo "Error: Toc window is not open" | echohl None
        return
    endif

    if winnr() == winnum
        " Already in the taglist window. Close it and return
        if winbufnr(2) != -1
            " If a window other than the taglist window is open,
            " then only close the taglist window.
            close
        endif
    else
        " Goto the taglist window, close it and then come back to the
        " original window
        let curbufnr = bufnr('%')
        exe winnum . 'wincmd w'
        close
        " Need to jump back to the original window only if we are not
        " already in that window
        let winnum = bufwinnr(curbufnr)
        if winnr() != winnum
            exe winnum . 'wincmd w'
        endif
    endif
endfunction

func! s:TocOpenFile(filename)
    " Goto the window containing the file.  If the window is not there, open a
    " new window
    let winnum = bufwinnr(a:filename)

    if winnum == -1
        " Locate the previously used window for opening a file
        let fwin_num = 0
        let first_usable_win = 0

        let i = 1
        let bnum = winbufnr(i)
        while bnum != -1
            if getwinvar(i, 'toc_window') != 'yes' && !getwinvar(i, '&previewwindow')
                let fwin_num = i
                break
            endif
            if first_usable_win == 0 &&
                        \ getwinvar(i, 'toc_window') != 'yes' &&
                        \ !getwinvar(i, '&previewwindow')
                " First non-taglist, non-plugin and non-preview window
                let first_usable_win = i
            endif
            let i = i + 1
            let bnum = winbufnr(i)
        endwhile

        " If a previously used window is not found, then use the first
        " non-taglist window
        if fwin_num == 0
            let fwin_num = first_usable_win
        endif

        if fwin_num != 0
            " Jump to the file window
            exe fwin_num . "wincmd w"

            " If the user asked to jump to the tag in a new window, then split
            " the existing window into two.
            " if a:win_ctrl == 'newwin'
                " split
            " endif
            " exe "edit " . escape(a:filename, ' ')
            exe "edit " . a:filename
        else
            " Open a new window
            if winbufnr(2) == -1
                " Only the taglist window is present
                    exe 'leftabove vertical split ' .
                                \ escape(a:filename, ' ')

                " Go to the taglist window to change the window size to
                " the user configured value
                call s:Toc_Exe_Cmd_No_Acmds('wincmd p')
                exe 'vertical resize ' . g:Tlist_WinWidth
                " Go back to the file window
                call s:Toc_Exe_Cmd_No_Acmds('wincmd p')
            else
                " A plugin or help window is also present
                wincmd w
                exe 'leftabove split ' . escape(a:filename, ' ')
            endif
        endif
        " Mark the window, so that it can be reused.
        " call s:Tlist_Window_Mark_File_Window()
    else
        if v:version >= 700
            " If the file is opened in more than one window, then check
            " whether the last accessed window has the selected file.
            " If it does, then use that window.
            let lastwin_bufnum = winbufnr(winnr('#'))
            if bufnr(a:filename) == lastwin_bufnum
                let winnum = winnr('#')
            endif
        endif
        exe winnum . 'wincmd w'

        " If the user asked to jump to the tag in a new window, then split the
        " existing window into two.
        " if a:win_ctrl == 'newwin'
            " split
        " endif
    endif
endfunc

function! s:Toc_Exe_Cmd_No_Acmds(cmd)
    let old_eventignore = &eventignore
    set eventignore=all
    exe a:cmd
    let &eventignore = old_eventignore
endfunction

func! MdTocToggle()
    " if MdTocWindowClose() == 0
        exe 'Toc'
    " endif
endfunc

function! MdTocWindowClose()
    " Make sure the taglist window exists
    let i = 1
    let bnum = winbufnr(i)
    while bnum != -1
        if getwinvar(i, 'markdown_toc_window') == 'yes'
            break
        endif
        let i = i + 1
        let bnum = winbufnr(i)
    endwhile
    
    let winnum = bnum
    " let winnum = bufwinnr(t:mdTocPath)
    if winnum == -1
        " echohl WarningMsg | echo "Error: Toc window is not open" | echohl None
        return 0
    endif

    if winnr() == winnum
        " Already in the taglist window. Close it and return
        if winbufnr(2) != -1
            " If a window other than the taglist window is open,
            " then only close the taglist window.
            close
        endif
    else
        " Goto the taglist window, close it and then come back to the
        " original window
        let curbufnr = bufnr('%')
        exe winnum . 'wincmd w'
        close
        " Need to jump back to the original window only if we are not
        " already in that window
        let winnum = bufwinnr(curbufnr)
        if winnr() != winnum
            exe winnum . 'wincmd w'
        endif
    endif
    return 1
endfunction

function! s:ToggleZoom()
    if exists("b:TocWindowZoomed") && b:TocWindowZoomed
        let size = exists("b:Toc_WinWidth") ? b:Toc_WinWidth : 30
        exec "silent vertical resize ". size
        let b:TocWindowZoomed = 0
    else
        exec "vertical resize"
        let b:TocWindowZoomed = 1
    endif
endfunction

func! s:PanBuildAndRun()
    if !exists('g:cssPath')
        return
    endif
    if !executable('pandoc')
        echohl WarningMsg | echo "Error: pandoc not installed" | echohl None
        return
    endif
    let cssPath = g:cssPath
    let srcFile=expand("%")
    let dstFile=expand("%:r").".html"
    let cmd = '!pandoc --ascii -c '.cssPath.' '.srcFile.' -o '.dstFile
    if(g:iswindows==1)
        let cmd = iconv(cmd, "utf-8", "cp936")
    endif
    silent exec cmd

    " replace md link to hmtl link in SUMMARY.md
    let tocName="Toc.md"
    if exists('g:tocFileName')
        let tocName = g:tocFileName
    endif
    if srcFile == tocName
        if(executable('sed') && executable('mv'))
            let dstFileTemp = dstFile.".tmp"
            let cmd = "!sed -e '/href=\"\./s/\.md/\.html/' ".dstFile. ">".dstFileTemp." && mv ".dstFileTemp." ".dstFile
            silent exec cmd
        endif
    endif

    if(g:iswindows==1)
        let cmd = '!start firefox '.dstFile
        let cmd = iconv(cmd, "utf-8", "cp936")
    else
        let cmd = '!firefox '.dstFile.' &'
    endif
    silent exec cmd
endfunc

func! s:AutoExpandLink(isFile)
    let l:indentChar = ' '
    let l:indentCount = 4
    let l:symbol = '-'
    if a:isFile == 1
        let l:symbol = '*'
    endif

    let l:lineBuffer = getline('.')
    let l:targetName = s:GetNameFromLine(l:lineBuffer)
    let l:lineNum = line('.')
    if strlen(l:targetName) > 0
        " echo l:targetName
        let l:targetLinkIndentLevel = s:GetLineIndentLevel(l:lineBuffer)
        " let path = l:targetName.'.html'
        " let path = substitute(l:targetName, ' ', '-', "g").'.html'
        let path = substitute(l:targetName, ' ', '-', "g").'.md'

        if l:targetLinkIndentLevel > 0 
            let l:l = l:lineNum - 1
            let l:tmpLevel = l:targetLinkIndentLevel
            while(l:l >= 0)
                let l:lineBuffer = getline(l:l)
                let l:indentLevel = s:GetLineIndentLevel(l:lineBuffer)
                if l:indentLevel == l:tmpLevel - 1
                    let l:lineBuffer = substitute(l:lineBuffer, '.*\](.*/\(.*\)\.\(html\|md\)).*', '\1', "g")
                    let l:name = s:GetNameFromLine(l:lineBuffer)
                    let path = l:name.'/'.path
                    let l:tmpLevel -= 1
                endif
                if l:indentLevel == 0
                    break
                endif
                let l:l -= 1
            endwhile
        endif
        let path = './'.path
        " echo path
        let result = repeat(l:indentChar, l:targetLinkIndentLevel * l:indentCount).l:symbol.' ['.l:targetName.']('.path.')'
        call setline(l:lineNum, result)
    else
        echohl WarningMsg | echo "Error: not a valid name" | echohl None
    endif
endfunc

func! s:GetNameFromLine(lineBuffer)
    let l:name = substitute(a:lineBuffer, '+ ', '', "g")
    let l:name = substitute(l:name, '- ', '', "g")
    let l:name = substitute(l:name, '* ', '', "g")
    " let l:name = substitute(l:name, ' ', '', "g")
    let l:name = substitute(l:name, '^\s*', '', "g")
    return l:name
endfunc

func! s:GetLineIndentLevel(lineBuffer)
    let l:indentCount = 4
    let result = -1 
    let N = strlen(a:lineBuffer)
    if N > 0
        let i = 0
        let blankNum = 0
        while i < N
            let ch = strpart(a:lineBuffer, i, 1)
            if ch == ' '
                let blankNum += 1
            else
                break
            endif
            let i += 1
        endwhile
        let result = blankNum / l:indentCount
    endif
    return result
endfunc


func! s:DeleteMdByLink()
    let l:lineBuffer = getline('.')
    let l:localLink = substitute(l:lineBuffer, '.*\](\(.*\)\.\(html\|md\)).*', '\1.md', "g")    " 将链接中的.html改为.md.
    " echo l:localLink
    let l:hasLink = match(l:localLink, '.\+\.\(html\|md\)')                                     " 匹配是否存在.html...
    if l:hasLink == 0                                                                   " ...如果存在才跳转
        " 检测目标文件所在文件夹是否存在, 如果不存在则创建
        let l:localLinkDir=fnamemodify(l:localLink, ':h')
        let l:localLinkDirExist = isdirectory(l:localLinkDir)
        if !l:localLinkDirExist
            call mkdir(l:localLinkDir, "p")
        endif

        " exec "e ".l:localLink 
        let dir=expand("%:p:h")
        let l:mdFile = dir.'/'.l:localLink
        if filereadable(l:mdFile)
             call inputsave()
             let confirmDelete = input("Delete ".l:mdFile." (y/n):")
             call inputrestore()
             if confirmDelete == 'y'
                 call delete(l:mdFile)
                 echo " -- Deleted"
             else
                 echo " -- Canceled"
             endif
        else
            echo l:mdFile." not found"
        endif
    endif
endfunc
