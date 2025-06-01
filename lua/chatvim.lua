local M = {}

function M.hello()
  -- vim.api.nvim_out_write("Hello world from chatvim.nvim!\n")
  vim.api.nvim_echo({{"Hello world from chatvim.nvim!", "Normal"}}, false, {})
end

return M
