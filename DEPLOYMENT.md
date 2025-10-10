# Deployment Guide

This guide walks through pushing the WHATWG DOM implementation to GitHub and configuring all services.

## Current Status

✅ Repository initialized with git  
✅ Initial commit created (56 files, 30K+ lines)  
✅ All 531 tests passing  
✅ Zero memory leaks  
✅ CI/CD workflows configured  

## Step 1: Create GitHub Repository

1. Go to https://github.com/new (or your organization)
2. Create a new repository:
   - **Name:** `dom` (or your preferred name)
   - **Description:** `WHATWG DOM Living Standard implementation in Zig`
   - **Visibility:** Public (recommended) or Private
   - **DO NOT** initialize with README, .gitignore, or license (we already have these)
3. Click "Create repository"

## Step 2: Add Remote and Push

After creating the repository, GitHub will show you commands. Use these instead:

```bash
# Add the GitHub remote (replace with your repository URL)
git remote add origin https://github.com/YOUR_USERNAME/dom.git

# Or if using SSH:
git remote add origin git@github.com:YOUR_USERNAME/dom.git

# Verify the remote
git remote -v

# Push the initial commit
git push -u origin main
```

**Expected output:**
```
Enumerating objects: 71, done.
Counting objects: 100% (71/71), done.
Delta compression using up to 8 threads
Compressing objects: 100% (64/64), done.
Writing objects: 100% (71/71), 123.45 KiB | 12.34 MiB/s, done.
Total 71 (delta 5), reused 0 (delta 0), pack-reused 0
To github.com:YOUR_USERNAME/dom.git
 * [new branch]      main -> main
Branch 'main' set up to track remote branch 'main' from 'origin'.
```

## Step 3: Configure GitHub Settings

### 3.1 Enable GitHub Actions

1. Go to **Settings** → **Actions** → **General**
2. Under "Actions permissions":
   - Select **"Allow all actions and reusable workflows"**
3. Under "Workflow permissions":
   - Select **"Read and write permissions"**
   - Check **"Allow GitHub Actions to create and approve pull requests"**
4. Click **Save**

### 3.2 Enable Discussions

1. Go to **Settings** → **Features**
2. Check **"Discussions"** (required for external contributors per CONTRIBUTING.md)
3. Click **Save changes**

### 3.3 Set Up Branch Protection

1. Go to **Settings** → **Branches**
2. Click **"Add rule"** or **"Add branch protection rule"**
3. Branch name pattern: `main`
4. Enable these settings:
   - ✅ **Require a pull request before merging**
     - ✅ Require approvals: **1**
     - ✅ Dismiss stale pull request approvals when new commits are pushed
   - ✅ **Require status checks to pass before merging**
     - ✅ Require branches to be up to date before merging
     - Search and add these required checks:
       - `test (ubuntu-latest, 0.15.1)`
       - `test (macos-latest, 0.15.1)`
       - `test (windows-latest, 0.15.1)`
       - `analyze (zig)`
   - ✅ **Require conversation resolution before merging**
   - ✅ **Do not allow bypassing the above settings** (for admins too)
5. Click **Create** or **Save changes**

### 3.4 Configure Issue Settings

Since only organization members can create issues:

1. Go to **Settings** → **Features**
2. Keep **"Issues"** enabled (for organization members)
3. Go to **Settings** → **Moderation options**
4. Under "Interaction limits":
   - Click **"Limit to existing users"** or **"Limit to prior contributors"**
   - This prevents external users from creating issues
   - External users will be directed to use Discussions

### 3.5 Set Up GitHub Pages (Optional)

If you want to host documentation:

1. Go to **Settings** → **Pages**
2. Under "Build and deployment":
   - **Source:** Select **"GitHub Actions"**
3. The documentation will be available at: `https://YOUR_USERNAME.github.io/dom/`

Note: You'll need to create a docs deployment workflow later.

### 3.6 Add Topics

1. Go to the repository main page
2. Click the **⚙️ gear icon** next to "About"
3. Add topics:
   - `zig`
   - `dom`
   - `whatwg`
   - `web-standards`
   - `dom-implementation`
   - `zig-library`
4. Add description: **"WHATWG DOM Living Standard implementation in Zig"**
5. Add website: `https://dom.spec.whatwg.org/` (spec reference)
6. Click **Save changes**

## Step 4: Verify GitHub Actions

After pushing, GitHub Actions will automatically run:

1. Go to **Actions** tab
2. You should see workflow runs:
   - **CI** - Multi-platform tests (triggers on push to main)
   - **CodeQL** - Security scanning (triggers on push)
   - **PR** - Only runs on pull requests

**Expected workflow results:**
- ✅ CI: All 3 platforms (Linux/macOS/Windows) pass all 531 tests
- ✅ CodeQL: No security issues found

