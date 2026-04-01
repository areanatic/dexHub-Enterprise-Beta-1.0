# Contributing to DexHub

Thank you for your interest in contributing to DexHub!

## How to Contribute

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/my-feature`)
3. Make your changes
4. Run validation: `bash .dexCore/_dev/tools/validate.sh`
5. Commit with clear message
6. Open a Pull Request

## What You Can Contribute

- **New Agents** — Add to `.dexCore/dxm/agents/` + create `.github/agents/{name}.agent.md`
- **New Workflows** — Add to `.dexCore/dxm/workflows/` + register in workflow-manifest.csv
- **New Skills** — Add to `.github/skills/{name}/SKILL.md`
- **Bug Fixes** — Run validate.sh, fix what fails
- **Documentation** — Improve READMEs, add examples

## Guidelines

- Follow existing code patterns and file structure
- Agent definitions are markdown — keep them clean and structured
- All output files go to `myDex/drafts/`, never to the project root (Guardrail G3)
- Show diffs before overwriting files (Guardrail G2)
- Test your changes with `validate.sh` before submitting

## Contributor License Agreement

By submitting a pull request, you agree that:

1. Your contribution is your original work
2. You grant the project maintainer (Arash Zamani) a perpetual, worldwide,
   non-exclusive, royalty-free license to use, modify, and relicense your
   contribution under any open-source license
3. You understand that this enables the project to evolve its licensing
   in the future while remaining open-source

## Code of Conduct

Be respectful, constructive, and collaborative. We're building something cool together.

## Questions?

Open an issue or start a discussion.
