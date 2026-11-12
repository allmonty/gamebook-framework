import 'package:markdown/markdown.dart';

import 'embed.dart';
import 'template.dart';

/// One tutorial chapter, rendered.
class Chapter {
  const Chapter({required this.slug, required this.title, required this.html});

  /// The file name without `.md`, the same in every language; also the
  /// page name (`<slug>.html`).
  final String slug;
  final String title;
  final String html;
}

final _heading = RegExp(r'^# (.+)$', multiLine: true);
final _mdLink = RegExp(r'href="([\w./-]+?)\.md(#[\w-]+)?"');

/// Renders a chapter's Markdown: example blocks become embeds, links to
/// other `.md` chapters become links to their pages (so the same files
/// read well on GitHub and on the site). The title is the first `# `.
Chapter renderChapter(String slug, String markdown, ExampleLookup lookup) {
  final title =
      _heading.firstMatch(markdown)?[1]?.trim() ??
      (throw BuildException('chapter $slug has no "# " title'));
  final html = markdownToHtml(
    embedExamples(markdown, lookup),
    extensionSet: ExtensionSet.gitHubWeb,
  ).replaceAllMapped(_mdLink, (m) => 'href="${m[1]}.html${m[2] ?? ''}"');
  return Chapter(slug: slug, title: title, html: html);
}
