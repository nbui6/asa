/// A project, read from the frontmatter of its home note.
///
/// Nothing in `core/` imports Flutter. That is what makes it testable without
/// a running app, and it is the one architecture rule this project has.
library;

class Project {
  const Project({
    required this.name,
    required this.status,
    required this.milestone,
    required this.nextStep,
    required this.repoPath,
    required this.updated,
    required this.sourceFile,
    this.description,
    this.parent,
    this.priority,
    this.deadline,
    this.jira,
    this.links = const [],
  });

  final String name;
  final String status;
  final String milestone;
  final String nextStep;
  final String repoPath;
  final String updated;

  /// The file this was read from, so the UI can say where a value came from.
  final String sourceFile;

  /// The first paragraph of ordinary text in the note, after the `#
  /// Heading` — derived, never typed, so it cannot go stale the way a
  /// frontmatter field would. Null when there is none; the screen shows
  /// nothing rather than a placeholder.
  final String? description;

  // Parsed for v0.1, not shown anywhere yet — every later version that
  // reads groups, priority, deadlines, Jira or links reads these, and none
  // of that work is repeated. Absent is null, never a placeholder string:
  // there is no screen yet for a placeholder to be honest or dishonest on.
  final String? parent;
  final String? priority;
  final String? deadline;
  final String? jira;
  final List<ProjectLink> links;
}

/// One typed, directional relationship to another project — `relates to`,
/// `blocks`, `blocked by`, `shares <aspect> with`, `supersedes`,
/// `superseded by`. Parsed and exposed; shown nowhere in this version.
class ProjectLink {
  const ProjectLink({required this.type, required this.target});

  final String type;
  final String target;
}

/// What happened when we tried to read a project note.
///
/// A result object rather than an exception or a null, because the screen has
/// to be able to show *why* nothing appeared. Silent failure is banned —
/// see PLAYBOOK.md section 7, rule 6.
class ProjectReadResult {
  const ProjectReadResult({this.project, this.error, this.rawFrontmatter = ''});

  final Project? project;
  final String? error;

  /// The frontmatter exactly as it was found, before parsing.
  /// Shown on screen so a human can see what the file really said.
  final String rawFrontmatter;

  bool get isSuccess => project != null;
}

/// Splits `key: value` lines out of a markdown frontmatter block.
///
/// Deliberately hand-written rather than using a YAML package. The frontmatter
/// this reads is a flat list of strings, and a YAML dependency would be a whole
/// specification to understand for something ten lines of code covers.
Map<String, String> parseFrontmatter(String fileContents) {
  final lines = fileContents.split('\n');

  // The block must start on the very first line, or there is no frontmatter.
  if (lines.isEmpty || lines.first.trim() != '---') {
    return {};
  }

  final fields = <String, String>{};

  for (var i = 1; i < lines.length; i++) {
    final line = lines[i];

    if (line.trim() == '---') {
      break; // end of the block
    }

    // An indented line belongs to a nested block, such as `links:`'s list
    // of `- type: target` entries. Those are read by parseLinks; a flat
    // key/value line never starts with whitespace, so this rules nothing
    // real out.
    if (line.isNotEmpty && line.trimLeft() != line) {
      continue;
    }

    final separator = line.indexOf(':');
    if (separator == -1) {
      continue; // not a key/value line — ignore it rather than failing
    }

    final key = line.substring(0, separator).trim();
    final value = stripQuotes(line.substring(separator + 1).trim());

    if (key.isNotEmpty) {
      fields[key] = value;
    }
  }

  return fields;
}

/// Removes one matching pair of surrounding quotes, if present.
String stripQuotes(String value) {
  if (value.length >= 2) {
    final first = value[0];
    final last = value[value.length - 1];
    final isQuoted =
        (first == '"' && last == '"') || (first == "'" && last == "'");
    if (isQuoted) {
      return value.substring(1, value.length - 1);
    }
  }
  return value;
}

/// Returns the frontmatter block as it appears in the file, `---` lines
/// and all. Used only for display.
String extractRawFrontmatter(String fileContents) {
  final lines = fileContents.split('\n');
  if (lines.isEmpty || lines.first.trim() != '---') {
    return '';
  }

  final block = <String>['---'];
  for (var i = 1; i < lines.length; i++) {
    block.add(lines[i]);
    if (lines[i].trim() == '---') {
      break;
    }
  }
  return block.join('\n');
}

