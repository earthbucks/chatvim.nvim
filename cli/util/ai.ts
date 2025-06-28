import z from "zod/v4";
import { OpenAI } from "openai";
import Anthropic from "@anthropic-ai/sdk";

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

export const ModelsSchema = z
  .enum([
    // anthropic
    "claude-3-5-sonnet-latest",
    "claude-3-7-sonnet-latest",
    "claude-sonnet-4-0",
    "claude-opus-4-0",

    // openai
    "gpt-4.1",
    "gpt-4.1-mini",
    "gpt-4.1-nano",
    "gpt-4o",
    "gpt-4o-mini",
    "gpt-4o-mini-search-preview",
    "gpt-4o-search-preview",
    "o1",
    "o1-mini",
    "o3",
    "o3-mini",

    // x.ai
    "grok-3",
  ])
  .default("grok-3");

export const models: z.infer<typeof ModelsSchema>[] = [
  // anthropic models
  "claude-3-5-sonnet-latest",
  "claude-3-7-sonnet-latest",
  "claude-sonnet-4-0",
  "claude-opus-4-0",

  // openai models
  "gpt-4.1",
  "gpt-4.1-mini",
  "gpt-4.1-nano",
  "gpt-4o",
  "gpt-4o-mini",
  "gpt-4o-mini-search-preview",
  "gpt-4o-search-preview",

  // x.ai models
  "o1",
  "o1-mini",
  "o3",
  "o3-mini",
  "grok-3",
];

export const providers: z.infer<typeof ProviderSchema>[] = [
  "anthropic",
  "openai",
  "xai",
];

export const ProviderSchema = z
  .enum(["anthropic", "openai", "xai"])
  .default("xai");

const ModelToProviderMap: Record<string, z.infer<typeof ProviderSchema>> = {
  // anthropic models
  "claude-3-5-sonnet-latest": "anthropic",
  "claude-3-7-sonnet-latest": "anthropic",
  "claude-sonnet-4-0": "anthropic",
  "claude-opus-4-0": "anthropic",

  // openai models
  "gpt-4.1": "openai",
  "gpt-4.1-mini": "openai",
  "gpt-4.1-nano": "openai",
  "gpt-4o": "openai",
  "gpt-4o-mini": "openai",
  "gpt-4o-mini-search-preview": "openai",
  "gpt-4o-search-preview": "openai",
  o1: "openai",
  "o1-mini": "openai",
  o3: "openai",
  "o3-mini": "openai",

  // xai models
  "grok-3": "xai",
};

function getProvider(model: string): z.infer<typeof ProviderSchema> {
  const provider = ModelToProviderMap[model];
  if (!provider) {
    throw new Error(`No provider found for model: ${model}`);
  }
  return provider;
}

export async function generateChatCompletionAnthropic({
  messages,
  model,
}: {
  messages: { role: "assistant" | "user" | "system"; content: string }[];
  model: string;
}): Promise<AsyncIterable<string>> {
  const apiKey = process.env.ANTHROPIC_API_KEY;
  if (!apiKey) {
    throw new Error("ANTHROPIC_API_KEY environment variable is not set.");
  }

  const anthropic = new Anthropic({
    apiKey,
  });

  try {
    const stream = anthropic.messages.stream({
      model,
      messages: messages.map((msg) => ({
        role: msg.role === "assistant" ? "assistant" : "user", // Anthropic only supports 'user' and 'assistant'
        content: msg.content,
      })),
      max_tokens: 4096, // Anthropic requires max_tokens to be set
    });

    // Transform Anthropic stream into an async iterable of text chunks
    return {
      async *[Symbol.asyncIterator]() {
        const textQueue: string[] = [];
        let isDone = false;
        let error: Error | null = null;
        let pendingResolve: ((value: IteratorResult<string>) => void) | null =
          null;

        // Listen for 'text' events and queue the text chunks
        stream.on("text", (text) => {
          if (text) {
            textQueue.push(text);
            if (pendingResolve) {
              const chunk = textQueue.shift();
              if (chunk) {
                pendingResolve({ value: chunk, done: false });
                pendingResolve = null;
              }
            }
          }
        });

        // Listen for 'end' event to signal completion
        stream.on("end", () => {
          isDone = true;
          if (pendingResolve) {
            pendingResolve({ value: "", done: true });
            pendingResolve = null;
          }
        });

        // Handle errors
        stream.on("error", (err) => {
          isDone = true;
          error = err instanceof Error ? err : new Error(String(err));
          if (pendingResolve) {
            pendingResolve({ value: "", done: true });
            pendingResolve = null;
          }
        });

        // Async iterator logic to yield text chunks
        while (true) {
          if (error) {
            throw error; // Propagate error to the consumer if one occurred
          }
          if (textQueue.length > 0) {
            const chunk = textQueue.shift();
            if (chunk) {
              yield chunk;
            }
          } else if (isDone) {
            break; // Exit loop if stream is done and no more chunks
          } else {
            // Wait for the next text event or completion
            const result = await new Promise<IteratorResult<string>>(
              (resolve) => {
                pendingResolve = resolve;
                if (isDone) {
                  resolve({ value: "", done: true });
                } else if (textQueue.length > 0) {
                  const chunk = textQueue.shift();
                  if (chunk) {
                    resolve({ value: chunk, done: false });
                  }
                }
              },
            );
            if (result.done) {
              break;
            }
            yield result.value;
          }
        }
      },
    };
  } catch (error) {
    console.error("Error generating Anthropic chat completion:", error);
    throw error;
  }
}

