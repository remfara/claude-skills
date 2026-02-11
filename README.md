# Claude Skills

Collection of Claude Code skills for server automation.

## Skills

| Skill | Description |
|-------|-------------|
| [n8n-update](./n8n-update/) | Safe n8n update on Docker — backup DB & volume, pull stable, recreate, verify |

## Structure

Each skill follows a consistent layout:

```
skill-name/
├── SKILL.md       # Main skill file for Claude Code
├── install.sh     # One-line installer
└── update.sh      # Script (if applicable)
```

## Usage

Install a skill into your Claude Code project:

```bash
# n8n-update
curl -fsSL https://raw.githubusercontent.com/remfara/claude-skills/main/n8n-update/install.sh | bash
```

Or manually copy the `SKILL.md` file into your project's `.claude/skills/` directory.

## Related

- [3x-ui-skill](https://github.com/AndyShaman/3x-ui-skill) — VPN server deployment automation (VLESS Reality/TLS)
