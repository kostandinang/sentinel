# Setup Guide

This guide will walk you through setting up Sentinel to monitor your Claude Code sessions.

## Prerequisites

- macOS 13 (Ventura) or later
- Claude Code installed
- Xcode 15+ (for building from source)

## Step 1: Build Sentinel

### Option A: Using Xcode

1. Open Terminal and navigate to the project:

   ```bash
   cd /path/to/sentinel/Sentinel
   ```

2. Open the package in Xcode:

   ```bash
   open Package.swift
   ```

3. In Xcode:

   - Wait for dependencies to resolve
   - Select "My Mac" as the destination
   - Click the Play button (⌘R) to build and run

4. The app will launch and appear in your menu bar (look for the shield icon 🛡️)

### Option B: Using Command Line

```bash
cd /path/to/sentinel/Sentinel
swift build -c release
```

The built binary will be at `.build/release/Sentinel`

## Step 2: Configure Claude Code Hooks

Sentinel receives events from Claude Code via custom URL scheme hooks.

### Setup Instructions

You need to manually edit Claude's settings file to configure hooks:

1. **Open Claude's settings file** in your text editor:

   ```bash
   nano ~/.claude/settings.json
   ```

2. **Add the hooks configuration** to the `"hooks"` property. If the file doesn't have a `hooks` property, add it. Here's the configuration to add (you can also copy from `Sentinel/Resources/example-hooks.json`):

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

3. **Save the file** and close your editor

4. **Verify the configuration** (optional):
   ```bash
   cat ~/.claude/settings.json
   ```

## Step 3: Grant Permissions

When you first launch Sentinel, macOS will ask for notification permissions:

1. Click "Allow" when prompted
2. Or manually enable in: System Settings → Notifications → Sentinel

## Step 4: Test the Integration

1. **Launch Sentinel** (if not already running)

   - You should see a gray shield icon in your menu bar

2. **Start a Claude Code session**:

   ```bash
   cd ~/Projects/some-project
   claude
   ```

3. **Submit a prompt** in Claude Code:

   ```
   Hello, what files are in this directory?
   ```

4. **Check Sentinel**:

   - The menu bar icon should turn blue (active)
   - You should see a notification: "New Session Started"
   - Click the icon to view session details

5. **Watch tool usage**:

   - When Claude Code uses a tool (e.g., `ls`), the icon turns orange
   - The tool name appears in the activity timeline

6. **End the session**:
   - Exit Claude Code normally
   - Sentinel should show the session as stopped
   - You'll see a "Session Completed" notification

## Understanding the Hooks

### What each hook does:

1. **UserPromptSubmit**

   - Fires when you submit a prompt to Claude Code
   - Creates a new session in Sentinel (if first prompt)
   - Marks session as "Active"

2. **PreToolUse**

   - Fires before Claude Code uses a tool (Read, Write, Bash, etc.)
   - Updates session status to "Using Tool"
   - Shows which tool is being used

3. **PostToolUse**

   - Fires after a tool completes
   - Returns session to "Active" status
   - Records tool completion in timeline

4. **Stop**
   - Fires when Claude Code session ends
   - Marks session as "Stopped"
   - Triggers completion notification

### URL Scheme Format

All hooks use the `sentinel://` URL scheme:

```
sentinel://hook?type={TYPE}&pid={PID}&[pwd={DIR}]&[tool={TOOL}]
```

Parameters:

- `type`: Hook type (prompt-submit, tool-start, tool-complete, session-stop)
- `pid`: Process ID of the Claude Code session
- `pwd`: Working directory (for prompt-submit)
- `tool`: Tool name (for tool-start and tool-complete)

## Customizing Hooks

You can customize the hooks configuration to:

### Monitor specific tools only

Add a matcher to filter which tools trigger hooks:

```json
{
  "matcher": "tool_name == 'Bash'",
  "hooks": [...]
}
```

### Add additional actions

Chain multiple commands:

```json
{
  "type": "command",
  "command": "sh -c \"open -g 'sentinel://...'; echo 'Hook triggered' >> /tmp/log\""
}
```

### Disable specific hooks

Comment out or remove hooks you don't want:

```json
{
  "hooks": {
    "UserPromptSubmit": [...],
    // "PreToolUse": [...],  // Disabled - won't track tool usage
    "Stop": [...]
  }
}
```

## Troubleshooting

### "Command not found: open"

The `open` command should be available on all macOS systems. If not:

```bash
which open  # Should output: /usr/bin/open
```

### Hooks not firing

1. Verify hooks configuration is set:

   ```bash
   cat ~/.claude/settings.json
   ```

   Make sure the `hooks` property is present and properly formatted.

   **IMPORTANT**: Claude Code uses `~/.claude/settings.json` with a `hooks` property,
   NOT a separate `~/.claude/hooks.json` file!

2. Check Claude Code loads hooks:

   ```bash
   # Look for hook-related messages in Claude Code output
   claude --verbose
   ```

3. Test the URL scheme manually:

   ```bash
   open "sentinel://hook?type=prompt-submit&pid=$$&pwd=$(pwd)"
   ```

   You should see a new session appear in Sentinel.

### Sentinel not responding to URLs

1. Verify Sentinel is running (shield icon in menu bar)

2. Check URL scheme is registered:

   ```bash
   # This should open Sentinel
   open "sentinel://"
   ```

3. Check Console.app for error messages:
   - Open Console.app
   - Search for "Sentinel"
   - Look for error messages

### Sessions not persisting

Check that Sentinel has permission to write to UserDefaults:

```bash
defaults read com.sentinel.Sentinel
```

If you see "Domain not found", Sentinel hasn't saved any data yet.

## Advanced Configuration

### Run Sentinel at Login

Currently not implemented, but you can:

1. System Settings → General → Login Items
2. Click "+" and add Sentinel.app
3. Or use a login item manager

### Custom Notification Sounds

Edit `NotificationManager.swift` to change notification sounds:

```swift
content.sound = UNNotificationSound(named: UNNotificationSoundName("custom.aiff"))
```

### Export Session Data

Session data is stored in UserDefaults. To export:

```bash
defaults read com.sentinel.Sentinel SentinelSessions > sessions.json
```

## Next Steps

- Explore the Settings panel (click gear icon in main window)
- Customize notification preferences
- Try monitoring multiple concurrent sessions
- View the activity timeline for detailed session insights

## Getting Help

If you encounter issues:

1. Check this guide's Troubleshooting section
2. Review the main README.md
3. Open an issue on GitHub with:
   - macOS version
   - Claude Code version
   - Error messages from Console.app
   - Your settings.json hooks configuration

---

Happy monitoring! 🛡️
