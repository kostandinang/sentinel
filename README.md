# Sentinel 🛡️

**Sentinel** is a native macOS menu bar application that monitors and displays the status of Claude Code agent sessions with a clean, modern interface.

## Features

- **Real-time Monitoring**: Track Claude Code sessions as they run
- **Menu Bar Integration**: Unobtrusive status indicator with dynamic icons
- **Session History**: View all active and recent sessions
- **Activity Timeline**: See every prompt, tool use, and event
- **Native Notifications**: Get notified about important events
- **Beautiful UI**: Clean, modern interface following macOS design guidelines

## Screenshots

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
   cd ~/Projects
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

To enable Sentinel monitoring, you need to configure Claude Code hooks:

### 1. Install the Hooks Configuration

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

Sentinel uses a custom URL scheme (`sentinel://`) to receive events from Claude Code via hooks. When Claude Code triggers a hook:

1. The hook executes a shell command
2. The command opens a `sentinel://` URL with event data
3. Sentinel receives and processes the URL
4. The UI updates in real-time
5. Notifications are sent (if enabled)

### Hook Types

| Hook Type       | Trigger                   | Data                   |
| --------------- | ------------------------- | ---------------------- |
| `prompt-submit` | User submits a prompt     | PID, working directory |
| `tool-start`    | Agent starts using a tool | PID, tool name         |
| `tool-complete` | Tool execution completes  | PID, tool name         |
| `session-stop`  | Session ends              | PID                    |

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

```
Sentinel/
├── Models/              # Data models
│   ├── AgentSession.swift
│   ├── HookEvent.swift
│   └── AgentType.swift
├── ViewModels/          # Business logic
│   ├── SessionManager.swift
│   └── MenuBarViewModel.swift
├── Views/               # UI components
│   ├── MenuBarView.swift
│   ├── MainWindow.swift
│   ├── SessionListView.swift
│   ├── SessionDetailView.swift
│   └── SettingsView.swift
├── Services/            # Utilities
│   ├── URLSchemeHandler.swift
│   ├── NotificationManager.swift
│   └── ProcessMonitor.swift
└── Resources/           # Assets and configs
    └── example-hooks.json
```

## Troubleshooting

### Sentinel isn't receiving events

1. **Check hooks are configured**: Verify hooks are set by viewing `~/.claude/settings.json` and ensuring the `hooks` property is present and properly formatted
2. **Restart Claude Code**: Close all Claude Code sessions and start a new one
3. **Check Console.app**: Look for error messages from Sentinel
4. **Verify URL scheme**: Run `open "sentinel://hook?type=prompt-submit&pid=12345&pwd=/tmp"` in Terminal

### Notifications aren't showing

1. **Check permissions**: System Settings → Notifications → Sentinel
2. **Enable in Sentinel settings**: Open Sentinel → Settings → Notifications
3. **Test notification**: Go to Settings and click "Test Notification"

### Sessions show as stopped immediately

This usually means the PID couldn't be tracked. Check that:

- Hooks are using `$PPID` correctly
- The process is still running when hooks fire

## Future Enhancements

- Support for other AI agents (Cursor, Copilot, etc.)
- Export session data (JSON, CSV, text)
- Statistics and analytics
- Custom icon themes
- Keyboard shortcuts
- Mini mode: compact session view in menu bar dropdown
- Integration with other development tools

## Contributing

Contributions are welcome! Please feel free to submit issues and pull requests.

## License

MIT License - See LICENSE file for details

---

_This README is crated with the help of Claude Code_
