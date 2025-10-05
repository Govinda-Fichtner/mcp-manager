# Claude Code Configuration for MCP Manager

## 🚨 CRITICAL: Git Commit Guidelines

### NEVER Add Attribution in Commits

**ABSOLUTE RULE**: When creating git commits or push messages:

1. ❌ **NEVER** add "Generated with Claude Code" attribution
2. ❌ **NEVER** add "Co-Authored-By: Claude" footer
3. ❌ **NEVER** add any Claude-related attribution or references
4. ✅ **ALWAYS** use clean, professional commit messages without AI attribution

**Author Configuration:**
- Author Name: `peter-ai-buddy`
- Author Email: `peter-ai-buddy@urknall.ai`
- Git config is already set - do not modify

### Commit Message Format

```
<type>: <short description>

- Bullet point describing change
- Another change
- More details as needed

Optional paragraph with context or rationale.
```

**Example Good Commit:**
```
feat: add health check timeout configuration

- Implement per-server configurable timeouts from registry
- Default timeout set to 5 seconds
- Add validation for timeout values
```

**Example Bad Commit (DO NOT DO THIS):**
```
feat: add health check timeout configuration

- Implement per-server configurable timeouts

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

## Project Guidelines

### Code Style
- Follow existing bash script conventions
- Use shellcheck for linting
- Maintain test coverage with ShellSpec

### Testing
- Run tests before committing: `npm test`
- All tests must pass before pushing
- Add tests for new functionality

### Documentation
- Update README.md for user-facing changes
- Keep troubleshooting docs current
- Document new MCP server integrations

## Development Workflow

1. Make changes
2. Run tests: `npm test`
3. Commit with clean message (no attribution)
4. Push to origin/main

## Pre-commit Hooks

The project has pre-commit hooks that run:
- ShellCheck (linting)
- ShellSpec tests
- Whitespace/file checks

Ensure all hooks pass before committing.
