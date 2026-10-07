import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Minimal, dependency-free HTML renderer for Teams message bodies.
///
/// Why not a package: the project has no HTML rendering dependency, and
/// message bodies come from an external system, so the safest option is to
/// support a small known-good subset and discard everything else.
///
/// Handled (matches what the Teams API actually returns):
///   p, div, span, br, hr, b/strong, i/em, u, s/strike/del, code/pre,
///   a, ul/ol/li, h1-h6, blockquote,
///   at       -> @mention, styled as a highlighted name
///   img      -> placeholder; Teams images are Microsoft Graph
///               `hostedContents` URLs that need a Graph token, so they
///               cannot be loaded by the app
///   attachment -> dropped; attachments are listed separately
///
/// Dropped entirely (tag and contents): script, style, iframe, object,
/// embed, svg. Unknown tags are unwrapped, keeping their text. Attributes
/// are never interpreted except `href` on links, which must be http(s) or
/// msteams. Nothing is executed and no WebView is used.
class SimpleHtmlText extends StatelessWidget {
  final String html;
  final TextStyle? baseStyle;
  final Color accentColor;

  /// Label for the inline-image placeholder, e.g. "Image, open in Teams".
  final String imagePlaceholder;

  /// Tapped when the user taps an image placeholder, usually "open in
  /// Teams", since that is the only place the image can be viewed.
  final VoidCallback? onImageTap;

  const SimpleHtmlText({
    super.key,
    required this.html,
    this.baseStyle,
    this.accentColor = const Color(0xFF0fbab5),
    this.imagePlaceholder = 'Image',
    this.onImageTap,
  });

  @override
  Widget build(BuildContext context) {
    final style =
        baseStyle ??
        const TextStyle(fontSize: 15, height: 1.55, color: Colors.black87);

    final blocks = _HtmlParser(
      html: html,
      baseStyle: style,
      accentColor: accentColor,
      imagePlaceholder: imagePlaceholder,
      onImageTap: onImageTap,
    ).parseBlocks();

    if (blocks.isEmpty) return Text('', style: style);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: blocks,
    );
  }
}

// Block markers. Private-use code points so they can never collide with
// real message text.
const String _kBreak = '\u{E000}';
const String _kBullet = '\u{E001}';
const String _kImage = '\u{E002}';
const String _kRule = '\u{E003}';
const String _kHeading = '\u{E004}'; // followed by the level digit

class _HtmlParser {
  final String html;
  final TextStyle baseStyle;
  final Color accentColor;
  final String imagePlaceholder;
  final VoidCallback? onImageTap;

  _HtmlParser({
    required this.html,
    required this.baseStyle,
    required this.accentColor,
    required this.imagePlaceholder,
    required this.onImageTap,
  });

  static final RegExp _dangerous = RegExp(
    r'<(script|style|iframe|object|embed|svg)\b[^>]*>.*?</\1>',
    caseSensitive: false,
    dotAll: true,
  );
  static final RegExp _dangerousSolo = RegExp(
    r'<(script|style|iframe|object|embed|svg)\b[^>]*/?>',
    caseSensitive: false,
  );

