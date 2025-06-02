local M = {}

function M.complete_text()
	local bufnr = vim.api.nvim_get_current_buf()
	if not vim.bo[bufnr].modifiable then
		vim.api.nvim_echo({ { "No file open to complete.", "WarningMsg" } }, false, {})
		return
	end
	local initialLines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	local text = table.concat(initialLines, "\n")
	-- local config = { delimiter = "===" }
	local partial = ""

	local function on_stdout(job_id, data, event)
		for _, line in ipairs(data) do
			if line ~= "" then
				local ok, msg = pcall(vim.fn.json_decode, line)
				if ok and msg.chunk then
					partial = partial .. msg.chunk
					local lines = vim.split(partial, "\n", { plain = true })
					local last = table.remove(lines)
					local last_line_num = vim.api.nvim_buf_line_count(bufnr) - 1
					if #lines > 0 then
						-- Append all complete lines
						vim.api.nvim_buf_set_lines(
							bufnr,
							last_line_num,
							last_line_num + 1,
							false,
							{
								(vim.api.nvim_buf_get_lines(bufnr, last_line_num, last_line_num + 1, false)[1] or "")
									.. lines[1],
							}
						)
						if #lines > 1 then
							vim.api.nvim_buf_set_lines(
								bufnr,
								last_line_num + 1,
								last_line_num + 1,
								false,
								{ unpack(lines, 2) }
							)
						end
						last_line_num = vim.api.nvim_buf_line_count(bufnr) - 1
					end
					-- Update the last (possibly partial) line
					if last ~= nil then
						vim.api.nvim_buf_set_lines(bufnr, last_line_num, last_line_num + 1, false, { last })
					end
					partial = last or ""
				elseif ok and msg.done then
					-- Flush any remaining partial line
					if partial ~= "" then
						local last_line_num = vim.api.nvim_buf_line_count(bufnr) - 1
						vim.api.nvim_buf_set_lines(bufnr, last_line_num, last_line_num + 1, false, { partial })
						partial = ""
					end
					vim.api.nvim_echo({ { "[Streaming complete]", "Normal" } }, false, {})
				end
			end
		end
	end

	local plugin_dir = debug.getinfo(1, "S").source:sub(2):match("(.*/)")
	local stream_js_path = plugin_dir .. "../stream.js"

	local job_id = vim.fn.jobstart({ "node", stream_js_path }, {
		on_stdout = on_stdout,
		on_stderr = function(job_id, data, event)
			for _, line in ipairs(data) do
				if line ~= "" then
					vim.api.nvim_echo({ { "[Error] " .. line, "ErrorMsg" } }, false, {})
				end
			end
		end,

		stdout_buffered = false,
	})

	local payload = {
		method = "complete",
		params = {
			text = text,
			-- config = config,
		},
	}
	vim.fn.chansend(job_id, vim.fn.json_encode(payload) .. "\n")
end

vim.api.nvim_create_user_command("ChatVimComplete", function()
	require("chatvim").complete_text()
end, {})

return M
