/// Round 39 cp6 §3 — every skill and agent in the kit, for the
/// Instruction for AI screen's *Skills & agents* part. Pure Dart, no
/// Flutter import.
library;

import 'dart:io';

/// One skill or agent, read from its own `SKILL.md`/`<name>.md`
/// frontmatter.
class SkillInfo {
  const SkillInfo({
    required this.name,
    required this.description,
    required this.inRepo,
    this.lastPackaged,
  });

  final String name;
  final String description;

  /// Whether `.claude\skills\<name>\SKILL.md` exists and matches
  /// `kit\skills\<name>\SKILL.md` byte for byte — the same comparison
  /// `kit\sync-skills.ps1 -Check` already makes, read here instead of
  /// shelled out to.
  final bool inRepo;

  /// `dist\skills\<name>.zip`'s own modification time — when it was last
  /// packaged for uploading to an account. Null when no zip exists yet.
  final DateTime? lastPackaged;
}

class AgentInfo {
  const AgentInfo({required this.name, required this.description});

  final String name;
  final String description;
}

/// `%USERPROFILE%\workspace\asa\`, derived from the projects folder as its
/// fixed sibling (rule 17's own workspace shape) — never guessed from
/// `Platform.script`, which points at the Flutter engine's own binary,
/// not this repo. Null when [projectsRoot] doesn't look like it sits
/// directly under a `workspace\` folder at all.
String? asaRepoPathFrom(String projectsRoot) {
  final parent = Directory(projectsRoot).parent;
  final candidate = Directory('${parent.path}${Platform.pathSeparator}asa');
  if (!candidate.existsSync()) return null;
  return candidate.path;
}

Map<String, String> _readFrontmatter(File file) {
  final fields = <String, String>{};
  if (!file.existsSync()) return fields;
  final lines = file.readAsStringSync().split('\n');
  if (lines.isEmpty || lines.first.trim() != '---') return fields;
  for (var i = 1; i < lines.length; i++) {
    if (lines[i].trim() == '---') break;
    final colon = lines[i].indexOf(':');
    if (colon == -1) continue;
    final key = lines[i].substring(0, colon).trim();
    final value = lines[i].substring(colon + 1).trim();
    if (key.isNotEmpty) fields[key] = value;
  }
  return fields;
}

/// Every skill in `kit\skills\`, alphabetical — the source of truth
/// itself, whether or not the repo's own installed copy currently
/// matches it.
Future<List<SkillInfo>> readSkillsCatalog(String asaRepoPath) async {
  final sep = Platform.pathSeparator;
  final skillsDir = Directory('$asaRepoPath${sep}kit${sep}skills');
  if (!skillsDir.existsSync()) return const [];

  final names =
      skillsDir
          .listSync()
          .whereType<Directory>()
          .map((d) => d.path.split(RegExp(r'[\\/]')).last)
          .toList()
        ..sort();

  final skills = <SkillInfo>[];
  for (final name in names) {
    final sourceFile = File('${skillsDir.path}$sep$name${sep}SKILL.md');
    if (!sourceFile.existsSync()) continue;
    final fields = _readFrontmatter(sourceFile);

    final installedFile = File(
      '$asaRepoPath$sep.claude${sep}skills$sep$name${sep}SKILL.md',
    );
    final inRepo =
        installedFile.existsSync() &&
        installedFile.readAsStringSync() == sourceFile.readAsStringSync();

    final zipFile = File('$asaRepoPath${sep}dist${sep}skills$sep$name.zip');
    final lastPackaged = zipFile.existsSync()
        ? zipFile.lastModifiedSync()
        : null;

    skills.add(
      SkillInfo(
        name: name,
        description: fields['description'] ?? '',
        inRepo: inRepo,
        lastPackaged: lastPackaged,
      ),
    );
  }
  return skills;
}

/// Every agent in `kit\agents\`, alphabetical.
Future<List<AgentInfo>> readAgentsCatalog(String asaRepoPath) async {
  final sep = Platform.pathSeparator;
  final agentsDir = Directory('$asaRepoPath${sep}kit${sep}agents');
  if (!agentsDir.existsSync()) return const [];

  final files =
      agentsDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.md'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  final agents = <AgentInfo>[];
  for (final file in files) {
    final fields = _readFrontmatter(file);
    final name =
        fields['name'] ??
        file.path.split(RegExp(r'[\\/]')).last.replaceAll('.md', '');
    agents.add(AgentInfo(name: name, description: fields['description'] ?? ''));
  }
  return agents;
}
