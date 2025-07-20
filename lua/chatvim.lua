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
    -- Cleanup will happen via on_exit or ChatvimStop
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
          else
            -- error handling for unexpected messages
            vim.api.nvim_echo({ { "[Warning] Unexpected message: " .. line, "WarningMsg" } }, false, {})
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
  local stream_js_path = plugin_dir .. "../chatvim.ts"

  local job_id = vim.fn.jobstart({ "node", stream_js_path, "complete", "--chunk", "--add-delimiters" }, {
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

-- Function to open a new markdown buffer in a left-side split

local function open_chatvim_window(args)
  -- Generate a unique filename like "/path/to/cwd/chat-YYYY-MM-DD-HH-MM-SS.md"
  local filename = vim.fn.getcwd() .. "/chat-" .. os.date("%Y-%m-%d-%H-%M-%S") .. ".md"

  -- Determine window placement based on argument
  local placement = args.args or ""
  local split_cmd = ""

  if placement == "left" then
    split_cmd = "topleft vsplit"
  elseif placement == "right" then
    split_cmd = "botright vsplit"
  elseif placement == "top" then
    split_cmd = "topleft split"
  elseif placement == "bottom" or placement == "bot" then
    split_cmd = "botright split"
  end

  -- Open the split if specified
  if split_cmd ~= "" then
    vim.cmd(split_cmd)
  end

  -- Edit the new file in the target window (creates a new unsaved buffer with the filename)
  vim.cmd("edit " .. vim.fn.fnameescape(filename))

  -- Optional: Ensure filetype is markdown (usually auto-detected, but explicit for safety)
  vim.bo.filetype = "markdown"
end

-- Define a new command called 'ChatvimNew' with an optional argument
vim.api.nvim_create_user_command("ChatvimNew", open_chatvim_window, {
  nargs = "?", -- Accepts 0 or 1 argument
  desc = "Open a new markdown buffer, optionally in a left-side split (ChatvimNew [left])",
})

vim.api.nvim_create_user_command("ChatvimNewLeft", function()
  open_chatvim_window({ args = "left" })
end, { desc = "Open a new markdown buffer in a left-side split" })

vim.api.nvim_create_user_command("ChatvimNewRight", function()
  open_chatvim_window({ args = "right" })
end, { desc = "Open a new markdown buffer in a right-side split" })

vim.api.nvim_create_user_command("ChatvimNewTop", function()
  open_chatvim_window({ args = "top" })
end, { desc = "Open a new markdown buffer in a top split" })

vim.api.nvim_create_user_command("ChatvimNewBottom", function()
  open_chatvim_window({ args = "bottom" })
end, { desc = "Open a new markdown buffer in a bottom split" })

vim.api.nvim_create_user_command("ChatvimComplete", function()
  require("chatvim").complete_text()
end, {})

vim.api.nvim_create_user_command("ChatvimStop", function()
  require("chatvim").stop_completion()
end, {})

-- Function to open a new markdown buffer prefilled with help text from Node.js
local function open_chatvim_help_window(args)
  -- Generate a unique filename like "/path/to/cwd/chat-YYYY-MM-DD-HH-MM-SS.md"
  local filename = vim.fn.getcwd() .. "/chat-" .. os.date("%Y-%m-%d-%H-%M-%S") .. ".md"

  -- Determine window placement based on argument
  local placement = args.args or ""
  local split_cmd = ""

  if placement == "left" then
    split_cmd = "topleft vsplit"
  elseif placement == "right" then
    split_cmd = "botright vsplit"
  elseif placement == "top" then
    split_cmd = "topleft split"
  elseif placement == "bottom" or placement == "bot" then
    split_cmd = "botright split"
  end

  -- Open the split if specified
  if split_cmd ~= "" then
    vim.cmd(split_cmd)
  end

  -- Edit the new file in the target window (creates a new unsaved buffer with the filename)
  vim.cmd("edit " .. vim.fn.fnameescape(filename))

  -- Optional: Ensure filetype is markdown (usually auto-detected, but explicit for safety)
  vim.bo.filetype = "markdown"

  -- Optional: Set window size if in a split (adjust as needed)
  if placement == "left" or placement == "right" then
    vim.api.nvim_win_set_width(0, 40) -- Current window (0) width to 40 columns
  elseif placement == "top" or placement == "bottom" or placement == "bot" then
    vim.api.nvim_win_set_height(0, 20) -- Current window height to 20 rows
  end

  -- Get the current buffer (newly created)
  local buf = vim.api.nvim_get_current_buf()

  -- Define path to the Node.js script
  local plugin_dir = debug.getinfo(1, "S").source:sub(2):match("(.*/)")
  local stream_js_path = plugin_dir .. "../chatvim.ts"

  -- Variable to collect stdout lines
  local output_lines = {}

  -- Callback for stdout: collect all lines, including blank ones
  local function on_stdout(_, data, _)
    for _, line in ipairs(data) do
      table.insert(output_lines, line) -- Include all lines, even empty ones for blank lines
    end
  end

  -- Callback for stderr: log errors (optional, can be expanded)
  local function on_stderr(_, data, _)
    if #data > 0 and data[1] ~= "" then
      vim.api.nvim_echo({ { "Error from Node.js: " .. table.concat(data, "\n"), "ErrorMsg" } }, false, {})
    end
  end

  -- Callback for exit: insert collected output into buffer and center cursor
  local function on_exit(_, code, _)
    if code ~= 0 then
      vim.api.nvim_echo({ { "Node.js command failed with code " .. code, "ErrorMsg" } }, false, {})
      return
    end

    -- Insert the collected output lines into the buffer
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, output_lines)

    -- Move cursor to the end of the content
    local last_line = #output_lines
    vim.api.nvim_win_set_cursor(0, { last_line, 0 })

    -- Center the cursor at the bottom (equivalent to 'zz')
    vim.cmd("normal! zz")
  end

  -- Start the Node.js job to get help text
  local job_id = vim.fn.jobstart({ "node", stream_js_path, "helpfile" }, {
    on_stdout = on_stdout,
    on_stderr = on_stderr,
    on_exit = on_exit,
    stdout_buffered = false, -- Non-buffered in case output is large/streamed
    stderr_buffered = false,
  })

  -- Optional: Handle job failure
  if job_id <= 0 then
    vim.api.nvim_echo({ { "Failed to start Node.js job", "ErrorMsg" } }, false, {})
  end
end

-- Define the :ChatvimHelp command with optional argument
vim.api.nvim_create_user_command("ChatvimHelp", open_chatvim_help_window, {
  nargs = "?", -- Accepts 0 or 1 argument (e.g., "left")
  complete = function()
    return { "left", "right", "top", "bottom" } -- Suggestions for placements
  end,
  desc = "Open a new markdown buffer prefilled with help text, optionally in a split (e.g., ChatvimHelp left)",
})

-- Chatvim (chatvim.nvim) keybindings
local opts = { noremap = true, silent = true }
vim.api.nvim_set_keymap("n", "<Leader>cvc", ":ChatvimComplete<CR>", opts)
vim.api.nvim_set_keymap("n", "<Leader>cvs", ":ChatvimStop<CR>", opts)
vim.api.nvim_set_keymap("n", "<Leader>cvnn", ":ChatvimNew<CR>", opts)
vim.api.nvim_set_keymap("n", "<Leader>cvnl", ":ChatvimNewLeft<CR>", opts)
vim.api.nvim_set_keymap("n", "<Leader>cvnr", ":ChatvimNewRight<CR>", opts)
vim.api.nvim_set_keymap("n", "<Leader>cvnb", ":ChatvimNewBottom<CR>", opts)
vim.api.nvim_set_keymap("n", "<Leader>cvnt", ":ChatvimNewTop<CR>", opts)

return M
