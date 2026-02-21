# GitHub Copilot Instructions

## Pre-commit Checks

Before suggesting or finalising any commit, ensure all pre-commit hooks pass cleanly.
Run `pre-commit run --all-files` and resolve any reported issues (linting, formatting,
trailing whitespace, etc.) before the code is considered ready to commit.

## Conventional Commits

All commit messages **must** follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

Allowed types:

| Type | When to use |
|------|-------------|
| `feat` | A new feature |
| `fix` | A bug fix |
| `docs` | Documentation changes only |
| `style` | Formatting, missing semicolons, etc. — no logic change |
| `refactor` | Code change that is neither a fix nor a feature |
| `perf` | Performance improvements |
| `test` | Adding or correcting tests |
| `chore` | Build process, dependency updates, tooling |
| `ci` | CI/CD pipeline changes |
| `revert` | Reverts a previous commit |

Breaking changes must append `!` after the type/scope and include a `BREAKING CHANGE:` footer.

## Documentation Updates

When making significant code changes, update all relevant documentation in the same PR:

- **`README.md`** — update usage examples, configuration options, environment variables, or architecture notes that are affected by the change.
- **Inline comments / docstrings** — keep them accurate and in sync with the implementation.
- **`CHANGELOG.md`** — do not edit manually; it is managed automatically by `release-please` via conventional commit messages.

A PR that changes behaviour without updating the relevant docs should be considered incomplete.
