# Sentinel Quick Start

Get up and running with Sentinel.

## 1. Build

```bash
./build.sh
```

Or open in Xcode:

```bash
open Package.swift
```

Then press ⌘R to build and run.

## 2. Install Hooks

### Claude Code

```bash
mkdir -p ~/.claude

# If settings.json doesn't exist, create it with the hooks
if [ ! -f ~/.claude/settings.json ]; then
  cp sentinel/Resources/example-hooks.json ~/.claude/settings.json
else
  # Merge hooks into existing settings.json using jq
  jq -s '.[0] * .[1]' ~/.claude/settings.json sentinel/Resources/example-hooks.json > ~/.claude/settings.json.tmp && mv ~/.claude/settings.json.tmp ~/.claude/settings.json
fi
```

**Note**: If you don't have `jq` installed: `brew install jq`

## 3. Run Sentinel

From Xcode: Press ⌘R

Or from command line:

```bash
./.build/release/Sentinel
```

Or install to Applications:

```bash
./install.sh
open /Applications/Sentinel.app
```

## 4. Test It

1. Look for the shield icon 🛡️ in your menu bar
2. Start a Claude Code session in any project
3. Submit a prompt
4. Watch the icon turn blue!
5. Click the icon to see session details

## 5. Grant Permissions

When prompted, allow Sentinel to:

- Send notifications
- Run in the background

## That's It!

Sentinel is now monitoring your Claude Code sessions.

For more details, see:

- [README.md](README.md) - Full documentation
- [SETUP_GUIDE.md](SETUP_GUIDE.md) - Detailed setup instructions

## Troubleshooting

**Icon not appearing?**

- Make sure Sentinel is running
- Check Activity Monitor for "Sentinel" process

**Not receiving events?**

- Verify hooks are installed: `cat ~/.claude/settings.json`
- Restart Claude Code after installing hooks

**No notifications?**

- Check System Settings → Notifications → Sentinel
- Enable in Sentinel Settings (gear icon)

Need help? See [SETUP_GUIDE.md](SETUP_GUIDE.md) Troubleshooting section.

---

Happy monitoring! 🛡️
