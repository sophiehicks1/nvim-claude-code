local M = {}

M.config = {
  default_dir = nil, -- defaults to getcwd() if nil
  keymaps = {
    annotation_show = "<leader>cc",
    compose_open = "<leader>co",
    send_selection = "<leader>cs",
  },
}

local did_setup = false

function M.setup(opts)
  if did_setup then
    return
  end
  did_setup = true

  opts = opts or {}
  M.config = vim.tbl_deep_extend("force", M.config, opts)

  -- Highlight groups
  vim.api.nvim_set_hl(0, "ClaudeCodeSign", { default = true, fg = "#d4a373", bold = true })
  vim.api.nvim_set_hl(0, "ClaudeCodePopup", { default = true, link = "NormalFloat" })
  vim.api.nvim_set_hl(0, "ClaudeCodePopupBorder", { default = true, link = "FloatBorder" })

  -- Namespace for extmarks
  M.ns = vim.api.nvim_create_namespace("claudecode")

  -- Register commands and mappings
  require("claudecode.commands").register(M.config)
end

function M.is_setup()
  return did_setup
end

return M
