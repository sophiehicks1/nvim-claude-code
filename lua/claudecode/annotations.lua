local M = {}

local function get_ns()
  local cc = require("claudecode")
  if not cc.ns then
    vim.notify("claudecode: plugin not set up, call require('claudecode').setup() first", vim.log.levels.WARN)
    return nil
  end
  return cc.ns
end

--- Add an annotation to a buffer at a specific line.
---@param bufnr integer
---@param line_num integer 1-indexed line number
---@param comment string
function M.add(bufnr, line_num, comment)
  local ns = get_ns()
  if not ns then return end
  local annotations = vim.b[bufnr].claudecode_annotations or {}
  local line_idx = line_num - 1 -- extmarks are 0-indexed

  vim.api.nvim_buf_set_extmark(bufnr, ns, line_idx, 0, {
    sign_text = "CC",
    sign_hl_group = "ClaudeCodeSign",
  })

  annotations[tostring(line_num)] = comment
  vim.b[bufnr].claudecode_annotations = annotations
end

--- Show popup with annotation comment at the given line.
---@param bufnr integer
---@param line_num integer 1-indexed line number
function M.show_popup(bufnr, line_num)
  local annotations = vim.b[bufnr].claudecode_annotations or {}
  local comment = annotations[tostring(line_num)]
  if not comment then
    vim.notify("No Claude annotation on this line", vim.log.levels.INFO)
    return
  end

  local lines = vim.split(comment, "\n")
  local max_width = 0
  for _, line in ipairs(lines) do
    max_width = math.max(max_width, #line)
  end
  max_width = math.min(max_width, 80)

  local popup_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(popup_buf, 0, -1, false, lines)
  vim.bo[popup_buf].modifiable = false

  local win = vim.api.nvim_open_win(popup_buf, true, {
    relative = "cursor",
    row = 1,
    col = 0,
    width = max_width + 2,
    height = #lines,
    style = "minimal",
    border = "rounded",
  })
  vim.api.nvim_set_option_value("winhl", "Normal:ClaudeCodePopup,FloatBorder:ClaudeCodePopupBorder", { win = win })

  -- Close on any movement
  vim.api.nvim_create_autocmd({ "CursorMoved", "BufLeave", "InsertEnter" }, {
    buffer = popup_buf,
    once = true,
    callback = function()
      if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, true)
      end
    end,
  })
  -- Also close on q
  vim.keymap.set("n", "q", function()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end, { buffer = popup_buf, nowait = true })
end

--- Clear all annotations from a buffer (or all buffers if bufnr is nil).
---@param bufnr integer|nil
function M.clear(bufnr)
  local ns = get_ns()
  if not ns then return end
  if bufnr then
    vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
    vim.b[bufnr].claudecode_annotations = nil
  else
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_valid(buf) then
        vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
        vim.b[buf].claudecode_annotations = nil
      end
    end
  end
end

return M
