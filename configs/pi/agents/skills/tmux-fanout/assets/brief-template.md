# Worker brief — <ROLE>

> Replace `<ROLE>` and the bracketed fields. Keep it self-sufficient: a `pi -p`
> agent reads only this and exits — it cannot ask you a clarifying question
> mid-run. The orchestrator prepends a completion-protocol section telling the
> agent to write `<role>.result` and `touch <role>.done`; you do NOT need to
> mention those here. Describe the work only.

You are a pi coding agent working in `<repo path>`.

## Scope (what you own)

<One sentence. Name the exact files/dirs this agent may touch.>

## Out of scope (what you must NOT touch)

<List files/dirs owned by other parallel agents, or anything shared. Disjoint
ownership is how parallel runs stay safe — when in doubt, do nothing rather
than edit a contested file.>

## Task

<Concrete, ordered steps. Prefer exact paths and commands over prose. If a
decision is required, state the default you should take so the agent doesn't
block.>

## Verification

<How the agent confirms its own work before signaling done — e.g. "run
`bun build …`", "grep that the symlink resolves with `ls -lL`", "load the
extension via `pi -p 'reply ready'`". Verification is mandatory; an unverified
claim is what the Devil's Advocate reviewer will catch.>

## Done

Report a one-paragraph summary of what you wrote/edited and the verification
you ran. (The orchestrator captures this into `<role>.result` automatically —
just write the summary as your final message.) Do not commit.
