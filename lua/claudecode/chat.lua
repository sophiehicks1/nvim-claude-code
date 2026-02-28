local M = {}

--- Send buffer text to the Claude terminal and close the compose buffer.
---@param buf integer compose buffer number
function M.send_and_close(buf)
  local terminal = require("claudecode.terminal")
  local term_buf = terminal.get_terminal_buf()
  if not term_buf then
    vim.notify("No Claude Code terminal running. Use :ClaudeCode first.", vim.log.levels.WARN)
    return
  end

  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local text = table.concat(lines, "\n")
  if text:match("^%s*$") then
    vim.notify("Empty message, not sent", vim.log.levels.INFO)
    return
  end

  local chan = vim.bo[term_buf].channel
  if not chan or chan <= 0 then
    vim.notify("Claude terminal channel not available", vim.log.levels.ERROR)
    return
  end

  vim.api.nvim_chan_send(chan, text .. "\n")

  -- Close the compose buffer
  if vim.api.nvim_buf_is_valid(buf) then
    vim.api.nvim_buf_delete(buf, { force = true })
  end

  vim.notify("Sent to Claude", vim.log.levels.INFO)
end

--- Open a small compose scratch buffer at the bottom.
function M.open_compose()
  local terminal = require("claudecode.terminal")
  if not terminal.get_terminal_buf() then
    vim.notify("No Claude Code terminal running. Use :ClaudeCode first.", vim.log.levels.WARN)
    return
  end

  vim.cmd("botright 8split")
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_current_buf(buf)

  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].filetype = "markdown"

  -- Buffer-local mappings
  vim.keymap.set("n", "<CR>", function()
    M.send_and_close(buf)
  end, { buffer = buf, desc = "Send to Claude" })

  vim.keymap.set("n", "q", function()
    if vim.api.nvim_buf_is_valid(buf) then
      vim.api.nvim_buf_delete(buf, { force = true })
    end
  end, { buffer = buf, nowait = true, desc = "Close compose buffer" })

  vim.cmd("startinsert")
end

return M
