# Changelog

- v0.0.7:
  - Overhaul streaming to buffer every 500ms, fixing laggy updates.
- v0.0.6:
  - Support gpt-4.1 from OpenAI.
  - Use promises-based API instead of callback-based API for readline.
- v0.0.5:
  - Include timeouts in js code to make hanging less likely.
- v0.0.4:
  - Add ":ChatVimStop" command to stop streaming.
- v0.0.3:
  - Write one chunk at a time, but ...
  - Disable syntax highlighting while streaming to prevent lag.
- v0.0.2:
  - Add "Computing..." spinner.
  - Write one line at a time (less lag).
- v0.0.1: Complete markdown documents with Grok.
