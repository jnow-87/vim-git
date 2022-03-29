if exists('g:loaded_git') || &diff || &compatible
	finish
endif

let g:loaded_git = 1


""""
"" configuration variables
""""

"{{{
let g:git_blame_win_title = get(g:, "git_blame_win_title", "blame")
"}}}


""""
"" commands
""""

"{{{
command GitBlame call git#blame#file()
command GitBlameLine call git#blame#line()
"}}}
