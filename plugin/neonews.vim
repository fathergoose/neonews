" Title: neonews
" Description: A plugin to manage todos from neovim.
" Last Change: 16 October, 2022
" Maintainer: Al Ilseman <https://github.com/fathergoose>

if exists("g:loaded_neonews")
  finish
endif
let g:loaded_neonews = 1

command! NNewsRead lua require'neonews'.read_news()
command! NNewsMarkUnread lua require'neonews'.mark_news_unread()

lua << EOF
vim.api.nvim_create_user_command("NNewsCheck", function(params)
	if (params.args == "false") or (params.args == "0") or (params.args == "quiet") or (params.args == "q") then
		require("neonews").check_news(true)
	else
		require("neonews").check_news()
	end
end, { nargs = "?" })
EOF
