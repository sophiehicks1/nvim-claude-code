local M = {}

function M.check()
  vim.health.start("claudecode")

  -- Check Neovim version (need 0.10+ for modern extmark/float features)
  if vim.fn.has("nvim-0.10") == 1 then
    vim.health.ok("Neovim >= 0.10")
  else
    vim.health.warn("Neovim >= 0.10 recommended for full feature support")
  end

  -- Check plugin is loaded
  local cc = require("claudecode")
  if cc.is_setup() then
    vim.health.ok("Plugin is set up")
  else
    vim.health.error("Plugin not set up. Call require('claudecode').setup() or add plugin/ to runtimepath")
  end

  -- Check namespace exists
  if cc.ns then
    vim.health.ok("Namespace 'claudecode' created")
  else
    vim.health.warn("Namespace not created (setup not called?)")
  end

  -- Check nvim-mcp-server is installed
  if vim.fn.executable("nvim-mcp-server") == 1 then
    vim.health.ok("nvim-mcp-server executable found")
  else
    vim.health.error("nvim-mcp-server not found. Install with: pip install nvim-mcp-server")
  end

  -- Check $NVIM socket is set (indicates we're inside a Neovim terminal)
  local nvim_socket = vim.env.NVIM or vim.env.NVIM_LISTEN_ADDRESS
  if nvim_socket then
    vim.health.ok("$NVIM socket: " .. nvim_socket)
  else
    vim.health.info("$NVIM not set (normal when not running inside a nested terminal)")
  end

  -- Check Claude Code MCP config
  local settings_path = vim.fn.expand("~/.claude/settings.json")
  if vim.fn.filereadable(settings_path) == 1 then
    local content = table.concat(vim.fn.readfile(settings_path), "\n")
    if content:find("mcp__nvim") then
      vim.health.ok("Claude Code settings.json has nvim MCP permission")
    else
      vim.health.warn("~/.claude/settings.json exists but no mcp__nvim permission found. Add: \"mcp__nvim__*\" to permissions.allow")
    end
  else
    vim.health.warn("~/.claude/settings.json not found")
  end
end

return M
