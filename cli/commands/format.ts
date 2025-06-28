import prettier from "prettier";
import { readStdin } from "../util/stdin.js";

export async function handleFormat(input?: string) {
  try {
    let formatText = input;
    const isPiped = !process.stdin.isTTY && !input;
    if (isPiped) {
      formatText = (await readStdin()).trim();
    }
    if (!formatText) {
      console.error(
        "No input supplied for formatting (argument or stdin required).",
      );
      process.exit(1);
    }
    // Format the input Markdown with prettier to enforce max width of 80
    const formattedInput = await prettier.format(formatText, {
      parser: "markdown",
      printWidth: 80,
      proseWrap: "always",
    });
    process.stdout.write(`${formattedInput}`);
  } catch (err) {
    console.error("Error formatting input:", err);
    process.exit(1);
  }
}
