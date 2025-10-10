# Quick Deployment Reference

**Status:** ✅ Ready to deploy (531 tests passing, 0 leaks)

## 1️⃣ Create GitHub Repository

```
Name: dom
Description: WHATWG DOM Living Standard implementation in Zig
Visibility: Public
☑️ DO NOT initialize with README/gitignore/license
```

## 2️⃣ Push to GitHub

```bash
# Add remote (use your URL)
git remote add origin git@github.com:YOUR_ORG/dom.git

# Push
git push -u origin main
```

## 3️⃣ GitHub Settings (5 min)

### Enable Services
- **Settings → Actions → General**
  - ✅ Allow all actions
  - ✅ Read and write permissions
  - ✅ Allow Actions to create PRs

- **Settings → Features**
  - ✅ Enable Discussions
  - ✅ Enable Issues

### Branch Protection
- **Settings → Branches → Add rule**
  - Branch: `main`
  - ✅ Require PR before merging (1 approval)
  - ✅ Require status checks (add all CI jobs)
  - ✅ Require conversation resolution

### Issue Restrictions
- **Settings → Moderation**
  - Set "Limit to existing users" or "Limit to prior contributors"
  - This enforces "organization members only" policy

### Repository Info
- **⚙️ About → Edit**
  - Topics: `zig`, `dom`, `whatwg`, `web-standards`
  - Description: "WHATWG DOM Living Standard implementation in Zig"
  - Website: https://dom.spec.whatwg.org/

## 4️⃣ Verify CI

Go to **Actions** tab - should see:
- ✅ CI workflow running (3 platforms)
- ✅ CodeQL analysis running

Wait for green checkmarks ✅

## 5️⃣ Create Release

```bash
git tag -a v1.0.0 -m "Release v1.0.0: Initial WHATWG DOM implementation"
git push origin v1.0.0
```

Watch **Actions** → **Release** workflow create the release automatically.

## 6️⃣ Done! 🎉

Your repository is now:
- ✅ Live on GitHub
- ✅ CI/CD automated
- ✅ Branch protected
- ✅ Released (v1.0.0)
- ✅ Ready for contributors

## Quick Commands

```bash
# Check everything is committed
git status

# View commit
git log --oneline

# List remotes
git remote -v

# Check branches
git branch -a

# Run tests locally before pushing
zig build test --summary all
```

## What Happens Automatically

### On Push to Main
- CI tests on Linux/macOS/Windows
- CodeQL security scan
- Badges update in README

### On PR Creation
- All CI checks run
- Formatting validation
- Memory leak detection
- Required before merge

### On Tag Push (v*.*.*)
- Full test suite
- Release builds created
- GitHub Release published
- Artifacts uploaded

### Daily (Nightly)
- Full test suite
- Benchmarks
- Cross-compilation tests
- Health checks

### Weekly
- Dependabot checks for updates
- PRs created automatically

## Help

- Full deployment guide: `DEPLOYMENT.md`
- CI/CD details: `GITHUB_ACTIONS_SETUP.md`
- Quick CI reference: `CI_QUICKSTART.md`
- Contributing: `CONTRIBUTING.md`
