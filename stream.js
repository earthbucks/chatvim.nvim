import * as readline from "readline";
import z from "zod/v4";
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
const ChatMessageSchema = z.object({
    role: z.enum(["user", "assistant"]),
    content: z.string(),
});
const ChatLogSchema = z.array(ChatMessageSchema).min(1).default([]);
// Extract front matter from markdown text
function parseFrontMatter(text) {
    const tomlMatch = text.match(/^\+\+\+\n([\s\S]*?)\n\+\+\+/);
    if (tomlMatch) {
        try {
            return TOML.parse(tomlMatch[1] || "");
        }
        catch (e) {
            console.error("Invalid TOML front matter:", e);
        }
    }
    const yamlMatch = text.match(/^---\n([\s\S]*?)\n---/);
    if (yamlMatch) {
        try {
            return YAML.parse(yamlMatch[1] || "");
        }
        catch (e) {
            console.error("Invalid YAML front matter:", e);
        }
    }
    return {};
}
function getSettingsFromFrontMatter(text) {
    const frontMatter = parseFrontMatter(text);
    if (frontMatter && typeof frontMatter === "object") {
        return SettingsSchema.parse(frontMatter);
    }
    return SettingsSchema.parse({});
}
function parseText(text) {
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
rl.on("line", (line) => {
    const req = JSON.parse(line);
    const parsed = InputSchema.safeParse(req);
    if (!parsed.success) {
        console.error("Invalid input:", parsed.error);
        return;
    }
    const { method, params } = parsed.data;
    if (method === "complete") {
        const { text } = params;
        // now, to get settings, the markdown input may have toml or yaml front
        // matter. toml is preferred. toml starts with '+++' and yaml starts with
        // '---'.
        const settings = getSettingsFromFrontMatter(text);
        const delimiter = settings.delimiter;
        const delimiterPrefix = settings.delimiterPrefix;
        const delimiterSuffix = settings.delimiterSuffix;
        const fullDelimiter = `${delimiterPrefix}${delimiter}${delimiterSuffix}`;
        const parsedText = parseText(text);
        if (!parsedText) {
            console.error("No text provided after front matter.");
            return;
        }
        const arrText = parsedText
            .split(fullDelimiter)
            .filter((s) => s.length > 0);
        // first message is always from the user. then, alternate user/assistant
        const chatLog = arrText.map((s, index) => {
            return {
                role: index % 2 === 0 ? "user" : "assistant",
                content: s,
            };
        });
        // confirm that last message is from the user and it is not empty
        if (chatLog.length === 0 ||
            chatLog[chatLog.length - 1]?.role !== "user" ||
            !chatLog[chatLog.length - 1]?.content) {
            console.error("Last message must be from the user and cannot be empty.");
            return;
        }
        process.stdout.write(`${JSON.stringify({ chunk: fullDelimiter })}\n`);
        process.stdout.write(`${JSON.stringify({ chunk: `## User Input\n${text}\n\n` })}\n`);
        setTimeout(() => {
            // Simulate a response
            const chatLogString = chatLog
                .map((msg) => `${msg.role}: ${msg.content}`)
                .join("\n");
            const response = `This is a simulated response for the input: ${chatLogString}`;
            process.stdout.write(`${JSON.stringify({ chunk: `## AI Response\n${response}` })}\n`);
            process.stdout.write(`${JSON.stringify({ chunk: fullDelimiter })}\n`);
            process.stdout.write(`${JSON.stringify({ done: true })}\n`);
        }, 500);
    }
    else {
        console.error("Unsupported method:", method);
        return;
    }
});
