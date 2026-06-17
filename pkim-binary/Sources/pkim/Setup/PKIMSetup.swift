import Foundation

/// Canonical PKIM-stack configuration: database names, group trees,
/// smart-group definitions, and template content.
///
/// Centralised here because the five `setup-*` and `verify-*` verbs
/// all need to agree on the same canonical shape. Ports of the
/// AppleScript helpers (`scripts/setup-database-groups.applescript`,
/// `scripts/verify-database-setup.applescript`,
/// `scripts/verify-smart-groups.applescript`,
/// `scripts/fix-smart-group-predicates.applescript`,
/// `scripts/install-note-templates.applescript`).
///
/// This is "policy-laden" by the doc-22 layer rules — the AppleScripts
/// were the same. Future variation (different group shape, different
/// smart-group set) belongs in a config file the verb reads at runtime;
/// for the canonical PKIM bootstrap, hardcoded here is fine.
enum PKIMSetup {

    static let knowledgeDB = "PKIM-Knowledge"
    static let evidencePersonalDB = "PKIM-Evidence-Personal"
    static let evidenceWorkDB = "PKIM-Evidence-Work"
    static let evidenceServerDB = "PKIM-Evidence-Server"
    static let pilotDB = "PKIM-Pilot"

    /// Group tree for the knowledge database.
    static let knowledgeGroups: [String] = [
        "/Inbox",
        "/Notes",
        "/Notes/Literature",
        "/Notes/Synthesis",
        "/Notes/Relations",
        "/Notes/Topics",
        "/Notes/Projects",
        "/Templates",
        "/Operations",
        "/Archive",
    ]

    /// Group tree for evidence-style databases (personal/work/server/pilot).
    static let evidenceGroups: [String] = [
        "/Inbox",
        "/Sources",
        "/Sources/Imported",
        "/Sources/Indexed",
        "/Captures",
        "/Captures/Web",
        "/Captures/Bookmarks",
        "/Captures/Scans",
        "/Working",
        "/Review",
        "/Archive",
    ]

    /// Database-shape classification. Knowledge has the literature /
    /// synthesis / relations tree; evidence DBs have the
    /// sources / captures / working tree.
    enum Shape: String, Sendable, CaseIterable {
        case knowledge
        case evidence

        /// Group list for this shape.
        var groups: [String] {
            switch self {
            case .knowledge: return PKIMSetup.knowledgeGroups
            case .evidence: return PKIMSetup.evidenceGroups
            }
        }

        /// Map a canonical database name to its shape. Returns `nil`
        /// for unknown databases.
        static func of(database: String) -> Shape? {
            switch database {
            case PKIMSetup.knowledgeDB: return .knowledge
            case PKIMSetup.evidencePersonalDB,
                 PKIMSetup.evidenceWorkDB,
                 PKIMSetup.evidenceServerDB,
                 PKIMSetup.pilotDB:
                return .evidence
            default: return nil
            }
        }
    }

    /// One canonical smart group: name, predicate, and the databases
    /// it should exist in.
    struct SmartGroupSpec: Sendable, Equatable {
        let name: String
        /// Optional text predicate. `nil` for "is empty / not empty"
        /// smart groups that the GUI created and we don't rebuild —
        /// `fix-smart-groups` skips those, `verify-smart-groups`
        /// still checks them.
        let predicate: String?
        let databases: [String]
    }

    /// All canonical PKIM smart groups (verify list, 10 entries).
    static let smartGroups: [SmartGroupSpec] = [
        .init(name: "Needs Profile",
              predicate: nil,
              databases: [knowledgeDB, evidencePersonalDB, evidenceWorkDB, evidenceServerDB, pilotDB]),
        .init(name: "Needs OCR",
              predicate: nil,
              databases: [evidencePersonalDB, evidenceWorkDB, evidenceServerDB, pilotDB]),
        .init(name: "Needs Knowledge Note",
              predicate: nil,
              databases: [evidencePersonalDB, evidenceWorkDB, evidenceServerDB, pilotDB]),
        .init(name: "Needs Relation Note",
              predicate: nil,
              databases: [knowledgeDB]),
        .init(name: "Needs Filing",
              predicate: "mdreview_state==\"approved\"",
              databases: [knowledgeDB, evidencePersonalDB, evidenceWorkDB, evidenceServerDB, pilotDB]),
        .init(name: "Indexed Risk",
              predicate: nil,
              databases: [evidencePersonalDB, evidenceWorkDB, evidenceServerDB, pilotDB]),
        .init(name: "Mirror Drift",
              predicate: "mdmirror_state==\"stale\"",
              databases: [knowledgeDB]),
        .init(name: "Automation Error",
              predicate: "mdautomation_last_run_state==\"error\"",
              databases: [knowledgeDB, evidencePersonalDB, evidenceWorkDB, evidenceServerDB, pilotDB]),
        .init(name: "Needs Human Review",
              predicate: "mdreview_state==\"needs-human\"",
              databases: [knowledgeDB, evidencePersonalDB, evidenceWorkDB, evidenceServerDB, pilotDB]),
        .init(name: "Ready for Mirror",
              predicate: "mdreview_state==\"approved\"&&mdknowledgestatus==\"active\"",
              databases: [knowledgeDB]),
    ]

