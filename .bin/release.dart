import 'dart:convert';
import 'dart:io';

const String _pubspecPath = 'pubspec.yaml';
const String _changelogPath = 'CHANGELOG.md';

Future<void> main(List<String> args) async {
  final ReleaseOptions options = ReleaseOptions.parse(args);

  _printHeader(options);

  await _assertToolExists('git');
  await _assertToolExists('flutter');

  await _assertGitWorktreeIsClean();

  final String pubspecContent = await _readFile(_pubspecPath);
  final SemanticVersion currentVersion = _extractVersion(pubspecContent);

  final SemanticVersion nextVersion = options.bump == BumpLevel.auto
      ? await _inferNextVersionFromCommits(currentVersion)
      : currentVersion.bumped(options.bump);

  if (nextVersion == currentVersion) {
    _fail('Could not infer a new version. Add commits or pass --bump patch|minor|major.');
  }

  final String nextTag = 'v$nextVersion';
  await _assertTagDoesNotExist(nextTag);
  await _assertChangelogContainsVersion(nextVersion);

  stdout.writeln('Current version: $currentVersion');
  stdout.writeln('Next version:    $nextVersion');

  final bool proceed =
      options.yes ||
      _confirm('Proceed with release ${nextVersion.toString()}?', defaultYes: true);
  if (!proceed) {
    _info('Release cancelled by user.');
    return;
  }

  final String updatedPubspec = _updateVersion(pubspecContent, nextVersion);
  await File(_pubspecPath).writeAsString(updatedPubspec);
  _info('Updated $_pubspecPath version to $nextVersion.');

  await _run('flutter', <String>['test']);

  await _run('git', <String>['add', _pubspecPath, _changelogPath]);
  await _run('git', <String>['commit', '-m', 'chore(release): $nextTag']);
  await _run('git', <String>['tag', '-a', nextTag, '-m', 'Release $nextTag']);

  await _run('flutter', <String>['pub', 'publish', '--dry-run']);

  if (options.dryRun) {
    _info('Dry run complete. Skipping push, tag push, and publish.');
    return;
  }

  final bool publishConfirmed =
      options.yes || _confirm('Publish $nextTag to pub.dev now?', defaultYes: false);
  if (!publishConfirmed) {
    _info('Publish skipped. Version commit and tag were created locally.');
    _info('Run: git push && git push --tags && flutter pub publish -f');
    return;
  }

  await _run('git', <String>['push']);
  await _run('git', <String>['push', '--tags']);
  await _run('flutter', <String>['pub', 'publish', '-f']);

  _info('Release $nextTag finished successfully.');
}

enum BumpLevel { auto, patch, minor, major }

class ReleaseOptions {
  ReleaseOptions({required this.bump, required this.dryRun, required this.yes});

  final BumpLevel bump;
  final bool dryRun;
  final bool yes;

  static ReleaseOptions parse(List<String> args) {
    BumpLevel bump = BumpLevel.auto;
    bool dryRun = false;
    bool yes = false;

    for (int index = 0; index < args.length; index++) {
      final String arg = args[index];
      if (arg == '--dry-run') {
        dryRun = true;
        continue;
      }
      if (arg == '--yes' || arg == '-y') {
        yes = true;
        continue;
      }
      if (arg == '--help' || arg == '-h') {
        _printUsage();
        exit(0);
      }
      if (arg == '--bump') {
        if (index + 1 >= args.length) {
          _fail('Missing value for --bump. Expected patch|minor|major|auto.');
        }
        bump = _parseBumpLevel(args[index + 1]);
        index++;
        continue;
      }
      if (arg.startsWith('--bump=')) {
        final String value = arg.split('=').last.trim();
        bump = _parseBumpLevel(value);
        continue;
      }

      _fail('Unknown argument: $arg');
    }

    return ReleaseOptions(bump: bump, dryRun: dryRun, yes: yes);
  }
}

class SemanticVersion {
  const SemanticVersion(this.major, this.minor, this.patch);

