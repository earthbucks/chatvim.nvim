import * as readline from "readline";

const rl = readline.createInterface({ input: process.stdin });
rl.on("line", (line: string) => {
  const req = JSON.parse(line);
  // Simulate streaming
  if (req.method === "complete") {
    // Simulate streaming a completion
    process.stdout.write(`${JSON.stringify({ chunk: "## AI Completion\n" })}\n`);
    setTimeout(() => {
      process.stdout.write(`${JSON.stringify({ chunk: "This is a streamed response." })}\n`);
      process.stdout.write(`${JSON.stringify({ done: true })}\n`);
    }, 500);
  }
});
