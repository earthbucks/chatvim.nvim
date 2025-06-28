import * as TOML from "@iarna/toml";
import YAML from "yaml";
import { z } from "zod";

export const SettingsSchema = z.object({
  delimiterPrefix: z.string().default("\n\n"),
  delimiterSuffix: z.string().default("\n\n"),
  userDelimiter: z.string().default("# === USER ==="),
  assistantDelimiter: z.string().default("# === ASSISTANT ==="),
  systemDelimiter: z.string().default("# === SYSTEM ==="),
  model: z.string().default("grok-3"),
});

type ChatRole = "user" | "assistant" | "system";
type Settings = z.infer<typeof SettingsSchema>;

const FRONT_MATTER_REGEX = {
  toml: /^\+\+\+\n([\s\S]*?)\n\+\+\+/,
  yaml: /^---\n([\s\S]*?)\n---/,
};

function parseFrontMatter(text: string): Record<string, unknown> {
  for (const [type, regex] of Object.entries(FRONT_MATTER_REGEX)) {
    const match = text.match(regex);
    if (match) {
      try {
        return type === "toml"
          ? TOML.parse(match[1] || "")
          : YAML.parse(match[1] || "");
      } catch (e) {
        console.error(`Invalid ${type.toUpperCase()} front matter:`, e);
      }
    }
  }
  return {};
}

function getSettingsFromFrontMatter(text: string): Settings {
  const frontMatter = parseFrontMatter(text);
  return SettingsSchema.parse(frontMatter);
}

function stripFrontMatter(text: string): string {
  for (const regex of Object.values(FRONT_MATTER_REGEX)) {
    const match = text.match(regex);
    if (match) {
      return text.replace(match[0], "").trim();
    }
  }
  return text;
}

function buildDelimiterRegex(settings: Settings): RegExp {
  const roles: { role: ChatRole; delimiter: string }[] = [
    { role: "user", delimiter: settings.userDelimiter },
    { role: "assistant", delimiter: settings.assistantDelimiter },
    { role: "system", delimiter: settings.systemDelimiter },
  ];
  const escapedDelimiters = roles.map(({ delimiter }) =>
    `${settings.delimiterPrefix}${delimiter}${settings.delimiterSuffix}`.replace(
      /[.*+?^${}()|[\]\\]/g,
      "\\$&",
    ),
  );
  return new RegExp(`(${escapedDelimiters.join("|")})`, "g");
}

function parseChatLog(
  text: string,
  settings: Settings,
): { role: ChatRole; content: string }[] {
  const delimiterRegex = buildDelimiterRegex(settings);
  const parts = [];
  let lastIndex = 0;
  let match = delimiterRegex.exec(text);

  while (match) {
    if (match.index > lastIndex) {
      parts.push({ content: text.slice(lastIndex, match.index), delim: null });
    }
    parts.push({ content: "", delim: match[0] });
    lastIndex = delimiterRegex.lastIndex;
    match = delimiterRegex.exec(text);
  }
  if (lastIndex < text.length) {
    parts.push({ content: text.slice(lastIndex), delim: null });
  }

  const chatLog: { role: ChatRole; content: string }[] = [];
  let currentRole: ChatRole = "user";
  let first = true;

  for (let i = 0; i < parts.length; i++) {
    const { content, delim } = parts[i] as {
      content: string;
      delim: string | null;
    };
    if (first) {
      const nextDelim = parts[i + 1]?.delim;
      if (
        content.trim().length === 0 &&
        nextDelim ===
          `${settings.delimiterPrefix}${settings.systemDelimiter}${settings.delimiterSuffix}`
      ) {
        currentRole = "system";
      } else if (content.trim().length > 0) {
        chatLog.push({ role: "user", content });
      }
      first = false;
      continue;
    }
    if (delim) {
      if (delim.includes(settings.userDelimiter)) {
        currentRole = "user";
      } else if (delim.includes(settings.assistantDelimiter)) {
        currentRole = "assistant";
      } else if (delim.includes(settings.systemDelimiter)) {
        currentRole = "system";
      }
      const nextContent = parts[i + 1]?.content;
      if ((nextContent?.trim().length as number) > 0) {
        chatLog.push({ role: currentRole, content: nextContent || "" });
      }
    }
  }
  return chatLog;
}

export function parseChatLogFromText(text: string): {
  settings: Settings;
  messages: { role: ChatRole; content: string }[];
} {
  const settings = getSettingsFromFrontMatter(text);
  const chatLogText = stripFrontMatter(text);
  const messages = parseChatLog(chatLogText, settings);
  return { settings, messages };
}
