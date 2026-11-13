import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../config.dart';
import '../theme.dart';

class AppImage extends StatelessWidget {
  const AppImage(this.path, {super.key, this.fit = BoxFit.cover});

  final String? path;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    const placeholder = ColoredBox(color: cardColor);
    if (path == null) return placeholder;
    return CachedNetworkImage(
      imageUrl: imageUrl(path!),
      fit: fit,
      placeholder: (_, _) => placeholder,
      errorWidget: (_, _, _) => const ColoredBox(color: cardColor, child: Icon(Icons.image_not_supported_outlined, color: muted)),
    );
  }
}

class FutureView<T> extends StatefulWidget {
  const FutureView({super.key, required this.load, required this.builder});

  final Future<T> Function() load;
  final Widget Function(BuildContext context, T data, Future<void> Function() reload) builder;

  @override
  State<FutureView<T>> createState() => _FutureViewState<T>();
}

class _FutureViewState<T> extends State<FutureView<T>> {
  late Future<T> _future = widget.load();

  Future<void> _reload() {
    setState(() => _future = widget.load());
    return _future.then((_) {}, onError: (_) {});
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
        if (snap.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Could not load. Check your connection.', style: TextStyle(color: muted)),
                TextButton(onPressed: _reload, child: const Text('Retry')),
              ],
            ),
          );
        }
        return widget.builder(context, snap.data as T, _reload);
      },
    );
  }
}
