# ChatVim CLI 🦫

_ChatVim CLI way to chat with markdown files on your command line._

## Basic Idea

The basic idea of ChatVim CLI is to put LLMs on the command line, like this:

```sh
chatvim forget "What is 1 + 1?"
```

Output

```sh
1 + 1 is 2.
```

Read on for more details.

## Installation

Install globally using npm:

```sh
npm install -g chatvim
```

This provides one global command:

- `chatvim` &nbsp;—&nbsp; Main entry point for ChatVim CLI

## Usage

### API Keys

You MUST first set at least one API key for an LLM provider.

```sh
export OPENAI_API_KEY=your_openai_api_key
export ANTHROPIC_API_KEY=your_anthropic_api_key
export XAI_API_KEY=your_xai_api_key
```

### Help

For full usage instructions, run:

```sh
chatvim --help
```

### Command List

A brief overview of available commands:

- **forget** &nbsp;—&nbsp; Send a prompt to the LLM and get a response
- **save** &nbsp;—&nbsp; Save a prompt and response to a markdown file
- **buffer** &nbsp;—&nbsp; Buffer input for later processing
- **format** &nbsp;—&nbsp; Format markdown output for better readability
- **color** &nbsp;—&nbsp; Colorize markdown output for better visibility
- **models** &nbsp;—&nbsp; List available LLM models
- **providers** &nbsp;—&nbsp; List available LLM providers

## Example Workflows

```sh
# Simple math prompt
chatvim forget "What is 2 plus 2?"

# Code generation
chatvim forget "Generate a JavaScript function that reverses an array"

# Use a markdown file as context and log the response
chatvim remember --file chat.md "Generate a Python function to calculate factorial"

# If you don't specify the file name, it will default to `chat.md`
chatvim remember "Generate a Python function to calculate Fibonacci sequence"
# ^ This will create or overwrite `chat.md`

# Pipe input as prompt
cat my-instructions.txt | chatvim forget

# Generate, buffer, format, and colorize Markdown output
chatvim forget "Show me a Python bubble sort function with comments in Markdown." | chatvim buffer | chatvim format | chatvim color

# Buffer and format direct Markdown input
echo "# Quick Note\n\nThis is a short note with a code block:\n\n\`\`\`bash\necho 'Hello, World!'\n\`\`\`" | chatvim buffer | chatvim format

# Format and colorize without buffering
chatvim forget "Write a short Markdown note." | chatvim format | chatvim color
```

## License

MIT

_Developed by Identellica LLC_ 🦫
