# 🤝 Contributing to Ambitions

We welcome and appreciate all contributions to **Ambitions**, whether it's bug reports, feature requests, or direct code improvements. This document outlines the best practices and rules to follow to ensure high quality and consistency across the project.

---

## 🧭 Our Philosophy

- **Open Source First** – Everything in Ambitions is public, transparent and meant to be shared.
- **Quality over Quantity** – We prefer small, clean and documented contributions.
- **Performance & Security** – Your code must never sacrifice runtime efficiency or expose vulnerabilities.

---

## 🚧 Rules Before You Start

### ✅ Do:
- Follow **Lua 5.4** standards (constants, annotations, memory scope)
- Use our naming conventions (`camelCase`, `PascalCase`, `SNAKE_CASE` for constants)
- Keep functions **pure**, **modular**, and **reusable**
- Use a **maximum of 3 nested conditionals**
- Document every function with annotations
- Write commit messages that are **clear and descriptive** (see below)

### ❌ Don’t:
- Submit code with console prints, test leftovers, or debug spam
- Modify multiple features in a single PR
- Push directly to `main`
- Use XAMPP-specific code (Ambitions is **MariaDB only**)

---

## 📦 Local Setup

```bash
git clone https://github.com/Ambitions-Studio/Ambitions.git
cd Ambitions
# Setup MariaDB + HeidiSQL
# Configure your server.cfg to use Ambitions as base
```

We strongly recommend testing with the latest **FiveM artifacts (12208+)**.

---

## 🔀 Git Workflow & Branch Strategy

### Our Two-Tier Branch System

- **`main`** – Production-ready code. 100% clean, tested, and error-free.
- **`dev`** – Testing & quality assurance. Last barrier before production.

### Contribution Flow

```
Contributor:  main → feature/xxx → PR to dev
Maintainer:   dev (review/test) → PR to main
```

### Step-by-Step Guide

1. **Clone the repository**
   ```bash
   git clone https://github.com/Ambitions-Studio/Ambitions.git
   cd Ambitions
   ```

2. **Create a feature branch from `main`**
   ```bash
   git checkout main
   git pull origin main
   git checkout -b feature/your-feature-name
   ```

   Branch naming conventions:
   - `feature/` – New features (e.g., `feature/inventory-system`)
   - `fix/` – Bug fixes (e.g., `fix/character-spawn-error`)
   - `refactor/` – Code refactoring (e.g., `refactor/permission-cache`)
   - `docs/` – Documentation changes (e.g., `docs/callback-examples`)

3. **Make your changes**
   - Follow all code standards outlined in this document
   - Test locally with multiple scenarios
   - Ensure no console prints, debug code, or test data remains

4. **Commit with clear messages**
   ```bash
   git add .
   git commit -m "TYPE - Clear description of what changed"
   ```

   Commit message types:
   - `ADD` – Adding new functionality
   - `FIX` – Fixing bugs or errors
   - `REMOVE` – Removing code or files
   - `REFACTOR` – Code restructuring without behavior change
   - `UPDATE` – Updating existing features
   - `DOCS` – Documentation changes

5. **Push your branch**
   ```bash
   git push origin feature/your-feature-name
   ```

6. **Open a Pull Request targeting `dev`**
   - Go to GitHub and open a PR
   - **Target branch: `dev`** (NOT `main`)
   - Fill out the PR template completely
   - Link related issues if applicable

7. **Review & Testing Phase**
   - A maintainer will test your changes in `dev`
   - Code quality, standards, and functionality will be reviewed
   - You may be asked to make changes

8. **Merge to `main`**
   - Once approved in `dev`, maintainers will create a PR from `dev` → `main`
   - Only 100% validated code reaches `main`

### Important Rules

- ❌ **Never push directly to `main` or `dev`**
- ❌ **Never create PRs targeting `main`** (only maintainers do this)
- ✅ **Always branch from `main`** (the stable base)
- ✅ **Always target `dev`** with your PRs
- ✅ **Keep PRs focused** – One feature/fix per PR

---

## 🧪 Suggested Tools

- **EditorConfig**: already included
- **Luacheck**: for linting Lua code
- **HeidiSQL**: for DB testing
- **FiveM FXServer Console**: for logs/debug

---

## 🐞 Reporting Issues

If you encounter a bug:
- Ensure it’s not already reported
- Create an issue with a **clear title** and **step-by-step reproduction**
- Add logs or screenshots if possible

Use the provided **bug report template** when opening issues.

---

## 📜 Licensing

By contributing, you agree that your code will be licensed under the **LGPL 3.0**, the same license as the core project.

---

Thank you for helping make Ambitions better for the entire FiveM community! 💙
