local M = {}

function M.complete_text()
  local bufnr = vim.api.nvim_get_current_buf()
  if not vim.bo[bufnr].modifiable then
    vim.api.nvim_echo({ { "No file open to complete.", "WarningMsg" } }, false, {})
    return
  end

  local initialLines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local text = table.concat(initialLines, "\n")
  local orig_last_line = initialLines[#initialLines] or ""
  local orig_line_count = #initialLines
  local first_chunk = true

  local partial = ""

  -- Appends a chunk (which may contain newlines) to the end of the buffer.
  -- Neovim buffers are line-based, so you cannot insert a string with embedded
  -- newlines directly. This function splits the chunk on '\n' and appends each
  -- segment as a separate line.
  local function append_chunk_to_buffer(bufnr, chunk, opts)
    opts = opts or {}
    local orig_last_line = opts.orig_last_line
    local orig_line_count = opts.orig_line_count
    local first_chunk = opts.first_chunk

    local lines = vim.split(chunk, "\n", { plain = true })
    local last_line_num = vim.api.nvim_buf_line_count(bufnr) - 1

    if #lines == 1 then
      -- Only a partial line, update last line
      vim.api.nvim_buf_set_lines(bufnr, last_line_num, last_line_num + 1, false, { lines[1] })
      return lines[1]
    else
      -- On first chunk, if original input does not end with newline, append to last line
      if
        first_chunk
        and orig_last_line ~= ""
        and orig_last_line
          == vim.api.nvim_buf_get_lines(bufnr, orig_line_count - 1, orig_line_count, false)[1]
      then
        vim.api.nvim_buf_set_lines(
          bufnr,
          orig_line_count - 1,
          orig_line_count,
          false,
          { orig_last_line .. lines[1] }
        )
      else
        vim.api.nvim_buf_set_lines(bufnr, last_line_num, last_line_num + 1, false, { lines[1] })
      end
      -- Insert all complete lines except the first and last
      if #lines > 2 then
        vim.api.nvim_buf_set_lines(
          bufnr,
          last_line_num + 1,
          last_line_num + 1,
          false,
          { unpack(lines, 2, #lines - 1) }
        )
      end
      -- Add a new line for the last segment (partial or empty)
      vim.api.nvim_buf_set_lines(
        bufnr,
        last_line_num + (#lines - 1),
        last_line_num + (#lines - 1) + 1,
        false,
        { lines[#lines] }
      )
      return lines[#lines]
    end
  end

  local function on_stdout(job_id, data, event)
    for _, line in ipairs(data) do
      if line ~= "" then
        local ok, msg = pcall(vim.fn.json_decode, line)
        if ok and msg.chunk then
          partial = partial .. msg.chunk
          partial = append_chunk_to_buffer(bufnr, partial, {
            orig_last_line = orig_last_line,
            orig_line_count = orig_line_count,
            first_chunk = first_chunk,
          })
          first_chunk = false
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
    },
  }
  vim.fn.chansend(job_id, vim.fn.json_encode(payload) .. "\n")
end

vim.api.nvim_create_user_command("ChatVimComplete", function()
  require("chatvim").complete_text()
end, {})

return M
