
## Programming Style

Optimize for memory and CPU efficiency, informed by Linux kernel and game engine conventions.

- Be resource effecient. 
- Prefer plain data objects over class instances
- Prefer parameterized functions over class methods
- Prefer pure functions
  - Inside pure functions: mutate in place rather than creating new objects
  - At function boundaries: clone objects going in and out to prevent shared mutation

## Testing

- Don't write test for what type system already guarantees
- When writing tests:
  - Be concise — combine related cases in one test when they share the same logic
  - Assert outputs directly — never use conditional logic to force tests to pass

## Teams

- IMPORTANT: **Every team** must include a **Devil's Advocate** role:
  - Challenges all hypotheses and decisions from other agents
  - Demands evidence before signing off — no assumptions pass unchecked
  - Verifies by running tests locally when possible
  - When reproduction is hard in Node (e.g. visual/interaction bugs), uses the browser to verify
  - Only approves when proof is solid

## Debugging

- IMPORTANT: When asked to debug, **always spawn a team**:
  - **Investigator** — reproduces the bug, forms hypotheses, proposes fixes
  - **Devil's Advocate** — (see Teams section above)
- **Reproduce first** — prove the bug with observable output before reading code or proposing fixes. If reproduction is blocked, ask for help — don't guess.

## General Workflows

- IMPORTANT: Do NOT mention Claude in commit messages. Describe actual changes only.
- Always open PRs as Draft.


## Browser Automation

Use `agent-browser` for web automation. Run `agent-browser --help` for all commands.

Core workflow:
1. `agent-browser open <url>` - Navigate to page
2. `agent-browser snapshot -i` - Get interactive elements with refs (@e1, @e2)
3. `agent-browser click @e1` / `fill @e2 "text"` - Interact using refs
4. Re-snapshot after page changes

- WebGL fails in headless mode (SwiftShader can't create context). Always use `--headed` for WebGL pages.

