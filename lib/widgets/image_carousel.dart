import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'app_card.dart';

class ImageCarousel extends StatefulWidget {
  const ImageCarousel({super.key});

  static const List<String> images = [
    'assets/images/img 1.jpg',
    'assets/images/img 2.jpg',
    'assets/images/img 3.jpg',
    'assets/images/img 4.jpg',
    'assets/images/img 5.jpg',
    'assets/images/img 6.jpg',
    'assets/images/moduli.jpg',
  ];

  @override
  State<ImageCarousel> createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<ImageCarousel> {
  /// Altezza fissa della striscia: le slide sono fotografie di moduli, non
  /// schermate, e un'altezza derivata dalla larghezza cambiava formato a ogni
  /// telefono.
  static const double _height = 180;

  late final PageController _controller = PageController(
    viewportFraction: 0.85,
  );
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) => setState(() => _index = index);

  Widget _slide(int index) {
    final c = AppColors.of(context);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final page = _controller.hasClients
            ? (_controller.page ?? _index.toDouble())
            : _index.toDouble();
        final dist = (index - page).clamp(-1.0, 1.0);
        // La slide attiva sta a scala 1 e piena, le vicine rientrano e si
        // spengono: è la profondità del carosello, non una dissolvenza a caso.
        final scale = 1 - 0.05 * dist.abs();
        final opacity = 1 - 0.4 * dist.abs();
        return Opacity(
          opacity: opacity,
          child: Transform.scale(scale: scale, child: child),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(kCardRadius),
            boxShadow: [
              BoxShadow(
                color: c.shadow,
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(kCardRadius),
            child: SizedBox.expand(
              child: Image.asset(
                ImageCarousel.images[index],
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  color: c.accentSoft,
                  child: Icon(Icons.image_outlined, color: c.textSecondary),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return SizedBox(
      height: _height,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          ClipRect(
            child: SizedBox.expand(
              child: PageView.builder(
                controller: _controller,
                itemCount: ImageCarousel.images.length,
                padEnds: true,
                allowImplicitScrolling: true,
                onPageChanged: _onPageChanged,
                itemBuilder: (context, index) => _slide(index),
              ),
            ),
          ),
          Positioned(
            bottom: 10,
            child: Row(
              children: [
                for (var i = 0; i < ImageCarousel.images.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _index ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i == _index
                          ? c.accent
                          : Colors.white.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
