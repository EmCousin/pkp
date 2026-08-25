# Repository skills

This directory is the canonical source for AI skills in this repository. Each skill follows the [Agent Skills specification](https://agentskills.io/specification) and contains a `SKILL.md` with portable `name` and `description` frontmatter.

## Layout

```text
.agents/skills/
  rails-hotwire/
    SKILL.md
    references/
  progressive-enhancement/
    SKILL.md
    references/
  human-writing-style/
    SKILL.md
    references/
```

Use one skill for one coherent concern. Keep activation rules and non-negotiable instructions in `SKILL.md`; move longer rationale, examples, and checklists into `references/` so agents can load them only when needed.

## Discovery

- Codex and OpenCode discover `.agents/skills/` directly.
- Claude Code discovers the same directory through `.claude/skills`.
- Other harnesses can use the registry in the root `AGENTS.md` and read the same `SKILL.md` files.

Do not duplicate skill bodies in harness-specific directories. If another harness needs a dedicated location, add a link or a minimal loader that points back here.

## Adding a skill

1. Create `.agents/skills/<skill-name>/SKILL.md`.
2. Use a lowercase, hyphen-separated name that matches its directory.
3. Write a concrete description that says what the skill does and when it must load.
4. Keep the main file concise and put optional detail in `references/`.
5. Register the trigger in `AGENTS.md` when the skill expresses a repository-wide convention.
6. Validate the frontmatter and test that supported harnesses list the skill.
