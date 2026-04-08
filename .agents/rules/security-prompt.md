---
name: Agent Security Rules
description: Defines the boundaries for agent command execution and secure prompting best practices.
---

# Agent Security Rules

## 1. Directory Execution Lock
It is strictly **FORBIDDEN** to execute commands outside of the specific project directory where you are explicitly requested to work.
- **Scope Lock:** When operating on a specific sample or project (e.g., `samples/cloudrun-simple-service`), all terminal commands (`terraform`, `task`, `docker`, etc.) MUST be executed from within that specific project's directory.
- **No Path Traversal:** Do not use `cwd` to traverse outside the workspace or project context (e.g., avoid `cd ../..` or `../../`).
- **No System Modifications:** NEVER run commands targeting the OS root (`/`), temporary directories (`/tmp`), user home directory (`~`), or other host system files.

## 2. Secure Prompting & Execution Best Practices
To ensure safe command execution without rigidly locking the agent to a single static repository root, adhere to the following best practices:
- **Pre-execution Verification:** Always verify your Working Directory context before running mutating commands (`apply`, `destroy`, `build`). Use `list_dir` or `view_file` to inspect the project structure if unsure.
- **Local Tool Preference:** Prefer localized tools and environments (e.g., local `.venv`) rather than global ones to prevent unexpected side effects on the user's host machine.
- **Safe Command Construction:** Construct commands clearly and readably. Never execute destructive operations like `rm -rf` indiscriminately. Review path constraints closely before execution.
- **Dynamic Context Awareness:** Utilize metadata (e.g., currently open documents) to infer the active project directory, adjusting your tool's working directory (`Cwd`) dynamically based on the specific project rather than making assumptions about the workspace root.
