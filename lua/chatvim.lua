local M = {}

function M.complete_text()
  local CompletionSession = {}
  CompletionSession.__index = CompletionSession

  function CompletionSession:new(bufnr, orig_last_line, orig_line_count)
    return setmetatable({
      bufnr = bufnr,
      orig_last_line = orig_last_line,
      orig_line_count = orig_line_count,
      first_chunk = true,
      partial = "",
    }, self)
  end

  function CompletionSession:append_chunk(chunk)
    local lines = vim.split(chunk, "\n", { plain = true })
    local last_line_num = vim.api.nvim_buf_line_count(self.bufnr) - 1

    if #lines == 1 then
      vim.api.nvim_buf_set_lines(self.bufnr, last_line_num, last_line_num + 1, false, { lines[1] })
      return lines[1]
    end

    if self.first_chunk
      and self.orig_last_line ~= ""
      and self.orig_last_line == vim.api.nvim_buf_get_lines(self.bufnr, self.orig_line_count - 1, self.orig_line_count, false)[1]
    then
      vim.api.nvim_buf_set_lines(self.bufnr, self.orig_line_count - 1, self.orig_line_count, false, { self.orig_last_line .. lines[1] })
    else
      vim.api.nvim_buf_set_lines(self.bufnr, last_line_num, last_line_num + 1, false, { lines[1] })
    end

    if #lines > 2 then
      vim.api.nvim_buf_set_lines(self.bufnr, last_line_num + 1, last_line_num + 1, false, { unpack(lines, 2, #lines - 1) })
    end

    vim.api.nvim_buf_set_lines(
      self.bufnr,
      last_line_num + (#lines - 1),
      last_line_num + (#lines - 1) + 1,
      false,
      { lines[#lines] }
    )
    return lines[#lines]
  end

  local bufnr = vim.api.nvim_get_current_buf()
  if not vim.bo[bufnr].modifiable then
    vim.api.nvim_echo({ { "No file open to complete.", "WarningMsg" } }, false, {})
    return
  end

  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local orig_last_line = lines[#lines] or ""
  local orig_line_count = #lines
  local session = CompletionSession:new(bufnr, orig_last_line, orig_line_count)

  local function on_stdout(_, data, _)
    for _, line in ipairs(data) do
      if line ~= "" then
        local ok, msg = pcall(vim.fn.json_decode, line)
        if ok and msg.chunk then
          session.partial = session.partial .. msg.chunk
          session.partial = session:append_chunk(session.partial)
          session.first_chunk = false
        elseif ok and msg.done then
          if session.partial ~= "" then
            local last_line_num = vim.api.nvim_buf_line_count(session.bufnr) - 1
            vim.api.nvim_buf_set_lines(session.bufnr, last_line_num, last_line_num + 1, false, { session.partial })
            session.partial = ""
          end
          vim.api.nvim_echo({ { "[Streaming complete]", "Normal" } }, false, {})
        end
      end
    end
  end

  local function on_stderr(_, data, _)
    for _, line in ipairs(data) do
      if line ~= "" then
        vim.api.nvim_echo({ { "[Error] " .. line, "ErrorMsg" } }, false, {})
      end
    end
  end

  local plugin_dir = debug.getinfo(1, "S").source:sub(2):match("(.*/)")
  local stream_js_path = plugin_dir .. "../stream.js"

  local job_id = vim.fn.jobstart({ "node", stream_js_path }, {
    on_stdout = on_stdout,
    on_stderr = on_stderr,
    stdout_buffered = false,
  })

  local payload = {
    method = "complete",
    params = { text = table.concat(lines, "\n") },
  }
  vim.fn.chansend(job_id, vim.fn.json_encode(payload) .. "\n")
end

vim.api.nvim_create_user_command("ChatVimComplete", function()
  require("chatvim").complete_text()
end, {})

return M
