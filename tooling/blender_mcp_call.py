#!/usr/bin/env python3
from __future__ import annotations

import argparse
import asyncio
import json
import os
import sys
from pathlib import Path
from typing import Any, NoReturn


DEFAULT_CACHE_ENV = Path(
    "/Users/toris/.cache/uv/archive-v0/2MdHiH30JWRWtlL_"
)
CACHE_ENV = Path(os.environ.get("BLENDER_MCP_CACHE_ENV", DEFAULT_CACHE_ENV))
CACHED_PYTHON = CACHE_ENV / "bin" / "python"
MCP_EXECUTABLE = Path(
    os.environ.get("BLENDER_MCP_EXECUTABLE", CACHE_ENV / "bin" / "blender-mcp")
)
RUNTIME_MARKER = "_BLENDER_MCP_CALL_CACHED_RUNTIME"


def emit(payload: dict[str, Any]) -> None:
    """Write one machine-readable result to stdout."""
    print(json.dumps(payload, ensure_ascii=False, separators=(",", ":")))


def fail(error_type: str, message: str, *, exit_code: int = 1) -> NoReturn:
    emit({"ok": False, "error": {"type": error_type, "message": message}})
    raise SystemExit(exit_code)


def ensure_cached_runtime() -> None:
    """Re-exec with the Python interpreter that owns the cached MCP packages."""
    if os.environ.get(RUNTIME_MARKER) == "1":
        return
    if not CACHED_PYTHON.is_file():
        fail("runtime_not_found", f"Cached Python not found: {CACHED_PYTHON}")

    env = os.environ.copy()
    env[RUNTIME_MARKER] = "1"
    env["DISABLE_TELEMETRY"] = "true"
    env["PYTHONDONTWRITEBYTECODE"] = "1"
    os.execve(
        str(CACHED_PYTHON),
        [str(CACHED_PYTHON), str(Path(__file__).resolve()), *sys.argv[1:]],
        env,
    )


ensure_cached_runtime()

# These must be set even when the wrapper was launched inside the cached
# interpreter and therefore did not need a re-exec.
os.environ["DISABLE_TELEMETRY"] = "true"
os.environ["PYTHONDONTWRITEBYTECODE"] = "1"

try:
    from mcp import ClientSession, StdioServerParameters
    from mcp.client.stdio import stdio_client
except Exception as exc:  # pragma: no cover - only reached for a damaged cache
    fail("mcp_import_failed", f"Could not import the cached MCP client: {exc}")


class CliError(Exception):
    """A command-line error that should be returned as JSON."""


class JsonArgumentParser(argparse.ArgumentParser):
    def error(self, message: str) -> NoReturn:
        raise CliError(message)


def build_parser() -> JsonArgumentParser:
    parser = JsonArgumentParser(
        description="Call a tool on the locally cached Blender MCP server."
    )
    parser.add_argument(
        "tool",
        nargs="?",
        help="MCP tool name. Omit when using --list-tools or --code.",
    )
    parser.add_argument(
        "arguments_json",
        nargs="?",
        help="Tool arguments as a JSON object; defaults to {}.",
    )
    parser.add_argument(
        "--arguments-file",
        type=Path,
        help="Read the tool arguments JSON object from a UTF-8 file.",
    )
    parser.add_argument(
        "--list-tools",
        action="store_true",
        help="Initialize the server and print all advertised tools.",
    )
    code_group = parser.add_mutually_exclusive_group()
    code_group.add_argument(
        "--code",
        help="Call execute_blender_code with this Python source.",
    )
    code_group.add_argument(
        "--code-file",
        type=Path,
        help="Call execute_blender_code with Python source read from this file.",
    )
    parser.add_argument(
        "--user-prompt",
        default="",
        help="Optional user_prompt passed with --code/--code-file.",
    )
    parser.add_argument(
        "--host",
        default=os.environ.get("BLENDER_HOST", "localhost"),
        help="Blender add-on socket host (default: localhost).",
    )
    parser.add_argument(
        "--port",
        type=int,
        default=int(os.environ.get("BLENDER_PORT", "9876")),
        help="Blender add-on socket port (default: 9876).",
    )
    return parser


