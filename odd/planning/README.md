# Implementation Planning

MentorKit preserves the ability to accept a Product Requirements Document and turn it into a repository-aware implementation plan, but a PRD is **optional**.

## Two valid entry paths

### Direct user request

```text
User Request
  ↓
Authorization
  ↓
Codebase Knowledge
  ↓
Plan / Route when justified
  ↓
ODD Feature Document
  ↓
S#/T#
```

### User request + PRD

```text
User Request
  ↓
Optional PRD
  ↓
document-extractor
  ↓
Normalized PRD
  ↓
prd-reader
  ↓
PRD Analysis
  ↓
Codebase Knowledge
  ↓
Implementation Plan
  ↓
ODD Feature Document
  ↓
S#/T#
```

## Supported PRD formats

The extraction layer is format-aware while the planning layer is not.

Supported formats include:

- PDF;
- DOCX;
- DOC;
- ODT.

PDF files that contain only scanned images are detected as requiring OCR and are not silently treated as complete text extraction.

## Artifact locations

For substantial work:

```text
odd/tasks/<feature-name>.md
```

When an explicit or material Implementation Plan is justified:

```text
odd/planning/<feature-name>.md
```

The implementation plan is architectural/design context. The ODD feature document is the authoritative execution state.

## Important distinction

```text
User Request
  = authorized intent

PRD (optional)
  = structured product intent

Implementation Plan
  = repository-aware solution route

ODD Feature Document
  = authorized execution state

Todo / agent scratchpad
  = ephemeral execution state
```

Never use the implementation plan as implicit authorization.

## Key rule

> PRD is an accelerator and source of structured requirements, not a gate to development.
