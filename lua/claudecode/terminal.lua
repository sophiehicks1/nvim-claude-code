local M = {}

-- Tracked terminal state
local state = {
  bufnr = nil,
  dir = nil,
}

--- Get the tracked terminal buffer number (or nil).
---@return integer|nil
function M.get_terminal_buf()
  if state.bufnr and vim.api.nvim_buf_is_valid(state.bufnr) then
    return state.bufnr
  end
  state.bufnr = nil
  state.dir = nil
  return nil
end

--- Open a split along the longest side of the current window.
local function open_split()
  local width = vim.o.columns
  local height = vim.o.lines
  if width > height * 2.5 then
    vim.cmd("vsplit")
  else
    vim.cmd("split")
  end
end

--- Open (or reopen) the Claude Code terminal.
---@param dir string|nil Directory to run in
function M.open(dir)
  local config = require("claudecode").config
  local resolved_dir = dir or config.default_dir or vim.fn.getcwd()
  resolved_dir = vim.fn.fnamemodify(resolved_dir, ":p"):gsub("/$", "")

  local existing_buf = M.get_terminal_buf()

  if existing_buf then
    -- Terminal already exists
    if dir and state.dir ~= resolved_dir then
      vim.notify(
        string.format(
          "Claude Code is already running in %s. Close it first or omit the directory argument to reopen it.",
          state.dir
        ),
        vim.log.levels.ERROR
      )
      return
    end

    -- Reopen existing terminal in a new split
    open_split()
    vim.api.nvim_set_current_buf(existing_buf)
    vim.cmd("startinsert")
    return
  end

  -- No existing terminal — create a new one
  open_split()
  -- Set local working directory before launching the terminal
  vim.cmd("lcd " .. vim.fn.fnameescape(resolved_dir))
  vim.cmd("terminal claude")
  local bufnr = vim.api.nvim_get_current_buf()

  state.bufnr = bufnr
  state.dir = resolved_dir

  vim.cmd("startinsert")

  -- Clean up on terminal close
  vim.api.nvim_create_autocmd("TermClose", {
    buffer = bufnr,
    once = true,
    callback = function()
      if state.bufnr == bufnr then
        state.bufnr = nil
        state.dir = nil
      end
      -- Wipe the terminal buffer after a short delay
      vim.defer_fn(function()
        if vim.api.nvim_buf_is_valid(bufnr) then
          vim.api.nvim_buf_delete(bufnr, { force = true })
        end
      end, 100)
    end,
  })
end

return M
