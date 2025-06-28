# ChatVim CLI 🦫

_ChatVim CLI way to chat with markdown files on your command line._

## Basic Idea

The basic idea of ChatVim CLI is to put LLMs on the command line, like this:

```sh
cv prompt "What is 1 + 1?"
```

Output

```sh
1 + 1 is 2.
```

Read on for more details.

## Installation

Install globally using npm:

```sh
npm install -g @chatvim/cli
```

This provides one global command:

- `cv` &nbsp;—&nbsp; Main entry point for ChatVim CLI

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
cv --help
```

### Command List

A brief overview of available commands:

- **prompt** &nbsp;—&nbsp; Send a prompt to the LLM and get a response
- **save** &nbsp;—&nbsp; Save a prompt and response to a markdown file
- **buffer** &nbsp;—&nbsp; Buffer input for later processing
- **format** &nbsp;—&nbsp; Format markdown output for better readability
- **color** &nbsp;—&nbsp; Colorize markdown output for better visibility
- **models** &nbsp;—&nbsp; List available LLM models
- **providers** &nbsp;—&nbsp; List available LLM providers

## Example Workflows

```sh
# Simple math prompt
cv prompt "What is 2 plus 2?"

# Code generation
cv prompt "Generate a JavaScript function that reverses an array"

# Save the prompt and response to a markdown file
cv save --file cv.md "Generate a Python function to calculate factorial"

# If you don't specify the file name, it will default to `cv.md`
cv save "Generate a Python function to calculate Fibonacci sequence"
# ^ This will create or overwrite `cv.md`

# Pipe input as prompt
cat my-instructions.txt | cv prompt

# Generate, buffer, format, and colorize Markdown output
cv prompt "Show me a Python bubble sort function with comments in Markdown." | cv buffer | cv format | cv color

# Buffer and format direct Markdown input
echo "# Quick Note\n\nThis is a short note with a code block:\n\n\`\`\`bash\necho 'Hello, World!'\n\`\`\`" | cv buffer | cv format

# Format and colorize without buffering
cv prompt "Write a short Markdown note." | cv format | cv color
```

## License

MIT

_Developed by Identellica LLC_ 🦫
