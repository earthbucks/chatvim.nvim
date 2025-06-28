import { models } from "../util/ai.js";

export async function handleModels() {
  for (const model of models) {
    console.log(`${model}`);
  }
}
