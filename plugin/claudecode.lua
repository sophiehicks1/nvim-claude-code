if vim.g.loaded_claudecode then
  return
end
vim.g.loaded_claudecode = true

-- Auto-bootstrap: call setup with defaults if user hasn't called it explicitly
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    if not require("claudecode").is_setup() then
      require("claudecode").setup()
    end
  end,
  once = true,
})
