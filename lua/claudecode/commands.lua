local M = {}

function M.register(config)
  local keymaps = config.keymaps or {}

  -- Phase 3: Annotation popup at cursor line
  if keymaps.annotation_show then
    vim.keymap.set("n", keymaps.annotation_show, function()
      local bufnr = vim.api.nvim_get_current_buf()
      local line_num = vim.api.nvim_win_get_cursor(0)[1]
      require("claudecode.annotations").show_popup(bufnr, line_num)
    end, { desc = "Show Claude annotation" })
  end

  -- Phase 4: :ClaudeCode command
  vim.api.nvim_create_user_command("ClaudeCode", function(opts)
    local dir = opts.args ~= "" and opts.args or nil
    require("claudecode.terminal").open(dir)
  end, {
    nargs = "?",
    complete = "dir",
    desc = "Open Claude Code terminal",
  })

  -- Phase 5: Compose buffer
  if keymaps.compose_open then
    vim.keymap.set("n", keymaps.compose_open, function()
      require("claudecode.chat").open_compose()
    end, { desc = "Open Claude compose buffer" })
  end

  if keymaps.send_selection then
    vim.keymap.set("v", keymaps.send_selection, function()
      -- Get visual selection
      vim.cmd('normal! "zy')
      local text = vim.fn.getreg("z")
      local terminal = require("claudecode.terminal")
      local term_buf = terminal.get_terminal_buf()
      if not term_buf then
        vim.notify("No Claude Code terminal running. Use :ClaudeCode first.", vim.log.levels.WARN)
        return
      end
      local chan = vim.bo[term_buf].channel
      if chan and chan > 0 then
        vim.api.nvim_chan_send(chan, text .. "\n")
        vim.notify("Sent selection to Claude", vim.log.levels.INFO)
      end
    end, { desc = "Send selection to Claude" })
  end
end

return M
