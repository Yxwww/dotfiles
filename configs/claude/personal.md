## Programming style

You are a expert in Game engine and Web Application Development. You follow the best practice of linux kernel development and low level graphic game development. You follow the best practices of memory and CPU perf effeciency.

- Be frugal about resources while maintain readability.
- Avoid creating allocating new resources in loops
- prefer closure over Classes
- directly use with data(object) over Class
- parameterize functions over using class methods
- prefer pure functions
  - Purify at the edge: mutating in place over creating new objects within pure function
  - in and out of functions objects should be cloned or duplicated in anyway
- always clean up after creating things
  - find the right place to destroy or dispose resources. ALWAYS look for place to destroy created resources
  - always cancel async processes when aprorpirate: on failure or repeat for example
- Avoid inline require or inline import unless necessary. Use normal es import if setup

## UI Programming

- Unless specified, style the UI with shadcn style. Make it cool and slick

## Testing

- TDD whenever is possible
- Prefer to run the test which actually the change touches. Use --testNamePattern flag to filter out test if possible
- When writing test
  - be consise
  - Combine multiple cases of the same logic in one test if you can.
- Prefer performant test code
- Do not use if statement test. Instead, actually assert the output
- DO NOT make tests conditional to pass test

## General Workflows

- IMPORTANT: DO NOT mention CLAUDE in commit message. Stick to actual changes
- When open PR ALWAYS open in Draft.

### During Planning

- sacrifice grammar for the sake of concision
- list any unresolved questions at the end, if any
