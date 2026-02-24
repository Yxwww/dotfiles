## Programming Style

Primary stack: TypeScript, React. Optimize for memory and CPU efficiency, informed by Linux kernel and game engine conventions.

- Be frugal with resources while maintaining readability
- Avoid allocating new resources in loops
- Prefer closures over classes
- Prefer plain data objects over class instances
- Prefer parameterized functions over class methods
- Prefer pure functions
  - Inside pure functions: mutate in place rather than creating new objects
  - At function boundaries: clone objects going in and out to prevent shared mutation
- Always clean up created resources
  - Find the right place to destroy or dispose resources
  - Cancel async processes on failure or when superseded
- Use normal ES imports at module top; avoid inline require/import unless necessary

- Unless specified, style with shadcn. Keep it clean and slick.

## Testing

- TDD whenever possible.
- Run only tests the change touches. Use `--testNamePattern` to filter when possible
- Don't write test for what type system already guarantees
- When writing tests:
  - Be concise — combine related cases in one test when they share the same logic
  - Prefer performant test code
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

### Planning

- Sacrifice grammar for concision
- List unresolved questions at the end
- Fan out independent work to parallel subagents; don't serialize what can run concurrently
- Always suggest verification steps when not specified

## Tooling

- For any changes to the Claude Code status line, use the "statusline-setup" agent

## Browser Automation

Use `agent-browser` for web automation. Run `agent-browser --help` for all commands.

Core workflow:
1. `agent-browser open <url>` - Navigate to page
2. `agent-browser snapshot -i` - Get interactive elements with refs (@e1, @e2)
3. `agent-browser click @e1` / `fill @e2 "text"` - Interact using refs
4. Re-snapshot after page changes

- WebGL fails in headless mode (SwiftShader can't create context). Always use `--headed` for WebGL pages.