If workflows don't start automatically:
- Check that Actions are enabled (Step 3.1)
- Check workflow files have correct triggers
- Manually trigger from Actions tab → Select workflow → Run workflow

## Step 5: Create First Release

Once CI passes on main:

```bash
# Create and push a tag for v1.0.0
git tag -a v1.0.0 -m "Release v1.0.0: Initial WHATWG DOM implementation

Production-ready implementation with:
- 531 tests passing
- Zero memory leaks
- ~95% WHATWG spec coverage
- Multi-platform support (Linux/macOS/Windows)
- Reference-counted memory management
- Comprehensive documentation"

# Push the tag
git push origin v1.0.0
```

This will automatically trigger the **Release** workflow which will:
1. Run all tests on all platforms
2. Build release binaries for Linux/macOS/Windows
3. Create a GitHub Release with:
   - Release notes
   - Downloadable artifacts
   - Change summary

**View the release:**
- Go to **Releases** tab
- You should see `v1.0.0` with artifacts

## Step 6: Configure Dependabot (Auto-configured)

Dependabot is already configured via `.github/dependabot.yml` and will:
- Check for Zig updates weekly
- Create PRs automatically
- Run CI on dependency updates

**To review Dependabot PRs:**
1. Go to **Pull requests** tab
2. Look for PRs from `dependabot[bot]`
3. Review changes and merge if CI passes

## Step 7: Set Up Notifications (Optional)

Configure how you want to be notified:

1. Go to **Settings** → **Notifications**
2. Choose notification preferences for:
   - Issues
   - Pull requests
   - Releases
   - Actions workflows

## Verification Checklist

After completing all steps, verify:

- [ ] Repository is accessible on GitHub
- [ ] All files are visible in the repository
- [ ] README.md renders correctly with badges
- [ ] CI badge shows passing status
- [ ] GitHub Actions tab shows successful workflow runs
- [ ] Discussions are enabled and accessible
- [ ] Issues are enabled (for organization members only)
- [ ] Branch protection rules are active on `main`
- [ ] Release v1.0.0 is created with artifacts
- [ ] Topics are added to repository
- [ ] Dependabot is configured

## Post-Deployment: Continuous Integration

### Daily Automation (Nightly Workflow)

The nightly workflow runs daily at 00:00 UTC and performs:
- Full test suite on all platforms
- Memory leak checks
- Performance benchmarks
- Cross-compilation tests (macOS → Linux/Windows)
- Health status reporting

**View nightly results:**
- Go to **Actions** → **Nightly CI**
- Check for failures or performance regressions

### On Every Pull Request

The PR workflow automatically:
1. Runs all tests on all platforms
2. Checks code formatting (`zig fmt`)
3. Validates memory safety (leak detection)
4. Requires CI to pass before merge (if branch protection is enabled)

### On Every Release Tag

When you push a tag (`v*.*.*`):
1. Full test suite runs
2. Release builds are created
3. GitHub Release is published
4. Artifacts are uploaded

## Troubleshooting

### Workflows Don't Start

**Problem:** Workflows don't trigger after push  
**Solution:**
1. Check Actions are enabled: Settings → Actions → General
2. Verify workflow files are in `.github/workflows/`
3. Check workflow triggers in YAML files
4. Look for errors in Actions tab

### CI Fails on Windows

**Problem:** Tests fail on Windows but pass locally  
**Solution:**
1. Check for path separator issues (`/` vs `\`)
2. Verify line endings (CRLF vs LF)
3. Check file permissions
4. Review Windows-specific workflow steps

### Branch Protection Prevents Merge

**Problem:** Can't merge even though CI passes  
**Solution:**
1. Ensure required status checks are completed
2. Verify you have required approvals
3. Check that all conversations are resolved
4. As admin, you can bypass rules (but shouldn't)

### Dependabot PRs Fail

**Problem:** Dependabot PRs don't pass CI  
**Solution:**
1. Review the dependency update
2. Check if Zig version change breaks tests
3. Update code if necessary
4. Dependabot will automatically rebase

## Next Steps

After deployment:

1. **Announce the release:**
   - Share on Zig Discord
   - Post on social media
   - Update any package registries

2. **Monitor the project:**
   - Watch for issues and discussions
   - Review Dependabot PRs
   - Check nightly workflow results

3. **Plan future work:**
   - Review `PROJECT_COMPLETE.md` for enhancement ideas
   - Monitor WHATWG spec updates
   - Consider additional features

4. **Engage with community:**
   - Respond to discussions
   - Review pull requests
   - Update documentation based on feedback

## Support

For questions or issues during deployment:
- Check GitHub Actions logs for error details
- Review workflow YAML files for configuration
- Consult `GITHUB_ACTIONS_SETUP.md` for detailed CI/CD information
- Open a discussion if you need help

---

**Ready to deploy!** 🚀

The WHATWG DOM implementation is production-ready and fully configured for enterprise-grade development workflows.
