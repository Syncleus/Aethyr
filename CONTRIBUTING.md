# Contributing

[![Commitizen friendly](https://img.shields.io/badge/commitizen-friendly-brightgreen.svg)](http://commitizen.github.io/cz-cli/)
[![Clever Semantic Versioning](https://img.shields.io/SemVer/2.0.0.png)](https://www.w3.org/submissions/semantic-versioning/)
[![Matrix](https://img.shields.io/matrix/cleverthis%3Aqoto.org?server_fqdn=matrix.qoto.org&label=Matrix%20chat)](https://matrix.to/#/#CleverThis:qoto.org)

When contributing to this repository, it is usually a good idea to first discuss the change you
wish to make via issue, email, or any other method with the owners of this repository before
making a change. This could potentially save a lot of wasted hours.

Please note we have a code of conduct, please follow it in all your interactions with the project.

## File Organization

All project files should be organized in appropriate subdirectories rather than placed in the
project root. The root directory should be reserved for standard ecosystem files that
conventionally live there (e.g., project manifests, lock files, CI configurations,
`.gitignore`, `README`, `CONTRIBUTING`, `LICENSE`, and similar well-known files). Any file that
is not a widely recognized root-level convention belongs in a subdirectory.

Each directory should have a clear, single purpose — do not mix concerns. For example, source
code directories must not contain test files, documentation, mocking code, or examples. Test
directories must not contain production source code. Documentation, configuration, scripts, and
examples should each have their own designated locations.

### BDD Test Organization Guidelines

- **Group new steps with related ones.** Before adding a new step definition file, check for an
  existing file that covers the same behavior and extend it instead of creating a duplicate.
- **Name feature-specific step files after their feature.** Steps used only by a particular
  feature file should live in a correspondingly named step definition file.
- **Keep shared steps in purpose-driven modules.** Steps used across multiple features belong in
  clearly named, reusable files; prefer updating an existing shared file when it already fits the
  purpose before creating another one.
- **Ship features with complete implementations.** Every feature file must arrive with all of its
  steps fully implemented — never add placeholder steps or commit a feature without its supporting
  step code already in place.

## Development

### Testing

#### Testing Philosophy

- **Behavior-Driven Development (BDD):** All unit-level and scenario tests must follow the
  Behavior-Driven Development approach using a framework that adheres to the Cucumber/Gherkin
  standard. Feature files written in Gherkin syntax are the primary vehicle for expressing test
  scenarios. Integration and end-to-end tests may use a separate framework suited to that purpose.
- **Prefer BDD Over xUnit:** Do not write xUnit-style unit tests (e.g., JUnit, pytest, NUnit,
  xUnit.net). All unit-level tests should be expressed as BDD scenarios in Gherkin. This ensures
  tests are readable, behavior-focused, and serve as living documentation.
- **Multi-Level Testing Mandate:** Every coding task must include or update tests at multiple
  levels: unit tests, integration tests, and performance benchmarks. Testing is non-optional and
  is part of the definition of done for any task.
- **Task Runner Execution:** Run all test suites exclusively through the project's designated task
  runner. Do not invoke test frameworks directly from the command line. If the task runner is
  missing a required session or dependency, add it to the task runner configuration before
  proceeding.
- **Coverage Thresholds:** Test coverage must remain above the project-defined threshold at all
  times. Coverage is measured as part of the standard test pipeline and enforced automatically.
- **Failure Capture and Remediation:** Any test failure during development immediately becomes a
  blocking task. Document the failure context and resolve it before progressing to other work.
  Never leave a known-failing test unaddressed. Note: TDD bug-capture tests use the
  `@tdd_expected_fail` tag to pass CI while the bug is unfixed — see
  [Bug Fix Workflow](#bug-fix-workflow). These are not "unaddressed" failures; they are
  tracked and resolved through the TDD workflow.
- **Quality Gates:** Do not consider work complete until all tests pass, all documentation is
  updated, and all associated quality checks (linting, type checking, security scanning, etc.)
  succeed. All quality gates must pass before a task is marked done.

#### Running Tests

Tests are run through the project's task runner. Refer to the
[Project-Specific Guidelines](#project-specific-guidelines) section for exact commands and
session names.

### Commit Scope and Quality

A clean version control history is a cornerstone of maintainable, collaborative development.
Every commit should be an atomic, self-contained unit of change that can be understood, built,
tested, and if necessary reverted or cherry-picked with confidence. For a deeper discussion of
the principles behind these guidelines, see
[Writing High Quality, Well Scoped, Commits](https://jeffreyfreeman.me/blog/writing-high-quality-well-scoped-commits/).

#### Atomic Commits

- **One logical change per commit.** Each commit must encapsulate a single, focused change — one
  bug fix, one refactoring, one feature increment. If you are fixing two separate bugs or adding
  two independent features, use separate commits for each.
- **Related changes together, nothing more.** A commit should be a wrapper for related changes
  only. If one logical change requires edits across multiple files, those edits belong in one
  commit. Conversely, unrelated edits that happen to touch the same file should be split into
  separate commits.
- **Do not mix concerns.** Never bundle cosmetic changes (reformatting, renaming, whitespace
  fixes) with functional changes in the same commit. If you need to reformat code, do so in a
  dedicated commit containing no semantic changes. Similarly, isolate large-scale code moves or
  renames into their own commits — perform a pure move in one commit, then make modifications in
  the next. This keeps diffs readable and preserves accurate file history.

#### Commit Completeness

- **Include tests with the change.** If your change introduces or modifies behavior, the tests
  covering that behavior belong in the same commit. A feature and its tests are one logical unit
  of work — they either both go in, or neither does. This ensures that anyone checking out any
  commit in history can run the test suite and see it pass, including the new tests.
- **Include documentation with the change.** If your commit changes how something works, update
  the relevant documentation (README, user guide, code comments, API docs) in the same commit.
  Do not defer documentation to a later commit — if someone checked out your commit, they should
  have everything needed to understand and use the change.
- **Update ancillary files.** Configuration, build scripts, changelogs, and other metadata
  affected by the change should be updated in the same commit. The project should never be in a
  state where the code says one thing but the documentation or configuration says another.
- **Do not commit half-done work.** Only commit when a piece of functionality is fully
  implemented and tested. Incomplete code — partial features, failing tests, placeholder
  implementations — does not belong in the commit history. Use feature branches or stashing to
  save work in progress.

#### Build and Test Integrity

- **Each commit must build and pass all tests.** The repository should be in a working state at
  every commit. If someone checks out any commit from history, the code must compile (or run) and
  all tests must pass. This is essential for tools like `git bisect` and for safely reverting
  individual commits.
- **Test before committing.** Run the project's test suite before each commit to verify nothing
  is broken. Do not commit code you *think* is complete — verify it.
- **Self-review the diff.** Before committing, review the staged diff to confirm only the
  intended changes are included and that no debugging statements, temporary code, or unrelated
  edits have crept in.

#### Independence and Revertibility

- **Each commit must be cleanly revertible.** If a commit were reverted, the codebase should
  still build correctly and make sense. This happens naturally when commits are atomic and
  self-contained — reverting one change does not entangle unrelated code.
- **Minimize hidden interdependencies.** Commits should not secretly rely on subsequent commits
  to function. If commit A prepares for commit B, A should stand on its own without leaving the
  system in a broken state.
- **Keep history bisect-friendly.** Since each commit represents a valid, testable state of the
  project, `git bisect` can reliably pinpoint where a regression was introduced. Broken
  intermediate commits defeat this capability.

#### Commit Hygiene

- **Commit often to keep changes small.** Frequent, small commits are easier to review, easier
  to merge, and easier to debug than infrequent large ones. It is always easier to squash
  several small commits together than to split one large tangled commit apart.
- **Use interactive staging.** Use your version control's staging tools (e.g., `git add -p`) to
  selectively stage changes, splitting mixed edits into separate focused commits.
- **Use topic branches.** Develop features and fixes on separate branches. This isolates work
  until it is complete and prevents half-finished commits from entering the main history.
- **Clean up history before merging.** Use interactive rebase or amend to fix typos, consolidate
  fixup commits, and polish the commit series before pushing to shared branches. The goal is a
  tidy history where every commit is meaningful, not a trail of corrections patching the previous
  commit.
- **Reference issues and tickets.** When a commit relates to a bug report, feature request, or
  discussion, include a reference (e.g., `Fixes #123`, `Refs: PROJ-456`) in the commit message
  footer. This provides traceability and can automatically close issues when commits are merged.

### Commit Message Format

All commits on this repository must follow the
[Conventional Changelog standard](https://github.com/conventional-changelog/conventional-changelog-eslint/blob/master/convention.md).
It is a very simple format so you can still write commit messages by hand. However it is
highly recommended developers install [Commitizen](https://commitizen.github.io/cz-cli/),
it extends the git command and will make writing commit messages a breeze. All CleverThis
repositories are configured with local Commitizen configuration scripts.

Getting Commitizen installed is usually trivial, just install it via npm. You will also
need to install the cz-customizable adapter which CleverThis repositories are configured
to use.

```bash
npm install -g commitizen@2.8.6 cz-customizable@4.0.0
```

Below is an example of Commitizen in action. It replaces your usual `git commit` command
with `git cz` instead. The new command takes all the same arguments however it leads you
through an interactive process to generate the commit message.

![Commitizen friendly](https://wiki.cleverthis.com/public_media/commitizen.gif)

Commit messages are used to automatically generate our changelogs, and to ensure
commits are searchable in a useful way. So please use the Commitizen tool and adhere to
the commit message standard or else we cannot accept Pull Requests without editing
them first.

Below is an example of a properly formated commit message.

```
chore(Commitizen): Made repository Commitizen friendly.

Added standard Commitizen configuration files to the repo along with all the custom rules.

ISSUES CLOSED: #31
```

#### First Line vs. Commit Body

A commit message has two distinct parts separated by a blank line:

1. **First line (subject line):** A short, structured summary following the Conventional
   Changelog format (e.g., `feat(cli): add tool and validation commands`). When an issue
   specifies a commit message in its Metadata section, that prescribed text is the first line
   and must be used exactly as written.
2. **Body (all subsequent lines after the blank line):** Free-form text where the contributor
   describes implementation details, rationale, trade-offs, and any other relevant context.
   The body is at the contributor's discretion and should be appropriate in length for the
   scope of the change — detailed enough to explain *what* was done and *why*, but not
   excessively long. The body should also include the issue reference footer (e.g.,
   `ISSUES CLOSED: #45`).

Example with a prescribed first line from an issue's Metadata:

```
feat(cli): add tool and validation commands

Implemented `agents tool add/remove/list/show` with YAML config input and
schema validation. Added `agents validation attach/detach` for resource-scoped
validation attachments. Updated CLI reference documentation.

ISSUES CLOSED: #280
```

### Pull Request Process

> **Terminology:** "Pull Request" (PR) and "Merge Request" (MR) are used interchangeably in
> this project and its documentation. This project is hosted on Forgejo, which uses the term
> "Pull Request."

Every Pull Request must meet the following requirements before it is submitted for review:

1. **Provide a detailed description.** Every PR must include a clear, descriptive body that
    explains the purpose of the change, summarizes what was done and why, and provides enough
    context for a reviewer to understand the PR without reading every line of code. At a
    minimum, the description must contain:
    - A **summary** of the changes and the motivation behind them.
    - An **issue reference** using a closing keyword that Forgejo recognizes (e.g.,
      `Closes #45`, `Fixes #45`) so that the linked issue is automatically closed when the PR
      is merged. If the PR addresses multiple issues, include a closing keyword for each.
    - A **dependency link**: in addition to the textual reference, add the linked issue as a
      Forgejo dependency on the PR **with the correct direction**: the PR must be marked as
      **blocking** the issue, and the issue must **depend on** the PR. This means that on the
      PR you add the issue under "blocks", and on the issue the PR appears under "depends on."
      Getting this direction right is critical — if the dependency is reversed (the issue
      blocking the PR), Forgejo will prevent the PR from being merged or closed until the
      issue is resolved, which is the opposite of the intended workflow. See
      [Linking and Dependencies](#linking-and-dependencies) for a full explanation of
      dependency direction.

    If your change is not associated with an existing issue, create one first — see
    [Creating Issues](#creating-issues). PRs submitted without a description or without an
    issue reference will not be reviewed.
2. **One Epic scope per PR.** Each PR must be associated with a single Epic. Do not combine
   work from multiple unrelated Epics in one PR. If your changes span multiple Epics, split
   them into separate PRs.
3. **Atomic, well-scoped commits.** All commits in the PR must follow the
   [Commit Scope and Quality](#commit-scope-and-quality) guidelines. Each commit should be
   small, self-contained, and independently buildable and testable.
4. **Commit messages reference tickets.** Every commit in the PR must reference the issue it
   addresses in its commit message footer (e.g., `ISSUES CLOSED: #45` or `Refs: #45`). See
   [Commit Message Format](#commit-message-format).
5. **Follow the Conventional Changelog standard.** All commit messages must follow the
   [Conventional Changelog](https://github.com/conventional-changelog/conventional-changelog-eslint/blob/master/convention.md)
   standard as described in [Commit Message Format](#commit-message-format).
6. **Update the changelog.** The PR must include an update to the changelog file. Add one new
   entry per commit in the PR that describes the change from the user's perspective.
7. **No build or install artifacts.** Ensure that install or build dependencies do not appear
   in any commits in the PR.
8. **Update CONTRIBUTORS.md.** Add your name to `CONTRIBUTORS.md` if it is not already listed
   (one entry per person).
9. **Adjust the version number (when applicable).** If your change warrants a version bump,
    update the project version to reflect the new version that this PR represents, following
    [Clever Semantic Versioning](https://www.w3.org/submissions/semantic-versioning/) as
    described in the [Versioning](#versioning) section. Note that most commits and Pull
    Requests will not require a version change — a bump is only appropriate when the change
    introduces new functionality, fixes a bug in a released version, or makes a breaking API
    change. Routine work such as refactoring, documentation updates, test improvements, or
    changes that have not yet been included in a release typically do not warrant a version
    bump.
10. **All automated checks must pass.** Before requesting review, ensure that all CI checks
      pass, including tests, linting, type checking, coverage, and security scans. PRs with
      failing checks will not be reviewed.
11. **Assign a milestone.** Every PR must be assigned to the same milestone as its linked
    issue(s). If the linked issues span multiple milestones, assign the PR to the milestone
    of the primary issue. A PR without a milestone will not be reviewed.
12. **Apply a Type label.** Every PR must carry exactly one `Type/` label that matches the
    nature of the change — the same `Type/` labels used for issues (e.g., `Type/Bug`,
    `Type/Feature`, `Type/Task`). This enables filtering and searching PRs by the kind of
    work they contain. Other label scopes (`State/`, `Priority/`, `MoSCoW/`) are primarily
    used on issues, but may occasionally be applied to Pull Requests when warranted (e.g.,
    to track PR-specific workflow state or to flag a PR for special handling).

#### After Submission

Once your PR is submitted:

- Move the associated issue(s) to `State/In review` (see
  [Ticket Lifecycle](#ticket-lifecycle)).
- A maintainer will review your PR. We aim to provide initial feedback within 48 hours.
- Your PR will either be approved or you will receive specific feedback on what needs to be
  changed. If changes are requested, address them and push updated commits.
- Once all requirements are met (see
  [Review and Merge Requirements](#review-and-merge-requirements) below), a maintainer will
  merge the PR.
- After the PR is merged, move the associated issue(s) to `State/Completed`.

### Review and Merge Requirements

For a Pull Request to be merged, **all** of the following conditions must be satisfied.

#### Automated Checks

All CI pipeline checks must pass. This includes, but is not limited to:

- All tests (unit, integration, and any other applicable test suites).
- Linting and code formatting.
- Static type checking.
- Security scanning.
- Test coverage must remain at or above the project-defined minimum threshold. The general
  minimum is **85%**. Individual projects may enforce a higher threshold — see the
  [Project-Specific Guidelines](#project-specific-guidelines) section for this project's exact
  requirement.

#### Peer Review

- **Minimum approvals:** Every PR requires at least **two (2)** approving reviews from project
  contributors who are not the PR author.
- **No unresolved objections:** At the time of merge, there must be no open "Request Changes"
  or "Rejected" reviews. All requested changes must be addressed and the reviewer must either
  re-approve or withdraw their objection before the PR can be merged.
- **Author exclusion:** The author of a PR cannot serve as one of its reviewers. Self-approval
  does not count toward the required approvals.
- **What reviewers evaluate:** Reviewers are expected to assess the PR for:
  - **Correctness:** Does the code do what it claims to do? Does it satisfy the acceptance
    criteria of the linked issue(s)?
  - **Readability:** Is the code clear, well-named, and easy to follow?
  - **Performance:** Are there unnecessary inefficiencies, redundant operations, or potential
    scalability concerns?
  - **Security:** Does the code introduce any security vulnerabilities or unsafe patterns?
  - **Style:** Does the code follow the project's coding standards and conventions?
  - **Test coverage:** Are the tests adequate? Do they cover edge cases and failure modes?
- **Maintainer override:** In exceptional circumstances, a project owner may override the
  review requirements to merge a PR with fewer approvals. This is reserved for urgent fixes
  and is not the norm.

#### Merge Checklist

Before a PR is merged, confirm the following:

- [ ] PR description is detailed, explains the change, and includes closing keywords for all
      linked issues (e.g., `Closes #45`)
- [ ] Linked issues are added as Forgejo dependencies on the PR with the correct direction
      (the PR **blocks** the issue; the issue **depends on** the PR)
- [ ] All CI checks pass (tests, linting, type checking, security, coverage)
- [ ] Test coverage meets or exceeds the project-defined threshold
- [ ] At least two approving reviews from non-author contributors
- [ ] No open "Request Changes" or "Rejected" reviews
- [ ] All commits follow Conventional Changelog format
- [ ] Every commit references its associated issue
- [ ] Changelog has been updated
- [ ] CONTRIBUTORS.md has been updated (if applicable)
- [ ] Version number has been updated
- [ ] PR is assigned to the correct milestone (matching its linked issues)
- [ ] PR has exactly one appropriate `Type/` label
- [ ] Associated issue(s) are in `State/In review` or `State/Completed`

### Versioning

All projects must follow
[Clever Semantic Versioning](https://www.w3.org/submissions/semantic-versioning/). Version
numbers take the form `MAJOR.MINOR.PATCH` where:

- **MAJOR** is incremented for incompatible API changes.
- **MINOR** is incremented for backwards-compatible new functionality.
- **PATCH** is incremented for backwards-compatible bug fixes.

Breaking changes are only permitted in major version increments. Every release must have a
version number that accurately communicates the nature of its changes to consumers. Refer to
the project-specific [Backwards Compatibility](#backwards-compatibility) section for details on
how this project applies these rules during its current development phase.

## Code Style & Best Practices

### General Principles

- **Specification-First Development:** Treat the project specification as the authoritative source
  of truth for design and architecture. Architectural changes follow an ADR (Architecture Decision
  Record) process: proposed changes must first be captured in an ADR, reviewed, and approved.
  Once approved, the decision is incorporated into the specification, which then serves as the
  definitive source of truth for implementation. Code should only be written to reflect what the
  specification describes — when there is a discrepancy between the current codebase and the
  specification, always assume the specification is correct and align the code accordingly.
- **Modern Tooling:** Use modern, idiomatic build tools and workflows for the project's language
  ecosystem. Avoid legacy approaches such as Makefiles or wrapper shell scripts. All tooling
  should be from the current ecosystem and used as designed — not wrapped in custom scripts.
- **Prefer Existing Tooling:** When the project's current tools can solve a problem, use them
  rather than introducing new dependencies. Keep the toolchain simple and consistent. Adding new
  tooling should be a deliberate decision, not a default.
- **Modular Design:** Keep files under 500 lines. Break large files into focused, cohesive modules.
- **Environment Safety:** Never hardcode secrets or sensitive information.
- **Test-First Development:** Write tests before implementation.
- **Clean Architecture:** Separate concerns, maintain clear boundaries between layers.
- **Documentation:** Keep all documentation updated alongside code changes.

### Import Guidelines

- **Idiomatic Usage:** Follow the import conventions established by the project's language and
  ecosystem. When the language or its style guide prescribes a standard way to declare imports,
  use it consistently.
- **Narrow Imports:** Import only what is needed. Prefer importing specific symbols over broad
  wildcard or module-level imports to keep dependencies explicit and avoid polluting the local
  namespace.

### Programming Patterns

Use these patterns and principles liberally throughout the codebase:

#### SOLID Principles

- **Single Responsibility Principle (SRP):** Each class should have one reason to change; one responsibility only.
- **Open/Closed Principle (OCP):** Classes should be open for extension but closed for modification.
- **Liskov Substitution Principle (LSP):** Subtypes must be substitutable for their base types without altering program correctness.
- **Interface Segregation Principle (ISP):** Clients should not be forced to depend on interfaces they don't use; prefer small, specific interfaces.
- **Dependency Inversion Principle (DIP):** Depend on abstractions, not concretions; high-level modules should not depend on low-level modules.

#### Creational Patterns

- **Factory Pattern:** For object creation with complex initialization logic.
- **Abstract Factory Pattern:** For creating families of related objects without specifying concrete classes.
- **Builder Pattern:** For constructing complex objects step by step with fluent interfaces.
- **Prototype Pattern:** For cloning objects instead of creating new instances.
- **Singleton Pattern:** For single-instance resources (use sparingly, prefer dependency injection).
- **Object Pool Pattern:** For reusing expensive-to-create objects.
- **Dependency Injection:** For testability and inversion of control.

#### Structural Patterns

- **Adapter Pattern:** For interface compatibility between incompatible classes.
- **Bridge Pattern:** For separating abstraction from implementation to vary them independently.
- **Composite Pattern:** For treating individual objects and compositions uniformly in tree structures.
- **Decorator Pattern:** For extending functionality without modifying original code.
- **Facade Pattern:** For providing simplified interfaces to complex subsystems.
- **Flyweight Pattern:** For sharing common state among many objects to reduce memory usage.
- **Proxy Pattern:** For controlling access to objects (lazy loading, access control, logging).
- **Module Pattern:** For encapsulating related functionality in cohesive units.

#### Behavioral Patterns

- **Chain of Responsibility Pattern:** For passing requests along a chain of handlers.
- **Command Pattern:** For encapsulating operations as objects.
- **Interpreter Pattern:** For defining grammar and interpreting language sentences.
- **Iterator Pattern:** For sequential access to collection elements without exposing representation.
- **Mediator Pattern:** For centralizing complex communications between objects.
- **Memento Pattern:** For capturing and restoring object state without violating encapsulation.
- **Observer Pattern:** For event-driven architectures and loose coupling between publishers and subscribers.
- **State Pattern:** For altering object behavior when internal state changes.
- **Strategy Pattern:** For algorithms that can be selected at runtime.
- **Template Method Pattern:** For defining algorithm skeletons with customizable steps.
- **Visitor Pattern:** For separating algorithms from the objects they operate on.
- **Null Object Pattern:** For providing default behavior instead of null references.

#### Architectural Patterns

- **Repository Pattern:** For data access abstraction and separation of domain from data access logic.
- **Unit of Work Pattern:** For maintaining a list of objects affected by transactions and coordinating changes.
- **Service Layer Pattern:** For defining application boundaries and encapsulating business logic.
- **MVC (Model-View-Controller):** For separating data, presentation, and control logic.
- **CQRS (Command Query Responsibility Segregation):** For separating read and write operations.
- **Event Sourcing Pattern:** For storing state changes as a sequence of events.
- **Specification Pattern:** For encapsulating business rules and making them reusable and composable.

## Error and Exception Handling

### Argument Validation

**All public and protected class methods must validate arguments as the first guard.** Perform
these checks before any other logic. The purpose of argument validation is to ensure fail-fast
behavior — invalid inputs should be rejected immediately at the boundary where they enter, so
that errors surface close to their source rather than propagating silently into deeper logic
where they become difficult to diagnose.

**Checks to perform:**
- **Value Range:** Ensure numeric values are within acceptable bounds.
- **Null Checks:** Reject null values where not expected; explicitly accept them only when documented.
- **Type Verification:** In languages that support runtime type inspection, verify that arguments
  are of the expected type, following the idiomatic approach for the language. Prefer catching
  type errors at compile time through static type systems whenever possible; resort to runtime
  type checks only when the language lacks compile-time enforcement or when interfacing with
  untyped boundaries (e.g., deserialized input, dynamic plugin APIs).
- **Empty Strings:** Reject empty strings where non-empty strings are required.
- **Empty Collections:** Check for empty lists, maps, or sets if they must contain elements.
- **Invalid States:** Verify object state is valid for the operation.

### Exception Propagation

**CRITICAL: Do not suppress errors. Let exceptions propagate to top-level execution.**

- Exceptions should bubble up to the top level where they can be properly logged and handled.
- Do not catch exceptions just to log and re-raise; let them propagate naturally.
- Do not use bare catch-all exception handlers without re-raising unless you have specific
  recovery logic.

**Only catch exceptions when you can meaningfully handle them** (e.g., retry logic, resource
cleanup, adding context). Otherwise, let them propagate.

### Fail-Fast Principles

**Design code to fail immediately when something is wrong:**

- **Type Safety:** In languages that support static type systems or type annotations, use them
  extensively and run static type checkers as part of the standard build pipeline. In languages
  without static type systems, use whatever idiomatic mechanisms the language provides for
  expressing and verifying type constraints.
- **Early Validation:** Check preconditions at function entry, not deep in logic.
- **Assertions:** Use assertions for invariants that should never be violated during development.
- **No Silent Failures:** Avoid returning null or default values when an error condition
  exists — raise exceptions or return explicit error types.
- **Explicit Over Implicit:** Make failure conditions explicit rather than hiding them.

**Benefits:**
- Bugs are caught closer to their source.
- Stack traces are more meaningful.
- Debugging is faster.
- System state remains consistent.

### Best Practices Summary

- Validate all arguments in public/protected methods immediately.
- Use static type annotations and type checking where the language supports it.
- Let exceptions propagate; don't suppress them.
- Fail fast when preconditions aren't met.
- Only catch exceptions when you have meaningful recovery logic.
- Never catch exceptions just to log them — let them bubble up for centralized handling.

## Type Safety

Prefer static typing whenever the language supports it. When a language offers a static type
system or type annotation mechanism, use it pervasively and enforce it with a type checker in
the build pipeline. When the language does not have a static type system but provides idiomatic
mechanisms for expressing or verifying type constraints at runtime, use those instead. In
languages that offer neither, rely on the argument validation and fail-fast principles described
above to catch type-related errors as early as possible.

- **Full Annotations:** In languages with type annotation support, every function signature,
  variable declaration, and return type should be annotated with explicit types.
- **No Suppression:** When a static type checker is in use, never disable it via configuration
  files and never use inline comments or annotations to suppress individual type checking errors
  (e.g., no `type: ignore`, `noinspection`, `@SuppressWarnings`, or equivalent directives).
- **Continuous Enforcement:** Type checking, whether static or through other idiomatic means,
  must be part of the standard test and CI pipeline. It runs on every commit and must pass
  before work is considered complete.

## Test Isolation and Mock Placement

All mocks, test doubles, and mock implementations must exist only within test directories.
Production source code and utility scripts must never contain mock implementations, test data,
or conditional testing behavior.

- **Strict Separation:** Test support code (mocks, fakes, stubs, fixtures) lives exclusively in
  test directories. Source code directories are reserved for production code only.
- **No Conditional Test Behavior:** Production code must not contain `if testing:` guards,
  test-only code paths, or any logic that changes behavior based on whether the code is under
  test.
- **Dependency Injection:** Use dependency injection to swap implementations during tests. Design
  classes and functions to accept their dependencies as parameters rather than creating them
  internally, making it straightforward to substitute test doubles without modifying production
  code.
- **Unit Tests Only:** Mocks, fakes, stubs, and test doubles are permitted only in unit tests.
  Integration tests must exercise real services, real endpoints, and real dependencies — mocking
  of any kind is strictly prohibited in integration tests.

## Documentation Standards

- **Continuous Documentation:** Update documentation alongside code changes. Discoveries,
  decisions, and workarounds must be documented promptly — no decision should remain
  undocumented. If new information appears during implementation, extend the relevant
  documentation immediately before proceeding.
- **Single Documentation Surface:** Each type of documentation has a canonical location. Avoid
  scattering related notes across multiple files or locations. If a document exists for a
  particular purpose, update it rather than creating a new file elsewhere.
- **Traceability:** When a decision impacts future work, reference the relevant code by its
  logical location — for example, module path, class name, and method name (e.g.,
  `mypackage.services.user_service.UserService.authenticate`). Include the commit hash
  at the time of writing so that if names are later refactored, someone can trace the original
  location through version control history. **Never reference code by line number**
  (`file_path:line_number`) as line numbers shift with every edit and become misleading quickly.
  Record substantive design decisions, pattern choices, and risk mitigations in the appropriate
  documentation alongside these logical references to the code they affect.
- **Documentation Completeness:** Documentation updates are part of the definition of done for
  any task. Work is not complete until all affected documentation has been reviewed and updated
  to reflect the current state of the code.

## Issues and Project Management

This section describes how issues (also called tickets) are created, classified, and moved
through their lifecycle. Following these guidelines ensures that work is well-organized,
traceable, and easy for maintainers and contributors to coordinate on.

### Creating Issues

Anyone may create an issue at any time without prior approval. New issues automatically enter
the `State/Unverified` state (see [Ticket Lifecycle](#ticket-lifecycle) below). While you do
not need permission to open an issue, taking the time to write a well-structured issue greatly
increases the chances it will be acted on quickly.

Every issue must include:

- **Title:** A concise, descriptive summary of the work or problem. The title should be
  specific enough that a reader can understand the scope without opening the issue body. Avoid
  vague titles such as "Fix bug" or "Improve performance" — instead write something like
  "Fix null pointer when parsing empty configuration file" or "Add CSV export to usage metrics
  dashboard."
- **Labels:** When creating an issue, apply the appropriate labels from the
  [Label System](#label-system). At minimum, every new issue must have:
  - A **State** label — new issues should be labeled `State/Unverified` (this is the initial
    state for all issues; see [Ticket Lifecycle](#ticket-lifecycle)).
  - A **Type** label — one of `Type/Bug`, `Type/Feature`, `Type/Task`, `Type/Epic`, or
    `Type/Legendary`, as appropriate for the nature of the work.
  - A **Priority** label — if you have a suggested priority, apply it (e.g.,
    `Priority/Medium`). If unsure, use `Priority/Backlog` and a maintainer will adjust it
    during triaging.

  Do **not** assign `MoSCoW/` labels — these are set exclusively by the project owner.
- **Milestone:** Every non-Epic, non-Legendary issue that has moved beyond `State/Unverified`
  must be assigned to a milestone. `Type/Epic` and `Type/Legendary` issues are exempt from
  this requirement because they typically span multiple milestones; a milestone may optionally
  be assigned to them but is not required. Issues in `State/Unverified` may optionally have a
  milestone — it is not required at creation time, but is typically assigned by a maintainer
  during triaging when the issue is moved to `State/Verified`. Once a non-Epic, non-Legendary
  issue is in any active state (`State/Verified`, `State/In progress`, `State/Paused`,
  `State/In review`, or `State/Completed`), a milestone is mandatory. If no appropriate
  milestone exists, discuss with the project owner before proceeding.
- **Branch/Tag (Ref):** Forgejo issues have a **branch/tag** field (the `Ref` field on the
  issue form) that associates the issue with a specific branch or tag in the repository.
  The rules for this field depend on the nature of the issue:
  - **Development issues** (features, fixes, chores, refactoring — any issue where a branch
    is created for the work): the Ref field must be set to the **same branch** named in the
    issue body's Metadata section. This field becomes required when the issue moves to
    `State/In progress` or later, and must always reference a **branch**, not a tag. Setting
    this field allows Forgejo to associate the issue with the correct branch in its UI and
    link tracking.
  - **Non-development issues** (bug reports, questions, support requests, and other issues
    that do not have their own working branch): the Ref field may be left blank. If the
    issue relates to a specific branch or tag (e.g., a bug observed on a particular release
    tag, or a question about code on a specific branch), the field may optionally be set to
    that branch or tag for reference.
- **Description:** The body of the issue must contain the following sections:
  - **Background and context:** Why does this issue exist? What is the motivation?
  - **Current behavior** (for bugs): What is happening now that is incorrect or undesirable?
    Include reproduction steps, error messages, logs, or screenshots where applicable.
  - **Expected behavior:** What should happen instead, or what does "done" look like?
  - **Acceptance criteria:** A clear, testable list of conditions that must be met for the
    issue to be considered complete. Each criterion should be unambiguous enough that any
    reviewer can independently verify whether it has been satisfied.
  - **Supporting information:** Links to related issues, relevant documentation, screenshots,
    logs, reproduction steps, or any other material that helps clarify the issue.
  - **Metadata:** A section at the top of the issue body (typically labeled `## Metadata`)
    that contains:
    - **Commit message:** The exact first line of the commit message that should
      be used when committing work for this issue. This must follow the
      [Conventional Changelog](https://github.com/conventional-changelog/conventional-changelog-eslint/blob/master/convention.md)
      format (e.g., `feat(cli): add tool and validation commands`). When making the commit,
      this first line is followed by a blank line, after which the contributor may freely write
      additional lines in the commit body to describe the implementation details, rationale,
      and any other relevant context (see
      [Commit Message Format](#commit-message-format) for the full structure).
    - **Branch name:** The name of the branch that should be used for work on this issue
      (e.g., `feature/m3-tool-cli`).

    Example:
    ```markdown
    ## Metadata
    - **Commit Message**: `feat(cli): add tool and validation commands`
    - **Branch**: `feature/m3-tool-cli`
    ```
  - **Subtasks** *(required)*: A section (typically labeled `## Subtasks`) containing a
    checklist of discrete work items that break the issue down into smaller, trackable steps.
    Each subtask must be a Markdown checkbox item (`- [ ]`). Subtasks are required for all
    issues except those where the work is so straightforward that decomposition would be
    trivial (e.g., a single-line configuration change). This makes progress visible and helps
    contributors and reviewers understand the scope of work at a glance. Example:
    ```markdown
    ## Subtasks
    - [ ] Implement input validation for configuration parser
    - [ ] Add error messages for malformed YAML files
    - [ ] Tests (Behave): Add scenarios for config parsing edge cases
    - [ ] Tests (Robot): Add integration test for config loading
    - [ ] Verify coverage >=97% via `nox -s coverage_report`
    - [ ] Run `nox` (all default sessions), fix any errors
    ```
  - **Definition of Done:** A section (typically labeled `## Definition of Done`) that
    explicitly describes when the issue should be considered satisfied and complete. This goes
    beyond the acceptance criteria by specifying the full set of conditions for closure —
    including that all subtasks are checked off, the commit has been created with the correct
    first-line message from the Metadata section and pushed to the correct branch, and a Pull
    Request has been submitted, reviewed, and merged. Example:
    ```markdown
    ## Definition of Done
    This issue is complete when:
    - All subtasks above are completed and checked off.
    - A Git commit is created where the **first line** of the commit message
      matches the Commit Message in Metadata exactly, followed by a blank line,
      then additional lines providing relevant details about the implementation.
    - The commit is pushed to the remote on the branch matching the **Branch** in
      Metadata exactly.
    - The commit is submitted as a **pull request** to `master`, reviewed, and
      **merged** before this issue is marked done.
    ```
- **Parent link(s):** If the issue is part of a larger effort, link it to its parent Epic or
  Legendary using Forgejo's dependency system (see
  [Linking and Dependencies](#linking-and-dependencies) and
  [Ticket Type Hierarchy](#ticket-type-hierarchy)). An issue may have more than one parent —
  for example, an end-to-end test issue might belong to both a testing Epic and the thematic
  Epic whose feature it validates. All non-Epic, non-Legendary issues should be linked to at
  least one parent when one exists. **Do not reference parent tickets by number in the issue
  description body.** Instead, open the child ticket and add the parent under "blocks," or
  open the parent and add the child under "depends on." This creates a machine-readable
  directed link that Forgejo tracks and displays automatically — the child blocks the parent
  because the parent cannot be completed until the child is done.
- **Blocking link(s):** If the issue blocks or is blocked by other issues, these dependencies
  must be recorded at creation time when known. Link to any issues that this issue blocks, and
  any issues that block this one (e.g., "Blocked by #57", "Blocks #63"). See
  [Linking and Dependencies](#linking-and-dependencies) for the full process, including when
  to apply the `Blocked` label.

### Label System

Issues are classified using a structured label system organized into several scopes. Each
scope is denoted by a prefix followed by a `/` (e.g., `State/Verified`, `Priority/High`).
Labels are not free-form — use only the labels defined below.

#### State Labels (`State/`)

State labels track where an issue or pull request is in its lifecycle. Every issue must have
exactly one State label at all times. Pull requests may also carry a State label when it aids
workflow tracking. See [Ticket Lifecycle](#ticket-lifecycle) for the rules governing
transitions between states.

| Label | Meaning |
|---|---|
| `State/Unverified` | The issue has been created but has not yet been reviewed by a maintainer. This is the initial state for all new issues. |
| `State/Verified` | A maintainer has reviewed the issue and confirmed it is valid, actionable, and not a duplicate. The issue is ready to be worked on. |
| `State/In progress` | Someone is actively working on this issue. |
| `State/Paused` | Work on this issue has been temporarily suspended, typically because it is blocked by another issue. When an issue is paused due to a blocker, the `Blocked` label must also be present and the blocking issue must be linked (see [Linking and Dependencies](#linking-and-dependencies)). |
| `State/In review` | The implementation is complete and a Pull Request has been submitted. The work is awaiting peer review. |
| `State/Completed` | The issue has been resolved and all associated Pull Requests have been merged. |
| `State/Wont Do` | The issue has been reviewed and a deliberate decision has been made not to address it. This may be because the issue is out of scope, not reproducible, or superseded by other work. A comment explaining the reason is required. |

Additionally, the label `Duplicate` is used when an issue is a duplicate of an existing issue.
When marking an issue as a duplicate, always link to the original issue in a comment before
closing it.

#### Priority Labels (`Priority/`)

Priority labels indicate the relative urgency of an issue. Priority is typically assigned by
maintainers during triaging, but contributors may suggest a priority when creating an issue.

| Label | Meaning |
|---|---|
| `Priority/Critical` | Must be addressed immediately. Reserved for outages, data loss, security vulnerabilities, or other issues that block a release or affect production. |
| `Priority/High` | Important work that should be completed soon. High-priority items are typically addressed in the current or next development cycle. |
| `Priority/Medium` | Normal priority. The issue is valid and should be addressed, but is not urgent. |
| `Priority/Low` | Nice to have. The issue is valid but is not time-sensitive and may be deferred. |
| `Priority/Backlog` | The issue has not yet been prioritized. This is the default priority for newly verified issues until a maintainer assigns a different priority. |

#### MoSCoW Labels (`MoSCoW/`)

MoSCoW labels categorize issues by their importance to the project's goals and milestones:

| Label | Meaning |
|---|---|
| `MoSCoW/Must Have` | This issue is essential. The project cannot ship or the milestone cannot be considered complete without it. |
| `MoSCoW/Should Have` | This issue is important but not strictly essential. It should be included if at all possible, but the release is not blocked without it. |
| `MoSCoW/Could Have` | This issue is desirable but not necessary. It will be included only if time and resources permit. |

There is no "Won't Have" label. Issues that will not be addressed are instead moved to the
`State/Wont Do` state.

**Important:** MoSCoW labels are assigned exclusively by the project owner. Contributors
should not add, remove, or change MoSCoW labels on issues.

#### Type Labels (`Type/`)

Type labels classify the nature of the work:

| Label | Meaning |
|---|---|
| `Type/Bug` | A defect in existing functionality. Something that was working or was expected to work is broken or behaving incorrectly. |
| `Type/Feature` | A new capability or user story. This issue describes functionality that does not yet exist. Also referred to as a "User Story." |
| `Type/Task` | A unit of technical or administrative work that is not directly a bug fix or a new feature (e.g., refactoring, updating dependencies, improving documentation, infrastructure work). |
| `Type/Testing` | A test-only work item. Used for TDD bug-capture issues that introduce a failing test to prove a bug exists before the fix is implemented (see [Bug Fix Workflow](#bug-fix-workflow)). Also used for standalone test infrastructure or test coverage work. |
| `Type/Epic` | A large body of work that can be broken down into multiple smaller issues. See [Ticket Type Hierarchy](#ticket-type-hierarchy). |
| `Type/Legendary` | An exceptionally large body of work, bigger than an Epic, representing a major initiative. See [Ticket Type Hierarchy](#ticket-type-hierarchy). |

#### Special Labels

| Label | Meaning |
|---|---|
| `Blocked` | This issue cannot proceed because it depends on another issue that has not yet been resolved. When applying this label, you must link to the blocking issue in a comment. If no issue exists for the blocker, create one first. See [Linking and Dependencies](#linking-and-dependencies). |
| `Signed-off:` | Used during the review process to indicate formal sign-off by a reviewer or maintainer. |

### Ticket Lifecycle

Every issue follows a defined lifecycle. The standard progression is:

```
State/Unverified → State/Verified → State/In progress → State/In review → State/Completed
```

At any point, an issue may also transition to `State/Wont Do` or be marked as `Duplicate`.
An issue may transition to `State/Paused` from `State/In progress` if it becomes blocked,
and back to `State/In progress` once the blocker is resolved.

#### Stage Descriptions and Transition Rules

1. **Unverified → Verified (or Wont Do / Duplicate)**

   All newly created issues start as `State/Unverified`. A maintainer will review the issue
   during triaging (see [Triaging](#triaging)) to determine whether it is valid and actionable.
   After review, the maintainer will move the issue to one of the following:
   - `State/Verified` — the issue is accepted and ready to be worked on.
   - `State/Wont Do` — the issue will not be addressed (with a comment explaining why).
   - `Duplicate` — the issue already exists (with a link to the original).

   Contributors do not move their own issues out of `State/Unverified`. This transition is
   performed by maintainers only.

2. **Verified → In Progress**

   When a contributor begins working on a verified issue, they must move it to
   `State/In progress`. This signals to other contributors that the issue is being actively
   worked on and prevents duplicate effort. If you intend to work on an issue, assign yourself
   to it and update the state label at the same time.

3. **In Progress → Paused** *(optional)*

   If work on an issue is blocked by a dependency on another unresolved issue, move it to
   `State/Paused` and add the `Blocked` label. You must link to the blocking issue in a
   comment (e.g., "Blocked by #57"). See
   [Linking and Dependencies](#linking-and-dependencies) for full instructions. Once the
   blocker is resolved, remove the `Blocked` label and move the issue back to
   `State/In progress`.

4. **In Progress → In Review**

   When the implementation is complete and a Pull Request has been submitted, move the issue to
   `State/In review`. The Pull Request must reference the issue as described in
   [Pull Request Process](#pull-request-process).

5. **In Review → Completed**

   Once the Pull Request has passed all automated checks, received the required approvals (see
   [Review and Merge Requirements](#review-and-merge-requirements)), and been merged, move the
   issue to `State/Completed`.

6. **Any State → Wont Do**

   At any point, a maintainer may decide that an issue will not be addressed and move it to
   `State/Wont Do`. The reason must be documented in a comment on the issue.

### Ticket Type Hierarchy

This project uses a three-tier ticket hierarchy to organize work from strategic objectives
down to individual implementation tasks. Each tier has a formal definition, a target audience,
and strict rules governing its use.

```
Issue → Epic → Legendary
(commit)   (capability)   (strategic pillar)
```

- **Issues** are the atomic unit of work. Each issue corresponds to exactly one commit.
  Developers work at this level.
- **Epics** group related issues into a demonstrable capability. Project managers and tech
  leads work at this level.
- **Legendaries** group related epics into a strategic pillar of the project. The project
  owner works at this level.

#### Issues (Atomic Work Unit)

Issues are the leaf nodes of the hierarchy and the unit of work that developers implement.
Every issue maps to exactly one commit. The structural requirements for issue descriptions
(title, labels, metadata, subtasks, acceptance criteria, definition of done) are described
in [Creating Issues](#creating-issues). The criteria below define what qualifies as a
well-scoped issue.

| # | Criterion | Definition |
|---|-----------|------------|
| 1 | **Atomicity** | The smallest meaningful unit of work that produces a single verifiable change to the codebase. If describing the change requires "and" between two unrelated actions, it should be two separate issues. |
| 2 | **Single Commit** | Corresponds to exactly one commit. One issue produces one commit. The commit must be atomic, self-contained, buildable, and testable in isolation per the [Commit Scope and Quality](#commit-scope-and-quality) guidelines. |
| 3 | **Single Responsibility** | Addresses exactly one concern — one bug fix, one function addition, one refactor, one test addition, one documentation update. Mixed concerns require separate issues. |
| 4 | **Assignability** | Can be fully owned and executed by a single developer without requiring synchronization with other in-flight work. |
| 5 | **Verifiability** | Has a clear, binary verification criterion stated in the issue description. The change either passes verification or it does not. |
| 6 | **Self-Containment** | All context needed to implement the change is present in the issue description, its parent Epic, or clearly referenced artifacts. A developer should not need to seek clarification to begin work. |
| 7 | **Implementation Independence** | Can ideally be implemented, reviewed, and merged without blocking on other issues in the same Epic. Where ordering dependencies exist, they must be explicitly documented using the [Linking and Dependencies](#linking-and-dependencies) process. |
| 8 | **Subtask Decomposition** | Must include a subtask checklist in the issue description (see [Creating Issues](#creating-issues)) that breaks the work into discrete, trackable steps. Subtasks are required for all issues except those where the work is so straightforward that decomposition would be trivial (e.g., a single-line configuration change). Subtasks are documentation within the issue body, not child tickets. |
| 9 | **Leaf Node** | Issues are leaf nodes in the ticket hierarchy — they have no child tickets. If an issue requires decomposition into multiple commits during implementation, it must be promoted to an Epic and broken into separate issues. |
| 10 | **Mandatory Parent** | Must belong to at least one Epic. Orphan issues are not permitted — every atomic change serves a larger capability. An issue may belong to more than one Epic when it genuinely serves multiple capabilities (e.g., an integration test that validates two Epics), but multi-parenting should be the exception rather than the rule. |
| 11 | **Finite Completion** | Done when the single commit is merged and all verification criteria pass. No ongoing or recurring obligation. Reopening is not permitted — if follow-up work is needed, a new issue is created. |

#### Epics (Capability Unit)

Epics represent demonstrable capabilities composed of multiple issues. They are the level at
which project managers and tech leads track progress and coordinate work across developers.
Every Epic must produce an outcome that can be shown to a stakeholder.

| # | Criterion | Definition |
|---|-----------|------------|
| 1 | **Demonstrable Outcome** | Completion produces an outcome that can be demonstrated to a stakeholder — a working feature, a visible improvement, a passing integration test, a live system behavior. Not "code was written" but "here is something you can see, invoke, or verify." Every Epic must answer the question: "What will I show someone when this is done?" If there is no demonstration, the Epic is not a real capability unit. |
| 2 | **Thematic Coherence** | All child issues share a unified goal. Removing any child issue would leave the capability incomplete or degraded. Adding an unrelated issue would violate the theme. |
| 3 | **Own Acceptance Criteria** | Has explicit acceptance criteria beyond "all child issues are closed." The Epic defines what "this capability works end-to-end" means — an integration behavior, a user-visible outcome, or a systemic property that only emerges from the children working together. |
| 4 | **Full Decomposability** | Can be completely decomposed into issues at planning time. If it cannot be broken into concrete implementation steps, it is too vague and must be refined before work begins. |
| 5 | **Bounded Scope** | Has a clear, finite endpoint. The set of issues required is knowable in advance (though subject to refinement). Open-ended or exploratory work must be scoped into a concrete deliverable before it qualifies as an Epic. |
| 6 | **Minimum Composition** | Must contain at least two child issues. If only one issue is needed, the work does not warrant Epic-level coordination and should be filed as an issue under an existing Epic. |
| 7 | **Coordination Boundary** | Represents the level at which cross-developer dependencies and integration concerns are managed. The Epic owner ensures children are sequenced correctly and the integrated result works. |
| 8 | **Milestone Affinity** | Typically aligns with a single milestone. May straddle at most one milestone boundary (some child issues in milestone N, others in N+1), but should not scatter across many milestones — that signals it should be split or is actually a Legendary in disguise. |
| 9 | **Mandatory Parent** | Must belong to at least one Legendary. No Epic exists outside a strategic pillar. |
| 10 | **Finite Completion** | Done when all child issues are closed AND the Epic's own acceptance criteria are independently verified through demonstration. The Epic is then closed permanently — additional work in the same area is a new Epic, not a reopening. |

#### Legendaries (Strategic Pillar)

Legendaries are the highest level of the ticket hierarchy. They represent the major strategic
pillars of the project — the essential dimensions that must be realized for the project to be
considered successful. The project owner tracks progress at this level.

| # | Criterion | Definition |
|---|-----------|------------|
| 1 | **Strategic Alignment** | Represents a major architectural dimension, business objective, or foundational pillar of the project. Each Legendary answers the question: "What is one of the essential things this project must achieve to be considered successful?" |
| 2 | **Articulated End State** | Has a clearly written terminal condition — a concrete, verifiable description of what "this pillar is fully realized" means. This prevents scope creep and perpetual Legendaries. If the end state cannot be articulated in a single paragraph, the Legendary is too vague. |
| 3 | **Multi-Milestone Span** | Naturally spans multiple milestones, reflecting the evolutionary and iterative nature of strategic goals. A Legendary that fits entirely within one milestone is likely an Epic in disguise. |
| 4 | **Epic Grouping** | Groups Epics that share a strategic theme, even when those Epics address different functional areas or technical layers. The unifying factor is strategic intent, not implementation similarity. |
| 5 | **Minimum Composition** | Must contain at least two child Epics. If only one Epic is needed, the work does not represent a strategic pillar and should be modeled as an Epic under an existing Legendary. |
| 6 | **Relative Independence** | Legendaries should be as independent as practical — minimal cross-Legendary blocking dependencies. Where dependencies exist, they must be explicitly documented. Two Legendaries that are tightly coupled should be considered for merger. |
| 7 | **Progress Measurability** | Progress is measured by Epic completion, not issue counts. The project owner should be able to glance at Legendary status and understand what fraction of the strategic pillar is realized. |
| 8 | **Owner Accountability** | Represents the dimensions along which the project owner evaluates project health and makes strategic prioritization decisions. |
| 9 | **No Parent** | Legendaries are the root of the ticket hierarchy. They have no parent ticket. |
| 10 | **Finite Completion** | Done when all child Epics are closed AND the articulated end state is independently verified. A Legendary is then closed permanently. If new strategic needs emerge in the same domain, a new Legendary is created — the old one is not reopened. |

#### Cross-Cutting Rules

**Hierarchy**

- The ticket hierarchy is a strict tree with limited multi-parenting: Issue → Epic →
  Legendary. No skip-level parenting is permitted (an issue cannot be a direct child of a
  Legendary).
- Each Epic has exactly one parent Legendary. Each issue has at least one parent Epic
  (multi-parenting is permitted for issues but should be the exception). Legendaries have no
  parent.
- No circular dependencies at any level of the hierarchy.
- **Promotion and demotion:** If an issue requires decomposition into multiple commits during
  implementation, it must be promoted to an Epic and broken into separate issues. If an Epic
  collapses to a single issue, it should be demoted (the issue absorbed into another Epic). If
  a Legendary is left with only one child Epic, evaluate whether the Legendary should be
  absorbed into another Legendary.

**Completion**

- Every ticket at every level must have an articulated, verifiable end state defined at
  creation time.
- A parent ticket is complete only when: (a) all of its children are complete, AND (b) its own
  acceptance criteria are independently met. Children being done is necessary but not
  sufficient.
- No ticket at any level may remain open indefinitely. If the scope of work changes, close the
  existing ticket with a comment explaining the change and open a new ticket with the revised
  scope. Do not reopen closed tickets.

**Relationship to Milestones and Versions**

- Milestones and versions are a temporal planning tool. They are orthogonal to the ticket
  hierarchy — they represent *when* work happens, not *how* it is organized.
- Issues (atomic work units) are assigned to milestones. This is where scheduling lives.
- Epics and Legendaries are **not** assigned to milestones. They inherit temporal presence from
  their child issues — an Epic "participates in" whichever milestones its issues are assigned
  to, and a Legendary spans whichever milestones its Epics touch.
- There must be no one-to-one coupling between any hierarchy level and milestones. Multiple
  Legendaries will contribute work to the same milestone. A single Legendary will have work
  across multiple milestones. This is expected and correct.

### Linking and Dependencies

Proper linking between issues ensures that dependencies are visible and that work is
coordinated effectively.

#### Dependency Direction

**The direction of a dependency link in Forgejo matters and must be set correctly.** Forgejo
models dependencies with two sides: a ticket that **blocks** another and a ticket that
**depends on** the first. These are not interchangeable — reversing the direction changes the
meaning and can have practical consequences (see
[Pull Request Dependencies](#pull-request-dependencies) below for a critical example).

When creating a dependency between two issues:

- The issue that must be completed **first** is the **blocker**. It should list the other issue
  under its **"blocks"** list.
- The issue that **cannot proceed** until the blocker is resolved is the **dependent**. It
  should list the blocker under its **"depends on"** list.

For example, if issue #57 must be finished before issue #63 can begin:

- Issue #57 **blocks** #63.
- Issue #63 **depends on** #57.

In Forgejo's UI, you set this by opening issue #63 and adding #57 under "depends on," or by
opening issue #57 and adding #63 under "blocks." Both actions create the same directed link.

#### Pull Request Dependencies

**This direction is especially critical for the relationship between Pull Requests and
issues.** When a PR implements work for an issue, the correct dependency direction is:

- The **PR blocks** the issue.
- The **issue depends on** the PR.

This reflects reality: the issue cannot be closed until the PR is merged (the PR's completion
is a prerequisite for the issue's completion).

**WARNING:** If the dependency is set in the **wrong** direction — that is, the issue is
recorded as blocking the PR — Forgejo will prevent the PR from being merged or closed until
the issue is resolved first. Since the issue cannot be resolved until the PR is merged, this
creates an unresolvable deadlock. Always verify the direction before saving the dependency
link.

To set the correct direction in Forgejo's UI:

1. Open the **Pull Request**.
2. In the dependency section, add the linked issue under **"blocks"**.
3. Verify that on the **issue** side, the PR now appears under **"depends on."**

Alternatively, open the issue and add the PR under "depends on" — this creates the same
directed link.

#### Issue-to-Issue Dependencies

- **Parent links:** All non-Epic, non-Legendary issues must be linked to their parent Epic or
  Legendary exclusively through Forgejo's dependency system — open the child issue and add the
  parent under "blocks," or open the parent and add the child under "depends on." The child
  **blocks** the parent because the parent cannot be completed until all its children are done;
  the parent **depends on** the child. **Do not reference parent tickets by number in the issue
  description body or in comments.** The machine-readable dependency link that Forgejo tracks
  and displays automatically is the sole mechanism for expressing the parent-child hierarchy.
- **Blocking relationships:** If an issue cannot be worked on until another issue is resolved,
  this dependency must be explicitly recorded:
  1. Add the `Blocked` label to the dependent issue.
  2. Link to the blocking issue in a comment (e.g., "Blocked by #57").
  3. Add the Forgejo dependency with the correct direction: the blocking issue **blocks** the
     dependent issue, and the dependent issue **depends on** the blocking issue.
  4. If no issue exists for the blocker, create one before marking the dependency.
  5. Move the blocked issue to `State/Paused`.
- **Resolution:** When a blocking issue is resolved, remove the `Blocked` label from all
  issues it was blocking and move them back to the appropriate state (typically
  `State/In progress` or `State/Verified`).
- **Cross-references:** Use issue references (e.g., `#123`) liberally in comments and
  descriptions to create a navigable web of related work. This helps reviewers and future
  contributors understand the context and history of decisions.

### Triaging

Triaging is the process by which maintainers review `State/Unverified` issues and determine
their disposition. During triaging, a maintainer will:

1. Read the issue and assess whether it is valid, actionable, and sufficiently well-described.
2. Check for duplicates. If the issue duplicates an existing one, mark it as `Duplicate`, link
   to the original, and close it.
3. If the issue is not something the project will address, move it to `State/Wont Do` with a
   comment explaining why.
4. If the issue is valid, move it to `State/Verified` and apply appropriate `Type/` and
   `Priority/` labels. Newly verified issues receive `Priority/Backlog` by default unless the
   maintainer determines a higher priority is warranted.
5. Assign the issue to the appropriate milestone. A milestone is mandatory for all issues
   beyond `State/Unverified`.
6. Link the issue to a parent Epic or Legendary if applicable.

Contributors can help the triaging process by writing clear, complete issues that include all
the required fields described in [Creating Issues](#creating-issues). A well-written issue is
significantly more likely to be verified quickly and acted on.

### Bug Fix Workflow

All bug fixes follow a mandatory **Test-Driven Development (TDD)** workflow. The principle is:
before fixing a bug, first prove it exists by writing a test that captures the buggy behavior.
Only then does someone implement the fix that makes that test pass. This ensures every bug fix
is verifiable and prevents regressions.

TDD bug-capture tests use a **tagging system** to pass CI while the bug is still unfixed. The
test framework's environment hooks invert the pass/fail behavior for tagged tests, so the test
suite passes at every commit on `master` — both before and after the fix. See
[TDD Bug Test Tags](#tdd-bug-test-tags) for the tag conventions and mechanics.

#### Workflow Steps

1. **TDD issue created.** For every new `Type/Bug` issue, a corresponding `Type/Testing` issue
   is created with a title prefixed `TDD:`. This TDD issue's sole deliverable is a test that
   captures the bug's behavior, tagged with `@tdd_bug`, `@tdd_bug_<N>` (where N is the bug
   issue number), and `@tdd_expected_fail`. The original bug issue **depends on** (is blocked
   by) the TDD issue via a Forgejo dependency link.
2. **TDD branch and PR.** The TDD assignee creates a `tdd/` branch from `master`, commits the
   tagged test, and opens a PR to `master`. Because the `@tdd_expected_fail` tag is present,
   the test framework inverts the result — the test passes CI even though the underlying
   assertion fails (proving the bug exists). The PR is reviewed for test quality and correct
   tagging, and is **merged to `master`** through the normal merge process. The TDD issue is
   closed when the PR is merged.
3. **Bug fix branch.** The bug fix assignee creates a `bugfix/` branch from `master` (which
   now contains the tagged TDD test). They implement the fix and **remove the
   `@tdd_expected_fail` tag** from the test (leaving `@tdd_bug` and `@tdd_bug_<N>` in place
   as permanent references). The test now runs normally and must pass. They open a PR to
   `master` with `Closes #<bug_issue_number>`. The CI quality gate verifies that the
   `@tdd_expected_fail` tag has been removed.
4. **Resolution.** When the bug fix PR is merged, the bug issue is closed. The test remains in
   the codebase permanently with `@tdd_bug` and `@tdd_bug_<N>` tags, serving as a regression
   guard for the fixed bug.

#### Priority

Bug issues (`Type/Bug`) and their TDD counterparts are always `Priority/Critical` and
`MoSCoW/Must Have`. They take precedence over feature work and other task types.

#### Branch Naming

TDD branches use the prefix `tdd/mN-` and bug fix branches use the prefix `bugfix/mN-` (where
N is the milestone number). Both branches should share the same descriptive name for
traceability (e.g., `tdd/m3-shacl-crash` and `bugfix/m3-shacl-crash`).

#### Assignees

Ideally, the TDD issue and the bug fix issue should be assigned to different developers to
provide independent verification — one developer proves the bug exists, another proves they
fixed it. This is preferred but not mandatory when capacity does not allow it.

## Project-Specific Guidelines

The following guidelines are specific to the **Aethyr MUD Server** and supplement the general
rules above with concrete tools, thresholds, and conventions particular to this Ruby-based
project.

### Backwards Compatibility

As described in the general [Versioning](#versioning) section, this project follows
[Clever Semantic Versioning](https://www.w3.org/submissions/semantic-versioning/). New major
versions (the leading number, e.g., the `2` in `v2.0.0`) are not backwards compatible, as
permitted by Clever Semantic Versioning rules. Prior to v2.0.0, no attempt is made to maintain
any level of backwards compatibility with previous versions — there are no migration guides, no
compatibility shims, and no support for old configurations, storage formats, or save-game data.
Any effort toward backwards compatibility will begin only from v2.0.0 onward.

### File Organization

All files must be organized in the following project directories:

- `lib/aethyr/core/` — Core engine source code (actions, commands, objects, connections,
  rendering, utilities, event sourcing). MUST NOT contain test files, documentation, mocking
  code, or examples.
- `lib/aethyr/extensions/` — Extension layer: additional game objects, skills, commands, input
  handlers, flags, reactions, and help entries. Same restrictions as core source.
- `lib/aethyr/experiments/` — Experimental sandbox code (CLI, runner, sandbox).
- `tests/unit/` — Cucumber/Gherkin unit test feature files and Ruby step definitions.
- `tests/integration/` — Cucumber/Gherkin integration test feature files, step definitions, and
  server bootstrap fixtures.
- `docs/` — Documentation source files for the Docusaurus site.
- `conf/` — Runtime configuration files (`config.yaml`, `mssp.yaml`, `intro.txt`).
- `bin/` — Executable entry points (`aethyr`, `aethyr_setup`, `aethyr_experiments`).
- `scripts/` — Utility and development setup scripts.
- `worldcover/` — ESA WorldCover GeoTIFF satellite imagery tiles for procedural world
  generation. Do not add or remove tiles without coordinating with the project owner.

### BDD Framework

- All unit-level and scenario tests use **Cucumber** (v9.x) under `tests/unit/` following the
  Gherkin standard. Step definitions are written in Ruby.
- Integration and end-to-end tests also use **Cucumber** under `tests/integration/`.
- **Do not write RSpec-style or Test::Unit-style standalone test files** under any
  circumstances. All test scenarios must be expressed as Gherkin `.feature` files with
  corresponding Ruby step definitions. RSpec and Test::Unit are available as development
  dependencies for use within step definitions (assertions, mocks), but not as standalone test
  frameworks.
- Test doubles and lightweight mocks are defined inline in step definition files using plain
  Ruby classes. Do not use heavy mocking frameworks in unit tests.

**Cucumber-Specific Guidelines:**
- Before adding a file under `tests/unit/step_definitions/`, check for an existing file that
  covers the same behavior and extend it.
- Steps used only by `foo.feature` must live in `foo_steps.rb`.
- Steps meant for multiple features belong in clearly named, reusable step files under the
  same `step_definitions/` directory.
- Use `Test::Unit::Assertions` (via `World(Test::Unit::Assertions)`) for assertions in step
  definitions. The custom `assert_raises_with_message` helper is available via
  `tests/assertions.rb`.
- Shared environment setup lives in `tests/common_env.rb`, which both unit and integration
  suites require.

### TDD Bug Test Tags

TDD bug-capture tests (see [Bug Fix Workflow](#bug-fix-workflow)) use a three-tag system that
allows the test to pass CI while the bug is unfixed, and automatically enforces correctness
when the bug is fixed. This tagging system applies to all Cucumber test suites (both unit and
integration).

#### Tag Definitions

| Tag | Purpose | Lifecycle |
|-----|---------|-----------|
| `@tdd_bug` | Generic filter tag. Present on **all** TDD bug tests. Used to list, filter, and count TDD bug tests across the codebase. | **Permanent** — never removed. |
| `@tdd_bug_<N>` | Issue reference tag (e.g., `@tdd_bug_123`). Links the test to the specific `Type/Bug` issue it captures. N is the bug issue number. | **Permanent** — never removed. Serves as a regression reference. |
| `@tdd_expected_fail` | Behavioral switch. When present, the test framework inverts the test result: the test **passes** if the underlying assertion fails (bug still exists) and **fails** if the assertion passes (bug was fixed without removing the tag). | **Temporary** — removed by the bug fix developer when the fix is implemented. |

#### Example

When the TDD developer first writes the test:
```gherkin
@tdd_bug @tdd_bug_42 @tdd_expected_fail
Scenario: Bug #42 - Player teleport fails when inventory contains cursed items
  Given a player in the starting room with a cursed dagger
  When the player teleports to the market square
  Then the player should arrive in the market square with inventory intact
```

After the bug fix developer implements the fix and removes `@tdd_expected_fail`:
```gherkin
@tdd_bug @tdd_bug_42
Scenario: Bug #42 - Player teleport fails when inventory contains cursed items
  Given a player in the starting room with a cursed dagger
  When the player teleports to the market square
  Then the player should arrive in the market square with inventory intact
```

#### Tag Validation Rules

These rules are enforced by the test environment hooks and CI quality gates:

- Any scenario with `@tdd_bug_<N>` **must** also have `@tdd_bug`.
- Any scenario with `@tdd_expected_fail` **must** also have `@tdd_bug` and at least one
  `@tdd_bug_<N>`.
- A bug fix PR that closes issue `#N` **must** remove `@tdd_expected_fail` from all scenarios
  tagged `@tdd_bug_N`. If the tag is still present, the CI quality gate blocks the PR.
- A bug fix PR that closes issue `#N` where no `@tdd_bug_N` test exists in the codebase is
  blocked by the CI quality gate — the TDD step was skipped.

### Testing Tools

Run tests using **Rake** via Bundler. Do not invoke `cucumber` or other test runners directly.
If a Rake task is missing a required dependency, add it to the `aethyr.gemspec` development
dependencies and re-run `bundle install` before retrying.

- **Unit tests (with coverage):** `bundle exec rake unit` *(this is the default task)*
- **Unit tests (no coverage):** `bundle exec rake unit_nocov`
- **Unit tests (with profiling):** `bundle exec rake unit_profile`
- **Integration tests (with coverage):** `bundle exec rake integration`
- **Integration tests (no coverage):** `bundle exec rake integration_nocov`
- **Integration tests (with profiling):** `bundle exec rake integration_profile`

To run a specific integration feature file in isolation:

```bash
FEATURE=tests/integration/server.feature bundle exec rake integration_nocov
```

**Coverage thresholds:**

| Suite | Minimum Coverage | Measured By |
|-------|-----------------|-------------|
| Unit tests | **85%** | `bundle exec rake unit` (SimpleCov) |
| Integration tests | **35%** | `bundle exec rake integration` (SimpleCov) |

Coverage reports are generated in `build/tests/unit/coverage/` and
`build/tests/integration/coverage/` respectively. The unit test coverage threshold of **85%**
is the enforced merge gate described in
[Review and Merge Requirements](#review-and-merge-requirements). Pull Requests that cause
unit coverage to drop below 85% will not be merged.

**Performance profiling:** Use ruby-prof for profiling performance-sensitive code. Profiling
runs are available via `bundle exec rake unit_profile` and
`bundle exec rake integration_profile`, which generate method-level call graphs.

### Merge Requirements

The general [Review and Merge Requirements](#review-and-merge-requirements) apply to this
project with the following project-specific details:

- **Automated checks** are run via Rake. The default task (`bundle exec rake`) runs the unit
  test suite with coverage enforcement. Integration tests (`bundle exec rake integration`)
  should also pass before merge.
- **Coverage gate:** 85% for unit tests, 35% for integration tests. Measured by SimpleCov as
  part of the respective Rake tasks.
- **Linting:** All code must pass **RuboCop** (`bundle exec rubocop`). See
  [Static Analysis](#static-analysis) for details.

### Static Analysis

All code should pass **RuboCop** (`bundle exec rubocop`). RuboCop is configured as a
development dependency in `aethyr.gemspec`. While the project does not currently enforce
RuboCop in an automated CI gate, all contributors are expected to run it locally before
committing and address any warnings or errors. When adding new code, follow the style that
RuboCop enforces — consistent naming, method length limits, and idiomatic Ruby conventions.

Do not add blanket `rubocop:disable` comments to bypass entire rule categories. If a specific
disable is genuinely necessary (e.g., for a method that unavoidably exceeds the parameter
limit), scope it as narrowly as possible and include a comment explaining why the exception
is warranted.

### Build and Project Management

- **Bundler** for dependency management and gem packaging.
- **Rake** for task automation (test execution, coverage, profiling, documentation).
- **`aethyr.gemspec`** is the single source of truth for gem metadata, dependencies, and
  version (via `Aethyr::VERSION` in `lib/aethyr/app_info.rb`).
- No Makefiles, no legacy approaches. The `Rakefile` defines all build and test tasks using
  a structured, SOLID-compliant task builder architecture.
- Commands should use the native Ruby toolchain:
  - `bundle install` — install dependencies
  - `bundle exec rake` — run the default task (unit tests with coverage)
  - `bundle exec rake -T` — list all available tasks
  - `gem build aethyr.gemspec` — build the gem
- **Docker** is available for development and deployment. Use `docker compose up` to start
  the server in a container, or use the devcontainer configuration for a full development
  environment.

### Require and Module Guidelines

- Place all `require` and `require_relative` statements at the top of the Ruby file, before
  any class or module definitions. Do not scatter requires throughout the file or bury them
  inside methods.
- Never place `require` statements inside conditional blocks, loops, or `begin/rescue`
  constructs.
- Use `require_relative` for loading files within the Aethyr codebase (e.g.,
  `require_relative '../util/config'`). Use `require` for loading gems and standard library
  modules.
- When only a specific class or module is needed from a large file, prefer requiring the
  specific file rather than a directory-level `require_all` loader. The `require_all` gem is
  available but should be reserved for bulk-loading entire subsystems at startup (e.g.,
  loading all commands or all input handlers).

### Mock Placement

ALL mocks, test doubles, and mock implementations must exist only within the `tests/`
directory hierarchy. Production code in `lib/` and utility scripts in `scripts/` must NEVER
contain mock implementations, test data, or conditional testing behavior. Use dependency
injection to swap implementations during tests.

In unit tests, lightweight test doubles are defined as plain Ruby classes directly in step
definition files. For integration tests, test fixtures (pre-seeded game objects, configuration
files) live under `tests/integration/server_bootstrap/`.

### EventMachine and Server Architecture

Aethyr's network layer is built on **EventMachine**, a reactor-pattern I/O library for Ruby.
When working with the server and connection code, follow these guidelines:

#### Reactor Pattern

- **Never block the reactor.** All code running inside the EventMachine reactor loop must be
  non-blocking. Long-running operations (disk I/O, complex computation, external service calls)
  must be deferred using `EventMachine.defer` or run in a separate thread via
  `concurrent-ruby`.
- **Use callbacks, not blocking waits.** The EventMachine model is callback-driven. Do not use
  `sleep`, blocking `IO.read`, or any other call that would stall the reactor.
- **Telnet protocol:** The connection layer handles raw telnet negotiation including MCCP (MUD
  Client Compression Protocol). When modifying connection code, be aware of the telnet state
  machine in `lib/aethyr/core/connection/telnet.rb` and the negotiation codes in
  `telnet_codes.rb`.

#### Wisper Pub/Sub Events

Aethyr uses the **Wisper** gem for publish/subscribe event dispatch. This is the primary
mechanism for decoupling game logic from the engine core.

- **Subscribe explicitly.** Register event listeners using `subscribe` or `on` rather than
  relying on global hooks.
- **Keep handlers focused.** Each event handler should do one thing. If a handler needs to
  trigger additional side effects, publish a new event rather than expanding the handler.
- **Name events descriptively.** Use past-tense verb phrases for event names (e.g.,
  `player_moved`, `item_dropped`, `combat_resolved`) to clearly indicate that the event
  represents something that has already happened.

#### Concurrency

- Use **concurrent-ruby** data structures (`Concurrent::Hash`, `Concurrent::Array`,
  `Concurrent::Atom`) for any shared mutable state accessed from multiple threads or deferred
  blocks.
- The `$manager` global manages the game object graph and must be treated as a shared resource.
  Access it through the established patterns in the codebase — do not introduce new global
  mutable state.

### Extension Development

The extension system under `lib/aethyr/extensions/` allows adding new game content without
modifying the core engine. When developing extensions, follow these patterns:

#### Adding New Game Objects

1. Create a new file in `lib/aethyr/extensions/objects/` (e.g., `torch.rb`).
2. Inherit from the appropriate base class in `lib/aethyr/core/objects/` (e.g., `Item`,
   `Container`, `Wearable`).
3. Use the trait mixins from `lib/aethyr/core/objects/traits/` to compose behavior (e.g.,
   `include Expires` for items that decay, `include HasInventory` for containers).
4. Register the object so the persistence layer (Gary/GDBM) can serialize and deserialize it.

#### Adding New Commands

1. Create the action handler in `lib/aethyr/extensions/actions/commands/`.
2. Create the corresponding input handler in `lib/aethyr/extensions/input_handlers/`.
3. Add a `.help` file in `lib/aethyr/extensions/help/` documenting the command for players.
4. Write Cucumber scenarios in `tests/unit/` covering the new command's behavior.

#### Adding New Skills

1. Create the skill implementation in `lib/aethyr/extensions/skills/`.
2. Register it in `lib/aethyr/extensions/skills.rb`.
3. Test the skill's behavior through Cucumber scenarios.

#### Extension Conventions

- Extensions must not modify core engine files. If core changes are needed to support an
  extension, those changes must be submitted as a separate issue and PR.
- Each extension file should be self-contained and follow the same SOLID principles as core
  code.
- Extensions must include tests. A new game object or command without corresponding Cucumber
  scenarios will not be accepted.

### Event Sourcing

Aethyr includes an **event sourcing** subsystem built on the **Sequent** framework with
**ImmuDB** as an optional tamper-proof event store backend.

#### When to Use Event Sourcing

Event sourcing is not enabled by default (see `event_sourcing_enabled: false` in
`conf/config.yaml`). When working with the event sourcing subsystem:

- Event sourcing code lives in `lib/aethyr/core/event_sourcing/` and
  `lib/aethyr/event_sourcing/`.
- **Commands** (write intents) are defined in `commands.rb`. **Events** (immutable facts) are
  defined in `events.rb`.
- **Command handlers** in `command_handlers.rb` validate commands and emit events.
- **Projections** in `projections.rb` build read-model state from event streams.
- The **ImmuDB event store** (`immudb_event_store.rb`) provides cryptographic verification of
  event integrity.

#### Event Sourcing Conventions

- Events are immutable records of facts. Never modify or delete events once stored.
- Command handlers must validate all preconditions before emitting events. If validation fails,
  raise an exception — do not emit a "failure" event.
- Keep projections simple and focused. Each projection should build one read model.
- When adding new aggregate types, follow the existing patterns in `domain.rb` for aggregate
  root definition.
- ImmuDB connection configuration is in `conf/config.yaml` (`:immudb_address`,
  `:immudb_port`, `:immudb_username`, `:immudb_password`, `:immudb_database`).

### World Generation

Aethyr includes a procedural world generation system that uses real-world satellite imagery
from the **ESA WorldCover** dataset, processed via the **GDAL** (Geospatial Data Abstraction
Library) Ruby bindings.

- GeoTIFF tiles live in the `worldcover/` directory. These are large binary files tracked in
  the repository — do not add, remove, or modify tiles without coordinating with the project
  owner.
- The world cover generator (`lib/aethyr/core/util/world_cover_generator.rb`) converts
  satellite land-cover classification data into MUD terrain types.
- When modifying the generator, be mindful of performance — tile processing is
  computationally expensive. Use `concurrent-ruby` for parallel processing and lock-free data
  structures (see `CHANGELOG.md` for the 1.1.0 performance improvements).
- The world seeder (`bin/aethyr_setup`) uses the generator to populate the initial game world.

### Running the Server Locally

To run the Aethyr MUD server locally for development:

1. **Install dependencies:**
   ```bash
   bundle install
   ```

2. **Seed the world** (first time only):
   ```bash
   bundle exec bin/aethyr_setup
   ```

3. **Start the server:**
   ```bash
   bundle exec bin/aethyr
   ```
   The server listens on the address and port configured in `conf/config.yaml` (default:
   `127.0.0.1:8080`). Connect with any telnet or MUD client:
   ```bash
   telnet localhost 8080
   ```

4. **Docker alternative:**
   ```bash
   docker compose up
   ```
   This maps port `1337` on the host to port `8888` in the container.

**Server configuration** lives in `conf/config.yaml`. Key settings include:

| Key | Description | Default |
|-----|-------------|---------|
| `:address` | Bind address | `127.0.0.1` |
| `:port` | Listen port | `8080` |
| `:admin` | Admin username | `root` |
| `:log_level` | Logging verbosity (0-3) | `2` |
| `:save_rate` | Auto-save interval (seconds) | `1440` |
| `:event_sourcing_enabled` | Enable event sourcing subsystem | `false` |
| `:mccp` | Enable MUD Client Compression Protocol | `false` |

Use the `--verbose` / `-v` flag for maximum log output. The `AETHYR_CFG` environment variable
can point to an alternative configuration file, and `.aethyr.rc` in the working directory is
loaded as a defaults file.

### Documentation

Aethyr has two documentation systems:

#### Docusaurus Site

The primary documentation site is built with **Docusaurus** and lives in the `docs/` directory.
It includes developer guides, server administration, player documentation, and architectural
overviews.

- **Build the static site:** `bundle exec rake documentation`
- **Serve locally with hot-reload:** `bundle exec rake documentation_serve`
- Documentation is written in Markdown/MDX. Follow the existing structure:
  - `docs/developer/` — Architecture, extending, event sourcing API
  - `docs/server/` — Server administration, running, world building
  - `docs/player/` — Player-facing command reference and lore
- The site supports inline Kroki diagrams via a custom remark plugin
  (`docs/plugins/remark-kroki-inline.js`).

#### API Documentation (RDoc)

API-level documentation is generated from source code comments using **RDoc**:

- **Generate API docs:** `bundle exec rake rdoc`
- Output is placed in `build/docs/`.
- All public classes and methods should have RDoc comments explaining their purpose, parameters,
  and return values.

When modifying code, update both the relevant Docusaurus page (if the change affects user-facing
or developer-facing behavior) and the RDoc comments on the affected classes and methods.

### Error Handling Examples

The following are Ruby-specific examples illustrating the general error and exception handling
principles described earlier in this document.

**Argument validation example:**
```ruby
def process_data(data, threshold)
  # Argument validation first
  raise ArgumentError, 'data cannot be nil' if data.nil?
  raise ArgumentError, 'data cannot be empty' if data.empty?
  unless data.all? { |item| item.is_a?(String) }
    raise TypeError, 'data must contain only strings'
  end
  unless threshold.is_a?(Integer) && threshold.between?(0, 100)
    raise ArgumentError, "threshold must be between 0 and 100, got #{threshold}"
  end

  # Now perform actual logic
  # ...
end
```

**Exception propagation guidelines:**
- Do not use bare `rescue` or `rescue => e` without re-raising unless you have specific
  recovery logic. Prefer `rescue SpecificError` over catching all exceptions.
- Avoid returning `nil` or default values when an error condition exists — raise exceptions.
- Use Aethyr's custom error classes defined in `lib/aethyr/core/errors.rb` when the error
  is specific to the engine domain. Raise standard Ruby exceptions (`ArgumentError`,
  `TypeError`, `RuntimeError`) for general programming errors.
