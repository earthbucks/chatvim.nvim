import * as readline from "readline";
import z from "zod";
import * as TOML from "@iarna/toml";
import YAML from "yaml";

const SettingsSchema = z.object({
  delimiterPrefix: z.string().default("\n\n"),
  delimiter: z.string().default("==="),
  delimiterSuffix: z.string().default("\n\n"),
});

const MethodSchema = z.literal("complete");

const InputSchema = z.object({
  method: MethodSchema,
  params: z.object({
    text: z.string(),
  }),
});

// Extract front matter from markdown text
function parseFrontMatter(text: string) {
  const tomlMatch = text.match(/^\+\+\+\n([\s\S]*?)\n\+\+\+/);
  if (tomlMatch) {
    try {
      return TOML.parse(tomlMatch[1] || "");
    } catch (e) {
      console.error("Invalid TOML front matter:", e);
    }
  }
  const yamlMatch = text.match(/^---\n([\s\S]*?)\n---/);
  if (yamlMatch) {
    try {
      return YAML.parse(yamlMatch[1] || "");
    } catch (e) {
      console.error("Invalid YAML front matter:", e);
    }
  }
  return {};
}

function getSettingsFromFrontMatter(text: string) {
  const frontMatter = parseFrontMatter(text);
  if (frontMatter && typeof frontMatter === "object") {
    return SettingsSchema.parse(frontMatter);
  }
  return SettingsSchema.parse({});
}

function parseText(text: string) {
  // Remove front matter if it exists
  const tomlMatch = text.match(/^\+\+\+\n([\s\S]*?)\n\+\+\+/);
  if (tomlMatch) {
    return text.replace(tomlMatch[0], "").trim();
  }
  const yamlMatch = text.match(/^---\n([\s\S]*?)\n---/);
  if (yamlMatch) {
    return text.replace(yamlMatch[0], "").trim();
  }
  return text.trim();
}

const rl = readline.createInterface({ input: process.stdin });

rl.on("line", (line: string) => {
  const req = JSON.parse(line);
  const parsed = InputSchema.safeParse(req);
  if (!parsed.success) {
    console.error("Invalid input:", parsed.error);
    return;
  }
  const { method, params } = parsed.data;
  if (method !== "complete") {
    console.error("Unsupported method:", method);
    return;
  }
  const { text } = params;

  // now, to get settings, the markdown input may have toml or yaml front
  // matter. toml is preferred. toml starts with '+++' and yaml starts with
  // '---'.
  const settings = getSettingsFromFrontMatter(text);

  const delimiter = settings.delimiter;
  const delimiterPrefix = settings.delimiterPrefix;
  const delimiterSuffix = settings.delimiterSuffix;
  const fullDelimiter = `${delimiterPrefix}${delimiter}${delimiterSuffix}`;

  process.stdout.write(`${JSON.stringify({ chunk: `## User Input\n${text}` })}\n`);
  setTimeout(() => {
    // Simulate a response
    const response = `This is a simulated response for the input: ${text}`;
    process.stdout.write(`${JSON.stringify({ chunk: `## AI Response\n${response}` })}\n`);
    process.stdout.write(`${JSON.stringify({ done: true })}\n`);
  }, 500);
});
