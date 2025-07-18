# Chatvim

**AI chat with markdown files in Neovim.**

Unlike many other Neovim AI plugins, **Chatvim uses a plain markdown document as
the chat window**. No special dialogs or UI elements are required.

## Video Demo

https://github.com/user-attachments/assets/7fe523e8-b953-4307-ac62-df58884bdfd0

## Usage

Simply type a message into a file in Neovim, and then run the `:ChatvimComplete`
command to get a response from the default AI model. With no extra
configuration, the entire file is treaged as the user prompt. See below for more
details.

## Features

The purpose of Chatvim is to treat a markdown document as a conversation with an
AI assistant instead of using a separate chat window or dialog box.

You can save, copy, fork, version, and share the markdown document as you would
with any other markdown file. This is easier for some workflows than using a
separate chat interface.

Because Chatvim uses chat completion AI models, there must be some way to
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

You must install node.js v24+.

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
:ChatvimComplete
```

Completes the current markdown document using the AI model. If no delimiters are
present, it will treat the input as user input and append a response.

```vim
:ChatvimStop
```

Stops the current streaming response.

```vim
:ChatvimNew [direction]
```

`direction` can be blank or `left`, `right`, `top`, or `bottom`. Opens a new
(unsaved) markdown document in a new split window for a new chat session. If
`direction` is not specified, it defaults to the current window.

## Recommended Shortcuts

Add these shortcuts to your nvim configuration to make it easier to use Chatvim.

```lua
local opts = { noremap = true, silent = true }
vim.api.nvim_set_keymap("n", "<Leader>cvc", ":ChatvimComplete<CR>", opts)
vim.api.nvim_set_keymap("n", "<Leader>cvs", ":ChatvimStop<CR>", opts)
vim.api.nvim_set_keymap("n", "<Leader>cvw", ":ChatvimWrite<CR>", opts)
vim.api.nvim_set_keymap("n", "<Leader>cvnn", ":ChatvimNew<CR>", opts)
vim.api.nvim_set_keymap("n", "<Leader>cvnl", ":ChatvimNewLeft<CR>", opts)
vim.api.nvim_set_keymap("n", "<Leader>cvnr", ":ChatvimNewRight<CR>", opts)
vim.api.nvim_set_keymap("n", "<Leader>cvnb", ":ChatvimNewBottom<CR>", opts)
vim.api.nvim_set_keymap("n", "<Leader>cvnt", ":ChatvimNewTop<CR>", opts)
```

## Configuration

Use "+++" for TOML or "---" for YAML front matter. Front matter is used to
specify settings for Chatvim. Place the front matter at the top of your markdown
document, before any content. The front matter should look like this:

```markdown
+++
model = "grok-3"  # or "gpt-4.1", etc.
delimiterPrefix = "\n\n"
delimiterSuffix = "\n\n"
userDelimiter = "# === USER ==="
assistantDelimiter = "# === ASSISTANT ==="
systemDelimiter = "# === SYSTEM ==="
+++
```

All fields are optional.

## Models

Models supported:

- `claude-sonnet-4-0` (Anthropic)
- `claude-opus-4-0` (Anthropic)
- `claude-3-7-sonnet-latest` (Anthropic)
- `claude-3-5-sonnet-latest` (Anthropic)
- `gpt-4.1` (OpenAI)
- `gpt-4.1-mini` (OpenAI)
- `gpt-4.1-nano` (OpenAI)
- `gpt-4o` (OpenAI)
- `gpt-4o-mini` (OpenAI)
- `gpt-4o-mini-search-preview` (OpenAI)
- `gpt-4o-search-preview` (OpenAI)
- `o3` (OpenAI)
- `o3-mini` (OpenAI)
- `o1` (OpenAI)
- `o1-mini` (OpenAI)
- `grok-3` (default) (xAI)
- `grok-4-0709` (xAI)
- `grok-3-mini` (xAI)
- `grok-3-fast` (xAI)
- `grok-3-mini-fast` (xAI)

Providers supported:

- xAI (Set `XAI_API_KEY` environment variable to your xAI API key)
- OpenAI (Set `OPENAI_API_KEY` environment variable to your OpenAI API key)
- Anthropic (Set `ANTHROPIC_API_KEY` environment variable to your Anthropic API
  key)

## License

MIT license. See [LICENSE](LICENSE).

Copyright (C) 2025 EarthBucks Inc.
