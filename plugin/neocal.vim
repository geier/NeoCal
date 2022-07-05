" plugin/whid.vim
if exists('g:loaded_neocal') | finish | endif

let s:save_cpo = &cpo
set cpo&vim

hi def link NeoCalHeader      Number
hi def link NeoCalSubHeader   Identifier

command! NeoCal lua require'neocal'.neocal()

let &cpo = s:save_cpo
unlet s:save_cpo

let g:loaded_neocal = 1
