local M = {}

function M.hello()
	-- vim.api.nvim_out_write("Hello world from chatvim.nvim!\n")
	vim.api.nvim_echo({ { "Hello world from chatvim.nvim!", "Normal" } }, false, {})
end

function M.hello_node()
	local input = "from Lua"
	local output = vim.fn.system({ "node", "/Users/ryan/dev/chatvim.nvim/hello.js", input })
	-- vim.api.nvim_out_write(output .. "\n")
	vim.api.nvim_echo({ { output, "Normal" } }, false, {})
end

local function on_stdout(job_id, data, event)
	for _, line in ipairs(data) do
		if line ~= "" then
			local ok, msg = pcall(vim.fn.json_decode, line)
			if ok and msg.chunk then
				-- vim.api.nvim_out_write(msg.chunk)
				vim.api.nvim_echo({ { msg.chunk, "Normal" } }, false, {})
			elseif ok and msg.done then
				-- vim.api.nvim_out_write("\n[Streaming complete]\n")
				vim.api.nvim_echo({ { "\n[Streaming complete]\n", "Normal" } }, false, {})
			end
		end
	end
end

function M.stream_example()
	local job_id = vim.fn.jobstart({ "node", "/Users/ryan/dev/chatvim.nvim/stream.js" }, {
		on_stdout = on_stdout,
		stdout_buffered = false,
	})
	-- Send a JSON request to the Node.js process
	vim.fn.chansend(job_id, vim.fn.json_encode({ method = "stream", params = {} }) .. "\n")
end

return M
