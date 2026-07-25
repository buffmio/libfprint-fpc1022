# Cross-Distribution Project Description Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Present libfprint-fpc1022 as an experimental cross-distribution driver project while keeping Arch Linux as one supported installation route.

**Architecture:** Update the repository-owned public copy first and enforce the positioning with documentation contract checks. Then synchronize the tested release notes and concise project description to GitHub without changing source code, package names, release assets, or the upstream MR reference.

**Tech Stack:** Markdown, Bash/rg documentation checks, Git, GitHub CLI

## Global Constraints

- Keep the upstream reference as libfprint MR `!570`.
- Keep tested hardware limited to USB ID `10a5:9200`.
- Do not change the repository name, package names, tag, or release assets.
- Describe Arch Linux/AUR as one installation method, not the whole project's scope.
- Retain the experimental and unofficial warnings.

---

### Task 1: Enforce cross-distribution wording

**Files:**
- Modify: `packaging/test-docs.sh`
- Modify: `README.md`
- Modify: `docs/release-notes-v0.1.0-wip.md`

**Interfaces:**
- Consumes: Existing distribution table and release asset names.
- Produces: Repository-owned public copy that explicitly covers Arch Linux, Debian, Ubuntu, and Fedora.

- [ ] **Step 1: Add failing documentation assertions**

Add checks that the README describes packages for multiple distributions and
that the release notes name Debian, Ubuntu, Fedora, and the AUR route.

- [ ] **Step 2: Run the documentation check and verify it fails**

Run: `bash packaging/test-docs.sh`

Expected: FAIL because the new cross-distribution phrases are absent.

- [ ] **Step 3: Update the public copy**

Add a concise cross-distribution sentence to the README introduction and make
the Release package paragraph explicitly name Debian, Ubuntu, and Fedora while
retaining the separate AUR instruction.

- [ ] **Step 4: Run the documentation check and verify it passes**

Run: `bash packaging/test-docs.sh`

Expected: `Documentation contract checks passed`

### Task 2: Publish synchronized metadata

**Files:**
- Source: `docs/release-notes-v0.1.0-wip.md`
- Modify externally: GitHub repository description and Release body

**Interfaces:**
- Consumes: Verified repository-owned release notes.
- Produces: Public GitHub metadata matching the cross-distribution positioning.

- [ ] **Step 1: Review and commit the repository changes**

Run: `git diff --check && git diff`

Commit the documentation and test updates.

- [ ] **Step 2: Push the source commit**

Run: `git push github source-release:main`

- [ ] **Step 3: Update GitHub metadata**

Set the repository description to an experimental cross-distribution libfprint
driver for the FPC Sensor Controller `10a5:9200`. Replace the existing Release
body with `docs/release-notes-v0.1.0-wip.md`.

- [ ] **Step 4: Verify the public state**

Run the documentation check, inspect the clean Git status, query the GitHub
repository description and Release body, and confirm the published main commit.
