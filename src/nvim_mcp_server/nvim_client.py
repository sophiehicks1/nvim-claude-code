"""Neovim connection management via pynvim.

pynvim's socket transport uses its own asyncio event loop internally,
which conflicts with the MCP server's running loop.  We run all Neovim
RPC calls on a dedicated background thread to avoid the
"Cannot run the event loop while another loop is running" error.
"""

import asyncio
import os
from concurrent.futures import ThreadPoolExecutor
from typing import Any, Callable, TypeVar

import pynvim

T = TypeVar("T")

# Single reusable thread so the pynvim connection is always accessed from
# the same OS thread (pynvim is not thread-safe across multiple threads).
_executor = ThreadPoolExecutor(max_workers=1, thread_name_prefix="nvim-rpc")


class NvimClient:
    """Lazy-connecting Neovim RPC client.

    All public access goes through :meth:`run`, which dispatches the
    callback onto a dedicated background thread.
    """

    def __init__(self):
        self._nvim: pynvim.Nvim | None = None

    def _get_socket_path(self) -> str:
        path = os.environ.get("NVIM") or os.environ.get("NVIM_LISTEN_ADDRESS")
        if not path:
            raise RuntimeError(
                "Cannot connect to Neovim: neither $NVIM nor $NVIM_LISTEN_ADDRESS is set. "
                "Run Claude Code inside a Neovim :terminal so the env var is inherited."
            )
        return path

    def _connect(self) -> pynvim.Nvim:
        path = self._get_socket_path()
        return pynvim.attach("socket", path=path)

    def _get_nvim(self) -> pynvim.Nvim:
        """Return a live Neovim connection, reconnecting if stale.  Thread-unsafe — only call from _executor."""
        if self._nvim is not None:
            try:
                self._nvim.eval("1")
                return self._nvim
            except Exception:
                self._nvim = None

        self._nvim = self._connect()
        return self._nvim

    async def run(self, fn: Callable[[pynvim.Nvim], T]) -> T:
        """Run *fn(nvim)* on the background thread and return its result."""
        def _work():
            nvim = self._get_nvim()
            return fn(nvim)

        loop = asyncio.get_running_loop()
        return await loop.run_in_executor(_executor, _work)
