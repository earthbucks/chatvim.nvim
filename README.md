# ChatVim

Complete markdown documents using advanced AI models.

Currently, only supports Grok.

## Features

The purpose of ChatVim is to treat markdown documents as a conversation with an
AI assistant, allowing you to ask questions and get answers in the context of
the document. This is easier for some workflows than using a chat interface.

## Usage

You must install node.js v22+.

Set `XAI_API_KEY` environment variable to your xAI API key.

Install with LazyVim:

```lua
{
  "chatvim/chatvim.nvim",
}
```

## Commands

```vim
:ChatVimComplete
```

Completes the current markdown document using the AI model.

## Recommended Shortcuts

```lua
vim.api.nvim_set_keymap("n", "<Leader>cvc", ":ChatVimComplete<CR>", opts)
```

## Markdown Front Matter

Use "+++" for toml or "---" for yaml front matter. Front matter is used to
specify settings for ChatVim.

```toml
+++
delimiterPrefix = "\n\n"
delimiterSuffix = "\n\n"
userDelimiter = "# === USER ==="
assistantDelimiter = "# === ASSISTANT ==="
systemDelimiter = "# === SYSTEM ==="
+++
```

## License

MIT license. See [LICENSE](LICENSE).

Copyright (C) 2025 Identellica LLC
