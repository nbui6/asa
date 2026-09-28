// Round 39 cp6 §3 — the skills/agents catalog, read against the real repo
// itself (this file's own `kit\`, `.claude\`, `dist\`) — the same
// contract `kit\sync-skills.ps1 -Check` already proves in PowerShell.

import 'dart:io';

import 'package:asa/core/skills_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final repoRoot = Directory.current.path;

  group('asaRepoPathFrom', () {
    test('finds the real asa repo when it really sits next to a sibling '
        '"projects" folder', () {
      // repoRoot is this very repo — its own parent is workspace\, and
      // asaRepoPathFrom should find repoRoot itself as the "asa" sibling
      // of any folder that also lives directly under workspace\.
      final workspaceRoot = Directory(repoRoot).parent.path;
      final anySiblingFolder =
          '$workspaceRoot${Platform.pathSeparator}not-a-real-folder';
      expect(asaRepoPathFrom(anySiblingFolder), repoRoot);
    });

    test(r'null when there is no asa\ sibling at all', () {
      final tempRoot = Directory.systemTemp
          .createTempSync('asa-skills-catalog-test-')
          .path;
      expect(asaRepoPathFrom(tempRoot), isNull);
    });
  });

  group('readSkillsCatalog — against the real repo', () {
    test('finds the real asa skill, in the repo, described', () async {
      final skills = await readSkillsCatalog(repoRoot);
      expect(skills, isNotEmpty);
      final asaSkill = skills.where((s) => s.name == 'asa');
      expect(asaSkill, hasLength(1));
      expect(asaSkill.single.description, contains('Instruction for AI'));
      expect(asaSkill.single.inRepo, isTrue);
    });

    test('every real skill has a non-empty description', () async {
      final skills = await readSkillsCatalog(repoRoot);
      for (final skill in skills) {
        expect(skill.description, isNotEmpty, reason: skill.name);
      }
    });

    test(r'no kit\skills at all reads as no skills, not an error', () async {
      final tempRoot = Directory.systemTemp
          .createTempSync('asa-skills-catalog-test-')
          .path;
      final skills = await readSkillsCatalog(tempRoot);
      expect(skills, isEmpty);
    });
  });

  group('readAgentsCatalog — against the real repo', () {
    test('finds the real reviewer agent, described', () async {
      final agents = await readAgentsCatalog(repoRoot);
      expect(agents, isNotEmpty);
      final reviewer = agents.where((a) => a.name == 'reviewer');
      expect(reviewer, hasLength(1));
      expect(reviewer.single.description, contains('Code review'));
    });
  });
}
