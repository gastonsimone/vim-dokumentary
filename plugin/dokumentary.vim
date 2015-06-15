" dokumentary.vim - Improve what K does
" Author: Gastón Simone

if exists("g:loaded_dokumentary") || &cp
	finish
endif
let g:loaded_dokumentary = 1

" Configuration {{{1
if !exists('g:dokumentary_open')
	let g:dokumentary_open = 'rightbelow vnew'
endif
" }}}1

" Auxiliary functions {{{1
function! s:get_selected_text()
	let l:aux = @z
	normal! gv"zy
	let l:text = @z
	let @z = l:aux
	let l:text = substitute(l:text, '\\(.\\{-}\\)\\n.*', '\\1', '')
	return l:text
endfunction

function! s:get_keyword(visual)
	if a:visual
		return s:get_selected_text()
	else
		return expand('<cword>')
	endif
endfunction " }}}1

" Define a system dictionary as the default search {{{1
function! s:dict(visual)
	let l:keyword = shellescape(s:get_keyword(a:visual))
	if has('mac')
		" Use Mac OS X Dictionary app for keyword search by default
		silent let l:dokumentary_null = system('open dict://' . l:keyword)
	elseif has('unix')
		" Use command-line dictionary tools if available
		if len(system('which dict')) > 0
			call s:output_to_window(l:keyword, a:visual, 1, "dict")
		elseif len(system('which sdvc')) > 0
			call s:output_to_window(l:keyword, a:visual, 1, "sdvc")
		else
			echo "No dictionary program found."
		endif
	else
		echo "Dokumentary: Dictionary only supported on mac and unix."
	endif
endfunction

nnoremap <silent> K :call <SID>dict(0)<CR>
vnoremap <silent> K :call <SID>dict(1)<CR>

" }}}1

" External documentation programs {{{1

" Key: filetype, Value: command
let s:default_dokumentary_docprgs = {}
let s:default_dokumentary_docprgs["man"]      = "man {0} | col -b"
let s:default_dokumentary_docprgs["c"]        = "man {0} | col -b"
let s:default_dokumentary_docprgs["cpp"]      = "man {0} | col -b"
let s:default_dokumentary_docprgs["make"]     = "man {0} | col -b"
let s:default_dokumentary_docprgs["yacc"]     = "man {0} | col -b"
let s:default_dokumentary_docprgs["sh"]       = "man {0} | col -b"
let s:default_dokumentary_docprgs["python"]   = "pydoc {0}"
let s:default_dokumentary_docprgs["go"]       = "godoc {0}"
let s:default_dokumentary_docprgs["perl"]     = "perldoc -f {0}"
let s:default_dokumentary_docprgs["plaintex"] = "texdoc -I -M -q {0}"
let s:default_dokumentary_docprgs["tex"]      = "texdoc -I -M -q {0}"
let s:default_dokumentary_docprgs["dict"]     = "dict {0}"
let s:default_dokumentary_docprgs["sdvc"]     = "sdvc {0}"

if !exists('g:dokumentary_docprgs')
	let g:dokumentary_docprgs = {}
endif

call extend(g:dokumentary_docprgs, s:default_dokumentary_docprgs, "keep")

" }}}1

function! s:output_to_window(given_keyword, visual, newwindow, type) " {{{1
	if !empty(a:given_keyword)
		let l:keyword = a:given_keyword
	else
		let l:keyword = shellescape(s:get_keyword(a:visual))
	endif

	let l:prg = g:dokumentary_docprgs[a:type]

	if !empty(l:keyword) && executable(split(l:prg)[0])
		if a:newwindow
			if exists('g:dokumentary_open') && !empty(g:dokumentary_open)
				execute g:dokumentary_open
			else
				rightbelow 84vnew
			endif
			setlocal buftype=nofile
			set bufhidden=delete
		else
			0,$d
		endif

		let b:dokumentary_filetype = a:type

		let l:prgaux = substitute(l:prg, "{0}", l:keyword, "g")
		silent execute "read !" . l:prgaux
		0

		nnoremap <buffer> K :call <SID>output_to_window('', 0, 0, b:dokumentary_filetype)<CR>
		vnoremap <buffer> K :call <SID>output_to_window('', 1, 0, b:dokumentary_filetype)<CR>

		nnoremap <silent> <buffer> <RightMouse> <LeftMouse>:call <SID>output_to_window('', 0, 0, b:dokumentary_ftype)<CR>
		vnoremap <silent> <buffer> <RightMouse> :call <SID>output_to_window('', 1, 0, b:dokumentary_ftype)<CR>
	else
		echo "Dokumentary: Nothing to search."
	endif
endfunction " }}}1

function! s:open_man_page(visual, newwindow) " {{{1
	let l:expr = s:get_keyword(a:visual)

	" Matches man-page reference. Example: printf(3)
	let l:mansectionpattern = '\([a-zA-Z0-9_\-./]\+\)\((\([1-8]\))\)\?\([.,:;]\)\?'

	if match(l:expr, l:mansectionpattern) >= 0
		let l:name = substitute(l:expr, l:mansectionpattern, "\\1", "")
		let l:section = substitute(l:expr, l:mansectionpattern, "\\3", "")
	else
		let l:name = expand("<cword>")
		let l:section = ''
	endif

	let l:keyword = substitute(l:section . " " . l:name, "\s*\(.*\)", "\\1", "")

	if exists("g:dokumentary_man2html") && g:dokumentary_man2html && len(system('which man2html')) > 0
		let l:tmpfile = tempname() . '_' . l:keyword . '.html'
		silent execute '!man ' . l:keyword . ' | man2html > ' . l:tmpfile
		silent execute '!open ' . l:tmpfile
	else
		call s:output_to_window(l:keyword, a:visual, a:newwindow, "man")
	endif
endfunction " }}}1

function! s:add_doc_prg(ftype, prg) " {{{1
	if a:prg == "''"
		let l:prg = ''
	else
		let l:prg = a:prg
	endif
	let g:dokumentary_docprgs[a:ftype] = l:prg
	execute 'augroup dokumentary_' . a:ftype
	au!
	if !empty(l:prg)
		if l:prg =~# '^man '
			execute 'autocmd FileType ' . a:ftype . ' nnoremap <silent> <buffer> K :call <SID>open_man_page(0, 1)<CR>'
			execute 'autocmd FileType ' . a:ftype . ' vnoremap <silent> <buffer> K :call <SID>open_man_page(1, 1)<CR>'
		else
			execute 'autocmd FileType ' . a:ftype . ' nnoremap <silent> <buffer> K :call <SID>output_to_window("", 0, 1, "' . a:ftype . '")<CR>'
			execute 'autocmd FileType ' . a:ftype . ' vnoremap <silent> <buffer> K :call <SID>output_to_window("", 1, 1, "' . a:ftype . '")<CR>'
		endif
	endif
	augroup END
endfunction " }}}1

" Public commands {{{1
command! -nargs=+ Dokument call <SID>add_doc_prg(<f-args>)
" }}}1

" Mappings for each file type {{{1

for [ftype, prg] in items(g:dokumentary_docprgs)
	if !empty(prg)
		execute 'Dokument ' . ftype . ' ' . escape(prg, ' \')
	endif
endfor

" Special case for vim help
augroup dokumentary_vim
	au!
	autocmd FileType vim  nnoremap <silent> <buffer> K :execute ":help " . expand("<cword>")<CR>
	autocmd FileType help nnoremap <silent> <buffer> K :execute ":help " . expand("<cword>")<CR>
augroup END

" }}}1

" vim:ft=vim foldmethod=marker
