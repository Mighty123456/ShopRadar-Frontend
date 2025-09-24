import '../models/shop.dart';
import 'rating_widget.dart';
import 'package:flutter/material.dart';

class ReviewCard extends StatelessWidget {
  final ShopReview review;
  final bool showSentiment;

  const ReviewCard({
    super.key,
    required this.review,
    this.showSentiment = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User info and rating
          Row(
            children: [
              // User avatar
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFF2979FF).withValues(alpha: 0.1),
                child: review.userAvatar != null
                    ? ClipOval(
                        child: Image.network(
                          review.userAvatar!,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.person,
                              color: const Color(0xFF2979FF),
                              size: 20,
                            );
                          },
                        ),
                      )
                    : Icon(
                        Icons.person,
                        color: const Color(0xFF2979FF),
                        size: 20,
                      ),
              ),
              
              const SizedBox(width: 12),
              
              // User name and verification
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          review.userName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        if (review.isVerified) ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.verified,
                            color: Colors.blue,
                            size: 16,
                          ),
                        ],
                      ],
                    ),
                    Text(
                      review.timeAgo,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Rating
              RatingWidget(
                rating: review.rating,
                reviewCount: 0,
                showReviewCount: false,
                starSize: 16,
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Review comment
          Text(
            review.comment,
            style: const TextStyle(
              fontSize: 14,
              height: 1.4,
            ),
          ),

          if (showSentiment) ...[
            const SizedBox(height: 8),
            _SentimentChip(comment: review.comment),
          ],
          
          // Review images
          if (review.images.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: review.images.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    width: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: NetworkImage(review.images[index]),
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SentimentChip extends StatelessWidget {
  final String comment;
  const _SentimentChip({required this.comment});

  @override
  Widget build(BuildContext context) {
    // UI-only naive sentiment: positive if contains good words, negative if contains negative words
    final lower = comment.toLowerCase();
    const positiveWords = ['good', 'great', 'excellent', 'amazing', 'nice', 'original', 'best', 'love'];
    const negativeWords = ['bad', 'fake', 'poor', 'worst', 'terrible', 'late', 'slow'];
    bool isPositive = positiveWords.any((w) => lower.contains(w));
    bool isNegative = negativeWords.any((w) => lower.contains(w));
    Color bg;
    Color fg;
    String label;
    if (isPositive && !isNegative) {
      bg = const Color(0xFFE8F5E8);
      fg = const Color(0xFF2E7D32);
      label = 'Positive';
    } else if (isNegative && !isPositive) {
      bg = const Color(0xFFFFEBEE);
      fg = const Color(0xFFC62828);
      label = 'Negative';
    } else {
      bg = const Color(0xFFE3F2FD);
      fg = const Color(0xFF1565C0);
      label = 'Neutral';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            label == 'Positive' ? Icons.check_circle : label == 'Negative' ? Icons.cancel : Icons.info_outline,
            size: 14,
            color: fg,
          ),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 12)),
        ],
      ),
    );
  }
}
