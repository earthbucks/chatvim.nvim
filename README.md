# ChatVim

**AI chat with markdown files in Neovim.**

Unlike many other Neovim AI plugins, **ChatVim uses a plain markdown document as
the chat window**. No special dialogs or UI elements are required.

## Models

Models supported:

- `grok-3-beta` (default) (xAI)
- `gpt-4.1` (OpenAI)
- `gpt-4.1-mini` (OpenAI)
- `gpt-4.1-nano` (OpenAI)
- `o3` (OpenAI)
- `o3-mini` (OpenAI)
- `o1` (OpenAI)
- `o1-mini` (OpenAI)

Providers supported:

- xAI (Set `XAI_API_KEY` environment variable to your xAI API key)
- OpenAI (Set `OPENAI_API_KEY` environment variable to your OpenAI API key)

## Video Demo

https://github.com/user-attachments/assets/7fe523e8-b953-4307-ac62-df58884bdfd0

## Features

The purpose of ChatVim is to treat a markdown document as a conversation with an
AI assistant instead of using a separate chat window or dialog box.

You can save, copy, fork, version, and share the markdown document as you would
with any other markdown file. This is easier for some workflows than using a
separate chat interface.

Because ChatVim uses chat completion AI models, there must be some way to
separate user messages, assistant messages, and system messages. This is done
using delimiters in the markdown document.

The default delimiters are:

- `# === USER ===` for user messages
- `# === ASSISTANT ===` for assistant messages
- `# === SYSTEM ===` for system messages

You can customize these delimiters in the markdown front matter, explained
below.

If no delimiter is used (as is the case for most markdown documents), then the
entire markdown document is treated as user input, and the AI model will respond
to it as if it were a single user message. Delimiters will be added with the
first response.

## Installation

You must install node.js v22+.

You must also set at least one API key:
- Set `XAI_API_KEY` environment variable to your xAI API key.
- Set `OPENAI_API_KEY` environment variable to your OpenAI API key.

Then, install with LazyVim:

```lua
  {
    "chatvim/chatvim.nvim",
    build = "npm install",
    config = function()
      require("chatvim")
    end,
  },
```

Or with Packer:

```lua
  use {
    "chatvim/chatvim.nvim",
    run = "npm install",
    config = function()
      require("chatvim")
    end,
  }
```

## Commands

```vim
:ChatVimComplete
:ChatVimStop
```

Completes the current markdown document using the AI model. If no delimiters are
present, it will treat the input as user input and append a response.

## Recommended Shortcuts

Add these shortcuts to your nvim configuration to make it easier to use ChatVim.

```lua
vim.api.nvim_set_keymap("n", "<Leader>cvc", ":ChatVimComplete<CR>", opts)
vim.api.nvim_set_keymap("n", "<Leader>cvs", ":ChatVimStop<CR>", opts)
```

## Configuration

Use "+++" for TOML or "---" for YAML front matter. Front matter is used to
specify settings for ChatVim. Place the front matter at the top of your markdown
document, before any content. The front matter should look like this:

```markdown
+++
model = "grok-3-beta"  # or "gpt-4.1", etc.
delimiterPrefix = "\n\n"
delimiterSuffix = "\n\n"
userDelimiter = "# === USER ==="
assistantDelimiter = "# === ASSISTANT ==="
systemDelimiter = "# === SYSTEM ==="
+++
```

All fields are optional.

## Example

See the [example markdown document](example.md) for a complete example of how to
use ChatVim. The example document includes user messages, assistant messages,
and system messages, as well as the front matter configuration.

## License

MIT license. See [LICENSE](LICENSE).

Copyright (C) 2025 Identellica LLC
