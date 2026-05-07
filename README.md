# nvim-mcp-server

MCP server + Neovim plugin for Claude Code integration. Lets Claude read your buffers, open diffs and leave annotations.

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

### 2. Configure Claude Code

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

### 3. Install the Neovim plugin

This repo also contains an (optional) companion neovim plugin, which can be used to enable the
annotations functionality and to check the health of your nvim <-> claude connection. If you don't
use either of those features, you can safely ignore this step and the remaining MCP tools will work
just fine.

If you do choose to add this plugin, you can install it as you would install any other vim plugin (I
use `vim-plug`, but other methods work fine too!).

There is only one configuration point:

```
let g:claude_show_annotations_mapping = '<leader>sa' " defaults to ''
```

Once configured, you can use the mapping you chose to show the annotiations on the current line. You
can also check the health of the claude code configuration as follows

```
:checkhealth claudecode
```

## Usage

This MCP uses the `$NVIM` variable that neovim automatically sets for embedded terminal processes,
to allow claude to automatically discover and connect to your running vim instance.

There are therefore two ways to use it:

1. Run Claude Code inside nvim, to enable autodiscovery.
2. Manually configure the connection if you want to run claude code somewhere else.

### 1. Running Claude Code inside neovim

If you run claude code directly inside neovim, then claude will be able to autodiscover the vim
instance it's running inside without any configuration on your part. You can do this using the
following command:

```
:terminal claude
```

If you haven't used nvim terminals before, you can learn more using vim's built-in help:

```
:help :terminal
```

### 2. Manually configuring the connection

If you'd rather run claude code somewhere else, you can also connect the MCP server to your vim
instance by manually setting `$NVIM` to the value of `v:servername` yourself. How you do that will
depend on precisely how you're launching claude code, but the simplest method is as follows

First run the following inside the vim instance you want to connect to:

```
:echom v:servername
```

This will print a message at the bottom of the screen that should look something like this:

```
/run/user/1000/nvim.192189.0

```

Then pass that value through to claude code as an environment variable when you launch claude code

```
NVIM=<your-servername-value> claude
```

### MCP Tools (used by Claude)

n.b. All of these tools depend on $NVIM being set as described above.

 | Tool                                              | Description                                       | Needs vim plugin |
 | ------                                            | -------------                                     | ---------------- |
 | `list_nvim_buffers`                               | List open buffers with metadata                   | No               |
 | `get_current_buffer`                              | Get current buffer content, cursor, and cwd       | No               |
 | `get_buffer_content(bufnr)`                       | Get full content of a buffer by number            | No               |
 | `open_diff_view(file_path, proposed_content)`     | Open diff split with proposed changes             | No               |
 | `open_new_buffer(path, proposed_content)`         | Open new buffer with content for review           | No               |
 | `open_existing_file(path)`                        | Open existing file in a background tab for review | No               |
 | `add_comment_to_buffer(bufnr, line_num, comment)` | Add annotation at a line                          | Yes              |
 | `clear_annotations(bufnr)`                        | Clear annotations from buffer(s)                  | Yes              |

## Requirements

- Neovim >= 0.10
- Python >= 3.10
- Claude Code CLI (`claude`)
