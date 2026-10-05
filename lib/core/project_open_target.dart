/// What "open this project" means beyond just its folder — round-36 §3's
/// own link table. Every link that lands on a project (the overview, the
/// Tasks view) builds one of these instead of passing a bare folder
/// string, so the destination screen can open the right area, open "Not
/// in an area" instead, and briefly highlight the task that was actually
/// tapped. A caller that only has a folder — a plain project-row tap —
/// leaves every optional field at its default, landing wherever the
/// project screen already opens by default (round-36 §2 a: Plan).
library;

typedef ProjectOpenTarget = ({
  String folder,
  String? areaSourceFile,
  bool openHome,
  String? highlightRawLine,
  bool openLog,
  bool openStrategy,
});

ProjectOpenTarget openTarget(
  String folder, {
  String? areaSourceFile,
  bool openHome = false,
  String? highlightRawLine,
  bool openLog = false,
  bool openStrategy = false,
}) => (
  folder: folder,
  areaSourceFile: areaSourceFile,
  openHome: openHome,
  highlightRawLine: highlightRawLine,
  openLog: openLog,
  openStrategy: openStrategy,
);
