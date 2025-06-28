import { providers } from "../util/ai.js";

export async function handleProviders() {
  for (const model of providers) {
    console.log(`${model}`);
  }
}
