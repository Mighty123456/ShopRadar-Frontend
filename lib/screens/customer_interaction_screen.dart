import 'package:flutter/material.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/animated_message_dialog.dart';

class CustomerInteractionScreen extends StatefulWidget {
  const CustomerInteractionScreen({super.key});

  @override
  State<CustomerInteractionScreen> createState() => _CustomerInteractionScreenState();
}

class _CustomerInteractionScreenState extends State<CustomerInteractionScreen> {
  final _responseController = TextEditingController();
  String _selectedFilter = 'All Reviews';
  
  final List<Map<String, dynamic>> _reviews = [
    {
      'id': '1',
      'customerName': 'John Smith',
      'rating': 5,
      'comment': 'Excellent service and great quality products! The wireless headphones are amazing.',
      'date': DateTime.now().subtract(const Duration(days: 2)),
      'product': 'Wireless Headphones',
      'isResponded': false,
      'response': '',
      'sentiment': 'positive',
    },
    {
      'id': '2',
      'customerName': 'Sarah Johnson',
      'rating': 4,
      'comment': 'Good products but delivery was a bit slow. Overall satisfied with the purchase.',
      'date': DateTime.now().subtract(const Duration(days: 5)),
      'product': 'Smartphone Case',
      'isResponded': true,
      'response': 'Thank you for your feedback! We\'re working on improving our delivery times.',
      'sentiment': 'neutral',
    },
    {
      'id': '3',
      'customerName': 'Mike Wilson',
      'rating': 2,
      'comment': 'Product arrived damaged. Not happy with the quality.',
      'date': DateTime.now().subtract(const Duration(days: 7)),
      'product': 'USB-C Cable',
      'isResponded': false,
      'response': '',
      'sentiment': 'negative',
    },
    {
      'id': '4',
      'customerName': 'Emily Davis',
      'rating': 5,
      'comment': 'Amazing customer support! They helped me choose the perfect product.',
      'date': DateTime.now().subtract(const Duration(days: 10)),
      'product': 'Bluetooth Speaker',
      'isResponded': true,
      'response': 'We\'re glad we could help! Thank you for choosing our store.',
      'sentiment': 'positive',
    },
  ];

