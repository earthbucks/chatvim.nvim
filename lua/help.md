# === USER ===

What is Chatvim?

# === ASSISTANT ===

Chatvim is a set of tools for chatting with Markdown files.

## Parts of Chatvim

Chatvim has several parts:

- **Chatvim CLI**: A command-line interface for chatting with Markdown files.
- **chatvim.nvim**: A Neovim plugin that allows you to chat with Markdown files
  inside Neovim.
- **ChatvimLazy**: A Neovim distribution that includes helpful plugins for
  chatting with Markdown files. It includes chatvim.nvim by default.

## Chatvim CLI

The CLI provides the core functionality of Chatvim. It is written in
TypeScript/Node.js and includes all the code to use various AI APIs, such as
OpenAI, xAI, and Anthropic.

## chatvim.nvim

The Neovim plugin is the primary user interface most of the time. It provides a
way to easily "chat with" a Markdown file. It is configurable by specifying TOML
or YAML front-matter at the top of the Markdown file.

## ChatvimLazy

ChatvimLazy is a fork of LazyVim, a Neovim distribution, which is modified to
include the Chatvim Neovim plugin by default. It also has other settings and
plugins that work well with Chatvim.

# === USER ===
