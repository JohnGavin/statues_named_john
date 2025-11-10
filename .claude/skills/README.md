# Claude Skills for R Development

This folder contains reusable Claude skills for R development with reproducible Nix environments.

## What are Skills?

Skills are composable, portable bundles of instructions and resources that Claude can use across different projects. They help maintain consistency and best practices across your work.

## Available Skills

### 🔧 nix-rix-r-environment

**Purpose**: Set up and work within reproducible R development environments using Nix and the rix R package.

**Use when**:
- Starting new R projects requiring reproducible environments
- Working with R packages needing specific versions
- Setting up CI/CD with Nix
- Executing R code in controlled environments

**Key files**:
- `SKILL.md` - Main skill documentation and examples
- `setup-template.R` - Template for creating default.R files
- `quick-reference.md` - Quick command reference

### 📦 r-package-workflow

**Purpose**: Complete workflow for R package development from issue creation to PR merge using R packages (gert, gh, usethis) instead of CLI commands.

**Use when**:
- Developing R packages with version control
- Following GitHub-based development workflow
- Need to ensure proper testing and documentation
- Want reproducible development logs

**Key files**:
- `SKILL.md` - Complete workflow steps and best practices
- `workflow-template.R` - Annotated script template for development tasks

## How to Use Skills

### In Claude Code

Skills in the `.claude/skills/` folder are automatically available to Claude Code when working in this project directory.

**To invoke a skill:**
1. Simply reference the skill concept in your conversation (e.g., "set up a nix environment for R")
2. Claude will automatically use the skill knowledge
3. Skills are composable - you can use multiple skills together

### In Other Projects

**To reuse these skills:**

1. **Copy the entire folder** to your new project:
   ```bash
   cp -r /path/to/claude_rix/.claude/skills /path/to/new-project/.claude/
   ```

2. **Or copy individual skills**:
   ```bash
   mkdir -p /path/to/new-project/.claude/skills
   cp -r /path/to/claude_rix/.claude/skills/nix-rix-r-environment \
         /path/to/new-project/.claude/skills/
   ```

3. **Commit to git** so team members get them automatically:
   ```bash
   git add .claude/skills/
   git commit -m "Add Claude skills for R development"
   ```

## Skill Structure

Each skill is a folder containing:

```
skill-name/
├── SKILL.md              # Main documentation (required)
├── supporting-files.*    # Templates, examples, etc. (optional)
└── other-resources.*     # Any other helpful files (optional)
```

## Creating New Skills

To create a new skill:

1. Create a new folder in `.claude/skills/`
2. Add a `SKILL.md` file with:
   - Description
   - Purpose (when to use it)
   - How it works
   - Examples and patterns
   - Best practices
3. Add any supporting files (templates, scripts, etc.)
4. Document the skill in this README

## Best Practices

1. **Keep skills focused**: One clear purpose per skill
2. **Include examples**: Show concrete usage patterns
3. **Add templates**: Provide copy-paste starting points
4. **Document dependencies**: Note required tools/packages
5. **Version control**: Commit skills to share with team
6. **Test skills**: Verify they work in new projects

## Skill Compatibility

These skills are designed to work across:
- **Claude Code**: Desktop IDE integration
- **Claude.ai**: Web interface
- **Claude API**: Programmatic access

The same skill files work in all environments!

## Contributing

When adding or updating skills:

1. Follow the existing structure
2. Include clear examples
3. Test in a fresh project
4. Update this README
5. Commit with descriptive message

## Resources

- [Claude Skills Blog Post](https://claude.com/blog/skills)
- [Claude Code Documentation](https://code.claude.com/docs)
- [Example Skills Repository](https://github.com/anthropics/claude-skills)

## Questions?

Skills are a powerful way to codify best practices and share knowledge. Experiment with creating your own!
