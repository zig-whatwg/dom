# GitHub Actions CI/CD Setup

This document describes the comprehensive GitHub Actions CI/CD pipeline for the WHATWG DOM implementation in Zig.

## Overview

The CI/CD system consists of **6 workflow files** that provide comprehensive automated testing, quality checks, and release automation.

## Workflows

### 1. Main CI Workflow (`.github/workflows/ci.yml`)

**Triggers:**
- Push to `main` or `develop` branches
- Pull requests to `main` or `develop`
- Manual dispatch

**Jobs:**

#### `test` - Multi-platform Testing
- **Runs on:** Ubuntu, macOS, Windows
- **Zig Version:** 0.15.1
- **Steps:**
  - Checkout code
  - Setup Zig
  - Run full test suite (`zig build test --summary all`)
  - Check for memory leaks (Unix only)
  - Build project

#### `lint` - Code Quality Check
- **Runs on:** Ubuntu
- **Steps:**
  - Check code formatting with `zig fmt --check`

#### `build-release` - Release Mode Builds
- **Runs on:** Ubuntu
- **Steps:**
  - Build with ReleaseFast optimization
  - Build with ReleaseSafe optimization
  - Build with ReleaseSmall optimization

#### `coverage` - Test Coverage Report
- **Runs on:** Ubuntu
- **Steps:**
  - Run tests with summary
  - Generate test report in GitHub Step Summary

#### `docs` - Documentation Verification
- **Runs on:** Ubuntu
- **Steps:**
  - Verify all required documentation files exist
  - Check README.md has badges

#### `status-check` - Overall Status
- **Runs on:** Ubuntu
- **Depends on:** All other jobs
- **Steps:**
  - Verify all jobs passed
  - Report overall CI status

**Expected Runtime:** ~3-5 minutes

---

### 2. Release Workflow (`.github/workflows/release.yml`)

**Triggers:**
- Push tags matching `v*.*.*` (e.g., `v1.0.0`)
- Manual dispatch with version input

**Jobs:**

#### `create-release` - Release Creation
- **Runs on:** Ubuntu
- **Permissions:** Write to contents
- **Steps:**
  - Run full test suite (safety check)
  - Verify no memory leaks
  - Build release artifacts (Fast, Safe, Small)
  - Extract version from tag
  - Generate comprehensive release notes
  - Create GitHub release

#### `publish-docs` - Documentation Publishing
- **Runs on:** Ubuntu
- **Depends on:** create-release
- **Permissions:** Write to pages
- **Steps:**
  - Generate documentation site
  - Upload to GitHub Pages
  - Deploy documentation

**Release Notes Include:**
- Feature summary
- Installation instructions
- Quick start guide
- Test results
- Links to documentation

**Expected Runtime:** ~5-10 minutes

---

### 3. Nightly Tests (`.github/workflows/nightly.yml`)

**Triggers:**
- Scheduled: Daily at 2 AM UTC
- Manual dispatch

**Jobs:**

#### `test-zig-master` - Bleeding Edge Testing
- **Runs on:** Ubuntu
- **Continues on error:** Yes (informational)
- **Steps:**
  - Test with Zig master branch
  - Report compatibility status

#### `memory-leak-extended` - Deep Memory Testing
- **Runs on:** Ubuntu
- **Steps:**
  - Install Valgrind
  - Run extended memory leak detection
  - Verify zero leaks

#### `benchmark` - Performance Tracking
- **Runs on:** Ubuntu
- **Steps:**
  - Build in ReleaseFast mode
  - Measure build time
  - Measure test execution time
  - Report to GitHub Step Summary

#### `dependency-check` - Dependency Audit
- **Runs on:** Ubuntu
- **Steps:**
  - Verify build.zig.zon
  - Check for minimal dependencies
  - Report dependency status

#### `cross-compile` - Multi-platform Builds
- **Runs on:** Ubuntu
- **Matrix Strategy:** 5 targets
  - x86_64-linux
  - x86_64-windows
  - x86_64-macos
  - aarch64-linux
  - aarch64-macos
