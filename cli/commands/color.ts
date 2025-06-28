import { marked } from "marked";
import TerminalRenderer from "marked-terminal";
import { readStdin } from "../util/stdin.js";

export async function handleColor(input?: string) {
  let colorText = input;
  const isPiped = !process.stdin.isTTY && !input;
  if (isPiped) {
    colorText = (await readStdin()).trim();
  }
  if (!colorText) {
    console.error(
      "No input supplied for colorizing (argument or stdin required).",
    );
    process.exit(1);
  }
  try {
    // Setup marked-terminal renderer for syntax highlighting
    // @ts-ignore – marked-terminal lacks full typings
    marked.setOptions({ renderer: new TerminalRenderer() });
    const renderedOutput = marked(colorText);
    process.stdout.write(`${renderedOutput}\n`);
  } catch (err) {
    console.error("Error colorizing input:", err);
    process.exit(1);
  }
}
