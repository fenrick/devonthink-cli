# Evidence Policy By Library

## Purpose

This appendix makes library policy explicit so topology becomes operational rather than descriptive.

## `PKIM-Knowledge`

- import-first or index-allowed: import only
- mobile required: yes for notes
- external editability required: no
- work-policy restrictions: keep canonical note state here
- move automation allowed: yes, within approved native note policy

## `PKIM-Evidence-Personal`

- import-first or index-allowed: import first; index allowed only when ALL of the following are true: (a) another application must edit the file in place, (b) the folder has operational meaning outside DEVONthink, (c) the content is NOT mobile-critical
- mobile required: yes for selected source classes
- external editability required: only for live working folders
- work-policy restrictions: personal policy only
- move automation allowed: yes for imported items; indexed by approval only

## `PKIM-Evidence-Work`

- import-first or index-allowed: index allowed where external collaboration requires it
- mobile required: usually no unless explicitly chosen
- external editability required: often yes
- work-policy restrictions: follow work-policy restrictions on import and export
- move automation allowed: imported yes with approval; indexed no by default

## `PKIM-Evidence-Server`

- import-first or index-allowed: import preferred; index allowed only when ALL of the following are true: (a) the mount has been continuously available for at least 30 days without manual reconnection, (b) the host system policy permits DEVONthink to hold a reference to the mount, (c) the folder is not a cloud-sync placeholder path
- mobile required: no by default
- external editability required: depends on share semantics
- work-policy restrictions: depends on host system policy
- move automation allowed: only after mount and path policy validation

## `PKIM-Pilot`

- import-first or index-allowed: either, as needed for testing
- mobile required: no
- external editability required: test-only
- work-policy restrictions: none beyond safe local testing
- move automation allowed: yes, because it exists to validate mutation behaviour

