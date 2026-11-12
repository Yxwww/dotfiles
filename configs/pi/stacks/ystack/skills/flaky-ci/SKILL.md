---
name: flaky-ci
description: >
  Debug a test or build that passes locally but fails intermittently in CI, by turning CI into
  an observable remote debugging target instead of guessing locally. Enforces a bounded local
  repro budget, then a stop-and-confirm gate before pushing instrumentation. Forbids the
  timeout-retry-skip loop. Trigger when the user says CI is flaky, "fails in CI but passes
  locally", "can't reproduce", "intermittent failure", "only fails on CI", or when a CI run
  failed and a local run of the same command is green. Not for deterministic local bugs — use
  diagnosing-bugs.
---

# Flaky CI

A flaky failure is a **missing observation**, not a missing retry.

Local runs differ from CI in ways you cannot see: core count, memory ceiling, wall-clock
budget, CPU contention from parallel jobs, TZ, locale, filesystem ordering, cold caches.
When you cannot reproduce locally, continuing to run the same command locally is not
diagnosis — it is sampling from a distribution you cannot observe. Switch surfaces.

## The core move

**CI is a debugger you can instrument, not just a verifier you pass.** It is the only place
the failure actually happens, and it is hermetic and reproducible in a way your laptop is
not. Push code whose job is to make the failure *self-describing* in the log, then read it.

The failure mode this skill exists to prevent:

```
run locally → green → bump timeout → push → still flaky → add retry → green once
→ "fixed" → flaky again next week
```

Every lap of that loop costs a full CI round-trip and leaves the test suite strictly worse.

## Phase 1 — Bounded local repro

Cheap, and sometimes it works. Timebox it hard.

- **Read the actual CI log first.** Not the summary. The full job log, the stack, the
  assertion diff, the test names that failed, whether the failure is the same each time.
  Get the diagnostics that already exist before you add any.
- **Match the CI environment as closely as cheaply possible** for one attempt: same Node/
  runtime version, same test runner flags, single-threaded, `CI=true`, same TZ.
- **Provoke it.** Run the suspect test in a loop (`--repeat`, `while` loop, or the runner's
  own retry-until-fail) — 20–50 iterations, not 2. Many flakes are 1-in-20 and a single
  green run proves nothing. Run the *shard*/suite, not just the one test, if the log hints
  at ordering.
- **Vary the axis you suspect**: with/without `--parallel`, with low `--maxWorkers`, under
  CPU load, with a clean cache.

**Budget: 2–3 distinct attempts, each with a stated hypothesis.** Distinct means the
hypothesis changed the command. Re-running the same green command is not an attempt.

Stop immediately if you catch yourself about to raise a timeout, add a retry, add a
`sleep`, or widen an assertion tolerance. That is the signal that you have run out of
hypotheses — go to Phase 2.

## Phase 2 — Stop and confirm (required)

Do not push instrumentation without asking. Report and wait:

1. What failed in CI, quoted from the log.
2. What you tried locally and what happened.
3. Your top 1–3 hypotheses, and **the specific log line that would confirm or kill each**.
4. The instrumentation you intend to add and how many CI runs you expect it to take.

Then ask the user for the go-ahead. Instrumented pushes are visible side effects on shared
branches — the user may prefer a scratch branch, a draft PR, or a different approach.

## Phase 3 — Instrument for CI

Goal: the next CI failure explains itself. Instrument the **boundary**, dump the
**environment**, and make output survive failure.

**Environment dump** (once, at suite setup, gated behind an env flag or `CI`):

- runtime + dependency versions actually resolved (lockfile truth, not `package.json`)
- CPU count, `os.cpus().length`, available/total memory, container memory limit
- parallelism: worker/shard count, which shard this is
- TZ, locale, `LANG`, current time, any clock or seed source
- cache state (cold/warm), whether artifacts were restored

**Instrument the boundary, not the middle.** Around the flaky operation, log:

- inputs and preconditions (the pre-actual state, not just the expected)
- start/end timestamps and elapsed ms — makes a timing hypothesis readable at a glance
- for async: which promise resolved first, resolution order, queue depth, pending timers
- for ordering/state: a per-worker identity tag, and the full accumulated state at failure
- **on failure**: the real value, not a matcher's truncated diff

**Rules for the instrumentation itself:**

- Every added log carries a greppable unique marker, e.g. `[dbg-flaky]` — you will strip
  them later and you must be able to find all of them.
