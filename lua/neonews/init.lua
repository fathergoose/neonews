local fn = vim.fn
local neonews = {}
local runtime_path = os.getenv("VIMRUNTIME")
local defaults = {
	data_file = fn.stdpath("data") .. "/news_last_read",
	news_file = runtime_path .. "/doc/news.txt",
	datetime_format = "%Y-%m-%d %H:%M",
	startup_message = false,
	check_on_startup = true,
	unread_news_strategy = "mtime", -- or "sha256"
	display = "float", -- "vsplit" or "split"
}
function neonews.setup(opts)
	neonews.config = (opts and vim.tbl_deep_extend("force", defaults, opts)) or defaults
end

function neonews.draw_window()
	if neonews.config.display == "split" then
		vim.cmd("rightbelow split help news | exec '40wincmd|'")
	elseif neonews.config.display == "vsplit" then
		vim.cmd("rightbelow vert help news | exec '82wincmd|'")
	elseif neonews.config.display == "float" then
		local buf = vim.api.nvim_create_buf(false, true)
		local width = vim.api.nvim_get_option("columns")
		local height = vim.api.nvim_get_option("lines")

		local win_height = math.ceil(height * 0.8 - 4)
		local win_width = 82
        print(win_width)

		local row = math.ceil((height - win_height) / 2 - 1)
		local col = math.ceil((width - win_width) / 2)
		local win = vim.api.nvim_open_win(buf, true, {
			relative = "editor",
			height = win_height,
			width = win_width,
			row = row,
			col = col,
			style = "minimal",
			border = "rounded",
		})
		vim.api.nvim_buf_set_option(buf, "buftype", "help")
		vim.api.nvim_win_set_option(win, "foldmethod", "manual")
		vim.api.nvim_buf_set_option(buf, "tabstop", 8)
		vim.api.nvim_win_set_option(win, "arabic", false)
		vim.api.nvim_buf_set_option(buf, "binary", false)
		vim.api.nvim_buf_set_option(buf, "buflisted", false)
		vim.api.nvim_win_set_option(win, "cursorbind", false) -- Local to window
		vim.api.nvim_win_set_option(win, "diff", false)
		vim.api.nvim_win_set_option(win, "foldenable", false)
		vim.api.nvim_win_set_option(win, "list", false)
		vim.api.nvim_buf_set_option(buf, "modifiable", true)
		vim.api.nvim_win_set_option(win, "number", false)
		vim.api.nvim_win_set_option(win, "relativenumber", false)
		vim.api.nvim_win_set_option(win, "rightleft", false)
		vim.api.nvim_win_set_option(win, "scrollbind", false)
		vim.api.nvim_win_set_option(win, "spell", false)
		vim.api.nvim_win_set_option(win, "scl", "yes:1")
		vim.api.nvim_win_set_buf(win, buf)
		vim.api.nvim_command("view" .. neonews.config.news_file)
		vim.api.nvim_buf_set_option(buf, "modifiable", false)
		vim.api.nvim_buf_set_option(buf, "filetype", "help")
		vim.api.nvim_buf_set_option(buf, "syntax", "help")
	else
		error("Invalid display option: " .. neonews.config.display)
	end
end

function neonews.read_news()
	neonews.draw_window()
	local hash = fn.sha256(fn.join(fn.readfile(neonews.config.news_file)))
	local now = fn.strftime("%s")
	local result = fn.writefile({
		"mtime " .. now,
		"sha256 " .. hash,
	}, neonews.config.data_file)
	if result ~= 0 then
		vim.notify("Failed to write news last read file", vim.log.levels.ERROR)
	end
end

function neonews.mark_news_unread()
	fn.writefile({ "" }, neonews.config.data_file)
end

function neonews.check_news(quiet)
	if quiet == nil then
		quiet = false
	end
	local cfg = neonews.config
	local news_updated_at = fn.getftime(cfg.news_file)
	local last_hash = fn.split(fn.readfile(cfg.data_file, "", 2)[2])[2]

	if fn.filereadable(cfg.data_file) == 1 then
		if cfg.unread_news_strategy == "mtime" then
			local last_read_at = fn.split(fn.readfile(cfg.data_file, "", 1)[1])[2]
			if last_read_at == nil or last_read_at < news_updated_at then
				neonews.read_news()
			else
				if not quiet and (news_updated_at ~= nil) then
					local last_read_friendly = vim.fn.strftime(cfg.datetime_format, last_read_at)
					local news_updated_at_friendly = vim.fn.strftime(cfg.datetime_format, news_updated_at)
					local message = "No new news since "
						.. news_updated_at_friendly
						.. "; last read at "
						.. last_read_friendly
					vim.notify(message, vim.log.levels.INFO)
				end
			end
		else -- cfg.unread_news_strategy == "sha256"
			local latest_hash = fn.sha256(fn.join(fn.readfile(cfg.news_file)))
			if last_hash ~= latest_hash then
				neonews.read_news()
			else
				if not quiet and (news_updated_at ~= nil) then
					local message = "No changes to news.txt since last checked - sha256: " .. last_hash
					vim.notify(message, vim.log.levels.INFO)
				end
			end
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
