# Common Constraints

Shared constraints for all agents. Reference this file instead of duplicating.

## Minimal Changes Principle

Make the SMALLEST change that solves the problem.

**DO:**

- Touch ONLY files directly related to the issue requirements
- Make focused changes that directly address the issue
- Prefer 10-line fixes over 100-line refactors
- Keep scope strictly within issue requirements

**DO NOT:**

- Refactor unrelated code
- Add features beyond issue requirements
- "Improve" code outside the issue scope
- Restructure unless explicitly required by the issue

**Rule of Thumb**: If it's not mentioned in the issue, don't change it.

## Scope Discipline

- Complete assigned task, nothing more
- Do not refactor "while you're in there"
- Do not add features beyond requirements
- Do not "improve" unrelated code

## When Blocked

1. Document what's blocking you
2. Document what you tried
3. Escalate to immediate supervisor
4. Continue with non-blocked work if possible

## Work Without Issue Number

**STOP** - Do not start work without a GitHub issue number.

- Request issue creation first
- All work must be tracked

## Command Execution

### Never Use `cd`

**CRITICAL**: All commands MUST be run with relative paths from project root.

❌ **WRONG:**
```bash
cd frontend/WavelengthWatch
./run-tests-individually.sh
```

✅ **CORRECT:**
```bash
frontend/WavelengthWatch/run-tests-individually.sh
```

**Why:** Using `cd` creates hidden directory state that causes confusion, breaks command sequences, and makes debugging harder.

### Always Use Test Scripts

For frontend tests, **always use the test script** instead of direct tool invocation.

❌ **WRONG:**
```bash
xcodebuild test -scheme "WavelengthWatch Watch App"
```

✅ **CORRECT:**
```bash
frontend/WavelengthWatch/run-tests-individually.sh
```

**Why:** Test scripts encapsulate proper configuration, simulator management, and cleanup. Direct invocation bypasses these safeguards.
