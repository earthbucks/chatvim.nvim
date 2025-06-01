const readline = require('readline');

const rl = readline.createInterface({ input: process.stdin });
rl.on('line', (line) => {
  const req = JSON.parse(line);
  // Simulate streaming
  process.stdout.write(JSON.stringify({ chunk: "Hello " }) + "\n");
  setTimeout(() => {
    process.stdout.write(JSON.stringify({ chunk: "world!" }) + "\n");
    process.stdout.write(JSON.stringify({ done: true }) + "\n");
  }, 500);
});