- Never let instrumentation change behaviour. No added `await`, no reordered operations,
  no extra serialization that could hide the race. A Heisenbug that vanishes under logging
  is itself evidence — note it and report it.
- Prefer structured single-line output. Multi-line dumps get truncated or interleaved by
  parallel workers.
- Capture artifacts, not just stdout: on failure, write state dumps / screenshots / traces
  to an artifact path the CI uploads. Logs get truncated; artifacts do not.

**Loop it.** Read the CI output, form one hypothesis, add the *one* log that discriminates
it, push, read. Resist adding everything at once — you cannot attribute a result to a probe
you did not isolate.

## Phase 4 — Round-trip cost is the whole game

The loop is only as fast as the CI round-trip. Cut it deliberately:

- **Trigger only the failing job** — job/workflow filter, `workflow_dispatch` with inputs,
  a path filter, or a debug branch whose workflow runs just that test.
- **Skip what the answer does not need** — lint, build, unrelated shards, deployment steps.
- **Fail the job but keep the output** — ensure artifacts upload and logs print on failure
  (`if: always()` / equivalent). A job that dies before upload teaches you nothing.
- **Use the CI provider's re-run** to accumulate samples of the *same* commit: flake rate is
  data. N runs of the same SHA tells you whether the instrumentation changed anything.
- **Consider a container that mirrors CI** to make the round-trip local — once you know
  *what* differs. Do not build this before you have a hypothesis; that is the same
  guessing loop in disguise.

## Phase 5 — Exit criterion

You are done when you can state a **causal chain**: *this input, in this environment, under
this ordering/timing, produces that observed failure in the CI log,* and the fix addresses
that chain.

Not done when:

- "It's green now" — green is not an explanation.
- "The retry passed" — you hid it.
- "Nobody's complained" — a skipped test is a deleted test.

Then, and only then, apply the fix.

## Flakiness buckets → discriminating probe

| Bucket | Signature in the log | Probe |
| --- | --- | --- |
| Timing / async | fails only under load; passes in isolation | timestamps around the await; event ordering; is the wait a fixed `sleep` rather than a condition? |
| Ordering / shared state | fails when the full suite or a shard runs; per-test green | worker/shard id tag; accumulated state dump; run with a reversed or shuffled order, log the seed |
| Randomness | different assertion values each run | unseeded generator, map/set iteration order, `Date.now()`, `Math.random`, `crypto.randomUUID`, test order randomization — log the seed and replays |
| Parallel / resource | more failures with higher concurrency | worker count vs. failures; memory ceiling; port/DB/fixture collisions between workers |
| Environment drift | works on one runner class, not another | the environment dump above, diffed against a known-good run |
| Network / external | intermittent timeouts, not reproducible offline | mock/real boundary; log the request, retry count, and actual latency |
| Wall-clock budget | close to a timeout, varies with machine | elapsed ms vs. the configured limit; is the test flaky or genuinely slow? |

## Allowed fixes vs. the forbidden ones

**Allowed** — they remove the nondeterminism:

- replace `sleep(n)` with a wait on an explicit condition (poll/predicate with a generous
  ceiling, so it never masks a real hang)
- pin seeds and log them; pin test order when order matters to the contract
- isolate shared state: per-worker DB/schema, unique ports/fixtures, `beforeEach` reset
- make the assertion compare the real value with a readable diff
- raise a timeout **only** with evidence that the operation is genuinely slow at CI's
  resources — and then also reduce the work

**Forbidden** — they hide the nondeterminism:

- raising a timeout to paper over a race
- adding or increasing retries
- adding arbitrary `sleep`
- loosening an assertion or widening a tolerance
- `skip` / `only` / quarantine without a linked ticket and an owner
- merging on a green re-run

If you cannot fix it now, quarantine is legitimate — but it requires: a tracked ticket, a
note in the test explaining what is known and suspected, and the instrumentation stripped.

## Before you commit

Instrumentation must never reach the PR.

- Strip every `[dbg-flaky]` line: `rg -n '\[dbg-flaky\]'`.
- Revert any temporary env dumps, workflow debug steps, `--verbose` flag changes, and
  job-filter edits.
- Confirm the diff contains only the fix plus any instrumentation you *deliberately* keep as
  permanent, always-on value (e.g. an environment header line in CI output — useful, keep
  it, but say so).
- The final PR should contain: the fix, and a link to the CI run that evidenced the cause.
