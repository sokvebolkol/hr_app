import 'package:flutter/material.dart';
import '../../constants/constant.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  final List<Map<String, dynamic>> products = [
    {
      'name': 'Speed Loan',
      'target': 'For Immediate Needs Customer',
      'description': 'Quick approval for urgent financial needs',
      'image': 'assets/images/products/speed-loan.png',
      'features': [
        'This is a unique product tailored for those who are looking to improve their living standards such as expanding an existing micro-business, home renovations, purchasing a motor bike and paying for school fees among others.',
      ],
      'icon': Icons.flash_on,
      'color': Color(0xFFFF6B35),
    },
    {
      'name': 'General Loan',
      'target': 'For Opportunistic/Investor',
      'description': 'Versatile loan for various purposes',
      'image': 'assets/images/products/general-loan.png',
      'features': [
        'The ideal fund to support the cash flow of household expense or any types of investment. It can be used for purchasing land, repairing or buying a house, running or expanding their business and any mandatory expenses for their beloved family.',
      ],
      'icon': Icons.account_balance_wallet,
      'color': Color(0xFFFFA07A),
    },
    {
      'name': 'Agriculture Loan',
      'target': 'For Farmer',
      'description': 'Supporting farmers and agricultural businesses',
      'image': 'assets/images/products/agriculture-loan.png',
      'features': [
        'Farmers who are looking to grow their business can request an Agricultural Loan with ChokChey Finance. The loan is designed to be multipurpose and can be used in small scale agriculture, crop growing as well as raising livestock.',
      ],
      'icon': Icons.agriculture,
      'color': Color(0xFF90BE6D),
    },
    {
      'name': 'SME Loan',
      'target': 'For Entrepreneur/Business Owner',
      'description': 'Empower your small and medium enterprise',
      'image': 'assets/images/products/sme-loan.png',
      'features': [
        'If you are planning to start up business or expand your business activities, Chok Chey offers you a small and medium loan for funding your business production/processing of various commodities, businesses and other services called SME loans.',
      ],
      'icon': Icons.business,
      'color': Color(0xFFFF8C42),
    },
    {
      'name': 'Auto Loan',
      'target': 'For Automobile Lover',
      'description': 'Finance your dream vehicle today',
      'image': 'assets/images/products/auto-loan.png',
      'features': [
        'To bring a comfortable life for our beloved citizen, this product is designed to provide the capital needs to purchase any automobile that suit their lifestyle.',
      ],
      'icon': Icons.directions_car,
      'color': Color(0xFF95E1D3),
    },
    {
      'name': 'Vehicle ID Loan',
      'target': 'For Car/Motorbike Owner',
      'description': 'Special financing using vehicle ID as collateral',
      'image': 'assets/images/products/vehicle-loan.png',
      'features': [
        'This product is designed for the need of fund for vehicle\'s owner by just pledging the Vehicle/Motor ID Card as collateral and legitimate vehicle documents.',
      ],
      'icon': Icons.motorcycle,
      'color': Color(0xFF6A5ACD),
    },
    {
      'name': 'Group Loan',
      'target': 'For a Chief of Village/Community Leader',
      'description': 'Collaborative lending for groups and communities',
      'image': 'assets/images/products/group-loan.png',
      'features': [
        'This community-based loan product is developed to target small business owners, garment factory workers, civil servants, regular income earners, and farmers with seasonal income.',
      ],
      'icon': Icons.group,
      'color': Color(0xFF4ECDC4),
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Widget _buildProductCard(Map<String, dynamic> product, int index) {
    final delay = index * 0.1;
    final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(delay, delay + 0.4, curve: Curves.easeOut),
      ),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - animation.value)),
          child: Opacity(opacity: animation.value, child: child),
        );
      },
      child: Card(
        elevation: 4,
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showProductDetails(product),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Product Image/Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: product['color'].withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    product['icon'],
                    size: 40,
                    color: product['color'],
                  ),
                ),
                const SizedBox(width: 16),
                // Product Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product['name'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: secondary,
                        ),
                      ),
                      if (product['target'] != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          product['target'],
                          style: TextStyle(
                            fontSize: 12,
                            color: product['color'],
                            fontWeight: FontWeight.w600,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        product['description'],
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showProductDetails(Map<String, dynamic> product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder:
                (context, scrollController) => Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Handle
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          controller: scrollController,
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Product Icon
                              Center(
                                child: Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: product['color'].withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    product['icon'],
                                    size: 60,
                                    color: product['color'],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              // Product Name
                              Text(
                                product['name'],
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: secondary,
                                ),
                              ),
                              if (product['target'] != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  product['target'],
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: product['color'],
                                    fontWeight: FontWeight.w600,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 8),
                              // Description
                              Text(
                                product['description'],
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 24),
                              // Features
                              const Text(
                                'Key Features',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: secondary,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ...List.generate(
                                product['features'].length,
                                (index) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Icon(
                                      //   Icons.check_circle,
                                      //   color: product['color'],
                                      //   size: 20,
                                      // ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          product['features'][index],
                                          style: const TextStyle(
                                            fontSize: 16,
                                            height: 1.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 32),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: primary,
        title: const Text(
          'Our Products',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [primary.withOpacity(0.05), Colors.white],
          ),
        ),
        child: Column(
          children: [
            // Header Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: primary,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  const Text(
                    'Discover Our Financial Solutions',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${products.length} products available',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Products List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  return _buildProductCard(products[index], index);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
