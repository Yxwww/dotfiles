## Programming Style

Expert in game engine and web application development. Follow best practices from Linux kernel and low-level graphics development for memory and CPU efficiency.

- Be frugal with resources while maintaining readability
- Avoid allocating new resources in loops
- Prefer closures over classes
- Prefer plain data objects over class instances
- Prefer parameterized functions over class methods
- Prefer pure functions
  - Inside pure functions: mutate in place rather than creating new objects
  - At function boundaries: clone objects going in and out to prevent shared mutation
- Always clean up created resources
  - ALWAYS find the right place to destroy or dispose resources
  - Always cancel async processes on failure or when superseded
- Use normal ES imports at module top; avoid inline require/import unless necessary

## UI Programming

- Unless specified, style with shadcn. Keep it clean and slick.

## Testing

- TDD whenever possible
- Run only tests the change touches. Use `--testNamePattern` to filter when possible
- When writing tests:
  - Be concise — combine related cases in one test when they share the same logic
  - Prefer performant test code
  - Assert outputs directly — no conditional logic (`if`) to pass tests
  - Never make tests conditional to force them to pass

## General Workflows

- IMPORTANT: Do NOT mention Claude in commit messages. Describe actual changes only.
- Always open PRs as Draft.

### Planning

- Sacrifice grammar for concision
- List unresolved questions at the end
- Fan out independent work to parallel subagents; don't serialize what can run concurrently
- Always suggest verification steps when not specified

## Status Line

- For any changes to the Claude Code status line, use the "statusline-setup" agent
