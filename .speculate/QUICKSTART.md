# Sentinel v2.0 Development Quick Start

**For developers ready to start building today.**

## Getting Started in 5 Minutes

### 1. Set Up Your Environment

```bash
# Navigate to project
cd /Users/kostandin/Projects/misc/sentinel

# Open in Xcode
open sentinel.xcodeproj

# Install development tools
brew install swiftlint swiftformat
```

### 2. Choose Your Starting Point

Pick one based on your interests:

#### Option A: Multi-Agent Support (Backend/Architecture)
**Start here if you like:** System design, protocols, extensibility

```bash
# Read the spec
cat .speculate/01-multi-agent-support.json

# First task: design-agent-abstraction (3 hours)
# Create: sentinel/Models/AgentProtocol.swift
```

**What you'll build:** The abstract interface that all agents implement

#### Option B: Data Export (Full-Stack)
**Start here if you like:** Data processing, file formats, user features

```bash
# Read the spec
cat .speculate/02-data-export-analytics.json

# First task: design-export-schema (2 hours)
# Create: docs/EXPORT_SCHEMA.md
```

**What you'll build:** The export system for JSON, CSV, and text

#### Option C: UI/UX (Frontend/Design)
**Start here if you like:** SwiftUI, user experience, visual design

```bash
# Read the spec
cat .speculate/03-advanced-ui-ux.json

# First task: design-minimode-layout (2 hours)
# Create: docs/designs/MINIMODE_DESIGN.md
```

**What you'll build:** The compact menu bar mode

#### Option D: Testing (Quality/Infrastructure)
**Start here if you like:** Test automation, CI/CD, quality assurance

```bash
# Read the spec
cat .speculate/08-testing-quality.json

# First task: setup-unit-test-framework (2 hours)
# Modify: sentinel.xcodeproj, create test utilities
```

**What you'll build:** Comprehensive test suite and CI pipeline

### 3. Run the First Task

Each spec file contains tasks with:
- **acceptance_criteria:** What "done" looks like
- **technical_notes:** Implementation guidance
- **files_to_modify:** Exactly what to change

Example workflow:
```bash
# 1. Read the task details
jq '.tasks[0]' .speculate/01-multi-agent-support.json

# 2. Create a feature branch
git checkout -b feature/agent-abstraction

# 3. Implement the task
# (Open Xcode, start coding)

# 4. Test your changes
# (Write tests, run them)

# 5. Commit and push
git add .
git commit -m "feat: design agent abstraction protocol"
git push origin feature/agent-abstraction
```

### 4. Track Your Progress

Update the task status:
```bash
# Mark task as in-progress
# (Update .speculate/01-multi-agent-support.json)
# Change "status": "pending" → "status": "in_progress"

# When done, mark complete
# Change "status": "in_progress" → "status": "completed"
```

---

## Understanding the Specs

### Spec File Structure

Each category spec (e.g., `01-multi-agent-support.json`) contains:

```json
{
  "category": "Multi-Agent Support",
  "priority": "CRITICAL",
  "total_estimate_hours": 28,
  "tasks": [
    {
      "id": "design-agent-abstraction",
      "description": "Design abstract agent interface",
      "estimate_hours": 3,
      "status": "pending",
      "acceptance_criteria": [...],
      "technical_notes": [...],
      "files_to_modify": [...]
    }
  ],
  "relationships": [
    {"from": "task-a", "to": "task-b", "type": "blocks"}
  ]
}
```

### Task Relationships

- **blocks:** Task A must complete before Task B starts
- **relates_to:** Tasks are related but can run in parallel
- **part_of:** Task A is a subtask of Epic B

### Using the Graphs

Generate visual dependency graphs:
```bash
# If speculate CLI is installed
cd speculate && python3 -m speculate.cli available

# Or manually visualize with Mermaid
# Copy the relationships into a Mermaid live editor
# https://mermaid.live
```

---

## Development Guidelines

### Code Style

```swift
// ✅ Good: Descriptive names, guard statements
func handleSessionStartHook(pid: Int, workingDirectory: String) {
    guard let session = sessions[pid] else {
        logger.error("Session not found for PID: \(pid)")
        return
    }
    // Implementation
}

// ✅ Good: Computed properties for derived state
var activeSessionCount: Int {
    sessions.values.filter { $0.status == .active }.count
}
```