/// Builds a Project from already-parsed fields.
///
/// A missing field becomes a visible placeholder rather than an empty string,
/// so a gap in the note looks like a gap instead of looking like nothing.
Project projectFromFields(
  Map<String, String> fields,
  String sourceFile, {
  List<ProjectLink> links = const [],
  String? description,
}) {
  String field(String key) {
    final value = fields[key];
    if (value == null || value.isEmpty) {
      return '(not set)';
    }
    return value;
  }

  // These five are absent-tolerant and not shown anywhere yet, so a gap
  // stays null rather than becoming a placeholder nobody will read.
  String? optionalField(String key) {
    final value = fields[key];
    return (value == null || value.isEmpty) ? null : value;
  }

  return Project(
    name: field('project'),
    status: field('status'),
    milestone: field('milestone'),
    nextStep: field('next-step'),
    // repo-path is allowed to be genuinely empty — a project with no code yet.
    repoPath: fields['repo-path'] ?? '',
    updated: field('updated'),
    sourceFile: sourceFile,
    description: description,
    parent: optionalField('parent'),
    priority: optionalField('priority'),
    deadline: optionalField('deadline'),
    jira: optionalField('jira'),
    links: links,
  );
}

/// Parses the `links:` block out of frontmatter, if there is one.
///
/// `parseFrontmatter` only understands flat `key: value` lines. `links` is
/// the one field that is a nested list —
///
/// ```yaml
/// links:
///   - relates to: example-policy
///   - blocked by: example-integration
/// ```
///
/// — so it gets this small dedicated reader rather than teaching the flat
/// parser about YAML nesting. No real project has used this field yet, so
/// this follows the shape ADR 0008 specifies, unchecked against a real
/// file — the one place in this contract that could not be checked that
/// way.
List<ProjectLink> parseLinks(String fileContents) {
  final raw = extractRawFrontmatter(fileContents);
  if (raw.isEmpty) return [];

  final links = <ProjectLink>[];
  var inLinksBlock = false;

  for (final line in raw.split('\n')) {
    if (RegExp(r'^links:\s*$').hasMatch(line)) {
      inLinksBlock = true;
      continue;
    }

    if (!inLinksBlock) continue;

    final item = RegExp(r'^\s+-\s*(.+)$').firstMatch(line);
    if (item == null) {
      inLinksBlock = false; // dedented back out of the list
      continue;
    }

    final entry = item.group(1)!;
    final separator = entry.indexOf(':');
    if (separator == -1) continue;

    final type = entry.substring(0, separator).trim();
    final target = stripQuotes(entry.substring(separator + 1).trim());
    if (type.isNotEmpty && target.isNotEmpty) {
      links.add(ProjectLink(type: type, target: target));
    }
  }

  return links;
}

/// Derives the one-line description from the note's body — the first
/// paragraph of ordinary text after the `# Heading`.
///
/// "Ordinary" excludes blank lines, a blockquote (`>` — asa.md's own note
/// puts a callout there, and the description is the plain sentence before
/// it, not the callout), and any further heading. Reaching a heading
/// before finding a paragraph means there is no description — this only
/// looks in the note's own introduction, never into a named section
/// further down, so it cannot mistake `## Where I am`'s content for one.
///
/// Multiple lines of one paragraph are joined with a space; a second
/// paragraph, after a blank line, is never reached.
String? deriveDescription(String fileContents) {
  final lines = _bodyLines(fileContents);

  var i = 0;
  while (i < lines.length && !_isH1(lines[i])) {
    i++;
  }
  if (i == lines.length) return null; // no heading at all
  i++; // past the heading line

  while (i < lines.length) {
    final trimmed = lines[i].trim();
    if (trimmed.isEmpty || trimmed.startsWith('>')) {
      i++;
      continue;
    }
    if (trimmed.startsWith('#')) {
      return null; // a section arrived before any ordinary paragraph did
    }
    break;
  }
  if (i == lines.length) return null;

  final paragraph = <String>[];
  while (i < lines.length && lines[i].trim().isNotEmpty) {
    paragraph.add(lines[i].trim());
    i++;
  }

  final text = paragraph.join(' ').trim();
  return text.isEmpty ? null : text;
}

bool _isH1(String line) => line.trim().startsWith('# ');

/// The lines after the frontmatter block, or every line when there is none.
List<String> _bodyLines(String fileContents) {
  final lines = fileContents.split('\n');
  if (lines.isEmpty || lines.first.trim() != '---') {
    return lines;
  }

  var i = 1;
  while (i < lines.length && lines[i].trim() != '---') {
    i++;
  }
  return lines.sublist((i + 1).clamp(0, lines.length));
}
