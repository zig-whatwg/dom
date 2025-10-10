# CI/CD Quick Start Guide

This is a quick reference for using the GitHub Actions CI/CD pipeline.

## 🚀 First Time Setup (After Pushing to GitHub)

### 1. Enable GitHub Pages
```
1. Go to: Settings → Pages
2. Source: Select "GitHub Actions"
3. Click "Save"
```

### 2. Configure Branch Protection
```
1. Go to: Settings → Branches
2. Click "Add rule"
3. Branch name pattern: main
4. Enable: "Require status checks to pass"
5. Select: CI, PR Checks
6. Enable: "Require branches to be up to date"
7. Click "Create"
```

### 3. Verify Actions Enabled
```
1. Go to: Settings → Actions → General
2. Enable: "Allow all actions and reusable workflows"
3. Workflow permissions: "Read and write permissions"
4. Enable: "Allow GitHub Actions to create PRs"
5. Click "Save"
```

## 📝 Making Changes

### Before Every Commit
```bash
# 1. Format code
zig fmt src/

# 2. Run tests
zig build test --summary all

# 3. Check for leaks
zig build test 2>&1 | grep -i leak

# If all pass, commit!
git add .
git commit -m "feat: your change"
git push
```

### Creating a Pull Request
```bash
# 1. Create feature branch
git checkout -b feature/my-feature

# 2. Make changes and commit
git add .
git commit -m "feat: add my feature"

# 3. Push to GitHub
git push origin feature/my-feature

# 4. Create PR on GitHub
# - Fill out the PR template
# - Wait for CI checks (5-7 mins)
# - Address any failures
# - Request review
```

### After PR Checks Pass
- ✅ All 8 jobs should be green
- ✅ Review the PR summary
- ✅ Request maintainer review
- ✅ Merge when approved

## 🎉 Creating a Release

### Option 1: Automatic (Tag-based)
```bash
# 1. Ensure main is up to date
git checkout main
git pull

# 2. Create and push tag
git tag v1.0.0
git push origin v1.0.0

# 3. Wait ~10 minutes
# - Release workflow runs
# - Tests execute
# - Artifacts build
# - Release created
# - Docs published

# 4. Check GitHub Releases page
```

### Option 2: Manual Release
```
1. Go to: Actions → Release
2. Click: "Run workflow"
3. Select: main branch
4. Enter: v1.0.0
5. Click: "Run workflow"
6. Wait for completion
```

## 🔍 Monitoring CI/CD

### Viewing Workflow Runs
```
1. Go to: Actions tab
2. Click: Workflow name (CI, PR Checks, etc.)
3. Click: Specific run
4. View: Job details and logs
```

### Common Checks

**CI Workflow** (Every push to main/develop)
- Runs on: Ubuntu, macOS, Windows
- Tests: 531 tests
- Time: ~3-5 minutes

**PR Workflow** (Every pull request)
- Quick validation
- Format check
- Memory safety
- Time: ~5-7 minutes

**Nightly Workflow** (Daily at 2 AM UTC)
- Extended testing
- Performance benchmarks
- Cross-compilation
- Time: ~15-20 minutes

## ⚠️ Troubleshooting

### Tests Fail in CI but Pass Locally
```bash
# Use exact same Zig version
zig version  # Should be 0.15.1

# Clean build
rm -rf .zig-cache zig-out
zig build test
```

### Format Check Fails
```bash
# Format and recommit
zig fmt src/
git add src/
git commit --amend --no-edit
git push --force-with-lease
```

### Memory Leak Detected
```bash
# Check locally
zig build test 2>&1 | grep -A 5 -i leak

# Fix missing defer
# Add defer statements for allocations
# Retest and recommit
```

### Workflow Won't Trigger
- Check file is in `.github/workflows/`
- Verify YAML syntax is correct
- Ensure Actions are enabled in settings
- Check branch name matches trigger

## 📊 Understanding Status Badges

In README.md, you'll see:

```markdown
[![CI](https://img.shields.io/badge/CI-passing-brightgreen.svg)]()
```

**Badge Colors:**
- 🟢 Green = Passing
- 🔴 Red = Failing
- 🟡 Yellow = In progress
- ⚪ Gray = Not run

## 🔔 Dependabot

Dependabot automatically:
- Checks for GitHub Actions updates (weekly)
- Creates PRs for updates
- Labels with "dependencies"

**To handle Dependabot PRs:**
1. Review the PR
2. Check CI passes
3. Merge if safe
4. Dependabot will rebase if needed

## 📈 Performance Tracking

**Nightly benchmarks** track:
- Build time
- Test execution time
- Memory usage
- Cross-platform compatibility

View in: Actions → Nightly Tests → benchmark job

## 🔐 Security Monitoring

**CodeQL** runs:
- On every push to main
- On pull requests
- Weekly (Monday 6 AM UTC)

View alerts in: Security → Code scanning alerts

## 💡 Tips

### Speed Up Local Testing
```bash
# Quick test (skip some checks)
zig build test

# Full CI equivalent
zig fmt src/ && zig build test --summary all
```

### Pre-commit Hook (Optional)
```bash
# .git/hooks/pre-commit
#!/bin/sh
zig fmt --check src/ && zig build test
```

### Watch for Changes
```bash
# Use watchexec (install separately)
watchexec -e zig "zig build test"
```

## 📚 More Information

- **Full docs:** `GITHUB_ACTIONS_SETUP.md`
- **Contributing:** `CONTRIBUTING.md`
- **Workflow details:** `.github/workflows/*.yml`

## 🎯 Quick Reference

| Action | Command |
|--------|---------|
| Format code | `zig fmt src/` |
| Run tests | `zig build test --summary all` |
| Check leaks | `zig build test 2>&1 \| grep -i leak` |
| Build release | `zig build -Doptimize=ReleaseFast` |
| Create tag | `git tag v1.0.0 && git push origin v1.0.0` |
| View CI logs | GitHub → Actions → Workflow → Run |

## ✅ Checklist for Every Change

- [ ] Code formatted with `zig fmt`
- [ ] All tests pass locally
- [ ] No memory leaks
- [ ] Documentation updated (if needed)
- [ ] Commit message follows convention
- [ ] PR template filled out (for PRs)

---

**That's it!** The CI/CD is now working for you automatically. 🎉

**Questions?** Check `GITHUB_ACTIONS_SETUP.md` or open an issue.
