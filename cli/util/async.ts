export async function* withTimeout<T>(
  src: AsyncIterable<T>,
  ms: number,
): AsyncIterable<T> {
  for await (const chunk of src) {
    yield await Promise.race([
      Promise.resolve(chunk),
      new Promise<T>((_, rej) =>
        setTimeout(() => rej(new Error("Chunk timeout")), ms),
      ),
    ]);
  }
}
