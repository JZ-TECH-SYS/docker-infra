# Napkin Runbook

## Curation Rules
- Re-prioritize on every read.
- Keep recurring, high-value notes only.
- Max 10 items per category.
- Each item includes date + "Do instead".

## Execution & Validation (Highest Priority)
1. **[2026-03-14] Validate only the surface you changed first**
   Do instead: run the smallest relevant command inside `api/`, `web/`, `app/`, or the touched package before widening scope.
2. **[2026-03-14] Preserve the repository structure**
   Do instead: extend the current controllers, handlers, models, services, pages, and components before inventing new layers.
3. **[2026-03-14] Prefer minimal diffs over rewrites**
   Do instead: solve the concrete task with the smallest change that stays maintainable.

## Shell & Command Reliability
1. **[2026-03-14] Inspect manifests before changing tooling**
   Do instead: check `package.json`, `composer.json`, `docker-compose.yml`, and existing scripts before choosing commands.
2. **[2026-03-14] Run commands from the correct package root**
   Do instead: execute `npm`, `composer`, and test commands in the package that owns the change.

## Domain Behavior Guardrails
1. **[2026-03-14] Keep API and frontend contracts stable**
   Do instead: preserve response shapes, route conventions, and existing component contracts unless the task explicitly changes them.
2. **[2026-03-14] Reuse project patterns**
   Do instead: match naming, validation flow, error handling, and UI conventions already present in the repo.

## User Directives
1. **[2026-03-14] Keep solutions pragmatic and simple**
   Do instead: prefer straightforward implementations that solve the problem and remain extensible.
