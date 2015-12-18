""" Reswin plugin file

if exists('g:loaded_reswin')
  finish
endif
let g:loaded_reswin = 1

""""""""""""""""""""""
" Commands
""""""""""""""""""""""
" {{{
command! -range -nargs=+ -complete=shellcmd ReswinShell <line1>,<line2>call g:reswin#Shell(<q-args>)
command! -nargs=+ -complete=expression ReswinEval call g:reswin#Eval(<q-args>)
command! -nargs=+ -complete=command ReswinCommand call g:reswin#Command(<q-args>)
" }}}

" vim:foldmethod=marker:foldmarker={{{,}}}:foldlevel=99