- **Steps:**
  - Cross-compile for each target

#### `report` - Nightly Summary
- **Runs on:** Ubuntu
- **Depends on:** All nightly jobs
- **Steps:**
  - Generate comprehensive nightly report
  - Summarize all job results

**Expected Runtime:** ~15-20 minutes

---

### 4. PR Checks (`.github/workflows/pr.yml`)

**Triggers:**
- Pull request opened, synchronized, or reopened

**Jobs:**

#### `pr-info` - PR Information
- **Runs on:** Ubuntu
- **Steps:**
  - Display PR metadata in summary

#### `quick-test` - Fast Validation
- **Runs on:** Ubuntu
- **Steps:**
  - Quick build check
  - Quick test run (fast feedback)

#### `format-check` - Code Formatting
- **Runs on:** Ubuntu
- **Steps:**
  - Verify code is formatted with `zig fmt`
  - Fail with instructions if not formatted

#### `test-coverage` - Coverage Analysis
- **Runs on:** Ubuntu
- **Steps:**
  - Run tests verbosely
  - Analyze and report test results

#### `memory-safety` - Memory Verification
- **Runs on:** Ubuntu
- **Steps:**
  - Check for memory leaks
  - Report to step summary

#### `docs-check` - Documentation Updates
- **Runs on:** Ubuntu
- **Steps:**
  - Detect changed files
  - Suggest README updates if needed

#### `build-modes` - All Build Modes
- **Runs on:** Ubuntu
- **Matrix Strategy:** 4 modes
  - Debug
  - ReleaseFast
  - ReleaseSafe
  - ReleaseSmall

#### `pr-status` - PR Status Summary
- **Runs on:** Ubuntu
- **Depends on:** All PR jobs
- **Steps:**
  - Check all jobs passed
  - Generate comprehensive PR summary

**Expected Runtime:** ~5-7 minutes

---

### 5. CodeQL Analysis (`.github/workflows/codeql.yml`)

**Triggers:**
- Push to `main` branch
- Pull requests to `main`
- Scheduled: Monday at 6 AM UTC

**Jobs:**

#### `analyze` - Security Analysis
- **Runs on:** Ubuntu
- **Permissions:** Read/write security events
- **Steps:**
  - Initialize CodeQL (analyzes Zig as C/C++)
  - Build project
  - Perform security analysis

**Expected Runtime:** ~10-15 minutes

---

### 6. Dependabot (`.github/dependabot.yml`)

**Configuration:**
- **Ecosystem:** GitHub Actions
- **Schedule:** Weekly updates
- **Auto-labels:** dependencies, github-actions
- **Reviewers:** bcardaralla
- **Commit prefix:** ci
- **PR limit:** 5 concurrent

**Monitors:**
- GitHub Actions versions
- Workflow dependencies

---

## Issue Templates

### Bug Report (`.github/ISSUE_TEMPLATE/bug_report.yml`)

**Fields:**
- Bug description
- Reproduction steps
- Expected vs actual behavior
- Minimal reproduction code
- Zig version
- Operating system
- Additional context
- Checklist

### Feature Request (`.github/ISSUE_TEMPLATE/feature_request.yml`)

**Fields:**
- Feature type
- Description
- Use case
- WHATWG spec reference
- Proposed API
- Alternatives considered
- Checklist

### Question (`.github/ISSUE_TEMPLATE/question.yml`)

**Fields:**
- Question category
- Question details
- Context
- Related code
- Prior research

---

## Pull Request Template

**File:** `.github/PULL_REQUEST_TEMPLATE.md`

**Sections:**
- Description
- Type of change
- Related issues
- Changes made
- WHATWG spec compliance
- Testing details
- Memory safety verification
- Code quality checks
- Performance impact
- Breaking changes
- Documentation updates
- Comprehensive checklist

---

## Workflow Features

### Automatic Checks

All workflows automatically:
- ✅ Run tests on multiple platforms
- ✅ Verify no memory leaks
- ✅ Check code formatting
- ✅ Build in all optimization modes
- ✅ Generate test reports
- ✅ Create GitHub Step Summaries

