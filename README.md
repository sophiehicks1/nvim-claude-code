# nvim-mcp-server

MCP server + Neovim plugin for Claude Code integration. Lets Claude read your buffers, open diffs, leave annotations, and run inside a Neovim terminal.

## Installation

### 1. Install the MCP server

```bash
pip install git+https://github.com/sophiehicks1/nvim-mcp-server.git
```

Or for development:

```bash
cd nvim-mcp-server
pip install -e .
```

### 2. Install the Neovim plugin

**lazy.nvim:**

```lua
{
  "sophiehicks1/nvim-mcp-server",
  config = function()
    require("claudecode").setup({
      -- default_dir = nil,  -- defaults to getcwd()
      -- keymaps = {
      --   annotation_show = "<leader>cc",
      --   compose_open = "<leader>co",
      --   send_selection = "<leader>cs",
      -- },
    })
  end,
}
```

**vim-plug:**

```vim
Plug 'sophiehicks1/nvim-mcp-server'

" After plug#end(), add to your init.vim:
lua << EOF
require("claudecode").setup({
  default_dir = "~/projects",
  'ex_command' = true,
  keymaps = {
    annotation_show = "<leader>ca",
    compose_open = "<leader>co",
    send_selection = "<leader>cs",
  },
})
EOF
```

**packer.nvim:**

```lua
use {
  "sophiehicks1/nvim-mcp-server",
  config = function()
    require("claudecode").setup()
  end,
}
```

**Manual:** Add the repo root to your runtimepath:

```lua
vim.opt.runtimepath:append("/path/to/nvim-mcp-server")
```

### 3. Configure Claude Code

Add to `~/.claude/settings.json`:

```json
{
  "permissions": {
    "allow": ["mcp__nvim__*"]
  },
  "mcpServers": {
    "nvim": {
      "command": "nvim-mcp-server",
      "type": "stdio"
    }
  }
}
```

## Usage

### Commands

| Command | Description |
|---------|-------------|
| `:ClaudeCode [dir]` | Open Claude Code in a terminal split |
| `:checkhealth claudecode` | Run health checks |

### Keymaps (defaults)

| Keymap | Mode | Description |
|--------|------|-------------|
| `<leader>cc` | Normal | Show Claude annotation at cursor |
| `<leader>co` | Normal | Open compose buffer to send message to Claude |
| `<leader>cs` | Visual | Send selection to Claude terminal |

### Compose buffer

Press `<leader>co` to open a small scratch buffer. Type your message, then press `<Enter>` in normal mode to send it to the Claude terminal. Press `q` to cancel.

### MCP Tools (used by Claude)

| Tool | Description |
|------|-------------|
| `list_nvim_buffers` | List open buffers with metadata |
| `get_current_buffer` | Get current buffer content, cursor, and cwd |
| `get_buffer_content(bufnr)` | Get full content of a buffer by number |
| `open_diff_view(file_path, proposed_content)` | Open diff split with proposed changes |
| `open_new_buffer(path, proposed_content)` | Open new buffer with content for review |
| `open_existing_file(path)` | Open existing file in a background tab for review |
| `add_comment_to_buffer(bufnr, line_num, comment)` | Add annotation at a line |
| `clear_annotations(bufnr)` | Clear annotations from buffer(s) |

## Requirements

- Neovim >= 0.10
- Python >= 3.10
- Claude Code CLI (`claude`)
