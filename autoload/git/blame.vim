""""
"" local variables
""""

"{{{
let s:git_blame_bufnr = -1
let s:git_blame_linelen = 0
"}}}


""""
"" local functions
""""

"{{{
" \brief	git blame wrapper
"
" \param	file	file name to get blame info for
" \param	line	optional line number, if set blame info will only be
"					queried for the given line
"
" \return	list with the line-by-line git blame output
" 			on error an empty list is returned
function s:blame(file, line=-1)
	let l:cmd = "git blame"

	if a:line != -1
		let l:cmd .= " -L " . a:line . "," . a:line
	endif

	let l:cmd .= " " . a:file

	let l:output = systemlist(l:cmd)

	if v:shell_error != 0
		echohl Error
		echom join(l:output, " ")
		echohl None

		return []
	endif

	return l:output
endfunction
"}}}

"{{{
" \brief	parse a git blame output line
"
" \param	line	string with the line to parse
"
" \return	converted string
function s:parse_line(line)
	let l:hash = split(a:line, " ")[0]
	let l:lbrace = stridx(a:line, "(")
	let l:rbrace = stridx(a:line, ")")
	let l:info = split(a:line[l:lbrace + 1:l:rbrace])
	let l:author = l:info[0]
	let l:timestamp = join(l:info[1:-2], " ")

	return l:hash . " " . l:author . " " . l:timestamp
endfunction
"}}}

"{{{
" \brief	undo git blame configuration
function s:cleanup()
	" reset cursor- and scrollbind options
	call setbufvar(g:pair_bufnr, "&cursorbind", 0)
	call setbufvar(g:pair_bufnr, "&scrollbind", 0)

	" remove autocmds
	autocmd! GitBlame
endfunction
"}}}

"{{{
" \brief	load the git blame output to a buffer named g:git_blame_win_title
"
" \return	0 on success
" 			-1 otherwise
function s:buffer_load(file)
	let l:lines = s:blame(a:file)

	if len(l:lines) == 0
		return -1
	endif

	" create buffer
	let s:git_blame_bufnr = bufadd(g:git_blame_win_title)
	call bufload(s:git_blame_bufnr)

	" iterate blame info lines
	let l:i = 0

	for l:line in l:lines
		let l:line = s:parse_line(l:line)
		let s:git_blame_linelen = max([strlen(l:line), s:git_blame_linelen])

		call appendbufline(s:git_blame_bufnr, l:i, l:line)
		let l:i += 1
	endfor

	return 0
endfunction
"}}}

"{{{
" \brief	make the git blame buffer visible
" 			ensure to retain the cursor at the current file and line
function s:buffer_show(file)
	let l:pair_bufnr = bufnr()
	let l:line = line(".")

	" make buffer visible
	exec "leftabove " . s:git_blame_linelen . "vsplit"
	exec "edit " . g:git_blame_win_title

	" set buffer options
	setlocal filetype=gitblame
	setlocal noswapfile
	setlocal bufhidden=hide
	setlocal nowrap
	setlocal buftype=nofile
	setlocal nobuflisted
	setlocal colorcolumn=0
	setlocal nomodifiable
	setlocal nonumber
	setlocal bufhidden=wipe

	" remember original buffer
	let g:pair_bufnr = l:pair_bufnr

	" establish autocmds
	augroup GitBlame
	exec "autocmd BufWinLeave " . g:git_blame_win_title . " call s:cleanup()"
	exec "autocmd TabLeave * call s:buffer_destroy()"
	augroup End

	" set cursor- and scrollbind for the blame buffer and the original file
	setlocal cursorbind
	setlocal scrollbind
	call util#window#focus_file(a:file, l:line, 0)
	setlocal cursorbind
	setlocal scrollbind
endfunction
"}}}

"{{{
" \brief	remove the git blame buffer and cleanup configuration
function s:buffer_destroy()
	if bufexists(g:git_blame_win_title)
		call s:cleanup()
		exec "bdelete " . s:git_blame_bufnr
	endif
endfunction
"}}}


""""
"" global functions
""""

"{{{
" \brief	toggle git blame window
function git#blame#file()
	" cleanup existing git blame buffer
	if bufexists(g:git_blame_win_title)
		let l:winnr = bufwinnr(s:git_blame_bufnr)
		call s:buffer_destroy()

		" git blame window was visible and has been destroyed
		if l:winnr != -1
			return
		endif
	endif

	" show git blame info for file in current buffer
	let l:file = resolve(expand("%:p"))

	if s:buffer_load(l:file) != 0
		return
	endif

	call s:buffer_show(l:file)
endfunction
"}}}

"{{{
" \brief	show git blame info for file:line in current buffer
function git#blame#line()
	let l:file = resolve(expand("%:p"))
	let l:line = line(".")
	let l:output = s:blame(l:file, l:line)

	if len(l:output) > 0
		echo s:parse_line(l:output[0])
	endif
endfunction
"}}}