  final int major;
  final int minor;
  final int patch;

  SemanticVersion bumped(BumpLevel level) {
    switch (level) {
      case BumpLevel.auto:
        return this;
      case BumpLevel.patch:
        return SemanticVersion(major, minor, patch + 1);
      case BumpLevel.minor:
        return SemanticVersion(major, minor + 1, 0);
      case BumpLevel.major:
        return SemanticVersion(major + 1, 0, 0);
    }
  }

  @override
  String toString() => '$major.$minor.$patch';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is SemanticVersion &&
        major == other.major &&
        minor == other.minor &&
        patch == other.patch;
  }

  @override
  int get hashCode => Object.hash(major, minor, patch);
}

Future<SemanticVersion> _inferNextVersionFromCommits(SemanticVersion currentVersion) async {
  final String? lastTag = await _tryLastTag();
  final List<String> commitSubjects = await _commitSubjectsSinceReference(lastTag?.trim());

  if (commitSubjects.isEmpty) {
    return currentVersion;
  }

  BumpLevel highestLevel = BumpLevel.patch;
  for (final String subject in commitSubjects) {
    final String normalized = subject.trim();
    if (_looksBreaking(normalized)) {
      highestLevel = BumpLevel.major;
      break;
    }
    if (highestLevel != BumpLevel.major && _looksFeature(normalized)) {
      highestLevel = BumpLevel.minor;
    }
  }

  return currentVersion.bumped(highestLevel);
}

bool _looksBreaking(String commitSubject) {
  final RegExp conventionalBreaking = RegExp(r'^[a-z]+(\([^\)]+\))?!:', caseSensitive: false);
  final bool hasBreakingToken = commitSubject.contains('BREAKING CHANGE');
  return conventionalBreaking.hasMatch(commitSubject) || hasBreakingToken;
}

bool _looksFeature(String commitSubject) {
  final RegExp conventionalFeature = RegExp(r'^feat(\([^\)]+\))?:', caseSensitive: false);
  return conventionalFeature.hasMatch(commitSubject);
}

Future<void> _assertGitWorktreeIsClean() async {
  final ProcessResult result = await Process.run('git', <String>['status', '--porcelain']);

  if (result.exitCode != 0) {
    _fail('Could not read git status: ${result.stderr}');
  }

  final String output = (result.stdout as String).trim();
  if (output.isNotEmpty) {
    _fail('Git working tree is not clean. Commit/stash changes before releasing.');
  }
}

Future<void> _assertTagDoesNotExist(String tag) async {
  final ProcessResult result = await Process.run('git', <String>['tag', '--list', tag]);

  if (result.exitCode != 0) {
    _fail('Could not list tags: ${result.stderr}');
  }

  final String existingTag = (result.stdout as String).trim();
  if (existingTag == tag) {
    _fail('Tag $tag already exists.');
  }
}

Future<void> _assertChangelogContainsVersion(SemanticVersion version) async {
  final File changelog = File(_changelogPath);
  if (!await changelog.exists()) {
    _fail('$_changelogPath not found.');
  }

  final String content = await changelog.readAsString();
  final RegExp versionHeader = RegExp(
    r'^##\s+' + RegExp.escape(version.toString()) + r'\s*$',
    multiLine: true,
  );

  if (!versionHeader.hasMatch(content)) {
    _fail('$_changelogPath does not contain a section for ${version.toString()}.');
  }
}

