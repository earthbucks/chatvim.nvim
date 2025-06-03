# ChatVim

**Complete markdown documents using advanced AI models.**

Unlike many other neovim AI plugins, **ChatVim uses a plain markdown document as
the chat window**. No special dialogs or UI elements are required.

Currently, only supports Grok. More models will be added in the future.

## Features

The purpose of ChatVim is to treat markdown documents as a conversation with an
AI assistant instead of using a separate chat window or dialog box.

You can save, copy, fork, version, and share the markdown document as you would
with any other markdown file. This is easier for some workflows than using a
separate chat interface.

Because ChatVim uses chat completion AI models, there must be some way to
separate user messages, assistant messages, and system messages. This is done
using delimiters in the markdown document. The default delimiters are:

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

You must first install node.js v22+.

Set `XAI_API_KEY` environment variable to your xAI API key.

Install with LazyVim:

```lua
  {
    "chatvim/chatvim.nvim",
    build = "npm install",
    config = function()
      require("chatvim")
    end,
  },
```

## Commands

```vim
:ChatVimComplete
```

Completes the current markdown document using the AI model. If no delimiters are
present, it will treat the input as user input and append a response.

## Recommended Shortcuts

Add these shortcuts to your nvim configuration to make it easier to use ChatVim.

```lua
vim.api.nvim_set_keymap("n", "<Leader>cvc", ":ChatVimComplete<CR>", opts)
```

## Configuration

Use "+++" for TOML or "---" for YAML front matter. Front matter is used to
specify settings for ChatVim. Place the front matter at the top of your markdown
document, before any content. The front matter should look like this:

```markdown
+++
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
