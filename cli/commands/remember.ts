import { promises as fs } from "fs";
import { generateChatCompletionStream } from "../util/ai.js";
import { withTimeout } from "../util/async.js";
import { parseChatLogFromText } from "../util/parse.js";
import { readStdin } from "../util/stdin.js";

export async function handleRemember(
  input: string | undefined,
  opts: { file: string } = { file: "codey.md" },
) {
  let promptText = input;
  if (!promptText && !process.stdin.isTTY) {
    promptText = (await readStdin()).trim();
  }
  if (!promptText) {
    console.error("No prompt supplied (argument or stdin required).");
    process.exit(1);
  }

  let fileContent = "";
  try {
    fileContent = await fs.readFile(opts.file, "utf-8");
  } catch (err: unknown) {
    // @ts-ignore
    if (err?.code === "ENOENT") {
      // File does not exist, we will create it later with writeFile
      fileContent = "";
    } else {
      console.error(`Failed to read file ${opts.file}:`, err);
      process.exit(1);
    }
  }

  const { messages, settings } = parseChatLogFromText(fileContent);
  messages.push({
    role: "user",
    content: promptText,
  });

  try {
    const stream = await generateChatCompletionStream({
      messages,
      model: settings.model,
    });

    // Append user prompt to file
    const userEntry = `${promptText}`;
    try {
      if (fileContent === "") {
        // If file didn't exist or was empty, write the initial content
        await fs.writeFile(opts.file, userEntry, "utf-8");
      } else {
        // Otherwise, append the user entry
        await fs.appendFile(opts.file, userEntry, "utf-8");
      }
    } catch (writeErr) {
      console.error(
        `Failed to write user prompt to file ${opts.file}:`,
        writeErr,
      );
      process.exit(1);
    }

    // Append assistant delimiter before streaming response
    const assistantDelimiter = `${settings.delimiterPrefix}${settings.assistantDelimiter}${settings.delimiterSuffix}`;
    await fs.appendFile(opts.file, assistantDelimiter, "utf-8");

    let assistantResponse = "";
    for await (const textChunk of withTimeout(stream, 15_000)) {
      if (textChunk) {
        // Print to stdout
        process.stdout.write(textChunk);
        // Collect response to append in chunks or at once
        assistantResponse += textChunk;
        // Optionally, append in real-time (though this can be less efficient for many small writes)
        // await fs.appendFile(opts.file, textChunk, "utf-8");
      }
    }

    // Append the full assistant response to the file
    await fs.appendFile(opts.file, assistantResponse, "utf-8");

    // Append user delimiter after response
    const userDelimiter = `${settings.delimiterPrefix}${settings.userDelimiter}${settings.delimiterSuffix}`;
    await fs.appendFile(opts.file, userDelimiter, "utf-8");

    process.stdout.write("\n");

    process.exit(0);
  } catch (err) {
    console.error("Error generating chat completion:", err);
    process.exit(1);
  }
}
