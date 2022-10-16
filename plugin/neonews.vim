" Title: neonews
" Description: A plugin to manage todos from neovim.
" Last Change: 16 October, 2022
" Maintainer: Al Ilseman <https://github.com/fathergoose>

if exists("g:loaded_neonews")
  finish
endif
let g:loaded_neonews = 1

command! ReadNews lua require'neonews'.read_news()
command! UnreadNews lua require'neonews'.mark_news_unread()
command! CheckNews lua require'neonews'.check_news()