SemanticVersion _extractVersion(String pubspecContent) {
  final RegExp versionLine = RegExp(
    r'^version:\s*([0-9]+\.[0-9]+\.[0-9]+)\s*$',
    multiLine: true,
  );
  final RegExpMatch? match = versionLine.firstMatch(pubspecContent);
  if (match == null) {
    _fail('Could not find a simple semver version in $_pubspecPath.');
  }

  final List<String> parts = match!.group(1)!.split('.');
  return SemanticVersion(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
}

String _updateVersion(String pubspecContent, SemanticVersion version) {
  final RegExp versionLine = RegExp(r'^version:\s*[0-9]+\.[0-9]+\.[0-9]+\s*$', multiLine: true);
  if (!versionLine.hasMatch(pubspecContent)) {
    _fail('Could not update version in $_pubspecPath.');
  }
  return pubspecContent.replaceFirst(versionLine, 'version: $version');
}

Future<String?> _tryLastTag() async {
  final ProcessResult result = await Process.run('git', <String>[
    'describe',
    '--tags',
    '--abbrev=0',
  ]);

  if (result.exitCode != 0) {
    return null;
  }

  return (result.stdout as String).trim();
}

Future<List<String>> _commitSubjectsSinceReference(String? reference) async {
  final List<String> command = <String>['log', '--pretty=%s'];
  if (reference != null && reference.isNotEmpty) {
    command.add('$reference..HEAD');
  }

  final ProcessResult result = await Process.run('git', command);
  if (result.exitCode != 0) {
    _fail('Could not inspect commits: ${result.stderr}');
  }

  final String output = (result.stdout as String).trim();
  if (output.isEmpty) {
    return <String>[];
  }

  return const LineSplitter().convert(output);
}

Future<void> _assertToolExists(String executable) async {
  final ProcessResult result = await Process.run('which', <String>[executable]);
  if (result.exitCode != 0) {
    _fail('Required executable not found: $executable');
  }
}

Future<void> _run(String executable, List<String> arguments) async {
  stdout.writeln(r'$ ' + executable + (arguments.isEmpty ? '' : ' ${arguments.join(' ')}'));
  final Process process = await Process.start(
    executable,
    arguments,
    mode: ProcessStartMode.inheritStdio,
  );
  final int code = await process.exitCode;
  if (code != 0) {
    _fail('Command failed: $executable ${arguments.join(' ')} (exit $code)');
  }
}

Future<String> _readFile(String path) async {
  final File file = File(path);
  if (!await file.exists()) {
    _fail('File not found: $path');
  }
  return file.readAsString();
}

BumpLevel _parseBumpLevel(String value) {
  switch (value.trim().toLowerCase()) {
    case 'auto':
      return BumpLevel.auto;
    case 'patch':
      return BumpLevel.patch;
    case 'minor':
      return BumpLevel.minor;
    case 'major':
      return BumpLevel.major;
    default:
      _fail('Invalid --bump value "$value". Use patch|minor|major|auto.');
  }
}

bool _confirm(String prompt, {required bool defaultYes}) {
  final String suffix = defaultYes ? '[Y/n]' : '[y/N]';
  stdout.write('$prompt $suffix ');
  final String? input = stdin.readLineSync();
  final String normalized = (input ?? '').trim().toLowerCase();
  if (normalized.isEmpty) {
    return defaultYes;
  }
  return normalized == 'y' || normalized == 'yes';
}

void _printHeader(ReleaseOptions options) {
  stdout.writeln('super_tree release script');
  stdout.writeln(
    'Options: bump=${options.bump.name}, dryRun=${options.dryRun}, yes=${options.yes}',
  );
}

void _printUsage() {
  stdout.writeln('''
Usage: dart run .bin/release.dart [options]

Options:
	--bump <auto|patch|minor|major>  Select version bump strategy (default: auto).
	--dry-run                         Stop after dry-run publish validation.
	--yes, -y                         Skip interactive confirmations.
	--help, -h                        Show this help.

Behavior:
	1) Requires a clean git working tree.
	2) Computes next version (auto based on commits, or explicit bump).
	3) Ensures CHANGELOG.md has a matching "## <version>" section.
	4) Updates pubspec.yaml version.
	5) Runs flutter tests.
	6) Commits release files and creates an annotated git tag.
	7) Runs flutter pub publish --dry-run.
	8) Pushes + publishes (unless --dry-run).
''');
}

Never _fail(String message) {
  stderr.writeln('Error: $message');
  exitCode = 1;
  exit(exitCode);
}

void _info(String message) {
  stdout.writeln(message);
}