  @override
  void dispose() {
    _responseController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredReviews {
    switch (_selectedFilter) {
      case 'Positive Reviews':
        return _reviews.where((r) => r['sentiment'] == 'positive').toList();
      case 'Negative Reviews':
        return _reviews.where((r) => r['sentiment'] == 'negative').toList();
      case 'Unresponded':
        return _reviews.where((r) => !r['isResponded']).toList();
      default:
        return _reviews;
    }
  }

  void _showResponseDialog(Map<String, dynamic> review) {
    _responseController.clear();
    if (review['isResponded']) {
      _responseController.text = review['response'];
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.reply, color: Colors.blue, size: 24),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Respond to Review',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _responseController,
                labelText: 'Response',
                hintText: 'Write your response...',
                maxLines: 4,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  CustomButton(
                    onPressed: () {
                      Navigator.pop(context);
                      MessageHelper.showAnimatedMessage(
                        context,
                        message: 'Response submitted successfully!',
                        type: MessageType.success,
                        title: 'Success',
                      );
                    },
                    text: 'Submit Response',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600 && screenWidth < 900;
    final isLargeTablet = screenWidth >= 900;
    final isSmallScreen = screenWidth < 600;
    
    // Enhanced responsive breakpoints
    final isMedium = screenWidth >= 600 && screenWidth < 768;
    final isLarge = screenWidth >= 768 && screenWidth < 1024;
    final isExtraLarge = screenWidth >= 1024;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(isExtraLarge ? 24 : (isLarge ? 20 : (isMedium ? 16 : 12))),
              color: Colors.white,
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(
                          Icons.arrow_back,
                          color: Colors.black87,
                          size: isExtraLarge ? 28 : (isLarge ? 26 : (isMedium ? 24 : 20)),
                        ),
                        tooltip: 'Back',
                      ),
                      SizedBox(width: isExtraLarge ? 8 : (isLarge ? 6 : (isMedium ? 4 : 2))),
                      Expanded(
                        child: Text(
                          'Customer Reviews & Interactions',
                          style: TextStyle(
                            fontSize: isExtraLarge ? 28 : (isLarge ? 26 : (isMedium ? 24 : 20)),
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!isSmallScreen) ...[
                        SizedBox(width: isExtraLarge ? 20 : (isLarge ? 16 : (isMedium ? 12 : 8))),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isExtraLarge ? 16 : (isLarge ? 14 : (isMedium ? 12 : 10)), 
                            vertical: isExtraLarge ? 12 : (isLarge ? 10 : (isMedium ? 8 : 6))
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(isExtraLarge ? 12 : (isLarge ? 10 : (isMedium ? 8 : 6))),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedFilter,
                              isExpanded: false,
                              hint: Text(
                                'Filter reviews',
                                style: TextStyle(
                                  fontSize: isExtraLarge ? 16 : (isLarge ? 15 : (isMedium ? 14 : 12))
                                ),
                              ),
                              items: [
                                DropdownMenuItem(
                                  value: 'All Reviews', 
                                  child: Text(
                                    'All Reviews',
                                    style: TextStyle(
                                      fontSize: isExtraLarge ? 16 : (isLarge ? 15 : (isMedium ? 14 : 12))
                                    ),
                                  )
                                ),
                                DropdownMenuItem(
                                  value: 'Positive Reviews', 
                                  child: Text(
                                    'Positive Reviews',
                                    style: TextStyle(
                                      fontSize: isExtraLarge ? 16 : (isLarge ? 15 : (isMedium ? 14 : 12))
                                    ),
                                  )
                                ),
                                DropdownMenuItem(
                                  value: 'Negative Reviews', 
                                  child: Text(
                                    'Negative Reviews',
                                    style: TextStyle(
                                      fontSize: isExtraLarge ? 16 : (isLarge ? 15 : (isMedium ? 14 : 12))
                                    ),
                                  )
                                ),
                                DropdownMenuItem(
                                  value: 'Unresponded', 
                                  child: Text(
                                    'Unresponded',
                                    style: TextStyle(
                                      fontSize: isExtraLarge ? 16 : (isLarge ? 15 : (isMedium ? 14 : 12))
                                    ),
                                  )
                                ),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedFilter = value!;
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: isExtraLarge ? 20 : (isLarge ? 18 : (isMedium ? 16 : 14))),
                  _buildFilterChips(isSmallScreen, isTablet, isLargeTablet, isMedium, isLarge, isExtraLarge),
                ],
              ),
            ),
            
            Expanded(
              child: _filteredReviews.isEmpty
                  ? _buildEmptyState(isSmallScreen, isTablet, isLargeTablet, isMedium, isLarge, isExtraLarge)
                  : ListView.builder(
                      padding: EdgeInsets.all(isExtraLarge ? 24 : (isLarge ? 20 : (isMedium ? 16 : 12))),
                      itemCount: _filteredReviews.length,
                      itemBuilder: (context, index) {
                        final review = _filteredReviews[index];
                        return _buildReviewCard(review, isSmallScreen, isTablet, isLargeTablet, isMedium, isLarge, isExtraLarge);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips(bool isSmallScreen, bool isTablet, bool isLargeTablet, bool isMedium, bool isLarge, bool isExtraLarge) {
    if (isSmallScreen) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('All Reviews', isSmallScreen, isTablet, isLargeTablet, isMedium, isLarge, isExtraLarge),
            SizedBox(width: isExtraLarge ? 12 : (isLarge ? 10 : (isMedium ? 8 : 6))),
            _buildFilterChip('Positive Reviews', isSmallScreen, isTablet, isLargeTablet, isMedium, isLarge, isExtraLarge),
            SizedBox(width: isExtraLarge ? 12 : (isLarge ? 10 : (isMedium ? 8 : 6))),
            _buildFilterChip('Negative Reviews', isSmallScreen, isTablet, isLargeTablet, isMedium, isLarge, isExtraLarge),
            SizedBox(width: isExtraLarge ? 12 : (isLarge ? 10 : (isMedium ? 8 : 6))),
            _buildFilterChip('Unresponded', isSmallScreen, isTablet, isLargeTablet, isMedium, isLarge, isExtraLarge),
          ],
        ),
      );
    }

    return Wrap(
      spacing: isExtraLarge ? 12 : (isLarge ? 10 : (isMedium ? 8 : 6)),
      runSpacing: isExtraLarge ? 8 : (isLarge ? 6 : (isMedium ? 4 : 2)),
      children: [
        _buildFilterChip('All Reviews', isSmallScreen, isTablet, isLargeTablet, isMedium, isLarge, isExtraLarge),
        _buildFilterChip('Positive Reviews', isSmallScreen, isTablet, isLargeTablet, isMedium, isLarge, isExtraLarge),
        _buildFilterChip('Negative Reviews', isSmallScreen, isTablet, isLargeTablet, isMedium, isLarge, isExtraLarge),
        _buildFilterChip('Unresponded', isSmallScreen, isTablet, isLargeTablet, isMedium, isLarge, isExtraLarge),
      ],
    );
  }

  Widget _buildFilterChip(String label, bool isSmallScreen, bool isTablet, bool isLargeTablet, bool isMedium, bool isLarge, bool isExtraLarge) {
    final isSelected = _selectedFilter == label;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedFilter = label;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isExtraLarge ? 16 : (isLarge ? 14 : (isMedium ? 12 : 8)), 
          vertical: isExtraLarge ? 10 : (isLarge ? 8 : (isMedium ? 6 : 4))
        ),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2979FF) : Colors.transparent,
          border: Border.all(color: isSelected ? const Color(0xFF2979FF) : Colors.grey),
          borderRadius: BorderRadius.circular(isExtraLarge ? 20 : (isLarge ? 18 : (isMedium ? 16 : 12))),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: isExtraLarge ? 16 : (isLarge ? 15 : (isMedium ? 14 : 12)),
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.grey[700],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isSmallScreen, bool isTablet, bool isLargeTablet, bool isMedium, bool isLarge, bool isExtraLarge) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.reviews_outlined,
            size: isExtraLarge ? 80 : (isLarge ? 70 : (isMedium ? 60 : 50)),
            color: Colors.grey[400],
          ),
          SizedBox(height: isExtraLarge ? 24 : (isLarge ? 20 : (isMedium ? 16 : 12))),
          Text(
            'No reviews found',
            style: TextStyle(
              fontSize: isExtraLarge ? 24 : (isLarge ? 22 : (isMedium ? 20 : 18)),
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: isExtraLarge ? 12 : (isLarge ? 10 : (isMedium ? 8 : 6))),
          Text(
            'Try adjusting your filters or check back later',
            style: TextStyle(
              fontSize: isExtraLarge ? 16 : (isLarge ? 15 : (isMedium ? 14 : 12)),
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review, bool isSmallScreen, bool isTablet, bool isLargeTablet, bool isMedium, bool isLarge, bool isExtraLarge) {
    final sentiment = review['sentiment'] as String;
    final rating = review['rating'] as int;
    final isResponded = review['isResponded'] as bool;
    
    return Container(
      margin: EdgeInsets.only(bottom: isExtraLarge ? 20 : (isLarge ? 16 : (isMedium ? 12 : 8))),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isExtraLarge ? 16 : (isLarge ? 14 : (isMedium ? 12 : 8))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isExtraLarge ? 20 : (isLarge ? 16 : (isMedium ? 12 : 8))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review['customerName'] as String,
                        style: TextStyle(
                          fontSize: isExtraLarge ? 18 : (isLarge ? 17 : (isMedium ? 16 : 14)),
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: isExtraLarge ? 4 : 2),
                      Text(
                        review['product'] as String,
                        style: TextStyle(
                          fontSize: isExtraLarge ? 14 : (isLarge ? 13 : (isMedium ? 12 : 10)),
                          color: Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: List.generate(5, (index) {
                        return Icon(
                          index < rating ? Icons.star : Icons.star_border,
                          size: isExtraLarge ? 20 : (isLarge ? 18 : (isMedium ? 16 : 14)),
                          color: index < rating ? Colors.amber : Colors.grey[400],
                        );
                      }),
                    ),
                    SizedBox(height: isExtraLarge ? 4 : 2),
                    Text(
                      _formatDate(review['date'] as DateTime),
                      style: TextStyle(
                        fontSize: isExtraLarge ? 12 : (isLarge ? 11 : (isMedium ? 10 : 9)),
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: isExtraLarge ? 16 : (isLarge ? 14 : (isMedium ? 12 : 10))),
            Container(
              padding: EdgeInsets.all(isExtraLarge ? 16 : (isLarge ? 14 : (isMedium ? 12 : 8))),
              decoration: BoxDecoration(
                color: _getSentimentColor(sentiment).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(isExtraLarge ? 12 : (isLarge ? 10 : (isMedium ? 8 : 6))),
                border: Border.all(
                  color: _getSentimentColor(sentiment).withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                review['comment'] as String,
                style: TextStyle(
                  fontSize: isExtraLarge ? 16 : (isLarge ? 15 : (isMedium ? 14 : 12)),
                  color: Colors.black87,
                  height: 1.4,
                ),
              ),
            ),
            if (isResponded) ...[
              SizedBox(height: isExtraLarge ? 16 : (isLarge ? 14 : (isMedium ? 12 : 10))),
              Container(
                padding: EdgeInsets.all(isExtraLarge ? 16 : (isLarge ? 14 : (isMedium ? 12 : 8))),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(isExtraLarge ? 12 : (isLarge ? 10 : (isMedium ? 8 : 6))),
                  border: Border.all(
                    color: Colors.blue.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.reply,
                          size: isExtraLarge ? 18 : (isLarge ? 16 : (isMedium ? 14 : 12)),
                          color: Colors.blue,
                        ),
                        SizedBox(width: isExtraLarge ? 8 : (isLarge ? 6 : (isMedium ? 4 : 2))),
                        Text(
                          'Your Response',
                          style: TextStyle(
                            fontSize: isExtraLarge ? 14 : (isLarge ? 13 : (isMedium ? 12 : 10)),
                            fontWeight: FontWeight.w600,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isExtraLarge ? 8 : (isLarge ? 6 : (isMedium ? 4 : 2))),
                    Text(
                      review['response'] as String,
                      style: TextStyle(
                        fontSize: isExtraLarge ? 14 : (isLarge ? 13 : (isMedium ? 12 : 10)),
                        color: Colors.black87,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            SizedBox(height: isExtraLarge ? 16 : (isLarge ? 14 : (isMedium ? 12 : 10))),
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    onPressed: () => _showResponseDialog(review),
                    text: isResponded ? 'Edit Response' : 'Respond',
                    backgroundColor: isResponded ? Colors.orange : const Color(0xFF2979FF),
                  ),
                ),
                if (isSmallScreen) ...[
                  SizedBox(width: isExtraLarge ? 12 : (isLarge ? 10 : (isMedium ? 8 : 6))),
                  Container(
                    padding: EdgeInsets.all(isExtraLarge ? 12 : (isLarge ? 10 : (isMedium ? 8 : 6))),
                    decoration: BoxDecoration(
                      color: _getSentimentColor(sentiment).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(isExtraLarge ? 8 : (isLarge ? 6 : (isMedium ? 4 : 2))),
                    ),
                    child: Text(
                      sentiment.toUpperCase(),
                      style: TextStyle(
                        fontSize: isExtraLarge ? 12 : (isLarge ? 11 : (isMedium ? 10 : 9)),
                        fontWeight: FontWeight.w600,
                        color: _getSentimentColor(sentiment),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            if (!isSmallScreen) ...[
              SizedBox(height: isExtraLarge ? 12 : (isLarge ? 10 : (isMedium ? 8 : 6))),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: EdgeInsets.all(isExtraLarge ? 12 : (isLarge ? 10 : (isMedium ? 8 : 6))),
                    decoration: BoxDecoration(
                      color: _getSentimentColor(sentiment).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(isExtraLarge ? 8 : (isLarge ? 6 : (isMedium ? 4 : 2))),
                    ),
                    child: Text(
                      sentiment.toUpperCase(),
                      style: TextStyle(
                        fontSize: isExtraLarge ? 12 : (isLarge ? 11 : (isMedium ? 10 : 9)),
                        fontWeight: FontWeight.w600,
                        color: _getSentimentColor(sentiment),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Color _getSentimentColor(String sentiment) {
    switch (sentiment.toLowerCase()) {
      case 'positive':
        return Colors.green;
      case 'negative':
        return Colors.red;
      case 'neutral':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
