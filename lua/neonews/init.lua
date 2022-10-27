local neonews = {}
local runtime_path = os.getenv("VIMRUNTIME")
local defaults = {
	data_file = vim.fn.stdpath("data") .. "/news_last_read",
	news_file = runtime_path .. "/doc/news.txt",
	datetime_format = "%Y-%m-%d %H:%M",
	startup_message = false,
	check_on_startup = true,
	split = "",
}
function neonews.setup(opts)
	neonews.config = (opts and vim.tbl_deep_extend("force", defaults, opts)) or defaults
end

function neonews.read_news()
	vim.cmd("rightbelow vert help news | exec '82wincmd|'")
	local now = vim.fn.strftime("%s")
	local result = vim.fn.writefile({ now }, neonews.config.data_file)
	if result ~= 0 then
		vim.notify("Failed to write news last read file", vim.log.levels.ERROR)
	end
end

function neonews.mark_news_unread()
	vim.fn.writefile({ "" }, neonews.config.data_file)
end

function neonews.check_news(quiet)
	if quiet == nil then
		quiet = false
	end
	local cfg = neonews.config
	local news_updated_at = vim.fn.getftime(cfg.news_file)
	if vim.fn.filereadable(cfg.data_file) == 1 then
		local contents = vim.fn.readfile(cfg.data_file)
		local last_read = tonumber(contents[1])
		if last_read == nil or news_updated_at > last_read then
			neonews.read_news()
		elseif (news_updated_at ~= nil) and not quiet then
			local last_read_friendly = vim.fn.strftime(cfg.datetime_format, last_read)
			local news_updated_at_friendly = vim.fn.strftime(cfg.datetime_format, news_updated_at)
			local message = "No new news since " .. news_updated_at_friendly .. "; last read at " .. last_read_friendly
			vim.notify(message, vim.log.levels.INFO)
		elseif news_updated_at == nil then
			vim.notify("Failed to get last update timestamp for " .. cfg.news_file, vim.log.levels.ERROR)
		end
	else
		vim.cmd("e " .. cfg.data_file)
		vim.cmd("w | bw")
		neonews.read_news()
	end
end

if neonews.config and neonews.config.check_on_startup then
	local augroup = vim.api.nvim_create_augroup("Neonews")
	vim.api.nvim_create_autocmd("VimEnter", {
		group = augroup,
		callback = function()
			if neonews.config.startup_message then
				neonews.check_news()
			else
				neonews.check_news(true)
			end
		end,
		once = true,
	})
end

return neonews
