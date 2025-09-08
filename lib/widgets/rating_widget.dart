import 'package:flutter/material.dart';

class RatingWidget extends StatelessWidget {
  final double rating;
  final int reviewCount;
  final bool showReviewCount;
  final double starSize;
  final Color starColor;

  const RatingWidget({
    super.key,
    required this.rating,
    required this.reviewCount,
    this.showReviewCount = true,
    this.starSize = 16.0,
    this.starColor = Colors.amber,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Stars
        Row(
          children: List.generate(5, (index) {
            if (index < rating.floor()) {
              // Full star
              return Icon(
                Icons.star,
                size: starSize,
                color: starColor,
              );
            } else if (index < rating.ceil()) {
              // Half star
              return Icon(
                Icons.star_half,
                size: starSize,
                color: starColor,
              );
            } else {
              // Empty star
              return Icon(
                Icons.star_border,
                size: starSize,
                color: starColor,
              );
            }
          }),
        ),
        
        const SizedBox(width: 4),
        
        // Rating number
        Text(
          rating.toStringAsFixed(1),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: starSize * 0.8,
          ),
        ),
        
        // Review count
        if (showReviewCount) ...[
          const SizedBox(width: 4),
          Text(
            '($reviewCount)',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: starSize * 0.7,
            ),
          ),
        ],
      ],
    );
  }
}
