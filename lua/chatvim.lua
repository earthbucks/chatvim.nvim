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

return M
