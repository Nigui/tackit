<!-- Keep PRs focused; one logical change per PR. -->

## What & why

<!-- What does this change, and why? Link any issue: Closes #123 -->

## User-visible change

<!-- What will a user notice? "None" is a valid answer for internal work. -->

## How I verified

<!-- Commands run / manual steps. -->
- [ ] `swift build`
- [ ] `swift test`
- [ ] `cd editor && pnpm test`
- [ ] Ran `./scripts/run.sh` and exercised the change

## Checklist

- [ ] Conventional Commit title (`feat:`, `fix:`, `docs:`, …)
- [ ] No unilateral product/UX decisions (see `CLAUDE.md`); owner signed off on anything user-facing
- [ ] Any new user action is reachable by keyboard (hotkey-first)
