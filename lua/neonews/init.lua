local neonews = {}
local defaults = {
	data_file = vim.fn.stdpath("data") .. "/news_last_read",
	news_file = "$VIMRUNTIME/doc/news.txt",
    -- TODO: Confirm this works without alpha.nvim
    check_on_startup = false,
}
function neonews.setup(opts)
	neonews.config = opts and vim.tbl_deep_extend("force", defaults, opts) or defaults
	if neonews.config.check_on_startup then
		neonews.check_news()
	end
end

function neonews.read_news()
	vim.cmd("leftabove vert help news | exec '82wincmd|'")
	local now = vim.fn.strftime("%s")
	vim.fn.writefile({ now }, neonews.config.data_file)
end

function neonews.mark_news_unread()
	vim.fn.writefile({ "" }, neonews.config.data_file)
end

function neonews.check_news()
	local news_updated_at = vim.fn.getftime(neonews.config.news_file)
	if vim.fn.filereadable(neonews.config.data_file) == 1 then
		local last_read = tonumber(vim.fn.readfile(neonews.config.data_file)[1])
		if last_read == nil or news_updated_at > last_read then
			neonews.read_news()
		end
	else
		vim.cmd("e " .. neonews.config.data_file)
		vim.cmd("w | bw")
		neonews.read_news()
	end
end


return neonews
