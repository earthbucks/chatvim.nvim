import ora, { Ora } from "ora";
import { readStdin } from "../util/stdin.js";

export async function handleBuffer(input?: string) {
  let bufferText = input;
  const isPiped = !process.stdin.isTTY && !input;
  let spinner: Ora | undefined;
  if (isPiped) {
    spinner = ora("Buffering input...").start();
    bufferText = await readStdin();
    if (spinner) {
      spinner.stop();
    }
  }
  if (!bufferText) {
    if (spinner) {
      spinner.stop();
    }
    console.error(
      "No input supplied for buffering (argument or stdin required).",
    );
    process.exit(1);
  }
  process.stdout.write(`${bufferText}\n`);
}
