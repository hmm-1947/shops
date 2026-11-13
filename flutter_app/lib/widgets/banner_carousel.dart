import 'dart:async';
import 'package:flutter/material.dart';
import '../theme.dart';
import 'common.dart';

class BannerCarousel extends StatefulWidget {
  const BannerCarousel(this.images, {super.key});

  final List<String> images;

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  final _controller = PageController();
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    if (widget.images.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 4), (_) {
        if (_controller.hasClients) {
          _controller.animateToPage((_index + 1) % widget.images.length, duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 354 / 178,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: PageView.builder(
              controller: _controller,
              itemCount: widget.images.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (_, i) => AppImage(widget.images[i]),
            ),
          ),
        ),
        if (widget.images.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < widget.images.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _index ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(color: i == _index ? orange : const Color(0xFF8A8A8A), borderRadius: BorderRadius.circular(3)),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
