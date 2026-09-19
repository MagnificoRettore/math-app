import 'package:flutter/material.dart';

import 'app_card.dart';
import 'topic_background.dart';

class TopicImageCard extends StatelessWidget {
  final String title;
  final String? image;
  final Color color;
  final VoidCallback onTap;

  const TopicImageCard({
    super.key,
    required this.title,
    required this.image,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          height: 130,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              TopicBackground(image: image, color: color),
              Positioned(
                left: 16,
                right: 16,
                bottom: 12,
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}