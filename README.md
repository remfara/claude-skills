# Claude Skills

Collection of Claude Code skills for server automation.

## Skills

| Skill | Description |
|-------|-------------|
| [vpn-vps-deploy](./vpn-vps-deploy/) | Полный деплой VPN-сервера на чистый VPS — hardening ОС (firewall, SSH-ключи, fail2ban, sysctl), установка 3x-ui панели, настройка VLESS Reality/TLS, подключение клиентов через Hiddify |
| [n8n-update](./n8n-update/) | Безопасное обновление n8n в Docker — бэкап БД PostgreSQL и тома, pull stable-образа, пересоздание контейнера, проверка работоспособности, очистка старых бэкапов |

## Structure

Each skill follows a consistent layout:

```
skill-name/
├── SKILL.md       # Main skill file for Claude Code
├── install.sh     # One-line installer
├── references/    # Additional docs (if applicable)
└── *.sh           # Scripts (if applicable)
```

## Usage

Install a skill into your Claude Code project:

```bash
# vpn-vps-deploy
curl -fsSL https://raw.githubusercontent.com/remfara/claude-skills/main/vpn-vps-deploy/install.sh | bash

# n8n-update
curl -fsSL https://raw.githubusercontent.com/remfara/claude-skills/main/n8n-update/install.sh | bash
```

Or manually copy the `SKILL.md` file into your project's `.claude/skills/` directory.