    /// Only the smart groups `fix-smart-groups` rewrites (those that
    /// have a text predicate; the "is empty" GUI-built ones are left
    /// alone because the GUI binary predicates already work).
    static var rewritableSmartGroups: [SmartGroupSpec] {
        smartGroups.filter { $0.predicate != nil }
    }

    /// Canonical PKIM-Knowledge templates installed under /Templates/.
    struct TemplateSpec: Sendable, Equatable {
        let name: String
        let body: String
    }

    static let templates: [TemplateSpec] = [
        .init(name: "Knowledge Note", body: knowledgeNoteTemplate),
        .init(name: "Relation Note", body: relationNoteTemplate),
        .init(name: "Topic Note", body: topicNoteTemplate),
        .init(name: "Project Note", body: projectNoteTemplate),
    ]

    static let templatesGroup = "/Templates"
}

// MARK: - Template bodies (verbatim from install-note-templates.applescript)

private let knowledgeNoteTemplate = """
Title: {{Title}}
PKIM_ID: KN-YYYYMMDD-NNNN
DocRole: knowledge
NoteType: {{literature | synthesis | topic | project | decision | workflow}}
Review_State: inbox
Aliases: {{title alias}}; KN-YYYYMMDD-NNNN
PrimaryTopic: {{topic}}

# {{Title}}

## Summary

{{One paragraph overview of the note's purpose and main claim.}}

## Key points

-

## Evidence links

- [{{Source title}}](x-devonthink-item://{{SOURCE-UUID}})

## Related notes

- [[{{Related note title}}]]
"""

private let relationNoteTemplate = """
Title: Relation — {{source title}} {{type}} {{target title}}
PKIM_ID: RL-YYYYMMDD-NNNN
DocRole: relation
Relation_Type: {{supports | contradicts | extends | summarizes | references | exemplifies | precedes | supersedes}}
Source_Item: x-devonthink-item://{{SOURCE-UUID}}
Target_Item: x-devonthink-item://{{TARGET-UUID}}
Review_State: inbox
RelationStatus: proposed

# Why this relation exists

{{One or more sentences explaining why this edge is meaningful. Mandatory — a relation note with no rationale is invalid.}}

## Interpretation

{{Optional: further context, caveats, or conditions on this relation.}}
"""

private let topicNoteTemplate = """
Title: Topic — {{Topic name}}
PKIM_ID: KN-YYYYMMDD-NNNN
DocRole: knowledge
NoteType: topic
Review_State: inbox
PrimaryTopic: {{topic name}}

# {{Topic name}}

## What this topic means

{{Define the topic. Be specific about what belongs here.}}

## What it excludes

{{Define the boundary. What does NOT belong here?}}

## Key notes

- [[{{Related knowledge note}}]]

## Key evidence

- [{{Evidence title}}](x-devonthink-item://{{UUID}})

## Open questions

-
"""

private let projectNoteTemplate = """
Title: Project — {{Project name}}
PKIM_ID: KN-YYYYMMDD-NNNN
DocRole: knowledge
NoteType: project
Review_State: inbox
PrimaryTopic: {{project name}}

# {{Project name}}

## Goal

{{One sentence: what does this project accomplish?}}

## Context

{{Why does this exist? What problem does it solve?}}

## Notes

- [[{{Related note}}]]

## Evidence

- [{{Evidence title}}](x-devonthink-item://{{UUID}})

## Status

{{Current status, next action, blockers.}}
"""
