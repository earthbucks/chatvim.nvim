local spinner = {
  frames = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" },
  index = 1,
  active = false,
  buf = nil,
  win = nil,
  timer = nil,
}

local function update_spinner()
  if not spinner.active or not spinner.buf or not spinner.win then
    return
  end
  spinner.index = spinner.index % #spinner.frames + 1
  vim.api.nvim_buf_set_lines(spinner.buf, 0, -1, false, { "Computing... " .. spinner.frames[spinner.index] })
end

local function open_spinner_window()
  local win = vim.api.nvim_get_current_win() -- Get the current window
  local win_config = vim.api.nvim_win_get_config(win)
  local width = win_config.width or vim.api.nvim_win_get_width(win)
  local height = win_config.height or vim.api.nvim_win_get_height(win)

  -- Calculate center position
  local spinner_width = 15 -- Width of the spinner window
  local spinner_height = 1 -- Height of the spinner window
  local col = math.floor((width - spinner_width) / 2) -- Center horizontally
  local row = math.floor((height - spinner_height) / 2) -- Center vertically

  spinner.buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(spinner.buf, 0, -1, false, { "Computing... " .. spinner.frames[1] })
  spinner.win = vim.api.nvim_open_win(spinner.buf, false, {
    relative = "win", -- Position relative to the current window
    win = win, -- Specify the current window
    width = spinner_width,
    height = spinner_height,
    col = col, -- Centered column
    row = row, -- Centered row
    style = "minimal",
    border = "single",
  })
end

local function close_spinner_window()
  if spinner.win then
    vim.api.nvim_win_close(spinner.win, true)
    spinner.win = nil
  end
  if spinner.buf then
    vim.api.nvim_buf_delete(spinner.buf, { force = true })
    spinner.buf = nil
  end
end

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
    self.partial = self.partial .. chunk
    local lines = vim.split(self.partial, "\n", { plain = true })
    local last_line_num = vim.api.nvim_buf_line_count(self.bufnr) - 1

    -- Handle the first chunk specially if needed
    if
      self.first_chunk
      and self.orig_last_line ~= ""
      and self.orig_last_line
        == vim.api.nvim_buf_get_lines(self.bufnr, self.orig_line_count - 1, self.orig_line_count, false)[1]
    then
      vim.api.nvim_buf_set_lines(
        self.bufnr,
        self.orig_line_count - 1,
        self.orig_line_count,
        false,
        { self.orig_last_line .. lines[1] }
      )
    else
      vim.api.nvim_buf_set_lines(self.bufnr, last_line_num, last_line_num + 1, false, { lines[1] })
    end

    -- Append any additional complete lines
    if #lines > 2 then
      vim.api.nvim_buf_set_lines(
        self.bufnr,
        last_line_num + 1,
        last_line_num + 1,
        false,
        { unpack(lines, 2, #lines - 1) }
      )
    end

    -- Keep the last (potentially incomplete) line in the buffer
    self.partial = lines[#lines]
    vim.api.nvim_buf_set_lines(
      self.bufnr,
      last_line_num + (#lines - 1),
      last_line_num + (#lines - 1) + 1,
      false,
      { self.partial }
    )

    -- Scroll to the last line to ensure new data is visible
    local win = vim.api.nvim_get_current_win()
    local last_line = vim.api.nvim_buf_line_count(self.bufnr)
    vim.api.nvim_win_set_cursor(win, { last_line, 0 })

    self.first_chunk = false
    return self.partial
  end

  function CompletionSession:finalize()
    -- Write any remaining buffered content when the process ends
    if self.partial ~= "" then
      local last_line_num = vim.api.nvim_buf_line_count(self.bufnr) - 1
      vim.api.nvim_buf_set_lines(self.bufnr, last_line_num, last_line_num + 1, false, { self.partial })
      self.partial = ""
    end
    vim.api.nvim_echo({ { "[Streaming complete]", "Normal" } }, false, {})
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
          session.partial = session:append_chunk(msg.chunk)
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

  -- Disable syntax highlighting to avoid lag during streaming
  vim.cmd("syntax off")

  spinner.active = true
  open_spinner_window()

  local function on_exit(_, code, _)
    session:finalize()
    spinner.active = false
    if spinner.timer then
      spinner.timer:stop()
      spinner.timer = nil
    end
    -- Re-enable syntax highlighting after the process ends
    vim.cmd("syntax on")
    close_spinner_window()
    if code ~= 0 then
      vim.api.nvim_echo({ { "[Process exited with error code " .. code .. "]", "ErrorMsg" } }, false, {})
    end
  end

  -- Start a timer to animate the spinner
  spinner.timer = vim.loop.new_timer()
  spinner.timer:start(
    0,
    80,
    vim.schedule_wrap(function()
      if spinner.active then
        update_spinner()
      else
        if spinner.timer then
          spinner.timer:stop()
          spinner.timer = nil
        end
      end
    end)
  )

  local plugin_dir = debug.getinfo(1, "S").source:sub(2):match("(.*/)")
  local stream_js_path = plugin_dir .. "../stream.js"

  local job_id = vim.fn.jobstart({ "node", stream_js_path }, {
    on_stdout = on_stdout,
    on_stderr = on_stderr,
    on_exit = on_exit,
    stdout_buffered = false,
  })

  if job_id <= 0 then
    vim.api.nvim_echo({ { "[Error: Failed to start job]", "ErrorMsg" } }, false, {})
    spinner.active = false
    if spinner.timer then
      spinner.timer:stop()
      spinner.timer = nil
    end
    -- Re-enable syntax highlighting after the process ends
    vim.cmd("syntax on")
    close_spinner_window()
    return
  end

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
