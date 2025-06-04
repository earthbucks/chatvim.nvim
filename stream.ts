import * as readline from "readline";
import z from "zod/v4";
import * as TOML from "@iarna/toml";
import YAML from "yaml";
import { OpenAI } from "openai";

const SettingsSchema = z.object({
  delimiterPrefix: z.string().default("\n\n"),
  delimiterSuffix: z.string().default("\n\n"),
  userDelimiter: z.string().default("# === USER ==="),
  assistantDelimiter: z.string().default("# === ASSISTANT ==="),
  systemDelimiter: z.string().default("# === SYSTEM ==="),
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
  return text;
}

// New: scan for delimiters and build chat log
function parseChatLog(text: string, settings: z.infer<typeof SettingsSchema>) {
  const {
    delimiterPrefix,
    delimiterSuffix,
    userDelimiter,
    assistantDelimiter,
    systemDelimiter,
  } = settings;

  const delimiters = [
    {
      role: "user",
      delim: `${delimiterPrefix}${userDelimiter}${delimiterSuffix}`,
    },
    {
      role: "assistant",
      delim: `${delimiterPrefix}${assistantDelimiter}${delimiterSuffix}`,
    },
    {
      role: "system",
      delim: `${delimiterPrefix}${systemDelimiter}${delimiterSuffix}`,
    },
  ];

  // Build a regex to match any delimiter
  const delimRegex = new RegExp(
    `(${delimiters.map((d) => d.delim.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")).join("|")})`,
    "g",
  );

  // Split text into blocks and delimiters
  const parts = [];
  let lastIndex = 0;
  let match: RegExpExecArray | null;
  const regex = new RegExp(delimRegex, "g");

  match = regex.exec(text);
  while (match !== null) {
    if (match.index > lastIndex) {
      parts.push({ content: text.slice(lastIndex, match.index), delim: null });
    }
    parts.push({ content: "", delim: match[0] });
    lastIndex = regex.lastIndex;
    match = regex.exec(text);
  }

  if (lastIndex < text.length) {
    parts.push({ content: text.slice(lastIndex), delim: null });
  }

  // Now, walk through parts and assign roles
  const chatLog: { role: "user" | "assistant" | "system"; content: string }[] =
    [];
  let currentRole: "user" | "assistant" | "system" = "user";
  let first = true;
  for (let i = 0; i < parts.length; i++) {
    const { content, delim } = parts[i] as {
      content: string;
      delim: string | null;
    };
    if (first) {
      // If first block is empty or whitespace, and next is a system delimiter, treat as system
      if (
        content.trim().length === 0 &&
        parts[i + 1]?.delim ===
          `${delimiterPrefix}${systemDelimiter}${delimiterSuffix}`
      ) {
        currentRole = "system";
        first = false;
        continue;
      }
      // Otherwise, first block is user
      if (content.trim().length > 0) {
        chatLog.push({ role: "user", content: content });
      }
      first = false;
      continue;
    }
    if (delim) {
      // Find which role this delimiter is for
      const found = delimiters.find((d) => d.delim === delim);
      if (found) {
        currentRole = found.role as "user" | "assistant" | "system";
      }
      // Next part (if any) is the content for this role
      if (
        parts[i + 1] &&
        (
          parts[i + 1] as { content: string; delim: string | null }
        ).content.trim().length > 0
      ) {
        chatLog.push({
          role: currentRole,
          content: (parts[i + 1] as { content: string; delim: string | null })
            .content,
        });
      }
    }
  }
  return chatLog;
}

async function withTimeout<T>(promise: Promise<T>, ms: number): Promise<T> {
  return new Promise((resolve, reject) => {
    const timer = setTimeout(() => reject(new Error("Timeout")), ms);
    promise.then(
      (val) => {
        clearTimeout(timer);
        resolve(val);
      },
      (err) => {
        clearTimeout(timer);
        reject(err);
      },
    );
  });
}

export async function generateChatCompletionStream({
  messages,
}: {
  messages: { role: "assistant" | "user" | "system"; content: string }[];
}) {
  if (!process.env.XAI_API_KEY) {
    throw new Error("XAI_API_KEY environment variable is not set.");
  }
  const aiApiXAI = new OpenAI({
    apiKey: process.env.XAI_API_KEY,
    baseURL: "https://api.x.ai/v1",
  });

  try {
    const stream = await withTimeout(
      aiApiXAI.chat.completions.create({
        model: "grok-3-beta",
        messages,
        max_tokens: undefined,
        stream: true,
      }),
      30_000, // 30 seconds timeout
    );
    return stream;
  } catch (error) {
    console.error("Error generating chat completion:", error);
    throw error;
  }
}

const rl = readline.createInterface({ input: process.stdin });

rl.on("line", async (line: string) => {
  const req = JSON.parse(line);
  const parsed = InputSchema.safeParse(req);
  if (!parsed.success) {
    console.error("Invalid input:", parsed.error);
    return;
  }
  const { method, params } = parsed.data;
  if (method === "complete") {
    const { text } = params;

    const settings = getSettingsFromFrontMatter(text);

    const parsedText = parseText(text);
    if (!parsedText) {
      console.error("No text provided after front matter.");
      return;
    }

    const chatLog = parseChatLog(parsedText, settings);

    // confirm that last message is from the user and it is not empty
    if (
      chatLog.length === 0 ||
      chatLog[chatLog.length - 1]?.role !== "user" ||
      !chatLog[chatLog.length - 1]?.content
    ) {
      console.error("Last message must be from the user and cannot be empty.");
      return;
    }

    // Output the delimiter for streaming
    process.stdout.write(
      `${JSON.stringify({ chunk: settings.delimiterPrefix + settings.assistantDelimiter + settings.delimiterSuffix })}\n`,
    );

    if (!process.env.XAI_API_KEY) {
      console.error("XAI_API_KEY environment variable is not set.");
      return;
    }

    try {
      const stream = await generateChatCompletionStream({
        messages: chatLog,
      });

      async function* withStreamTimeout<T>(
        stream: AsyncIterable<T>,
        ms: number,
      ): AsyncIterable<T> {
        for await (const chunkPromise of stream) {
          yield await Promise.race([
            Promise.resolve(chunkPromise),
            new Promise<T>((_, reject) =>
              setTimeout(() => reject(new Error("Chunk timeout")), ms),
            ),
          ]);
        }
      }

      try {
        // 15s timeout per chunk
        for await (const chunk of withStreamTimeout(stream, 15000)) {
          if (chunk.choices[0]?.delta.content) {
            process.stdout.write(
              `${JSON.stringify({
                chunk: chunk.choices[0].delta.content,
              })}\n`,
            );
          }
        }
      } catch (error) {
        console.error("Chunk timeout error:", error);
        return;
      }
    } catch (error) {
      console.error("Error generating chat completion:", error);
      return;
    }

    process.stdout.write(
      `${JSON.stringify({ chunk: settings.delimiterPrefix + settings.userDelimiter + settings.delimiterSuffix })}\n`,
    );
    process.exit(0);
  } else {
    console.error("Unsupported method:", method);
    return;
  }
});
