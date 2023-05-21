if exists("b:current_syntax")
	syntax clear
endif


syn match blameHash		'^[a-fA-F0-9]\+'
syn match blameAuthor	' [a-zA-Z0-9_-]\+'
syn match blameTime		' [0-9-]\+'

highlight default blameHash		ctermfg=3
highlight default blameAuthor	ctermfg=4
highlight default blameTime		ctermfg=15
