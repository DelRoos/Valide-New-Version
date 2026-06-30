part of '../pedagogical_content.dart';

class _StreamingMarkdown extends StatelessWidget {
  const _StreamingMarkdown({
    required this.stream,
    required this.style,
    required this.onLinkTap,
  });

  final Stream<String> stream;
  final TextStyle style;
  final void Function(String url, String title)? onLinkTap;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<String>(
      stream: stream,
      initialData: '',
      builder: (context, snapshot) {
        final data = snapshot.data ?? '';
        return GptMarkdown(
          data,
          style: style,
          onLinkTap: onLinkTap,
          useDollarSignsForLatex: true,
          imageBuilder: PedagogicalContent._imageBuilder,
          codeBuilder: PedagogicalContent._codeBuilder,
        );
      },
    );
  }
}
