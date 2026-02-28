"""MCP server for Neovim integration."""

import os
import tempfile

from mcp.server.fastmcp import FastMCP

from .nvim_client import NvimClient

mcp = FastMCP("nvim")
client = NvimClient()

# ---------------------------------------------------------------------------
# Helpers (run inside the background thread via client.run)
# ---------------------------------------------------------------------------

def _buffer_info(buf, current_buf_number: int) -> dict:
    """Extract metadata from a Neovim buffer object."""
    return {
        "number": buf.number,
        "name": buf.name or "(unnamed)",
        "modified": buf.options["modified"],
        "is_current": buf.number == current_buf_number,
        "line_count": len(buf),
    }


def _visible_range(nvim) -> tuple[int, int]:
    """Return (first_line, last_line) 0-indexed for the current window."""
    top = nvim.call("line", "w0") - 1
    bot = nvim.call("line", "w$") - 1
    return top, bot


def _buffer_content_smart(buf, nvim) -> tuple[str, str]:
    """Return (content, description) using the ≤500-line / visible-region logic."""
    total = len(buf)
    if total <= 500:
        lines = buf[:]
        desc = f"full file ({total} lines)"
    else:
        top, bot = _visible_range(nvim)
        context = 50
        start = max(0, top - context)
        end = min(total, bot + context + 1)
        lines = buf[start:end]
        desc = f"lines {start + 1}-{end} of {total} (visible region + context)"
    return "\n".join(lines), desc


# ---------------------------------------------------------------------------
# Resources
# ---------------------------------------------------------------------------

@mcp.resource("nvim://current_buffer")
async def current_buffer_resource() -> str:
    """Current buffer file path, cursor position, visible range, and content."""
    def _work(nvim):
        buf = nvim.current.buffer
        win = nvim.current.window
        cursor = win.cursor  # (row 1-indexed, col 0-indexed)
        top, bot = _visible_range(nvim)
        content, desc = _buffer_content_smart(buf, nvim)
        return (
            f"path: {buf.name or '(unnamed)'}\n"
            f"cursor: line {cursor[0]}, col {cursor[1]}\n"
            f"visible: lines {top + 1}-{bot + 1}\n"
            f"content ({desc}):\n"
            f"{content}"
        )
    return await client.run(_work)


@mcp.resource("nvim://open_buffers")
async def open_buffers_resource() -> str:
    """List all open buffers with number, name, modified status, and current flag."""
    def _work(nvim):
        current_nr = nvim.current.buffer.number
        lines = []
        for buf in nvim.buffers:
            if not buf.options.get("buflisted", True):
                continue
            mod = " [+]" if buf.options["modified"] else ""
            cur = " *" if buf.number == current_nr else ""
            lines.append(f"{buf.number}: {buf.name or '(unnamed)'}{mod}{cur}")
        return "\n".join(lines) if lines else "(no listed buffers)"
    return await client.run(_work)


# ---------------------------------------------------------------------------
# Tools
# ---------------------------------------------------------------------------

@mcp.tool()
async def list_nvim_buffers() -> list[dict]:
    """List open Neovim buffers with number, path, modified status, is_current, and line_count."""
    def _work(nvim):
        current_nr = nvim.current.buffer.number
        result = []
        for buf in nvim.buffers:
            if not buf.options.get("buflisted", True):
                continue
            result.append(_buffer_info(buf, current_nr))
        return result
    return await client.run(_work)


@mcp.tool()
async def get_current_buffer() -> dict:
    """Get the current buffer's path, content, cursor position, visible range, and Neovim cwd."""
    def _work(nvim):
        buf = nvim.current.buffer
        win = nvim.current.window
        cursor = win.cursor
        top, bot = _visible_range(nvim)
        content, desc = _buffer_content_smart(buf, nvim)
        return {
            "path": buf.name or "(unnamed)",
            "cursor": {"line": cursor[0], "col": cursor[1]},
            "visible_range": {"start": top + 1, "end": bot + 1},
            "content_description": desc,
            "content": content,
            "cwd": nvim.call("getcwd"),
        }
    return await client.run(_work)


@mcp.tool()
async def get_buffer_content(path: str) -> dict:
    """Get the full content of a buffer identified by its file path. Errors if the file isn't open."""
    def _work(nvim):
        norm = os.path.abspath(path)
        for buf in nvim.buffers:
            buf_name = buf.name or ""
            if os.path.abspath(buf_name) == norm:
                content = "\n".join(buf[:])
                return {
                    "path": buf.name,
                    "line_count": len(buf),
                    "content": content,
                }
        raise ValueError(f"No buffer is open for path: {path}")
    return await client.run(_work)


@mcp.tool()
async def open_diff_view(file_path: str, proposed_content: str) -> str:
    """Open a vertical diff split comparing the original file with proposed changes.

    The left pane shows the original buffer; the right pane shows proposed content
    as a scratch buffer. Closing the scratch buffer cleans up the temp file.
    """
    # Write proposed content to a temp file first (no nvim needed)
    _, ext = os.path.splitext(file_path)
    fd, tmp_path = tempfile.mkstemp(suffix=ext, prefix="nvim_mcp_diff_")
    try:
        with os.fdopen(fd, "w") as f:
            f.write(proposed_content)
    except Exception:
        os.close(fd)
        os.unlink(tmp_path)
        raise

    def _work(nvim):
        escaped = nvim.call("fnameescape", file_path)
        nvim.command(f"edit {escaped}")
        tmp_escaped = nvim.call("fnameescape", tmp_path)
        nvim.command(f"vert diffsplit {tmp_escaped}")
        nvim.command("setlocal buftype=nofile bufhidden=wipe noswapfile")
        nvim.command(f"autocmd BufWipeout <buffer> silent! call delete('{tmp_path}')")
        return f"Diff view opened for {file_path}. Left=original, right=proposed. Close the proposed pane to clean up."

    return await client.run(_work)


@mcp.tool()
async def open_new_buffer(path: str, proposed_content: str) -> str:
    """Open a new buffer with the given path and content for the user to review and save.

    The buffer is marked as modified so the user sees it needs saving.
    """
    def _work(nvim):
        escaped = nvim.call("fnameescape", path)
        nvim.command(f"edit {escaped}")
        buf = nvim.current.buffer
        lines = proposed_content.split("\n")
        buf[:] = lines
        buf.options["modified"] = True
        return f"New buffer opened for {path} ({len(lines)} lines). Use :w to save."
    return await client.run(_work)


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

def main():
    mcp.run(transport="stdio")


if __name__ == "__main__":
    main()