### Testing Pattern

```swift
// Write tests FIRST (TDD)
func testAgentProtocolRegistration() {
    // Given
    let registry = AgentRegistry()
    let mockAgent = MockAgent()

    // When
    registry.register(mockAgent)

    // Then
    XCTAssertEqual(registry.agents.count, 1)
    XCTAssertEqual(registry.agent(for: "mock"), mockAgent)
}
```

### Commit Messages

Follow conventional commits:
```bash
feat: add agent abstraction protocol
fix: correct PID tracking in SessionManager
docs: update README with multi-agent setup
test: add unit tests for AgentRegistry
refactor: extract Claude adapter from URLSchemeHandler
```

---

## Common Tasks

### Running Tests

```bash
# All tests
xcodebuild test -scheme sentinel

# Specific test
xcodebuild test -scheme sentinel -only-testing:sentinelTests/AgentSessionTests

# With coverage
xcodebuild test -scheme sentinel -enableCodeCoverage YES
```

### Linting

```bash
# Run SwiftLint
swiftlint

# Auto-fix
swiftlint --fix

# Format code
swiftformat .
```

### Building

```bash
# Debug build
xcodebuild -scheme sentinel -configuration Debug

# Release build
xcodebuild -scheme sentinel -configuration Release

# Run app
xcodebuild -scheme sentinel -configuration Debug && open ~/Library/Developer/Xcode/DerivedData/.../sentinel.app
```

---

## Getting Help

### Documentation

- **Master Plan:** `.speculate/MASTER_PLAN.md` - Overall strategy
- **Roadmap:** `.speculate/ROADMAP.md` - High-level timeline
- **Specs:** `.speculate/0X-category-name.json` - Detailed tasks
- **Project Context:** `CLAUDE.md` - Architecture and patterns

### Asking Questions

Before asking:
1. Check the spec file for your category
2. Read the technical_notes in the task
3. Review the CLAUDE.md for architecture patterns
4. Search existing issues on GitHub

When asking:
- Specify which task you're working on (ID)
- Include relevant code snippets
- Describe what you've tried
- Share error messages or unexpected behavior

### Contributing

See `CONTRIBUTING.md` (to be created) for:
- Pull request process
- Code review guidelines
- Release process
- Community guidelines

---

## Next Steps After First Task

1. **Complete the task:** Meet all acceptance criteria
2. **Write tests:** Ensure your code is tested
3. **Update docs:** If you changed APIs or added features
4. **Create PR:** Push branch, open pull request
5. **Get reviewed:** Address feedback, iterate
6. **Merge:** Celebrate! 🎉
7. **Pick next task:** Check dependencies in relationships

---

## Recommended Task Sequences

### For Solo Developer (Prioritized)

**Week 1-2:** Foundation
1. design-agent-abstraction
2. refactor-claude-adapter
3. setup-unit-test-framework
4. setup-ci-pipeline

**Week 3-4:** Core Features
5. implement-cursor-agent
6. design-export-schema
7. implement-json-export
8. implement-resource-tracking

**Week 5-6:** UI/UX
9. design-minimode-layout
10. implement-minimode-view
11. add-search-filtering
12. design-theme-system

### For Team of 3 (Parallelized)

**Developer A (Backend):**
- All multi-agent support tasks
- Data export implementation
- Resource monitoring

**Developer B (Frontend):**
- All UI/UX tasks
- Theming and customization
- Analytics UI

**Developer C (Infrastructure):**
- All testing tasks
- CI/CD pipeline
- Performance optimization
- Security hardening

---

## Success Checklist

Before considering a task "done":

- [ ] All acceptance criteria met
- [ ] Tests written and passing
- [ ] SwiftLint passes with no errors
- [ ] Code reviewed (or self-reviewed thoroughly)
- [ ] Documentation updated if needed
- [ ] Committed with conventional commit message
- [ ] CI pipeline green

---

**Ready to build? Pick your starting point above and dive in!** 🚀

For questions or guidance, refer to the spec files or reach out to the team.
