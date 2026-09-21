import 'package:flutter/material.dart';

class TopicBackground extends StatelessWidget {
  final String? image;
  final Color color;

  const TopicBackground({super.key, required this.image, required this.color});

  @override
  Widget build(BuildContext context) {
    final bgImage = image;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (bgImage != null && bgImage.isNotEmpty)
          Image.asset(
            bgImage,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _Gradient(color: color),
          )
        else
          _Gradient(color: color),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.3),
                Colors.transparent,
                Colors.black.withValues(alpha: 0.45),
              ],
              stops: const [0.0, 0.35, 1.0],
            ),
          ),
        ),
      ],
    );
  }
}

class TopicHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? image;
  final Color color;
  final double height;

  const TopicHeader({
    super.key,
    required this.title,
    required this.image,
    required this.color,
    this.subtitle,
    this.height = 200,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          TopicBackground(image: image, color: color),
          Positioned(
            left: 20,
            right: 20,
            bottom: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                    color: Colors.white,
                    shadows: const [
                      Shadow(
                        color: Colors.black45,
                        blurRadius: 8,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Gradient extends StatelessWidget {
  final Color color;

  const _Gradient({required this.color});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withValues(alpha: 0.7), color],
        ),
      ),
    );
  }
}
