import * as readline from "readline";
import z from "zod";
import * as TOML from "@iarna/toml";
import YAML from "yaml";
const SettingsSchema = z.object({
    delimiter: z.string().default("==="),
});
const MethodSchema = z.literal("complete");
const InputSchema = z.object({
    method: MethodSchema,
    params: z.object({
        text: z.string(),
    }),
});
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
const rl = readline.createInterface({ input: process.stdin });
rl.on("line", (line) => {
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
    // TODO: implement parsing of front matter
    const settings = SettingsSchema.parse({ delimiter: "===" });
    const delimiter = settings.delimiter;
    process.stdout.write(`${JSON.stringify({ chunk: `## User Input\n${text}` })}\n`);
    setTimeout(() => {
        // Simulate a response
        const response = `This is a simulated response for the input: ${text}`;
        process.stdout.write(`${JSON.stringify({ chunk: `## AI Response\n${response}` })}\n`);
        process.stdout.write(`${JSON.stringify({ done: true })}\n`);
    }, 500);
});
