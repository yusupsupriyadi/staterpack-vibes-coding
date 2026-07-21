## graphify

This project has a knowledge graph at graphify-out/ with god nodes, community structure, and cross-file relationships.

Rules:

- For codebase questions, first run `graphify query "<question>"` when graphify-out/graph.json exists. Use `graphify path "<A>" "<B>"` for relationships and `graphify explain "<concept>"` for focused concepts. These return a scoped subgraph, usually much smaller than GRAPH_REPORT.md or raw grep output.
- If graphify-out/wiki/index.md exists, use it for broad navigation instead of raw source browsing.
- Read graphify-out/GRAPH_REPORT.md only for broad architecture review or when query/path/explain do not surface enough context.
- After modifying code, run `graphify update .` to keep the graph current (AST-only, no API cost).

# Mandatory Superpowers Workflow

Superpowers is the default development methodology for this repository.

## Skill Gate — Required Before Every Response

Before responding, asking clarification questions, creating a plan, inspecting files, editing code, or running commands:

1. Check all available skills for relevance to the current task.
2. If there is even a small possibility that a skill applies, invoke it using the `Skill` tool.
3. Use the fully qualified skill name, for example:
       - `superpowers:brainstorming`
       - `superpowers:writing-plans`
       - `superpowers:subagent-driven-development`
       - `superpowers:test-driven-development`
       - `superpowers:systematic-debugging`
       - `superpowers:verification-before-completion`

4. Do not merely state that you are using a skill. Actually invoke the skill and follow its complete instructions.
5. Never replace a skill invocation with your memory or summary of that skill.
6. If multiple skills apply, invoke them in the appropriate order.

This skill check is mandatory on every turn, including follow-up requests.

## Required Development Lifecycle

For any non-trivial feature, behavior change, refactor, or architectural work, follow this lifecycle unless the user explicitly limits the task to investigation or discussion:

1. Invoke `superpowers:brainstorming`.
2. Explore the repository and clarify requirements through the brainstorming process.
3. Present the proposed design and obtain user approval before implementation.
4. Invoke `superpowers:writing-plans`.
5. Produce a detailed, executable implementation plan.
6. Invoke `superpowers:using-git-worktrees` when isolation is appropriate.
7. Invoke `superpowers:subagent-driven-development` to execute the approved plan when subagents are available.
8. Invoke `superpowers:test-driven-development` before writing production implementation code.
9. Invoke `superpowers:requesting-code-review` after implementation.
10. Invoke `superpowers:verification-before-completion` before claiming the task is complete.
11. Invoke `superpowers:finishing-a-development-branch` when the implementation branch is ready.

Do not combine brainstorming, planning, and implementation into one uncontrolled step.

## Mandatory TDD Gate

Before creating or modifying production behavior:

1. Invoke `superpowers:test-driven-development`.
2. Write the failing test first.
3. Run the test and confirm the expected failure.
4. Write only the minimum implementation required to pass.
5. Run the test and confirm it passes.
6. Refactor while keeping all tests passing.

Do not write production code first and add tests afterward.

Exceptions are limited to documentation, static configuration, generated files, or tasks where tests are genuinely impossible. State the reason before proceeding with an exception.

## Debugging Gate

For every bug, failed test, unexpected output, deployment failure, integration issue, or inconsistent behavior:

1. Invoke `superpowers:systematic-debugging`.
2. Gather evidence and reproduce the issue.
3. Identify the root cause before changing code.
4. Do not apply speculative fixes.
5. Add or update a regression test before finalizing the fix.

## Completion Gate

Never say “done”, “fixed”, “working”, “complete”, or equivalent unless:

1. `superpowers:verification-before-completion` has been invoked.
2. Relevant tests, type checks, linting, and build commands have been run.
3. Their actual results have been inspected.
4. The implementation has been compared against the approved specification and plan.
5. Remaining limitations or unverified areas have been disclosed.

Evidence must come before completion claims.

## Interaction Rules

- Use `AskUserQuestion` when the workflow requires structured user decisions.
- Ask one focused question at a time during brainstorming.
- Do not begin implementation before the design is approved.
- Do not silently skip worktrees, subagents, testing, review, or verification.
- Do not create unnecessary abstractions or unrelated improvements.
- Follow YAGNI, DRY, and the existing repository conventions.
- Maintain a visible task list for multi-step work.
- Mark tasks complete only after their verification succeeds.

## Required First Response

At the beginning of every development task, briefly report:

- which Superpowers skill or skills were invoked;
- why they apply;
- the current workflow phase;
- what must happen before implementation begins.

If no Superpowers skill applies, explicitly state which available skills were evaluated and why none applies. Do not use this exception casually.

These instructions take precedence over the impulse to immediately inspect, plan, or edit code.

## Core Rule: Verify Before Claiming

Never assume the current state of the system.

Before making any claim about what exists, what changed, what is working, or what has been completed, verify the actual state using available tools or direct inspection.

### Rules

- Treat system state as dynamic and subject to change at any time.
- Do not use previous actions, prior sessions, memory, or assumptions as proof of the current state.
- Clearly distinguish between what was previously done and what is currently verified.
- Never present assumptions as facts.
- Claims such as `completed`, `fixed`, `running`, `created`, `deleted`, `updated`, or `working` must be supported by fresh verification.
- If verification is not possible, explicitly state that the current state is unverified.
- After making a change, validate the result before reporting success.
- Base conclusions on observable evidence, not inference alone.

### Required Workflow

**Inspect → Act → Verify → Report**

Do not claim success before verification is complete.

## Core Rule: Use Context7 for Up-to-Date Documentation

Use Context7 MCP whenever a task depends on external libraries, frameworks, SDKs, APIs, tools, or other version-sensitive technical information.

### Rules

- Do not rely solely on memory for version-sensitive technical information.
- Inspect the project first to identify the technology, dependency, and version in use.
- Resolve the correct library or package before retrieving documentation.
- Prefer documentation that matches the project’s actual dependency and version.
- Retrieve only information relevant to the current task.
- Prefer official, authoritative, and version-specific sources.
- Do not introduce APIs, options, or patterns that are not supported by the retrieved documentation.
- Clearly distinguish documented behavior from recommendations or assumptions.
- If Context7 does not provide sufficient or relevant documentation, search the internet.
- When searching the internet, prioritize official documentation, release notes, source repositories, and trusted technical references.
- Cross-check conflicting or unclear information before using it.
- If reliable documentation still cannot be found, state that the information is unverified and do not present it as fact.
- After implementation, validate the result against the project’s actual environment.

### Required Workflow

**Inspect Project → Identify Dependency → Search Context7 → Search the Internet if Needed → Implement → Verify**

Use Context7 as the primary documentation source and the internet as a fallback.
