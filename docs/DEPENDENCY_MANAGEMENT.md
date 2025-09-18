# Cross-Repo Dependency Management

This document explains how the automated dependency management system works between the Hyku Knapsack and Hyku repositories.

## Overview

The Hyku Knapsack has a complex circular dependency relationship with Hyku:
- **Hyku Knapsack** contains Hyku as a git submodule (`hyrax-webapp/`)
- **Hyku** references Hyku Knapsack as a gem dependency
- This creates a "chicken and egg" problem solved by the `required_for_knapsack_instances` branch

## Automated Workflows

### 1. Cross-Repo Compatibility Testing (`cross-repo-compatibility.yaml`)

**Purpose:** Ensures different combinations of Hyku and Knapsack versions work together.

**Triggers:**
- Push to `main` or `required_for_knapsack_instances` branches
- Pull requests
- Daily scheduled runs (2 AM UTC)
- Manual dispatch with custom parameters

**Test Matrix:**
- **Standard:** Latest main branches, Hyku main + Knapsack stable
- **Extended:** Multiple version combinations including beta releases
- **Minimal:** Quick compatibility check

**Features:**
- Intelligent test selection based on changes detected
- Docker-based testing environment
- Automatic failure reporting via GitHub issues
- Compatibility reports as artifacts

### 2. Hyku Submodule Auto-Sync (`hyku-sync.yaml`)

**Purpose:** Automatically updates the Hyku submodule when new changes are available.

**Triggers:**
- Scheduled runs twice daily (6 AM and 6 PM UTC)
- Manual dispatch with custom options

**Process:**
1. **Detection:** Checks for new commits in Hyku repository
2. **Testing:** Runs compatibility tests with the new version
3. **Update:** Creates a PR or commits directly (configurable)
4. **Sync:** Updates the `required_for_knapsack_instances` branch

**Safety Features:**
- Compatibility testing before updates
- Option to force updates even if tests fail
- Automatic rollback on critical failures
- Change logs in commit messages

### 3. Dependency Monitor (`dependency-monitor.yaml`)

**Purpose:** Continuously monitors for version drift and security issues.

**Triggers:**
- Every 4 hours
- Manual dispatch with specific check types

**Monitoring:**
- **Version Drift:** Tracks how far behind the submodule is
- **Security:** Scans for known vulnerabilities
- **Performance:** Basic performance regression detection

**Alerting:**
- Creates GitHub issues for critical drift
- Updates existing issues rather than spamming
- Provides actionable recommendations

## Manual Tools

### Compatibility Test Script (`scripts/compatibility-test.sh`)

A local script for testing compatibility before making changes.

**Usage:**
```bash
# Test with Hyku main branch, core tests
./scripts/compatibility-test.sh

# Test with specific Hyku version
./scripts/compatibility-test.sh v1.0.0.beta2

# Test with integration test suite
./scripts/compatibility-test.sh main integration

# Show help
./scripts/compatibility-test.sh --help
```

**Test Suites:**
- **core:** Basic functionality tests
- **integration:** Broader integration tests  
- **full:** Complete test suite (slow)
- **smoke:** Quick smoke tests

## Best Practices

### For Developers

1. **Before Making Changes:**
   ```bash
   # Run compatibility tests locally
   ./scripts/compatibility-test.sh
   ```

2. **Testing Specific Scenarios:**
   ```bash
   # Test with a specific Hyku branch
   ./scripts/compatibility-test.sh feature/new-feature
   ```

3. **Updating Dependencies:**
   - Use the automated workflows when possible
   - Test compatibility before manual updates
   - Update both repositories if needed

### For Maintainers

1. **Monitor Automated Issues:**
   - Review compatibility failure issues promptly
   - Address security advisories immediately
   - Keep the `required_for_knapsack_instances` branch stable

2. **Release Process:**
   - Ensure compatibility before releasing
   - Update documentation for breaking changes
   - Test with multiple Hyku versions if needed

3. **Workflow Configuration:**
   - Adjust test matrices based on project needs
   - Configure notification preferences
   - Update security scanning as needed

## Branch Strategy

### `required_for_knapsack_instances` Branch

This special branch exists to break the circular dependency:

- **Purpose:** Provides a stable reference for Hyku's gem dependency
- **Updates:** Automatically synced from main after successful tests
- **Usage:** Referenced in Hyku's Gemfile

**Why not use `main`?**
Using `main` would create a chicken-and-egg problem where:
1. Knapsack needs a new Hyku SHA
2. But Hyku needs a new Knapsack SHA to include that change
3. This creates an impossible circular dependency

The stable branch provides a known-good reference point that breaks this cycle.

## Troubleshooting

### Common Issues

1. **Compatibility Test Failures:**
   ```bash
   # Check specific test output
   docker-compose logs web
   
   # Test with different Hyku version
   ./scripts/compatibility-test.sh stable_version core
   ```

2. **Submodule Sync Issues:**
   ```bash
   # Manually update submodule
   git submodule update --remote hyrax-webapp
   
   # Reset to specific commit
   cd hyrax-webapp
   git checkout specific_sha
   cd ..
   git add hyrax-webapp
   ```

3. **Version Drift Alerts:**
   - Review the monitoring report in the issue
   - Run compatibility tests with latest versions
   - Update dependencies if tests pass

### Emergency Procedures

1. **Critical Security Issue:**
   ```bash
   # Force immediate update
   gh workflow run hyku-sync.yaml -f force_update=true -f create_pr=false
   ```

2. **Broken Automation:**
   - Disable problematic workflows temporarily
   - Fix issues in feature branches
   - Test thoroughly before re-enabling

3. **Rollback Required:**
   ```bash
   # Revert to previous working submodule version
   git checkout HEAD~1 -- hyrax-webapp
   git commit -m "Emergency rollback of Hyku submodule"
   ```

## Configuration

### Environment Variables

- `HYKU_REPO`: Target Hyku repository (default: `samvera/hyku`)
- `TARGET_BRANCH`: Default branch to sync (default: `main`)

### Workflow Inputs

Most workflows support manual configuration via workflow dispatch inputs:
- Custom branches/refs to test
- Test suite selection
- Force update options
- Notification preferences

### Secrets Required

- `GITHUB_TOKEN`: For creating issues and PRs (automatically provided)

## Contributing

When contributing to the dependency management system:

1. Test changes locally first
2. Update documentation for new features
3. Consider backward compatibility
4. Add monitoring for new failure modes

## Support

For issues with the dependency management system:

1. Check the [troubleshooting section](#troubleshooting)
2. Review recent workflow runs for error details
3. Create an issue with the `dependency-management` label
4. Include relevant logs and error messages
