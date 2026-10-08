# PRD → Implementation Planning

MentorKit preserves the ability to accept a Product Requirements Document and turn it into an implementation plan grounded in the target repository.

## Pipeline

```
User PRD
  ↓
document-extractor
  ↓
Normalized PRD
  ↓
prd-reader
  ↓
PRD Analysis
  ↓
codebase-conformist + codebase-graph
  ↓
Architecture / Policies / Existing Patterns
  ↓
Implementation Plan
  ↓
spec-writer
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

For substantial PRD-driven work:

```
odd/planning/<feature-name>.md
odd/tasks/<feature-name>.md
```

The implementation plan is architectural/design context. The ODD feature document is the authoritative execution state.

## Important distinction

```
PRD
  = user intent

Implementation Plan
  = repository-aware solution route

ODD Feature Document
  = authorized execution plan

Todo / agent scratchpad
  = ephemeral execution state
```

Never use the implementation plan as implicit authorization.