### Security Features

- CodeQL security analysis
- Dependabot for action updates
- Permission restrictions per job
- No secrets exposure in logs

### Performance Monitoring

- Build time tracking
- Test execution timing
- Cross-platform benchmarks
- Nightly performance reports

### Quality Gates

PRs must pass:
- All tests (531/531)
- Code formatting check
- Memory leak verification
- All build modes
- Documentation checks

### Release Automation

Releases automatically:
- Run full test suite
- Build all variants
- Generate release notes
- Create GitHub release
- Publish documentation

---

## Usage

### Running CI Locally

```bash
# Format code
zig fmt src/

# Run tests
zig build test --summary all

# Check for leaks
zig build test 2>&1 | grep -i leak

# Build release modes
zig build -Doptimize=ReleaseFast
zig build -Doptimize=ReleaseSafe
zig build -Doptimize=ReleaseSmall
```

### Creating a Release

1. **Tag the release:**
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```

2. **Workflow automatically:**
   - Runs all tests
   - Builds artifacts
   - Generates release notes
   - Creates GitHub release
   - Publishes documentation

3. **Manual release (if needed):**
   - Go to Actions → Release
   - Click "Run workflow"
   - Enter version (e.g., `v1.0.0`)

### Viewing Reports

- **Test Results:** Check "CI" workflow → "coverage" job
- **Build Times:** Check "Nightly Tests" → "benchmark" job
- **PR Status:** Automatic summary in PR checks
- **Security:** Check "CodeQL" workflow results

---

## Maintenance

### Updating Workflows

When updating workflows:

1. Test changes in a feature branch
2. Create PR to trigger PR workflow
3. Verify all checks pass
4. Merge to main

### Monitoring

Check these regularly:

- **CI Status:** All workflows passing?
- **Dependabot PRs:** Review and merge action updates
- **CodeQL Alerts:** Address security findings
- **Nightly Tests:** Monitor for regressions

### Troubleshooting

**If CI fails:**

1. Check the specific job that failed
2. Review the error logs
3. Reproduce locally:
   ```bash
   zig build test --summary all
   ```
4. Fix the issue
5. Push the fix

**If memory leaks detected:**

1. Run locally: `zig build test`
2. Check for missing `defer` statements
3. Review reference counting
4. Fix and verify locally
5. Push the fix

---

## CI/CD Statistics

### Coverage

- **Platforms:** Linux, macOS, Windows
- **Zig Versions:** 0.15.1 stable + master (nightly)
- **Build Modes:** Debug, ReleaseFast, ReleaseSafe, ReleaseSmall
- **Cross-compile:** 5 targets

### Quality Checks

- ✅ 531 automated tests
- ✅ Memory leak detection
- ✅ Code formatting enforcement
- ✅ Documentation verification
- ✅ Security analysis
- ✅ Performance tracking

### Automation Level

- **Automated:** 95%
  - Testing
  - Building
  - Releasing
  - Documentation
  
- **Manual:** 5%
  - Release approval
  - Security review
  - Breaking changes

---

## Future Enhancements

Potential additions:

1. **Code Coverage Reporting**
   - Integration with coverage tools
   - Visual coverage reports

2. **Performance Benchmarking**
   - Automated performance regression detection
   - Historical performance graphs

3. **Automated Changelogs**
   - Generate CHANGELOG.md from commits
   - Include in releases

4. **Docker Support**
   - Containerized builds
   - Reproducible environments

5. **Release Candidates**
   - Pre-release workflow
   - Beta testing automation

---

## Support

For CI/CD issues:

1. Check workflow logs in GitHub Actions tab
2. Review this documentation
3. Open an issue with the `ci` label
4. Reference failed workflow run

---

**CI/CD Setup Complete!** 🎉

The project now has enterprise-grade automation for:
- ✅ Testing on every commit
- ✅ Quality enforcement
- ✅ Automated releases
- ✅ Security monitoring
- ✅ Performance tracking

**Happy shipping!** 🚀