def load_call(ns: argparse.Namespace) -> tuple[str, dict[str, Any]] | None:
    """Validate CLI arguments and return a tool call, or None for list-tools."""
    uses_code = ns.code is not None or ns.code_file is not None
    uses_arguments = ns.arguments_json is not None or ns.arguments_file is not None

    if ns.list_tools:
        if ns.tool or uses_code or uses_arguments:
            raise CliError("--list-tools cannot be combined with a tool call")
        return None

    if uses_code:
        if uses_arguments:
            raise CliError("--code/--code-file cannot be combined with JSON arguments")
        if ns.tool not in (None, "execute_blender_code"):
            raise CliError("--code/--code-file only supports execute_blender_code")
        if ns.code_file is not None:
            try:
                code = ns.code_file.read_text(encoding="utf-8")
            except OSError as exc:
                raise CliError(f"Could not read code file: {exc}") from exc
            repository_root = Path(__file__).resolve().parents[1]
            code = (
                "import os\n"
                "import sys\n"
                f"repository_root = {str(repository_root)!r}\n"
                "os.environ['TOKENFRONT_REPO_ROOT'] = repository_root\n"
                "if repository_root not in sys.path:\n"
                "    sys.path.insert(0, repository_root)\n"
                + code
            )
        else:
            code = ns.code
        return "execute_blender_code", {
            "code": code,
            "user_prompt": ns.user_prompt,
        }

    if not ns.tool:
        raise CliError("Provide a tool name, --code, --code-file, or --list-tools")

    if ns.arguments_json is not None and ns.arguments_file is not None:
        raise CliError("Use either positional JSON or --arguments-file, not both")

    if ns.arguments_file is not None:
        try:
            raw_arguments = ns.arguments_file.read_text(encoding="utf-8")
        except OSError as exc:
            raise CliError(f"Could not read arguments file: {exc}") from exc
    else:
        raw_arguments = ns.arguments_json or "{}"

    try:
        arguments = json.loads(raw_arguments)
    except json.JSONDecodeError as exc:
        raise CliError(
            f"Tool arguments must be valid JSON: {exc.msg} at character {exc.pos}"
        ) from exc
    if not isinstance(arguments, dict):
        raise CliError("Tool arguments must decode to a JSON object")
    return ns.tool, arguments


def as_jsonable(value: Any) -> Any:
    """Convert MCP/Pydantic models and common containers to JSON-safe values."""
    if hasattr(value, "model_dump"):
        return value.model_dump(mode="json", by_alias=True, exclude_none=False)
    if isinstance(value, dict):
        return {str(key): as_jsonable(item) for key, item in value.items()}
    if isinstance(value, (list, tuple)):
        return [as_jsonable(item) for item in value]
    if isinstance(value, Path):
        return str(value)
    return value


def result_indicates_error(result: dict[str, Any]) -> bool:
    """Catch Blender MCP errors that are returned as successful text content."""
    if result.get("isError") is True:
        return True
    for item in result.get("content") or []:
        if not isinstance(item, dict):
            continue
        text = item.get("text")
        if isinstance(text, str) and text.lstrip().lower().startswith(("error:", "error ")):
            return True
    return False


async def call_mcp(
    call: tuple[str, dict[str, Any]] | None,
    *,
    host: str,
    port: int,
) -> tuple[dict[str, Any], int]:
    if not MCP_EXECUTABLE.is_file():
        raise FileNotFoundError(f"Cached Blender MCP executable not found: {MCP_EXECUTABLE}")

    child_env = os.environ.copy()
    child_env.update(
        {
            "BLENDER_HOST": host,
            "BLENDER_PORT": str(port),
            "DISABLE_TELEMETRY": "true",
            "PYTHONDONTWRITEBYTECODE": "1",
        }
    )
    server = StdioServerParameters(
        command=str(MCP_EXECUTABLE),
        args=[],
        env=child_env,
    )

    async with stdio_client(server) as (read_stream, write_stream):
        async with ClientSession(read_stream, write_stream) as session:
            initialized = await session.initialize()
            server_info = as_jsonable(initialized.serverInfo)

            if call is None:
                listed = await session.list_tools()
                return (
                    {
                        "ok": True,
                        "operation": "list_tools",
                        "server": server_info,
                        "tools": [as_jsonable(tool) for tool in listed.tools],
                        "nextCursor": listed.nextCursor,
                    },
                    0,
                )

            tool_name, arguments = call
            tool_result = as_jsonable(await session.call_tool(tool_name, arguments))
            reported_error = result_indicates_error(tool_result)
            payload: dict[str, Any] = {
                "ok": not reported_error,
                "operation": "call_tool",
                "tool": tool_name,
                "server": server_info,
                "result": tool_result,
            }
            if reported_error:
                payload["error"] = {
                    "type": "tool_result",
                    "message": "The MCP tool returned an error result",
                }
            return payload, 2 if reported_error else 0


def main() -> int:
    try:
        ns = build_parser().parse_args()
        call = load_call(ns)
        payload, exit_code = asyncio.run(call_mcp(call, host=ns.host, port=ns.port))
        emit(payload)
        return exit_code
    except CliError as exc:
        emit({"ok": False, "error": {"type": "cli", "message": str(exc)}})
        return 64
    except KeyboardInterrupt:
        emit({"ok": False, "error": {"type": "interrupted", "message": "Interrupted"}})
        return 130
    except BaseException as exc:
        emit(
            {
                "ok": False,
                "error": {
                    "type": type(exc).__name__,
                    "message": str(exc),
                },
            }
        )
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
