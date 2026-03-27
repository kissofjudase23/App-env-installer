# Copilot Commit Message Instructions

Based on [Conventional Commits](https://www.conventionalcommits.org/).

### Format

```
<type>(<scope>): <subject>

<body>

Refs: #<taskID>
```
- **type**: Required, the commit type
- **scope**: Optional, the affected module or component
- **subject**: Required, a short description (max 50 characters)
- **body**: Optional, detailed explanation
- **footer**: Optional, include `Refs: #<taskID>` to link the related task

### Types

| Type       | Description                                                  |
| ---------- | ------------------------------------------------------------ |
| `feat`     | A new feature                                                |
| `fix`      | A bug fix                                                    |
| `docs`     | Documentation only changes                                   |
| `style`    | Formatting changes (no logic impact)                         |
| `refactor` | Code change that neither fixes a bug nor adds a feature      |
| `perf`     | Performance improvement                                      |
| `test`     | Adding or updating tests                                     |
| `build`    | Build system or external dependency changes (e.g. npm, make) |
| `ci`       | CI configuration changes (e.g. pipeline, GitHub Actions)     |
| `chore`    | Other changes that don't affect src or test                  |
| `revert`   | Reverts a previous commit                                    |

### Rules

- Use **imperative mood** in subject: `add` not `added` or `adds`
- Subject starts with **lowercase**, **no period** at the end
- Use lowercase for **type** and **scope**
- Wrap lines at **72 characters** (body / footer)
- For Breaking Changes, add `BREAKING CHANGE:` in footer or append `!` after type
- Always include `Refs: #<taskID>` as footer to link the related task

### Examples
```text
ci(pipeline): add staging deployment step

Refs: #123456
```

```text
chore(k8s): increase api replicas to 3

Refs: #123457
```

```text
fix(k8s): correct liveness probe path

Refs: #123458
```

```text
feat(k8s): add redis deployment and service
Refs: #123459
```

```text
refactor(k8s): consolidate base kustomization overlays

Refs: #123460
```

```
chore(k8s): update image tag to v2.3.1

Refs: #123461
```


```
ci(k8s): add canary deployment stage

Refs: #123462
```

```
feat(payment)!: change payment API response format

BREAKING CHANGE: response field `amount` renamed to `totalAmount`
Refs: #123463
```


## Bad Examples
❌ `update` → Too vague
❌ `feat: add api and update service` → Doing too many things
