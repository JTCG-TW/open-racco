# Slack Channel Setup

## Prerequisites

You need a Slack app with **Socket Mode** enabled. Socket Mode requires no public URL — works on any local machine.

### 1. Create a Slack App

1. Go to https://api.slack.com/apps → **Create New App** → **From scratch**
2. Choose a name and workspace

### 2. Enable Socket Mode

In your app settings → **Socket Mode** → Enable

This generates an **App-Level Token** (`xapp-...`) — copy it.

### 3. OAuth Scopes

Under **OAuth & Permissions** → **Bot Token Scopes**, add:

| Scope | Purpose |
|-------|---------|
| `app_mentions:read` | Receive @mention events |
| `channels:history` | Read public channel messages |
| `channels:read` | Look up channel info |
| `chat:write` | Post messages |
| `emoji:read` | Read workspace emoji list |
| `files:read` | Download file attachments |
| `files:write` | Upload files |
| `groups:history` | Read private channel messages |
| `groups:read` | Look up private channel info |
| `im:history` | Read DM messages |
| `im:read` | Look up DM info |
| `im:write` | Open DM channels |
| `mpim:history` | Read multi-party DM messages |
| `mpim:read` | Look up MPIM info |
| `mpim:write` | Open multi-party DMs |
| `reactions:read` | Read reactions |
| `reactions:write` | Add emoji reactions |
| `users:read` | Resolve user names |

### 4. Event Subscriptions

Under **Event Subscriptions** → Enable → Subscribe to **Bot Events**:

- `app_mention` — @mention in channels
- `message.channels` — public channel messages
- `message.groups` — private channel messages
- `message.im` — DM messages
- `message.mpim` — multi-party DM messages

> **Tip:** You can also use the [Slack app manifest](https://api.slack.com/reference/manifests) to configure all of this at once — see `manifest.json` if provided.

> **Note:** `app_mention` and `message.*` can both fire for the same @mention. The plugin deduplicates them automatically.

### 5. Install the App

**OAuth & Permissions** → **Install to Workspace** → copy the **Bot User OAuth Token** (`xoxb-...`).

---

## Plugin Configuration

### Tokens

Create `~/.claude/channels/slack/.env` (mode 600):

```
SLACK_BOT_TOKEN=xoxb-...
SLACK_APP_TOKEN=xapp-...
```

### Access Control

Create `~/.claude/channels/slack/access.json`:

```json
{
  "dmPolicy": "open",
  "allowFrom": ["*"],
  "channels": {
    "C09XXXXXXXX": {
      "enabled": true,
      "requireMention": true
    }
  },
  "ackReaction": "eyes",
  "threadHistoryLimit": 20
}
```

**`dmPolicy`**:
- `"open"` — any Slack user can DM the bot and reach Claude
- `"allowlist"` — only user IDs listed in `allowFrom` can DM
- `"disabled"` — no DMs accepted

**`allowFrom`**: Slack user IDs (find yours via `/api/auth.test` or your profile URL). `["*"]` means all users (only meaningful in `allowlist` mode).

**`channels`**: per-channel config. The bot must be invited to the channel. Set `requireMention: true` to only respond when `@mentioned`.

**`threadHistoryLimit`**: how many prior messages to fetch when the bot is @mentioned inside a thread. Default `10`. Set to `0` to disable.

**`threadHistoryMaxCharsPerMessage`**: truncates individual messages to this many characters. Long stack traces get `[truncated]` suffix. Default `1000`.

**`threadHistoryMaxTotalChars`**: total character budget for the entire thread history block. Oldest messages are dropped first when over budget. Default `8000` (~2000 tokens).

> **Token cost note:** Thread history is only fetched on @mention inside a thread. The total cost is bounded by `threadHistoryMaxTotalChars`. Persona files (SOUL.md etc.) are included in *every* API call — keep them concise (<500 tokens total) to avoid accumulating unnecessary context costs.

**`ackReaction`**: emoji name (e.g. `"eyes"`) reacted to incoming messages as an ack. Set to `""` to disable.

---

## Persona Files

Place these optional markdown files in `~/.claude/channels/slack/` to define Claude's persona and behaviour. They are loaded at startup and injected into Claude's system context — effective for all conversations through this channel.

| File | Purpose |
|------|---------|
| `SOUL.md` | Personality, tone, core character |
| `AGENT.md` / `AGENTS.md` | Agent behaviour guidelines, task approach |
| `IDENTITY.md` | Identity definition (name, role, background) |
| `USER.md` | Context about the user(s) Claude will interact with |
| `TOOLS.md` | Documentation for available tools or workflows |

**Example `SOUL.md`:**

```markdown
You are Racco, a sharp and pragmatic engineering assistant for the team.
You prefer concise answers, flag problems directly, and never hedge when you have enough information to act.
When investigating bugs, start by asking for logs or error messages before hypothesising.
```

Changes to persona files take effect after restarting the Claude Code session (or running `/mcp reset` in Claude Code).

---

## Inbound Message Format

Messages arrive in Claude's context as:

```xml
<channel source="plugin:slack:slack" channel="C..." ts="1234567890.123456" user="U..." user_id="U..." thread_ts="...">
message text here
</channel>
```

File attachments appear as `attachment_N_url`, `attachment_N_name`, `attachment_N_mime` in the meta attributes. Use the `download_attachment` tool to fetch them.

## Permission Requests

When Claude Code asks for tool-use permission, the request is forwarded to DM users listed in `allowFrom` (when using `allowlist` mode). Reply with:

```
allow <5-char-code>
deny <5-char-code>
```
