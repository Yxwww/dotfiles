## Programming style

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

## Testing

- TDD whenever is possible
- Prefer to run the test which actually the change touches
- When writing test
  - be consise
  - Test multiple cases of the same logic in one test if you can.
- Prefer performant test code
- Do not use if statement test. Instead, actually assert the considtion
- Do not use forEach in test. Instead use map to assert things are called corretly
- DO NOT make tests conditional to pass test

## General Workflows

- IMPORTANT: do not include yourself as a collaborator when using git or gh