export async function generateChatCompletionXAI({
  messages,
  model,
}: {
  messages: { role: "assistant" | "user" | "system"; content: string }[];
  model: string;
}): Promise<AsyncIterable<string>> {
  const apiKey = process.env.XAI_API_KEY;
  if (!apiKey) {
    throw new Error("XAI_API_KEY environment variable is not set.");
  }

  const baseURL = "https://api.x.ai/v1";
  const aiApi = new OpenAI({
    apiKey,
    baseURL,
  });

  try {
    const stream = await withTimeout(
      aiApi.chat.completions.create({
        model,
        messages,
        max_tokens: undefined,
        stream: true,
      }),
      30_000, // 30 seconds timeout
    );

    // Transform XAI stream into an async iterable of text chunks
    return {
      async *[Symbol.asyncIterator]() {
        for await (const chunk of stream) {
          const text = chunk.choices[0]?.delta?.content || "";
          if (text) {
            yield text;
          }
        }
      },
    };
  } catch (error) {
    console.error("Error generating XAI chat completion:", error);
    throw error;
  }
}

export async function generateChatCompletionOpenAI({
  messages,
  model,
}: {
  messages: { role: "assistant" | "user" | "system"; content: string }[];
  model: string;
}): Promise<AsyncIterable<string>> {
  const apiKey = process.env.OPENAI_API_KEY;
  if (!apiKey) {
    throw new Error("OPENAI_API_KEY environment variable is not set.");
  }

  const aiApi = new OpenAI({
    apiKey,
    baseURL: undefined, // Use default OpenAI base URL
  });

  try {
    const stream = await withTimeout(
      aiApi.chat.completions.create({
        model,
        messages,
        max_tokens: undefined,
        stream: true,
      }),
      30_000, // 30 seconds timeout
    );

    // Transform OpenAI stream into an async iterable of text chunks
    return {
      async *[Symbol.asyncIterator]() {
        for await (const chunk of stream) {
          const text = chunk.choices[0]?.delta?.content || "";
          if (text) {
            yield text;
          }
        }
      },
    };
  } catch (error) {
    console.error("Error generating OpenAI chat completion:", error);
    throw error;
  }
}

export async function generateChatCompletionStream({
  messages,
  model,
}: {
  messages: { role: "assistant" | "user" | "system"; content: string }[];
  model: string;
}): Promise<AsyncIterable<string>> {
  const provider = getProvider(model);

  if (provider === "anthropic") {
    return generateChatCompletionAnthropic({ messages, model });
  }
  if (provider === "xai") {
    return generateChatCompletionXAI({ messages, model });
  }
  if (provider === "openai") {
    return generateChatCompletionOpenAI({ messages, model });
  }
  throw new Error(`Unsupported provider: ${provider}`);
}
