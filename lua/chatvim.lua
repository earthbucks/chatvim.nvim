local M = {}

function M.hello()
	vim.api.nvim_echo({ { "Hello world from chatvim.nvim!", "Normal" } }, false, {})
end

function M.hello_node()
	local input = "from Lua"
	local output = vim.fn.system({ "node", "/Users/ryan/dev/chatvim.nvim/hello.js", input })
	vim.api.nvim_echo({ { output, "Normal" } }, false, {})
end

-- local function on_stdout(job_id, data, event)
-- 	for _, line in ipairs(data) do
-- 		if line ~= "" then
-- 			local ok, msg = pcall(vim.fn.json_decode, line)
-- 			if ok and msg.chunk then
-- 				vim.api.nvim_echo({ { msg.chunk, "Normal" } }, false, {})
-- 			elseif ok and msg.done then
-- 				vim.api.nvim_echo({ { "\n[Streaming complete]\n", "Normal" } }, false, {})
-- 			end
-- 		end
-- 	end
-- end

-- function M.stream_example()
-- 	local job_id = vim.fn.jobstart({ "node", "/Users/ryan/dev/chatvim.nvim/stream.js" }, {
-- 		on_stdout = on_stdout,
-- 		stdout_buffered = false,
-- 	})
-- 	-- Send a JSON request to the Node.js process
-- 	vim.fn.chansend(job_id, vim.fn.json_encode({ method = "stream", params = {} }) .. "\n")
-- end

function M.complete_markdown()
	local bufnr = vim.api.nvim_get_current_buf()
	if not vim.api.nvim_buf_get_option(bufnr, "modifiable") then
		vim.api.nvim_echo({ { "No file open to complete.", "WarningMsg" } }, false, {})
		return
	end
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	local text = table.concat(lines, "\n")
	local config = { delimiter = "===" }

	local function on_stdout(job_id, data, event)
		for _, line in ipairs(data) do
			if line ~= "" then
				local ok, msg = pcall(vim.fn.json_decode, line)
				if ok and msg.chunk then
					local last_line = vim.api.nvim_buf_line_count(bufnr)
					local lines_to_insert = vim.split(msg.chunk, "\n", { plain = true, trimempty = true })
					vim.api.nvim_buf_set_lines(bufnr, last_line, last_line, false, lines_to_insert)
				elseif ok and msg.done then
					vim.api.nvim_echo({ { "[Streaming complete]", "Normal" } }, false, {})
				end
			end
		end
	end

	local job_id = vim.fn.jobstart({ "node", "/Users/ryan/dev/chatvim.nvim/stream.js" }, {
		on_stdout = on_stdout,
		stdout_buffered = false,
	})

	local payload = {
		method = "complete",
		params = {
			text = text,
			config = config,
		},
	}
	vim.fn.chansend(job_id, vim.fn.json_encode(payload) .. "\n")
end

vim.api.nvim_create_user_command("ChatVimComplete", function()
	require("chatvim").complete_markdown()
end, {})

return M
