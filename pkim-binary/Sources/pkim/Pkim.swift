import ArgumentParser

/// Root command for the `pkim` CLI.
///
/// Contract is defined in `docs/design/23-swift-pkim-binary.md`. Every
/// subcommand is a thin wrapper that produces a single JSON envelope on
/// stdout and exits with a code from `PkimExit`.
@main
struct Pkim: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "pkim",
        abstract: "PKIM CLI — atomic primitives for the DEVONthink-centric knowledge system.",
        discussion: """
            Skills compose these verbs to do work. The binary owns mechanism only;
            policy lives in skill markdown. See docs/design/22 and 23.
            """,
        subcommands: [
            MintId.self,
            Resolve.self,
            Get.self,
            Aliases.self,
            Tags.self,
            FilePath.self,
            Body.self,
            SetMetadata.self,
            SetTags.self,
            SetName.self,
            Move.self,
            CreateGroup.self,
            CreateNote.self,
            SetBody.self,
            ListCommand.self,
            Search.self,
            ExtractText.self,
            ProbeCapabilities.self,
            HealthCheck.self,
            MirrorOf.self,
            SetupDatabase.self,
            VerifyDatabase.self,
            VerifySmartGroups.self,
            FixSmartGroups.self,
            InstallTemplates.self,
        ]
    )
}
