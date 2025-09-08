// ignore_for_file: unused_element
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class AIInsightsScreen extends StatefulWidget {
  const AIInsightsScreen({super.key});

  @override
  State<AIInsightsScreen> createState() => _AIInsightsScreenState();
}

class _AIInsightsScreenState extends State<AIInsightsScreen> {
  String _selectedInsight = 'Pricing Trends';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2979FF),
        elevation: 0,
        title: const Text('AI Insights', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.psychology, size: 72, color: Colors.grey[400]),
              const SizedBox(height: 16),
              const Text(
                'AI Insights Coming Soon',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Insights will appear here when available.',
                style: TextStyle(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInsightTabs(bool isSmallScreen, bool isTablet, bool isLargeTablet, bool isMedium, bool isLarge, bool isExtraLarge) {
    if (isSmallScreen) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildInsightTab('Pricing Trends', isSmallScreen, isTablet, isLargeTablet, isMedium, isLarge, isExtraLarge),
            SizedBox(width: isExtraLarge ? 12 : (isLarge ? 10 : (isMedium ? 8 : 6))),
            _buildInsightTab('Customer Behavior', isSmallScreen, isTablet, isLargeTablet, isMedium, isLarge, isExtraLarge),
            SizedBox(width: isExtraLarge ? 12 : (isLarge ? 10 : (isMedium ? 8 : 6))),
            _buildInsightTab('Market Analysis', isSmallScreen, isTablet, isLargeTablet, isMedium, isLarge, isExtraLarge),
            SizedBox(width: isExtraLarge ? 12 : (isLarge ? 10 : (isMedium ? 8 : 6))),
            _buildInsightTab('Optimization Tips', isSmallScreen, isTablet, isLargeTablet, isMedium, isLarge, isExtraLarge),
          ],
        ),
      );
    }

    return Wrap(
      spacing: isExtraLarge ? 12 : (isLarge ? 10 : (isMedium ? 8 : 6)),
      runSpacing: isExtraLarge ? 8 : (isLarge ? 6 : (isMedium ? 4 : 2)),
      children: [
        _buildInsightTab('Pricing Trends', isSmallScreen, isTablet, isLargeTablet, isMedium, isLarge, isExtraLarge),
        _buildInsightTab('Customer Behavior', isSmallScreen, isTablet, isLargeTablet, isMedium, isLarge, isExtraLarge),
        _buildInsightTab('Market Analysis', isSmallScreen, isTablet, isLargeTablet, isMedium, isLarge, isExtraLarge),
        _buildInsightTab('Optimization Tips', isSmallScreen, isTablet, isLargeTablet, isMedium, isLarge, isExtraLarge),
      ],
    );
  }

  Widget _buildInsightTab(String title, bool isSmallScreen, bool isTablet, bool isLargeTablet, bool isMedium, bool isLarge, bool isExtraLarge) {
    final isSelected = _selectedInsight == title;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedInsight = title;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isExtraLarge ? 16 : (isLarge ? 14 : (isMedium ? 12 : 8)), 
          vertical: isExtraLarge ? 12 : (isLarge ? 10 : (isMedium ? 8 : 6))
        ),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2979FF) : Colors.transparent,
          border: Border.all(color: isSelected ? const Color(0xFF2979FF) : Colors.grey),
          borderRadius: BorderRadius.circular(isExtraLarge ? 20 : (isLarge ? 18 : (isMedium ? 16 : 12))),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: isExtraLarge ? 16 : (isLarge ? 15 : (isMedium ? 14 : 12)),
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.grey[700],
          ),
        ),
      ),
    );
  }

  Widget _buildInsightContent(bool isSmallScreen, bool isTablet, bool isLargeTablet, bool isMedium, bool isLarge, bool isExtraLarge) {
    switch (_selectedInsight) {
      case 'Pricing Trends':
        return _buildPricingTrends(isSmallScreen, isTablet, isLargeTablet, isMedium, isLarge, isExtraLarge);
      case 'Customer Behavior':
        return _buildCustomerBehavior(isSmallScreen, isTablet, isLargeTablet, isMedium, isLarge, isExtraLarge);
      case 'Market Analysis':
        return _buildMarketAnalysis(isSmallScreen, isTablet, isLargeTablet, isMedium, isLarge, isExtraLarge);
      case 'Optimization Tips':
        return _buildOptimizationTips(isSmallScreen, isTablet, isLargeTablet, isMedium, isLarge, isExtraLarge);
      default:
        return _buildPricingTrends(isSmallScreen, isTablet, isLargeTablet, isMedium, isLarge, isExtraLarge);
    }
  }

  Widget _buildPricingTrends(bool isSmallScreen, bool isTablet, bool isLargeTablet, bool isMedium, bool isLarge, bool isExtraLarge) {
    return Container(
      padding: EdgeInsets.all(isExtraLarge ? 24 : (isLarge ? 20 : (isMedium ? 16 : 12))),
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
            children: [
              Icon(Icons.trending_up, color: Colors.blue, size: isExtraLarge ? 28 : (isLarge ? 26 : (isMedium ? 24 : 20))),
              SizedBox(width: isExtraLarge ? 16 : (isLarge ? 12 : (isMedium ? 12 : 8))),
              Expanded(
                child: Text(
                  'Competitor Pricing Analysis',
                  style: TextStyle(
                    fontSize: isExtraLarge ? 20 : (isLarge ? 18 : (isMedium ? 16 : 16)),
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isExtraLarge ? 24 : (isLarge ? 20 : (isMedium ? 16 : 12))),
          SizedBox(
            height: isExtraLarge ? 250 : (isLarge ? 220 : (isMedium ? 200 : 200)),
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: isExtraLarge ? 50 : (isLarge ? 45 : (isMedium ? 40 : 40)),
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '\$${value.toInt()}',
                          style: TextStyle(fontSize: isExtraLarge ? 14 : (isLarge ? 12 : (isMedium ? 10 : 10))),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
                        if (value.toInt() >= 0 && value.toInt() < months.length) {
                          return Text(
                            months[value.toInt()],
                            style: TextStyle(fontSize: isExtraLarge ? 14 : (isLarge ? 12 : (isMedium ? 10 : 10))),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: true),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 120),
                      FlSpot(1, 125),
                      FlSpot(2, 118),
                      FlSpot(3, 130),
                      FlSpot(4, 128),
                      FlSpot(5, 135),
                    ],
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 3,
                    dotData: FlDotData(show: true),
                  ),
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 110),
                      FlSpot(1, 115),
                      FlSpot(2, 108),
                      FlSpot(3, 120),
                      FlSpot(4, 118),
                      FlSpot(5, 125),
                    ],
                    isCurved: true,
                    color: Colors.red,
                    barWidth: 3,
                    dotData: FlDotData(show: true),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: isExtraLarge ? 20 : (isLarge ? 16 : (isMedium ? 12 : 12))),
          Wrap(
            spacing: isExtraLarge ? 24 : (isLarge ? 20 : (isMedium ? 16 : 12)),
            runSpacing: 8,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: isExtraLarge ? 12 : (isLarge ? 8 : (isMedium ? 6 : 6))),
                  Text(
                    'Your Prices',
                    style: TextStyle(fontSize: isExtraLarge ? 16 : (isLarge ? 14 : (isMedium ? 12 : 12))),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: isExtraLarge ? 12 : (isLarge ? 8 : (isMedium ? 6 : 6))),
                  Text(
                    'Competitor Prices',
                    style: TextStyle(fontSize: isExtraLarge ? 16 : (isLarge ? 14 : (isMedium ? 12 : 12))),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: isExtraLarge ? 24 : (isLarge ? 20 : (isMedium ? 16 : 12))),
          Container(
            padding: EdgeInsets.all(isExtraLarge ? 20 : (isLarge ? 16 : (isMedium ? 12 : 12))),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lightbulb, color: Colors.blue, size: isExtraLarge ? 24 : (isLarge ? 20 : (isMedium ? 18 : 18))),
                    SizedBox(width: isExtraLarge ? 12 : (isLarge ? 8 : (isMedium ? 6 : 6))),
                    Text(
                      'Key Insight',
                      style: TextStyle(
                        fontSize: isExtraLarge ? 18 : (isLarge ? 16 : (isMedium ? 14 : 14)),
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isExtraLarge ? 16 : (isLarge ? 12 : (isMedium ? 8 : 8))),
                Text(
                  'Your pricing strategy is competitive and well-positioned in the market. Consider implementing dynamic pricing during peak seasons to maximize revenue.',
                  style: TextStyle(
                    fontSize: isExtraLarge ? 16 : (isLarge ? 14 : (isMedium ? 12 : 12)),
                    color: Colors.blue,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerBehavior(bool isSmallScreen, bool isTablet, bool isLargeTablet, bool isMedium, bool isLarge, bool isExtraLarge) {
    return Container(
      padding: EdgeInsets.all(isExtraLarge ? 24 : (isLarge ? 20 : (isMedium ? 16 : 12))),
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
            children: [
              Icon(Icons.people, color: Colors.green, size: isExtraLarge ? 28 : (isLarge ? 26 : (isMedium ? 24 : 20))),
              SizedBox(width: isExtraLarge ? 16 : (isLarge ? 12 : (isMedium ? 12 : 8))),
              Expanded(
                child: Text(
                  'Customer Activity Patterns',
                  style: TextStyle(
                    fontSize: isExtraLarge ? 20 : (isLarge ? 18 : (isMedium ? 16 : 16)),
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isExtraLarge ? 24 : (isLarge ? 20 : (isMedium ? 16 : 12))),
          SizedBox(
            height: isExtraLarge ? 250 : (isLarge ? 220 : (isMedium ? 200 : 200)),
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 100,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: isExtraLarge ? 50 : (isLarge ? 45 : (isMedium ? 40 : 40)),
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}%',
                          style: TextStyle(fontSize: isExtraLarge ? 14 : (isLarge ? 12 : (isMedium ? 10 : 10))),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                        if (value.toInt() >= 0 && value.toInt() < days.length) {
                          return Text(
                            days[value.toInt()],
                            style: TextStyle(fontSize: isExtraLarge ? 14 : (isLarge ? 12 : (isMedium ? 10 : 10))),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                barGroups: [
                  BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 65, color: Colors.green)]),
                  BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 75, color: Colors.green)]),
                  BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 70, color: Colors.green)]),
                  BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 80, color: Colors.green)]),
                  BarChartGroupData(x: 4, barRods: [BarChartRodData(toY: 85, color: Colors.green)]),
                  BarChartGroupData(x: 5, barRods: [BarChartRodData(toY: 90, color: Colors.green)]),
                  BarChartGroupData(x: 6, barRods: [BarChartRodData(toY: 95, color: Colors.green)]),
                ],
              ),
            ),
          ),
          SizedBox(height: isExtraLarge ? 20 : (isLarge ? 16 : (isMedium ? 12 : 12))),
          Container(
            padding: EdgeInsets.all(isExtraLarge ? 20 : (isLarge ? 16 : (isMedium ? 12 : 12))),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.schedule, color: Colors.green, size: isExtraLarge ? 20 : (isLarge ? 18 : (isMedium ? 16 : 16))),
                    SizedBox(width: isExtraLarge ? 12 : (isLarge ? 8 : (isMedium ? 6 : 6))),
                    Text(
                      'Peak Activity Times',
                      style: TextStyle(
                        fontSize: isExtraLarge ? 16 : (isLarge ? 14 : (isMedium ? 12 : 12)),
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isExtraLarge ? 16 : (isLarge ? 12 : (isMedium ? 8 : 8))),
                Text(
                  '• Weekends (Saturday-Sunday): Highest customer activity\n• Friday: Second highest activity day\n• Best time for promotions: Friday 2PM - Sunday 8PM',
                  style: TextStyle(
                    fontSize: isExtraLarge ? 16 : (isLarge ? 14 : (isMedium ? 12 : 12)),
                    color: Colors.green,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarketAnalysis(bool isSmallScreen, bool isTablet, bool isLargeTablet, bool isMedium, bool isLarge, bool isExtraLarge) {
    return Container(
      padding: EdgeInsets.all(isExtraLarge ? 24 : (isLarge ? 20 : (isMedium ? 16 : 12))),
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
            children: [
              Icon(Icons.analytics, color: Colors.orange, size: isExtraLarge ? 28 : (isLarge ? 26 : (isMedium ? 24 : 20))),
              SizedBox(width: isExtraLarge ? 16 : (isLarge ? 12 : (isMedium ? 12 : 8))),
              Expanded(
                child: Text(
                  'Market Trends & Opportunities',
                  style: TextStyle(
                    fontSize: isExtraLarge ? 20 : (isLarge ? 18 : (isMedium ? 16 : 16)),
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isExtraLarge ? 24 : (isLarge ? 20 : (isMedium ? 16 : 12))),
          _buildMarketTrendCard(
            'Electronics Demand',
            '+15%',
            'Growing demand for wireless accessories',
            Colors.green,
            Icons.trending_up,
            isSmallScreen, isTablet, isLargeTablet, isMedium, isLarge, isExtraLarge,
          ),
          SizedBox(height: isExtraLarge ? 16 : (isLarge ? 12 : (isMedium ? 8 : 8))),
          _buildMarketTrendCard(
            'Competition Level',
            'High',
            '5 new competitors in your area',
            Colors.orange,
            Icons.warning,
            isSmallScreen, isTablet, isLargeTablet, isMedium, isLarge, isExtraLarge,
          ),
          SizedBox(height: isExtraLarge ? 16 : (isLarge ? 12 : (isMedium ? 8 : 8))),
          _buildMarketTrendCard(
            'Seasonal Impact',
            'Peak Season',
            'Holiday season approaching - prepare inventory',
            Colors.blue,
            Icons.calendar_today,
            isSmallScreen, isTablet, isLargeTablet, isMedium, isLarge, isExtraLarge,
          ),
          SizedBox(height: isExtraLarge ? 24 : (isLarge ? 20 : (isMedium ? 16 : 12))),
          Container(
            padding: EdgeInsets.all(isExtraLarge ? 20 : (isLarge ? 16 : (isMedium ? 12 : 12))),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.insights, color: Colors.orange, size: isExtraLarge ? 20 : (isLarge ? 18 : (isMedium ? 16 : 16))),
                    SizedBox(width: isExtraLarge ? 12 : (isLarge ? 8 : (isMedium ? 6 : 6))),
                    Text(
                      'Market Opportunity',
                      style: TextStyle(
                        fontSize: isExtraLarge ? 16 : (isLarge ? 14 : (isMedium ? 12 : 12)),
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isExtraLarge ? 16 : (isLarge ? 12 : (isMedium ? 8 : 8))),
                Text(
                  'The electronics market in your area is growing rapidly. Consider expanding your product range to include smart home devices and gaming accessories.',
                  style: TextStyle(
                    fontSize: isExtraLarge ? 16 : (isLarge ? 14 : (isMedium ? 12 : 12)),
                    color: Colors.orange,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarketTrendCard(String title, String value, String description, Color color, IconData icon, bool isSmallScreen, bool isTablet, bool isLargeTablet, bool isMedium, bool isLarge, bool isExtraLarge) {
    return Container(
      padding: EdgeInsets.all(isExtraLarge ? 20 : (isLarge ? 16 : (isMedium ? 12 : 12))),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: isExtraLarge ? 28 : (isLarge ? 26 : (isMedium ? 24 : 20))),
          SizedBox(width: isExtraLarge ? 20 : (isLarge ? 16 : (isMedium ? 12 : 12))),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: isExtraLarge ? 18 : (isLarge ? 16 : (isMedium ? 14 : 14)),
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                SizedBox(height: isExtraLarge ? 8 : (isLarge ? 6 : (isMedium ? 4 : 4))),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: isExtraLarge ? 16 : (isLarge ? 14 : (isMedium ? 12 : 12)),
                    color: color.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: isExtraLarge ? 16 : (isLarge ? 14 : (isMedium ? 12 : 10)), vertical: isExtraLarge ? 10 : (isLarge ? 8 : (isMedium ? 6 : 6))),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: isExtraLarge ? 16 : (isLarge ? 14 : (isMedium ? 12 : 12)),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptimizationTips(bool isSmallScreen, bool isTablet, bool isLargeTablet, bool isMedium, bool isLarge, bool isExtraLarge) {
    return Container(
      padding: EdgeInsets.all(isExtraLarge ? 24 : (isLarge ? 20 : (isMedium ? 16 : 12))),
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
            children: [
              Icon(Icons.lightbulb, color: Colors.purple, size: isExtraLarge ? 28 : (isLarge ? 26 : (isMedium ? 24 : 20))),
              SizedBox(width: isExtraLarge ? 16 : (isLarge ? 12 : (isMedium ? 12 : 8))),
              Expanded(
                child: Text(
                  'AI-Powered Optimization Tips',
                  style: TextStyle(
                    fontSize: isExtraLarge ? 20 : (isLarge ? 18 : (isMedium ? 16 : 16)),
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isExtraLarge ? 24 : (isLarge ? 20 : (isMedium ? 16 : 12))),
          _buildTipCard(
            'Pricing Strategy',
            'Adjust your wireless headphones pricing to \$89.99 to match market average and increase competitiveness.',
            Colors.blue,
            'High Priority',
            isSmallScreen, isTablet, isLargeTablet, isMedium, isLarge, isExtraLarge,
          ),
          SizedBox(height: isExtraLarge ? 16 : (isLarge ? 12 : (isMedium ? 8 : 8))),
          _buildTipCard(
            'Inventory Management',
            'Increase stock of smartphone cases by 30% based on growing demand trends.',
            Colors.green,
            'Medium Priority',
            isSmallScreen, isTablet, isLargeTablet, isMedium, isLarge, isExtraLarge,
          ),
          SizedBox(height: isExtraLarge ? 16 : (isLarge ? 12 : (isMedium ? 8 : 8))),
          _buildTipCard(
            'Promotion Timing',
            'Schedule your next promotion for Friday 2PM to Sunday 8PM for maximum customer engagement.',
            Colors.orange,
            'High Priority',
            isSmallScreen, isTablet, isLargeTablet, isMedium, isLarge, isExtraLarge,
          ),
          SizedBox(height: isExtraLarge ? 16 : (isLarge ? 12 : (isMedium ? 8 : 8))),
          _buildTipCard(
            'Product Placement',
            'Feature wireless headphones prominently on your homepage as they have the highest conversion rate.',
            Colors.purple,
            'Medium Priority',
            isSmallScreen, isTablet, isLargeTablet, isMedium, isLarge, isExtraLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildTipCard(String title, String description, Color color, String priority, bool isSmallScreen, bool isTablet, bool isLargeTablet, bool isMedium, bool isLarge, bool isExtraLarge) {
    return Container(
      padding: EdgeInsets.all(isExtraLarge ? 20 : (isLarge ? 16 : (isMedium ? 12 : 12))),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: isExtraLarge ? 18 : (isLarge ? 16 : (isMedium ? 14 : 14)),
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: isExtraLarge ? 12 : (isLarge ? 10 : (isMedium ? 8 : 6)), vertical: isExtraLarge ? 8 : (isLarge ? 6 : (isMedium ? 4 : 4))),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  priority,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isExtraLarge ? 14 : (isLarge ? 12 : (isMedium ? 10 : 10)),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isExtraLarge ? 16 : (isLarge ? 12 : (isMedium ? 8 : 8))),
          Text(
            description,
            style: TextStyle(
              fontSize: isExtraLarge ? 16 : (isLarge ? 14 : (isMedium ? 12 : 12)),
              color: color.withValues(alpha: 0.8),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsSection(bool isSmallScreen, bool isTablet, bool isLargeTablet, bool isMedium, bool isLarge, bool isExtraLarge) {
    return Container(
      padding: EdgeInsets.all(isExtraLarge ? 24 : (isLarge ? 20 : (isMedium ? 16 : 12))),
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
            children: [
              Icon(Icons.auto_awesome, color: Colors.amber, size: isExtraLarge ? 28 : (isLarge ? 26 : (isMedium ? 24 : 20))),
              SizedBox(width: isExtraLarge ? 16 : (isLarge ? 12 : (isMedium ? 12 : 8))),
              Expanded(
                child: Text(
                  'AI Recommendations',
                  style: TextStyle(
                    fontSize: isExtraLarge ? 20 : (isLarge ? 18 : (isMedium ? 16 : 16)),
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isExtraLarge ? 24 : (isLarge ? 20 : (isMedium ? 16 : 12))),
          Container(
            padding: EdgeInsets.all(isExtraLarge ? 20 : (isLarge ? 16 : (isMedium ? 12 : 12))),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.amber.withValues(alpha: 0.1), Colors.orange.withValues(alpha: 0.1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.star, color: Colors.amber, size: isExtraLarge ? 20 : (isLarge ? 18 : (isMedium ? 16 : 16))),
                    SizedBox(width: isExtraLarge ? 12 : (isLarge ? 8 : (isMedium ? 6 : 6))),
                    Text(
                      'Top Recommendation',
                      style: TextStyle(
                        fontSize: isExtraLarge ? 16 : (isLarge ? 14 : (isMedium ? 12 : 12)),
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isExtraLarge ? 16 : (isLarge ? 12 : (isMedium ? 8 : 8))),
                Text(
                  'Based on AI analysis, implementing these optimizations could increase your revenue by 18-25% within the next quarter. Focus on pricing strategy and inventory management for immediate impact.',
                  style: TextStyle(
                    fontSize: isExtraLarge ? 16 : (isLarge ? 14 : (isMedium ? 12 : 12)),
                    color: Colors.amber,
                    height: 1.4,
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
