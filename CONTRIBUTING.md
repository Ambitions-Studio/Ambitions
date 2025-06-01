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

## 🔀 Creating a Pull Request

1. **Fork the repository**
2. Create a new branch: `git checkout -b feat/your-feature-name`
3. Make your changes
4. Test your code locally (and ideally with multiple players)
5. Commit using clear messages:
   ```sh
   git commit -m "feat(core): added player inventory sync on logout"
   ```
6. Push: `git push origin feat/your-feature-name`
7. Open a Pull Request against the `dev` branch

Your PR will be reviewed by a maintainer. You may be asked to make changes before it's accepted.

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
