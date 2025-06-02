var readline = require('readline');
var rl = readline.createInterface({ input: process.stdin });
rl.on('line', function (line) {
    var req = JSON.parse(line);
    // Simulate streaming
    if (req.method === "complete") {
        // Simulate streaming a completion
        process.stdout.write(JSON.stringify({ chunk: "## AI Completion\n" }) + "\n");
        setTimeout(function () {
            process.stdout.write(JSON.stringify({ chunk: "This is a streamed response." }) + "\n");
            process.stdout.write(JSON.stringify({ done: true }) + "\n");
        }, 500);
    }
    else {
        process.stdout.write(JSON.stringify({ chunk: "Hello " }) + "\n");
        setTimeout(function () {
            process.stdout.write(JSON.stringify({ chunk: "world!" }) + "\n");
        }, 500);
        setTimeout(function () {
            process.stdout.write(JSON.stringify({ done: true }) + "\n");
        }, 1000);
    }
});
