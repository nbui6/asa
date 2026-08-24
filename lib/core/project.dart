/// A project, read from the frontmatter of its home note.
///
/// Nothing in `core/` imports Flutter. That is what makes it testable without
/// a running app, and it is the one architecture rule this project has.
library;

class Project {
  final String name;
  final String status;
  final String milestone;
  final String nextStep;
  final String repoPath;
  final String updated;

  /// The file this was read from, so the UI can say where a value came from.
  final String sourceFile;

  const Project({
    required this.name,
    required this.status,
    required this.milestone,
    required this.nextStep,
    required this.repoPath,
    required this.updated,
    required this.sourceFile,
  });
}

/// What happened when we tried to read a project note.
///
/// A result object rather than an exception or a null, because the screen has
/// to be able to show *why* nothing appeared. Silent failure is banned —
/// see PLAYBOOK.md section 7, rule 6.
class ProjectReadResult {
  final Project? project;
  final String? error;

  /// The frontmatter exactly as it was found, before parsing.
  /// Shown on screen so a human can see what the file really said.
  final String rawFrontmatter;

  const ProjectReadResult({
    this.project,
    this.error,
    this.rawFrontmatter = '',
  });

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
    final isQuoted = (first == '"' && last == '"') || (first == "'" && last == "'");
    if (isQuoted) {
      return value.substring(1, value.length - 1);
    }
  }
  return value;
}

/// Returns the frontmatter block as it appears in the file, `---` lines and all.
/// Used only for display.
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
Project projectFromFields(Map<String, String> fields, String sourceFile) {
  String field(String key) {
    final value = fields[key];
    if (value == null || value.isEmpty) {
      return '(not set)';
    }
    return value;
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
  );
}
