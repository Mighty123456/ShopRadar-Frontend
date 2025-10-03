import 'package:flutter/material.dart';
import '../services/shop_offers_service.dart';

class OfferComparisonWidget extends StatelessWidget {
  final List<ShopOffer> offers;
  final VoidCallback? onClose;

  const OfferComparisonWidget({
    super.key,
    required this.offers,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    if (offers.length < 2) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Compare ${offers.length} Offers',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (onClose != null)
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close),
                ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),

          // Comparison Table
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: [
                const DataColumn(label: Text('Feature')),
                ...offers.map((offer) => DataColumn(
                  label: Text(
                    offer.product.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                )),
              ],
              rows: [
                // Discount
                DataRow(
                  cells: [
                    const DataCell(Text('Discount')),
                    ...offers.map((offer) => DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          offer.formattedDiscount,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    )),
                  ],
                ),

                // Original Price
                DataRow(
                  cells: [
                    const DataCell(Text('Original Price')),
                    ...offers.map((offer) => DataCell(
                      Text(
                        '₹${offer.product.price.toStringAsFixed(0)}',
                        style: const TextStyle(
                          decoration: TextDecoration.lineThrough,
                          color: Colors.grey,
                        ),
                      ),
                    )),
                  ],
                ),

                // Discounted Price
                DataRow(
                  cells: [
                    const DataCell(Text('Discounted Price')),
                    ...offers.map((offer) => DataCell(
                      Text(
                        '₹${offer.getDiscountedPrice().toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    )),
                  ],
                ),

                // Savings
                DataRow(
                  cells: [
                    const DataCell(Text('You Save')),
                    ...offers.map((offer) => DataCell(
                      Text(
                        '₹${(offer.product.price - offer.getDiscountedPrice()).toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    )),
                  ],
                ),

                // Category
                DataRow(
                  cells: [
                    const DataCell(Text('Category')),
                    ...offers.map((offer) => DataCell(
                      Chip(
                        label: Text(offer.category),
                        backgroundColor: Colors.blue.withValues(alpha: 0.1),
                      ),
                    )),
                  ],
                ),

                // Expires
                DataRow(
                  cells: [
                    const DataCell(Text('Expires')),
                    ...offers.map((offer) => DataCell(
                      _buildExpiryWidget(offer),
                    )),
                  ],
                ),

                // Uses Left
                DataRow(
                  cells: [
                    const DataCell(Text('Uses Left')),
                    ...offers.map((offer) => DataCell(
                      _buildUsesLeftWidget(offer),
                    )),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Best Deal Highlight
          _buildBestDealHighlight(),
        ],
      ),
    );
  }

  Widget _buildExpiryWidget(ShopOffer offer) {
    final daysLeft = offer.daysRemaining;
    final hoursLeft = offer.hoursRemaining;
    
    Color color = Colors.green;
    String text = '${daysLeft}d left';
    
    if (daysLeft == 0) {
      if (hoursLeft <= 24) {
        color = Colors.orange;
        text = '${hoursLeft}h left';
      } else {
        color = Colors.red;
        text = 'Expired';
      }
    } else if (daysLeft <= 3) {
      color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildUsesLeftWidget(ShopOffer offer) {
    if (offer.maxUses == 0) {
      return const Text('Unlimited');
    }
    
    final remaining = offer.maxUses - offer.currentUses;
    Color color = Colors.green;
    
    if (remaining <= 5) {
      color = Colors.orange;
    }
    if (remaining <= 2) {
      color = Colors.red;
    }

    return Text(
      '$remaining left',
      style: TextStyle(
        color: color,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildBestDealHighlight() {
    // Find the best deal
    ShopOffer? bestDeal;
    double bestSavings = 0;

    for (final offer in offers) {
      final savings = offer.product.price - offer.getDiscountedPrice();
      if (savings > bestSavings) {
        bestSavings = savings;
        bestDeal = offer;
      }
    }

    if (bestDeal == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.star,
            color: Colors.green,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Best Deal: ${bestDeal.product.name} - Save ₹${bestSavings.toStringAsFixed(0)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
