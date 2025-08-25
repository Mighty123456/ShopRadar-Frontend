import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class AnalyticsDashboardScreen extends StatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  State<AnalyticsDashboardScreen> createState() => _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  String _selectedPeriod = 'Last 7 Days';
  String _selectedMetric = 'Views';

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 900;
    final isLargeTablet = screenWidth >= 900;
    
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
                      Expanded(
                        child: Text(
                          'Analytics Dashboard',
                          style: TextStyle(
                            fontSize: isExtraLarge ? 28 : (isLarge ? 26 : (isMedium ? 24 : 20)),
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!isSmallScreen) ...[
                        const SizedBox(width: 16),
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
                              value: _selectedPeriod,
                              isExpanded: false,
                              hint: Text(
                                'Select period',
                                style: TextStyle(
                                  fontSize: isExtraLarge ? 16 : (isLarge ? 15 : (isMedium ? 14 : 12))
                                ),
                              ),
                              items: [
                                DropdownMenuItem(
                                  value: 'Last 7 Days', 
                                  child: Text(
                                    'Last 7 Days',
                                    style: TextStyle(
                                      fontSize: isExtraLarge ? 16 : (isLarge ? 15 : (isMedium ? 14 : 12))
                                    ),
                                  )
                                ),
                                DropdownMenuItem(
                                  value: 'Last 30 Days', 
                                  child: Text(
                                    'Last 30 Days',
                                    style: TextStyle(
                                      fontSize: isExtraLarge ? 16 : (isLarge ? 15 : (isMedium ? 14 : 12))
                                    ),
                                  )
                                ),
                                DropdownMenuItem(
                                  value: 'Last 3 Months', 
                                  child: Text(
                                    'Last 3 Months',
                                    style: TextStyle(
                                      fontSize: isExtraLarge ? 16 : (isLarge ? 15 : (isMedium ? 14 : 12))
                                    ),
                                  )
                                ),
                                DropdownMenuItem(
                                  value: 'Last Year', 
                                  child: Text(
                                    'Last Year',
                                    style: TextStyle(
                                      fontSize: isExtraLarge ? 16 : (isLarge ? 15 : (isMedium ? 14 : 12))
                                    ),
                                  )
                                ),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedPeriod = value!;
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: isExtraLarge ? 20 : (isLarge ? 18 : (isMedium ? 16 : 14))),
                  _buildMetricSelector(isSmallScreen, isTablet, isLargeTablet, isMedium, isLarge, isExtraLarge),
                ],
              ),
            ),
            
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isExtraLarge ? 24 : (isLarge ? 20 : (isMedium ? 16 : 12))),
                child: Column(
                  children: [
                    _buildOverviewCards(isSmallScreen, isTablet, isLargeTablet, isMedium, isLarge, isExtraLarge),
                    SizedBox(height: isExtraLarge ? 32 : (isLarge ? 28 : (isMedium ? 24 : 20))),
                    _buildChartSection(isSmallScreen, isTablet, isLargeTablet, isMedium, isLarge, isExtraLarge),
                    SizedBox(height: isExtraLarge ? 32 : (isLarge ? 28 : (isMedium ? 24 : 20))),
                    _buildTopProductsSection(isSmallScreen, isTablet, isLargeTablet, isMedium, isLarge, isExtraLarge),
                    SizedBox(height: isExtraLarge ? 32 : (isLarge ? 28 : (isMedium ? 24 : 20))),
                    _buildCustomerInsightsSection(isSmallScreen, isTablet, isLargeTablet, isMedium, isLarge, isExtraLarge),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricSelector(bool isSmallScreen, bool isTablet, bool isLargeTablet, bool isMedium, bool isLarge, bool isExtraLarge) {
    // For small screens, make it scrollable horizontally
    if (isSmallScreen) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildMetricChip('Views', Icons.visibility, Colors.blue, isSmallScreen, isTablet, isLargeTablet, isMedium, isLarge, isExtraLarge),
            SizedBox(width: isExtraLarge ? 16 : (isLarge ? 14 : (isMedium ? 12 : 8))),
            _buildMetricChip('Clicks', Icons.touch_app, Colors.green, isSmallScreen, isTablet, isLargeTablet, isMedium, isLarge, isExtraLarge),
            SizedBox(width: isExtraLarge ? 16 : (isLarge ? 14 : (isMedium ? 12 : 8))),
            _buildMetricChip('Saves', Icons.bookmark, Colors.orange, isSmallScreen, isTablet, isLargeTablet, isMedium, isLarge, isExtraLarge),
            SizedBox(width: isExtraLarge ? 16 : (isLarge ? 14 : (isMedium ? 12 : 8))),
            _buildMetricChip('Sales', Icons.shopping_cart, Colors.purple, isSmallScreen, isTablet, isLargeTablet, isMedium, isLarge, isExtraLarge),
          ],
        ),
      );
    }

    return Row(
      children: [
        _buildMetricChip('Views', Icons.visibility, Colors.blue, isSmallScreen, isTablet, isLargeTablet, isMedium, isLarge, isExtraLarge),
        SizedBox(width: isExtraLarge ? 16 : (isLarge ? 14 : (isMedium ? 12 : 8))),
        _buildMetricChip('Clicks', Icons.touch_app, Colors.green, isSmallScreen, isTablet, isLargeTablet, isMedium, isLarge, isExtraLarge),
        SizedBox(width: isExtraLarge ? 16 : (isLarge ? 14 : (isMedium ? 12 : 8))),
        _buildMetricChip('Saves', Icons.bookmark, Colors.orange, isSmallScreen, isTablet, isLargeTablet, isMedium, isLarge, isExtraLarge),
        SizedBox(width: isExtraLarge ? 16 : (isLarge ? 14 : (isMedium ? 12 : 8))),
        _buildMetricChip('Sales', Icons.shopping_cart, Colors.purple, isSmallScreen, isTablet, isLargeTablet, isMedium, isLarge, isExtraLarge),
      ],
    );
  }

  Widget _buildMetricChip(String label, IconData icon, Color color, bool isSmallScreen, bool isTablet, bool isLargeTablet, bool isMedium, bool isLarge, bool isExtraLarge) {
    final isSelected = _selectedMetric == label;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedMetric = label;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isExtraLarge ? 16 : (isLarge ? 14 : (isMedium ? 12 : 8)), 
          vertical: isExtraLarge ? 12 : (isLarge ? 10 : (isMedium ? 8 : 6))
        ),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          border: Border.all(color: isSelected ? color : Colors.grey),
          borderRadius: BorderRadius.circular(isExtraLarge ? 24 : (isLarge ? 22 : (isMedium ? 20 : 16))),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: isExtraLarge ? 20 : (isLarge ? 18 : (isMedium ? 16 : 14)),
              color: isSelected ? Colors.white : color,
            ),
            SizedBox(width: isExtraLarge ? 8 : (isLarge ? 7 : (isMedium ? 6 : 4))),
            Text(
              label,
              style: TextStyle(
                fontSize: isExtraLarge ? 16 : (isLarge ? 15 : (isMedium ? 14 : 12)),
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCards(bool isSmallScreen, bool isTablet, bool isLargeTablet, bool isMedium, bool isLarge, bool isExtraLarge) {
    // Responsive grid layout
    int crossAxisCount;
    if (isExtraLarge) {
      crossAxisCount = 4;
    } else if (isLarge) {
      crossAxisCount = 3;
    } else if (isMedium) {
      crossAxisCount = 2;
    } else {
      crossAxisCount = 2;
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: isExtraLarge ? 20 : (isLarge ? 16 : (isMedium ? 12 : 8)),
      mainAxisSpacing: isExtraLarge ? 20 : (isLarge ? 16 : (isMedium ? 12 : 8)),
      childAspectRatio: isExtraLarge ? 1.4 : (isLarge ? 1.3 : (isMedium ? 1.2 : 1.1)),
      children: [
        _buildOverviewCard(
          'Total Views',
          '0',
          '0%',
          Icons.visibility,
          Colors.blue,
          true,
          isSmallScreen,
          isTablet,
          isLargeTablet,
          isMedium,
          isLarge,
          isExtraLarge,
        ),
        _buildOverviewCard(
          'Total Clicks',
          '0',
          '0%',
          Icons.touch_app,
          Colors.green,
          true,
          isSmallScreen,
          isTablet,
          isLargeTablet,
          isMedium,
          isLarge,
          isExtraLarge,
        ),
        _buildOverviewCard(
          'Total Saves',
          '0',
          '0%',
          Icons.bookmark,
          Colors.orange,
          true,
          isSmallScreen,
          isTablet,
          isLargeTablet,
          isMedium,
          isLarge,
          isExtraLarge,
        ),
        _buildOverviewCard(
          'Conversion Rate',
          '0%',
          '0%',
          Icons.trending_up,
          Colors.purple,
          false,
          isSmallScreen,
          isTablet,
          isLargeTablet,
          isMedium,
          isLarge,
          isExtraLarge,
        ),
      ],
    );
  }

  Widget _buildOverviewCard(String title, String value, String change, IconData icon, Color color, bool isPositive, bool isSmallScreen, bool isTablet, bool isLargeTablet, bool isMedium, bool isLarge, bool isExtraLarge) {
    return Container(
      padding: EdgeInsets.all(isExtraLarge ? 20 : (isLarge ? 16 : (isMedium ? 12 : 8))),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: isExtraLarge ? 32 : (isLarge ? 28 : (isMedium ? 24 : 20)),
                color: color,
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isExtraLarge ? 8 : (isLarge ? 6 : (isMedium ? 4 : 2)), 
                  vertical: isExtraLarge ? 4 : (isLarge ? 3 : (isMedium ? 2 : 1))
                ),
                decoration: BoxDecoration(
                  color: isPositive ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(isExtraLarge ? 12 : (isLarge ? 10 : (isMedium ? 8 : 4))),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPositive ? Icons.trending_up : Icons.trending_down,
                      size: isExtraLarge ? 16 : (isLarge ? 14 : (isMedium ? 12 : 10)),
                      color: isPositive ? Colors.green : Colors.red,
                    ),
                    SizedBox(width: isExtraLarge ? 4 : 2),
                    Text(
                      change,
                      style: TextStyle(
                        fontSize: isExtraLarge ? 14 : (isLarge ? 13 : (isMedium ? 12 : 10)),
                        fontWeight: FontWeight.w600,
                        color: isPositive ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: isExtraLarge ? 16 : (isLarge ? 14 : (isMedium ? 12 : 10))),
          Text(
            value,
            style: TextStyle(
              fontSize: isExtraLarge ? 32 : (isLarge ? 28 : (isMedium ? 24 : 20)),
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: isExtraLarge ? 8 : (isLarge ? 6 : (isMedium ? 4 : 2))),
          Text(
            title,
            style: TextStyle(
              fontSize: isExtraLarge ? 16 : (isLarge ? 15 : (isMedium ? 14 : 12)),
              color: Colors.grey,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildChartSection(bool isSmallScreen, bool isTablet, bool isLargeTablet, bool isMedium, bool isLarge, bool isExtraLarge) {
    return Container(
      padding: EdgeInsets.all(isExtraLarge ? 20 : (isLarge ? 20 : (isMedium ? 16 : 12))),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isExtraLarge ? 12 : (isLarge ? 12 : (isMedium ? 10 : 8))),
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
          Text(
            '$_selectedMetric Over Time',
            style: TextStyle(
              fontSize: isExtraLarge ? 18 : (isLarge ? 17 : (isMedium ? 16 : 14)),
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: isExtraLarge ? 20 : (isLarge ? 18 : (isMedium ? 16 : 14))),
          SizedBox(
            height: isExtraLarge ? 200 : (isLarge ? 180 : (isMedium ? 160 : 140)),
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(fontSize: isExtraLarge ? 12 : (isLarge ? 11 : (isMedium ? 10 : 9))),
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
                            style: TextStyle(fontSize: isExtraLarge ? 12 : (isLarge ? 11 : (isMedium ? 10 : 9))),
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
                    spots: _getChartData(),
                    isCurved: true,
                    color: const Color(0xFF2979FF),
                    barWidth: 3,
                    dotData: FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF2979FF).withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<FlSpot> _getChartData() {
    switch (_selectedMetric) {
      case 'Views':
        return [
          const FlSpot(0, 0),
          const FlSpot(1, 0),
          const FlSpot(2, 0),
          const FlSpot(3, 0),
          const FlSpot(4, 0),
          const FlSpot(5, 0),
          const FlSpot(6, 0),
        ];
      case 'Clicks':
        return [
          const FlSpot(0, 0),
          const FlSpot(1, 0),
          const FlSpot(2, 0),
          const FlSpot(3, 0),
          const FlSpot(4, 0),
          const FlSpot(5, 0),
          const FlSpot(6, 0),
        ];
      case 'Saves':
        return [
          const FlSpot(0, 0),
          const FlSpot(1, 0),
          const FlSpot(2, 0),
          const FlSpot(3, 0),
          const FlSpot(4, 0),
          const FlSpot(5, 0),
          const FlSpot(6, 0),
        ];
      case 'Sales':
        return [
          const FlSpot(0, 0),
          const FlSpot(1, 0),
          const FlSpot(2, 0),
          const FlSpot(3, 0),
          const FlSpot(4, 0),
          const FlSpot(5, 0),
          const FlSpot(6, 0),
        ];
      default:
        return [];
    }
  }

  Widget _buildTopProductsSection(bool isSmallScreen, bool isTablet, bool isLargeTablet, bool isMedium, bool isLarge, bool isExtraLarge) {
    return Container(
      padding: EdgeInsets.all(isExtraLarge ? 20 : (isLarge ? 16 : (isMedium ? 12 : 8))),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isExtraLarge ? 12 : (isLarge ? 12 : (isMedium ? 10 : 8))),
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
          Text(
            'Top Performing Products',
            style: TextStyle(
              fontSize: isExtraLarge ? 18 : (isLarge ? 17 : (isMedium ? 16 : 14)),
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: isExtraLarge ? 20 : (isLarge ? 18 : (isMedium ? 16 : 14))),
          Column(
            children: [
              _buildProductRow('Wireless Headphones', 156, 1, isSmallScreen, isTablet, isLargeTablet, isMedium, isLarge, isExtraLarge),
              const Divider(),
              _buildProductRow('Smartphone Case', 134, 2, isSmallScreen, isTablet, isLargeTablet, isMedium, isLarge, isExtraLarge),
              const Divider(),
              _buildProductRow('USB-C Cable', 98, 3, isSmallScreen, isTablet, isLargeTablet, isMedium, isLarge, isExtraLarge),
              const Divider(),
              _buildProductRow('Bluetooth Speaker', 87, 4, isSmallScreen, isTablet, isLargeTablet, isMedium, isLarge, isExtraLarge),
              const Divider(),
              _buildProductRow('Power Bank', 76, 5, isSmallScreen, isTablet, isLargeTablet, isMedium, isLarge, isExtraLarge),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductRow(String name, int views, int rank, bool isSmallScreen, bool isTablet, bool isLargeTablet, bool isMedium, bool isLarge, bool isExtraLarge) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isExtraLarge ? 16 : (isLarge ? 14 : (isMedium ? 12 : 10))),
      child: Row(
        children: [
          Container(
            width: isExtraLarge ? 36 : (isLarge ? 32 : (isMedium ? 28 : 24)),
            height: isExtraLarge ? 36 : (isLarge ? 32 : (isMedium ? 28 : 24)),
            decoration: BoxDecoration(
              color: rank <= 3 ? Colors.amber : Colors.grey[300],
              borderRadius: BorderRadius.circular(isExtraLarge ? 18 : (isLarge ? 16 : (isMedium ? 14 : 12))),
            ),
            child: Center(
              child: Text(
                rank.toString(),
                style: TextStyle(
                  fontSize: isExtraLarge ? 16 : (isLarge ? 14 : (isMedium ? 12 : 10)),
                  fontWeight: FontWeight.bold,
                  color: rank <= 3 ? Colors.white : Colors.grey[600],
                ),
              ),
            ),
          ),
          SizedBox(width: isExtraLarge ? 20 : (isLarge ? 16 : (isMedium ? 14 : 12))),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontSize: isExtraLarge ? 18 : (isLarge ? 17 : (isMedium ? 16 : 14)),
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
          Text(
            '$views views',
            style: TextStyle(
              fontSize: isExtraLarge ? 16 : (isLarge ? 15 : (isMedium ? 14 : 12)),
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerInsightsSection(bool isSmallScreen, bool isTablet, bool isLargeTablet, bool isMedium, bool isLarge, bool isExtraLarge) {
    return Container(
      padding: EdgeInsets.all(isExtraLarge ? 20 : (isLarge ? 16 : (isMedium ? 12 : 8))),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isExtraLarge ? 12 : (isLarge ? 12 : (isMedium ? 10 : 8))),
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
          Text(
            'Customer Visit Patterns',
            style: TextStyle(
              fontSize: isExtraLarge ? 18 : (isLarge ? 17 : (isMedium ? 16 : 14)),
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: isExtraLarge ? 20 : (isLarge ? 18 : (isMedium ? 16 : 14))),
          SizedBox(
            height: isExtraLarge ? 200 : (isLarge ? 180 : (isMedium ? 160 : 140)),
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 100,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}%',
                          style: TextStyle(fontSize: isExtraLarge ? 12 : (isLarge ? 11 : (isMedium ? 10 : 9))),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const hours = ['9AM', '12PM', '3PM', '6PM', '9PM'];
                        if (value.toInt() >= 0 && value.toInt() < hours.length) {
                          return Text(
                            hours[value.toInt()],
                            style: TextStyle(fontSize: isExtraLarge ? 12 : (isLarge ? 11 : (isMedium ? 10 : 9))),
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
                  BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 0, color: Colors.blue)]),
                  BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 0, color: Colors.green)]),
                  BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 0, color: Colors.orange)]),
                  BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 0, color: Colors.purple)]),
                  BarChartGroupData(x: 4, barRods: [BarChartRodData(toY: 0, color: Colors.red)]),
                ],
              ),
            ),
          ),
          SizedBox(height: isExtraLarge ? 16 : (isLarge ? 14 : (isMedium ? 12 : 10))),
          Row(
            children: [
              Icon(Icons.info_outline, size: isExtraLarge ? 16 : (isLarge ? 15 : (isMedium ? 14 : 12)), color: Colors.grey[600]),
              SizedBox(width: isExtraLarge ? 8 : (isLarge ? 7 : (isMedium ? 6 : 4))),
              Expanded(
                child: Text(
                  'Peak customer activity is between 12PM-3PM. Consider scheduling promotions during these hours.',
                  style: TextStyle(
                    fontSize: isExtraLarge ? 14 : (isLarge ? 13 : (isMedium ? 12 : 10)),
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
