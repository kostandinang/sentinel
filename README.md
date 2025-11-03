# Sentinel 🛡️

![Platform](https://img.shields.io/badge/platform-macOS-lightgrey)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![SwiftUI](https://img.shields.io/badge/SwiftUI-blue)
![License](https://img.shields.io/github/license/kostandinang/sentinel)
![GitHub stars](https://img.shields.io/github/stars/kostandinang/sentinel)
![GitHub issues](https://img.shields.io/github/issues/kostandinang/sentinel)

**Sentinel** is a native macOS menu bar application that monitors and displays the status of AI coding agent sessions (Claude Code, Warp, Gemini CLI) with a clean, modern interface.

![Sentinel App Screenshot](screenshot.png)

## Features

- **Multi-Agent Support**: Track sessions from Claude Code, Warp.dev, Gemini CLI, and GitHub Copilot
- **Real-time Monitoring**: Track AI coding agent sessions as they run
- **Menu Bar Integration**: Unobtrusive status indicator with dynamic icons
- **Session History**: View all active and recent sessions
- **Activity Timeline**: See every prompt, tool use, and event
- **Native Notifications**: Get notified about important events
- **Beautiful UI**: Clean, modern interface.

### Menu Bar Status

The menu bar icon shows your current agent status at a glance:

- 🛡️ Gray shield: Idle (no active sessions)
- 🔵 Blue shield: Active (agent thinking)
- 🟠 Orange shield: Using tool
- 🔴 Red shield: Error

### Main Window

View detailed information about all your sessions, including:

- Working directory
- Process ID
- Duration
- Complete activity timeline
- Current operation status

## Installation

### Option 1: Build from Source

1. **Clone the repository**:

   ```bash
   git clone <repository-url>
   cd sentinel
   ```

2. **Open in Xcode**:

   ```bash
   open sentinel/sentinelApp.swift
   ```

3. **Build and Run**:
   - Select **sentinel** scheme
   - Click Run (⌘R)
   - The app will appear in your menu bar

### Option 2: Download Pre-built Binary

(Coming soon - download from Releases page)

## Setup

To enable Sentinel monitoring, you need to configure hooks for your AI coding agent(s). Sentinel supports:

- **Claude Code**: Uses `~/.claude/settings.json`
- **Warp.dev**: Uses Warp's hooks configuration
- **Gemini CLI**: Uses Gemini's hooks configuration
- **GitHub Copilot**: Uses VS Code extension or MCP integration

### 1. Install the Hooks Configuration

#### For Claude Code

You need to manually edit Claude's settings file to configure hooks:

**Step 1:** Open the Claude settings file in your text editor:

```bash
nano ~/.claude/settings.json
```

**Step 2:** Add the hooks configuration to the `"hooks"` property. If the file doesn't have a `hooks` property, add it. You can copy the configuration from `Sentinel/Resources/example-hooks.json`, or use this:

```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "sh -c \"open -g 'sentinel://hook?type=prompt-submit&pid=$PPID&pwd=$(pwd | sed 's/ /%20/g')'\""
          }
        ]
      }
    ],
    "PreToolUse": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "sh -c \"TOOL_NAME=$(python3 -c 'import sys, json; data = json.load(sys.stdin); print(data.get(\\\"tool_name\\\", \\\"Unknown\\\"))'); open -g \\\"sentinel://hook?type=tool-start&pid=$PPID&tool=$(echo \\\"$TOOL_NAME\\\" | sed 's/ /%20/g')\\\"\""
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "sh -c \"TOOL_NAME=$(python3 -c 'import sys, json; data = json.load(sys.stdin); print(data.get(\\\"tool_name\\\", \\\"Unknown\\\"))'); open -g \\\"sentinel://hook?type=tool-complete&pid=$PPID&tool=$(echo \\\"$TOOL_NAME\\\" | sed 's/ /%20/g')\\\"\""
          }
        ]
      }
    ],
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "sh -c \"open -g 'sentinel://hook?type=session-stop&pid=$PPID'\""
          }
        ]
      }
    ]
  }
}
```

**Step 3:** Save the file and close your editor.

#### For Warp.dev

If you're using Warp's AI features with agent mode:

**Step 1:** Configure Warp hooks (check Warp's documentation for the exact location of hooks configuration)

**Step 2:** Use the hooks configuration from `Sentinel/Resources/example-hooks-warp.json`

The key difference is adding `&agent=warp` to each URL, for example:

```
sentinel://hook?type=prompt-submit&pid=$PPID&pwd=$(pwd)&agent=warp
```

#### For Gemini CLI

If you're using the Gemini CLI tool with hooks support:

**Step 1:** Configure Gemini CLI hooks (check Gemini CLI documentation for the exact location)

**Step 2:** Use the hooks configuration from `Sentinel/Resources/example-hooks-gemini.json`

The key difference is adding `&agent=gemini` to each URL, for example:

```
sentinel://hook?type=prompt-submit&pid=$PPID&pwd=$(pwd)&agent=gemini
```

#### For GitHub Copilot

GitHub Copilot integration requires a VS Code extension or MCP (Model Context Protocol) server to send hooks to Sentinel:

**Option 1: VS Code Extension Integration (Recommended)**

Create a custom VS Code extension that listens to Copilot events and sends hooks to Sentinel. The extension should:

1. Listen to GitHub Copilot Chat events
2. Track when prompts are submitted
3. Monitor tool/extension usage
4. Send events to Sentinel via URL scheme

Example code for your extension:

```typescript
import * as vscode from "vscode";
import { exec } from "child_process";

// Send hook to Sentinel
function sendSentinelHook(type: string, toolName?: string) {
  const pid = process.pid;
  const pwd = vscode.workspace.workspaceFolders?.[0]?.uri.fsPath || "";
  let url = `sentinel://hook?type=${type}&pid=${pid}&pwd=${encodeURIComponent(
    pwd
  )}&agent=copilot`;

  if (toolName) {
    url += `&tool=${encodeURIComponent(toolName)}`;
  }

  exec(`open -g '${url}'`);
}

// Example: Listen to Copilot Chat
vscode.chat.onDidStartChat(() => {
  sendSentinelHook("prompt-submit");
});
```

**Option 2: MCP Server Integration**

Use the Model Context Protocol to create a server that bridges GitHub Copilot and Sentinel. See `example-hooks-copilot.json` for the complete configuration format.

**Option 3: Manual Testing**

You can test the integration manually by running:

```bash
open -g 'sentinel://hook?type=prompt-submit&pid=$$&pwd='$(pwd)'&agent=copilot'
```

**Note:** GitHub Copilot doesn't natively support hooks like Claude Code. Full integration requires developing a custom VS Code extension. See `Sentinel/Resources/example-hooks-copilot.json` for detailed integration guidelines.

### 2. Launch Sentinel

- Run the Sentinel app
- It will appear in your menu bar
- Grant notification permissions when prompted

### 3. Test It

- Start a Claude Code session in any project
- Type a prompt and submit it
- You should see Sentinel's icon change to blue
- Click the icon to see session details

## How It Works

Sentinel uses a custom URL scheme (`sentinel://`) to receive events from AI coding agents via hooks configured in their settings files. When an agent triggers a hook:

1. The agent reads hook configuration from its settings file (e.g., `~/.claude/settings.json` with `hooks` property)
2. The hook executes a shell command that opens a `sentinel://` URL with event data
3. Sentinel's URL scheme handler receives and processes the URL
4. The UI updates in real-time to reflect the current session state
5. Notifications are sent (if enabled in settings)

### Hook Types

| Hook Type       | Trigger                   | Data                          |
| --------------- | ------------------------- | ----------------------------- |
| `prompt-submit` | User submits a prompt     | PID, working directory, agent |
| `tool-start`    | Agent starts using a tool | PID, tool name, agent         |
| `tool-complete` | Tool execution completes  | PID, tool name, agent         |
| `session-stop`  | Session ends              | PID, agent                    |

### Supported Agents

| Agent          | Icon     | Status                  |
| -------------- | -------- | ----------------------- |
| Claude Code    | Terminal | ✅ Tested               |
| Warp.dev       | Bolt     | ⚠️ Beta                 |
| Gemini CLI     | Sparkles | ⚠️ Beta                 |
| GitHub Copilot | Code     | 🔧 Requires VS Code Ext |

## Usage

### Menu Bar

Click the Sentinel icon in your menu bar to:

- View quick status of active sessions
- Open the main window for details
- Quit the application

### Main Window

The main window shows:

- **Left sidebar**: List of all sessions (active and recent)
  - Toggle "Active Only" to filter
  - Click a session to view details
- **Right panel**: Detailed information
  - Session metadata (directory, PID, duration)
  - Complete activity timeline
  - Current operation status

### Settings

Access settings by clicking the gear icon in the main window:

- **Notifications**: Configure which events trigger notifications
- **Monitoring**: View supported agent types and URL scheme
- **Data**: Clear session history
- **Hook Configuration**: Copy example hooks to clipboard

## Architecture

### Application Structure

```
sentinel/
├── Models/              # Data models
│   ├── AgentSession.swift      # Session data structure
│   ├── HookEvent.swift          # Event types and data
│   ├── AgentType.swift          # Supported agent types
│   └── SessionGraphNode.swift   # Graph visualization data
├── ViewModels/          # Business logic
│   ├── SessionManager.swift     # Core session tracking
│   └── MenuBarViewModel.swift   # Menu bar state management
├── Views/               # UI components
│   ├── MenuBarView.swift        # Menu bar dropdown
│   ├── MainWindow.swift         # Main app window
│   ├── SessionListView.swift    # Session list sidebar
│   ├── SessionDetailView.swift  # Session details panel
│   ├── SessionGraphView.swift   # Session graph visualization
│   ├── CompactGraphView.swift   # Compact graph view
│   ├── SettingsView.swift       # Settings panel
│   └── Components/              # Reusable components
│       ├── AgentTagView.swift   # Agent type badges
│       └── ToolTagView.swift    # Tool usage badges
├── Services/            # Core services
│   ├── URLSchemeHandler.swift   # sentinel:// URL processing
│   ├── NotificationManager.swift # System notifications
│   └── ProcessMonitor.swift     # Process lifecycle tracking
└── Resources/           # Configuration examples
    ├── example-hooks.json       # Claude Code hooks
    ├── example-hooks-copilot.json
    ├── example-hooks-gemini.json
    └── example-hooks-warp.json
```

## Troubleshooting

### Sentinel isn't receiving events

1. **Check hooks are configured**:

   ```bash
   # Verify hooks are in settings.json under "hooks" property
   cat ~/.claude/settings.json | jq '.hooks'
   ```

   The hooks should be in `~/.claude/settings.json` under the `"hooks"` property, NOT in a separate `hooks.json` file.

2. **Restart Claude Code**: Close all Claude Code sessions and start a new one

3. **Check Console.app**: Look for error messages from Sentinel

4. **Verify URL scheme**: Test manually:
   ```bash
   open "sentinel://hook?type=prompt-submit&pid=12345&pwd=/tmp"
   ```

### Notifications aren't showing

1. **Check permissions**: System Settings → Notifications → Sentinel
2. **Enable in Sentinel settings**: Open Sentinel → Settings → Notifications
3. **Test notification**: Go to Settings and click "Test Notification"

### Sessions show as stopped immediately

This usually means the PID couldn't be tracked. Check that:

- Hooks are using `$PPID` correctly
- The process is still running when hooks fire

## Future Enhancements

- Support for additional AI agents (Cursor, Copilot, etc.)
- Export session data (JSON, CSV, text)
- Statistics and analytics
- Custom icon themes
- Keyboard shortcuts
- Mini mode: compact session view in menu bar dropdown
- Integration with other development tools
- Per-agent color themes and customization

## Contributing

Contributions are welcome!

Please feel free to submit issues and pull requests.

## License

MIT - See [LICENSE](./LICENSE) file for details

---

_This repo is crated with the help of Claude Code 🤖_