  List<Widget> parseBlocks() {
    var source = html
        .replaceAll(_dangerous, '')
        .replaceAll(_dangerousSolo, '')
        // Attachment placeholders: the files are shown in their own card.
        .replaceAll(
          RegExp(r'<attachment\b[^>]*>(\s*</attachment>)?', caseSensitive: false),
          '',
        )
        // Images and rules become standalone blocks.
        .replaceAll(
          RegExp(r'<img\b[^>]*>', caseSensitive: false),
          '$_kBreak$_kImage$_kBreak',
        )
        .replaceAll(
          RegExp(r'<hr\b[^>]*>', caseSensitive: false),
          '$_kBreak$_kRule$_kBreak',
        )
        // Headings: mark the block so it can be styled larger.
        .replaceAllMapped(
          RegExp(r'<h([1-6])\b[^>]*>', caseSensitive: false),
          (m) => '$_kBreak$_kHeading${m.group(1)}',
        )
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), _kBreak)
        .replaceAll(
          RegExp(r'</(p|div|h[1-6]|blockquote|tr)>', caseSensitive: false),
          _kBreak,
        )
        .replaceAll(
          RegExp(r'<(p|div|blockquote)\b[^>]*>', caseSensitive: false),
          '',
        )
        .replaceAll(RegExp(r'</?(ul|ol)\b[^>]*>', caseSensitive: false), _kBreak)
        .replaceAll(
          RegExp(r'<li\b[^>]*>', caseSensitive: false),
          '$_kBreak$_kBullet',
        )
        .replaceAll(RegExp(r'</li>', caseSensitive: false), '');

    final widgets = <Widget>[];
    var lastWasRule = false;

    void addBlock(Widget child, {double gap = 8}) {
      widgets.add(
        Padding(
          padding: EdgeInsets.only(top: widgets.isEmpty ? 0 : gap),
          child: child,
        ),
      );
    }

    for (final rawBlock in source.split(_kBreak)) {
      // Rule.
      if (rawBlock.trim() == _kRule) {
        // Collapse consecutive rules into one.
        if (!lastWasRule && widgets.isNotEmpty) {
          addBlock(Divider(height: 1, color: Colors.grey.shade300), gap: 12);
          lastWasRule = true;
        }
        continue;
      }

      // Image placeholder.
      if (rawBlock.trim() == _kImage) {
        addBlock(_imagePlaceholder(), gap: 10);
        lastWasRule = false;
        continue;
      }

      var block = rawBlock;
      var isBullet = false;
      int? headingLevel;

      if (block.startsWith(_kBullet)) {
        isBullet = true;
        block = block.substring(_kBullet.length);
      }
      if (block.startsWith(_kHeading) && block.length > _kHeading.length) {
        headingLevel = int.tryParse(block[_kHeading.length]);
        block = block.substring(_kHeading.length + 1);
      }

      // Skip whitespace-only blocks so the layout doesn't gain blank gaps.
      if (_strip(block).trim().isEmpty) continue;

      final blockStyle =
          headingLevel == null
              ? baseStyle
              : baseStyle.copyWith(
                fontSize: (baseStyle.fontSize ?? 15) + (7 - headingLevel),
                fontWeight: FontWeight.bold,
                height: 1.35,
              );

      final text = RichText(
        text: TextSpan(style: blockStyle, children: _inlineSpans(block, blockStyle)),
      );

      if (isBullet) {
        addBlock(
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8, right: 10, left: 4),
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: blockStyle.color?.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Expanded(child: text),
            ],
          ),
          gap: 4,
        );
      } else {
        addBlock(text, gap: headingLevel != null ? 14 : 8);
      }
      lastWasRule = false;
    }
    return widgets;
  }

  Widget _imagePlaceholder() {
    return Material(
      color: Colors.grey.shade100,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onImageTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              Icon(Icons.image_outlined, size: 22, color: Colors.grey[600]),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  imagePlaceholder,
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                ),
              ),
              if (onImageTap != null)
                Icon(
                  Icons.open_in_new_rounded,
                  size: 16,
                  color: Colors.grey[500],
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Converts one block of inline HTML into styled spans.
  List<InlineSpan> _inlineSpans(String input, TextStyle blockStyle) {
    final spans = <InlineSpan>[];
    final tagPattern = RegExp(r'<(/?)([a-zA-Z0-9]+)([^>]*)>');

    var bold = 0, italic = 0, underline = 0, strike = 0, code = 0, mention = 0;
    String? href;
    var cursor = 0;

    void emit(String text) {
      if (text.isEmpty) return;
      final decoded = _decodeEntities(text);
      if (decoded.isEmpty) return;

      var style = blockStyle.copyWith(
        fontWeight: (bold > 0 || mention > 0) ? FontWeight.bold : null,
        fontStyle: italic > 0 ? FontStyle.italic : null,
        decoration: TextDecoration.combine([
          if (underline > 0) TextDecoration.underline,
          if (strike > 0) TextDecoration.lineThrough,
        ]),
        fontFamily: code > 0 ? 'monospace' : null,
        color: mention > 0 ? accentColor : null,
      );

      if (href != null) {
        final link = href!;
        style = style.copyWith(
          color: Colors.blue[700],
          decoration: TextDecoration.underline,
        );
        spans.add(
          TextSpan(
            text: decoded,
            style: style,
            recognizer:
                TapGestureRecognizer()
                  ..onTap = () async {
                    final uri = Uri.tryParse(link);
                    if (uri == null) return;
                    try {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    } catch (_) {
                      // A bad link must not crash the view.
                    }
                  },
          ),
        );
      } else {
        spans.add(TextSpan(text: decoded, style: style));
      }
    }

    for (final match in tagPattern.allMatches(input)) {
      emit(input.substring(cursor, match.start));
      cursor = match.end;

      final closing = match.group(1) == '/';
      final tag = match.group(2)!.toLowerCase();
      final attrs = match.group(3) ?? '';

      switch (tag) {
        case 'b':
        case 'strong':
          bold += closing ? -1 : 1;
          break;
        case 'i':
        case 'em':
          italic += closing ? -1 : 1;
          break;
        case 'u':
          underline += closing ? -1 : 1;
          break;
        case 's':
        case 'strike':
        case 'del':
          strike += closing ? -1 : 1;
          break;
        case 'code':
        case 'pre':
          code += closing ? -1 : 1;
          break;
        case 'at':
          // Teams @mention: <at id="0">LIM Vuthy</at>
          if (!closing) emit('@');
          mention += closing ? -1 : 1;
          break;
        case 'a':
          if (closing) {
            href = null;
          } else {
            final hrefMatch = RegExp(
              '''href\\s*=\\s*["']([^"']*)["']''',
              caseSensitive: false,
            ).firstMatch(attrs);
            final value = hrefMatch?.group(1)?.trim();
            // Only http(s) and msteams links are tappable; javascript:,
            // data: and file: render as plain text.
            if (value != null &&
                RegExp(r'^(https?|msteams)://', caseSensitive: false)
                    .hasMatch(value)) {
              href = value;
            }
          }
          break;
        default:
          // Unknown tag (span, etc.): unwrap it, keep the text.
          break;
      }

      // Clamp so malformed markup cannot drive counters negative.
      bold = bold < 0 ? 0 : bold;
      italic = italic < 0 ? 0 : italic;
      underline = underline < 0 ? 0 : underline;
      strike = strike < 0 ? 0 : strike;
      code = code < 0 ? 0 : code;
      mention = mention < 0 ? 0 : mention;
    }

    emit(input.substring(cursor));
    return spans;
  }

  String _strip(String input) =>
      _decodeEntities(input.replaceAll(RegExp(r'<[^>]*>'), ''));

  String _decodeEntities(String input) => input
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&apos;', "'");
}
