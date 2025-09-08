import 'package:flutter/material.dart';
import '../models/shop.dart';
import 'rating_widget.dart';

class ComparisonCard extends StatelessWidget {
  final Shop shop;
  final bool isSelected;
  final bool canAdd;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const ComparisonCard({
    super.key,
    required this.shop,
    required this.isSelected,
    required this.canAdd,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected 
            ? const Color(0xFF2979FF).withValues(alpha: 0.1)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected 
              ? const Color(0xFF2979FF)
              : Colors.grey[200]!,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Shop icon
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isSelected 
                    ? const Color(0xFF2979FF).withValues(alpha: 0.2)
                    : const Color(0xFF2979FF).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Icon(
                Icons.store,
                color: isSelected 
                    ? const Color(0xFF2979FF)
                    : const Color(0xFF2979FF).withValues(alpha: 0.7),
                size: 24,
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Shop info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Shop name and status
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          shop.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isSelected 
                                ? const Color(0xFF2979FF)
                                : Colors.black87,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: shop.isOpen ? Colors.green : Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          shop.statusText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Category and distance
                  Row(
                    children: [
                      Icon(
                        Icons.category,
                        size: 12,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        shop.category,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.location_on,
                        size: 12,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        shop.formattedDistance,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Rating
                  RatingWidget(
                    rating: shop.rating,
                    reviewCount: shop.reviewCount,
                    starSize: 14,
                  ),
                  
                  // Offers count
                  if (shop.offers.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.local_offer,
                          size: 12,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${shop.offers.length} offer${shop.offers.length > 1 ? 's' : ''}',
                          style: const TextStyle(
                            color: Colors.orange,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            
            // Action button
            if (isSelected)
              IconButton(
                icon: const Icon(Icons.remove_circle, color: Colors.red),
                onPressed: onRemove,
                tooltip: 'Remove from comparison',
              )
            else if (canAdd)
              IconButton(
                icon: const Icon(Icons.add_circle, color: Color(0xFF2979FF)),
                onPressed: onAdd,
                tooltip: 'Add to comparison',
              )
            else
              Icon(
                Icons.block,
                color: Colors.grey[400],
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}
