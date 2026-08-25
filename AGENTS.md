# Repository instructions

## Skills

Repository skills use the open Agent Skills format and live in `.agents/skills/`.
Load the relevant `SKILL.md` before changing code or prose:

- `rails-hotwire`: load for Rails models, controllers, jobs, routes, views, helpers, mailers, migrations, and application architecture.
- `progressive-enhancement`: also load for any browser-facing behavior, ERB, forms, links, Turbo, Stimulus, or JavaScript.
- `human-writing-style`: load for prose intended for people, including documentation, product copy, emails, review comments, and pull request text.

The no-JavaScript path is a repository invariant. Every user-facing feature must remain functional when JavaScript is unavailable. Hotwire and Stimulus may improve speed, feedback, and convenience, but must not own the only working path.

## Project baseline

- This is a Rails 8.1 application using server-rendered ERB, Turbo, and Stimulus.
- Prefer the Rails framework and its defaults over additional layers, client-side frameworks, or custom infrastructure.
- Follow existing application patterns and `.rubocop.yml`.
- Use RSpec for tests. Add request or model coverage for behavior and system coverage for meaningful browser interactions.

## Skill maintenance

`.agents/skills/` is the canonical source. Do not maintain separate copies for individual AI tools. Harness-specific paths should point to this directory, and `AGENTS.md` should remain a short registry rather than duplicating full skill instructions.
