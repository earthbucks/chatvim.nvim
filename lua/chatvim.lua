local spinner = {
  frames = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" },
  index = 1,
  active = false,
  buf = nil,
  win = nil,
  timer = nil,
}

-- Store job_id and session globally to allow stopping
local current_job_id = nil
local current_session = nil

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
      update_timer = nil,
    }, self)
  end

  function CompletionSession:append_chunk(chunk)
    self.partial = self.partial .. chunk

    -- Only schedule a buffer update if there isn't already a timer running
    if not self.update_timer then
      self.update_timer = vim.loop.new_timer()
      self.update_timer:start(
        100,
        0,
        vim.schedule_wrap(function()
          -- Process the accumulated content
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
            self.first_chunk = false
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

          -- Clean up the timer
          if self.update_timer then
            self.update_timer:stop()
            self.update_timer:close()
            self.update_timer = nil
          end
        end)
      )
    end

    return self.partial
  end

  function CompletionSession:finalize()
    -- Stop any pending timer to ensure updates are applied immediately
    if self.update_timer then
      self.update_timer:stop()
      self.update_timer:close()
      self.update_timer = nil
    end
    -- Write any remaining buffered content when the process ends, using the same newline handling logic
    if self.partial ~= "" then
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
        self.first_chunk = false
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

      -- Reset partial after finalizing
      self.partial = ""
    end
    vim.api.nvim_echo({ { "[Streaming complete]", "Normal" } }, false, {})
  end

  local bufnr = vim.api.nvim_get_current_buf()
  if not vim.bo[bufnr].modifiable then
    vim.api.nvim_echo({ { "No file open to complete.", "WarningMsg" } }, false, {})
    return
  end

  -- If a job is already running, stop it before starting a new one
  if current_job_id then
    vim.api.nvim_echo({ { "[Warning: Stopping existing completion process]", "WarningMsg" } }, false, {})
    vim.fn.jobstop(current_job_id)
    -- Cleanup will happen via on_exit or ChatVimStop
  end

  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local orig_last_line = lines[#lines] or ""
  local orig_line_count = #lines
  local session = CompletionSession:new(bufnr, orig_last_line, orig_line_count)
  current_session = session -- Store session for potential cleanup

  local function on_stdout(_, data, _)
    vim.schedule(function()
      for _, line in ipairs(data) do
        if line ~= "" then
          local ok, msg = pcall(vim.fn.json_decode, line)
          if ok and msg and type(msg) == "table" and msg.chunk ~= nil and msg.chunk ~= "" then
            session.partial = session:append_chunk(msg.chunk)
          end
        end
      end
    end)
  end

  local function on_stderr(_, data, _)
    vim.schedule(function()
      for _, line in ipairs(data) do
        if line ~= "" then
          vim.api.nvim_echo({ { "[Error] " .. line, "ErrorMsg" } }, false, {})
        end
      end
    end)
  end

  spinner.active = true
  open_spinner_window()

  local function on_exit(_, code, _)
    vim.schedule(function()
      session:finalize()
      spinner.active = false
      if spinner.timer then
        spinner.timer:stop()
        spinner.timer = nil
      end
      close_spinner_window()
      current_job_id = nil
      current_session = nil
      if code ~= 0 then
        vim.api.nvim_echo({ { "[Process exited with error code " .. code .. "]", "ErrorMsg" } }, false, {})
      end
    end)
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

  local job_id = vim.fn.jobstart({ "node", stream_js_path, "prompt", "--chunk", "--add-delimiters" }, {
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

    close_spinner_window()
    current_job_id = nil
    current_session = nil
    return
  end

  -- Store the job_id for stopping later
  current_job_id = job_id

  -- local payload = {
  --   method = "complete",
  --   params = { text = table.concat(lines, "\n") },
  -- }
  -- vim.fn.chansend(job_id, vim.fn.json_encode(payload) .. "\n")
  vim.fn.chansend(job_id, table.concat(lines, "\n"))
  vim.fn.chanclose(job_id, "stdin")
end

function M.stop_completion()
  if not current_job_id then
    vim.api.nvim_echo({ { "[Info: No completion process running]", "Normal" } }, false, {})
    return
  end

  -- Stop the running job
  vim.fn.jobstop(current_job_id)
  vim.api.nvim_echo({ { "[Info: Completion process stopped]", "Normal" } }, false, {})

  -- Finalize the session if it exists
  if current_session then
    current_session:finalize()
    current_session = nil
  end

  -- Cleanup spinner and timer
  spinner.active = false
  if spinner.timer then
    spinner.timer:stop()
    spinner.timer = nil
  end
  close_spinner_window()

  -- Clear stored job_id
  current_job_id = nil
end

vim.api.nvim_create_user_command("ChatVimComplete", function()
  require("chatvim").complete_text()
end, {})

vim.api.nvim_create_user_command("ChatVimStop", function()
  require("chatvim").stop_completion()
end, {})

return M
