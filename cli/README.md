# Codey 🦫

<img src="./raw-images/codeybeaver-3.png" width="150" height="150" alt="Codey Beaver">

_Codey is a versatile CLI and Node.js toolkit for leveraging LLMs to help with
computer programming tasks._

---

## Basic Idea

The basic idea of Codey is to put LLMs on the command line, like this:

```sh
codey prompt "What is 1 + 1?"
```

Output

```sh
1 + 1 is 2.
```

Read on for more details.

## Installation

Install globally using npm:

```sh
npm install -g @codeybeaver/codey
```

This provides one global command:

- `codey` &nbsp;—&nbsp; Main entry point for Codey

---

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
codey --help
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

---

## Example Workflows

```sh
# Simple math prompt
codey prompt "What is 2 plus 2?"

# Code generation
codey prompt "Generate a JavaScript function that reverses an array"

# Save the prompt and response to a markdown file
codey save --file codey.md "Generate a Python function to calculate factorial"

# If you don't specify the file name, it will default to `codey.md`
codey save "Generate a Python function to calculate Fibonacci sequence"
# ^ This will create or overwrite `codey.md`

# Pipe input as prompt
cat my-instructions.txt | codey prompt

# Generate, buffer, format, and colorize Markdown output
codey prompt "Show me a Python bubble sort function with comments in Markdown." | codey buffer | codey format | codey color

# Buffer and format direct Markdown input
echo "# Quick Note\n\nThis is a short note with a code block:\n\n\`\`\`bash\necho 'Hello, World!'\n\`\`\`" | codey buffer | codey format

# Format and colorize without buffering
codey prompt "Write a short Markdown note." | codey format | codey color
```

---

## License

MIT

---

_Developed by Identellica LLC_ 🦫
