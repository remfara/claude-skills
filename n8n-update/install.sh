#!/bin/bash
set -e

SKILL_DIR=".claude/skills"
SKILL_URL="https://raw.githubusercontent.com/remfara/claude-skills/main/n8n-update/SKILL.md"

echo "Installing n8n-update skill..."

mkdir -p "$SKILL_DIR"
curl -fsSL "$SKILL_URL" -o "$SKILL_DIR/n8n-update.md"

echo "Skill installed to $SKILL_DIR/n8n-update.md"
echo "Claude Code will now use this skill when updating n8n."
