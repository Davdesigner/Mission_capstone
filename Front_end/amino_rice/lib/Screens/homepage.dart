import 'package:flutter/material.dart';
import 'login.dart';
import 'scanning.dart';
import 'history.dart';
import 'chatbot.dart';
import 'profile.dart';

/// Home screen for AminoRice - Rice Quality Assurance Application
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isArticleExpanded = false;
  bool _isArticle2Expanded = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.grey[50],
      drawer: _buildSideDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.grey[50],
        foregroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Navigate to notifications
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeSection(context),
            const SizedBox(height: 24),
            _buildQuickActionsSection(context),
            const SizedBox(height: 24),
            _buildRiceQualityArticleSection(context),
            const SizedBox(height: 24),
            _buildRiceVarietiesArticleSection(context),
            const SizedBox(height: 24),
            _buildRiceQualityTipsSection(context),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(BuildContext context) {
    final hour = DateTime.now().hour;
    String greeting = 'Good Morning';
    if (hour >= 12 && hour < 17) {
      greeting = 'Good Afternoon';
    } else if (hour >= 17) {
      greeting = 'Good Evening';
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D32).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            greeting,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Welcome to AminoRice',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Your trusted rice quality assurance assistant',
            style: TextStyle(fontSize: 16, color: Colors.white, height: 1.4),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.grain, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                'Quality First, Always',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  title: 'Scan Rice',
                  icon: Icons.camera_alt_outlined,
                  color: const Color(0xFF2E7D32),
                  onTap: () {
                    // TODO: Open camera to scan rice
                  },
                ),
              ),
              const SizedBox(width: 12),

              Expanded(
                child: _buildActionCard(
                  title: 'Chat Support',
                  icon: Icons.chat_outlined,
                  color: const Color(0xFF388E3C),
                  onTap: () {
                    // TODO: Open chat support
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  title: 'Total Scans',
                  icon: Icons.qr_code_scanner_sharp,
                  color: const Color(0xFF66BB6A),
                  onTap: () {
                    // TODO: Navigate to total scans
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiceQualityArticleSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: EdgeInsets.only(
              left: 4,
              bottom: _isArticleExpanded ? 16 : 8,
            ),
            child: Text(
              'Rice Quality Insights',
              style: TextStyle(
                fontSize: _isArticleExpanded ? 24 : 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          // Card Content
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Section with Overlapping Title (when collapsed)
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                      child: Image.asset(
                        'assets/001.jpg',
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 200,
                            color: Colors.grey[300],
                            child: const Center(
                              child: Icon(
                                Icons.image_not_supported,
                                size: 50,
                                color: Colors.grey,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    // Overlapping title when collapsed
                    if (!_isArticleExpanded)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.85),
                              ],
                            ),
                          ),
                          padding: const EdgeInsets.all(20),
                          child: const Text(
                            'Spectrophotometry in Rice Quality Assurance',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF66BB6A),
                              height: 1.3,
                              shadows: [
                                Shadow(
                                  color: Colors.black87,
                                  offset: Offset(0, 2),
                                  blurRadius: 6,
                                ),
                                Shadow(
                                  color: Colors.black45,
                                  offset: Offset(0, 4),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                // Content Section
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Headline (shown when expanded)
                      if (_isArticleExpanded)
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Spectrophotometry in Rice Quality Assurance',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2E7D32),
                                height: 1.3,
                              ),
                            ),
                            SizedBox(height: 16),
                          ],
                        ),
                      // Content Text
                      AnimatedCrossFade(
                        firstChild: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'There are around million metric huge amounts of rice created comprehensively consistently and even generally little ranches normally have high...',
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey[800],
                                height: 1.6,
                              ),
                              textAlign: TextAlign.justify,
                            ),
                          ],
                        ),
                        secondChild: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'There are around million metric huge amounts of rice created comprehensively consistently and even generally little ranches normally have high yield. When the cost of generation is developing, this oversight turns out to be more imperative than any other time in recent memory to look after gainfulness. With increasing expenses and high creation volume, rice agriculturists should now find a way to guarantee most extreme quality with each collect. In this post we will perceive how portable spectrophotometer is utilized as a part of expanding the quality and proficiency in Rice creation.',
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey[800],
                                height: 1.6,
                              ),
                              textAlign: TextAlign.justify,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Maintaining the quality of output, however, can be a challenge. As such, many modern ranches incorporate modern advances all through the generation procedure, encouraging yield administration, gathering, and processing. Today, a key segment of streamlining quality control is the utilization of spectrophotometers that measure rice shading, a vital pointer of value.',
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey[800],
                                height: 1.6,
                              ),
                              textAlign: TextAlign.justify,
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Key Indicators of Rice Quality',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'There are numerous sorts of rice plants and conceivably a large number of rice assortments which can be made by crossbreeding those plants. Because of the variety of rice from plant to plant, there\'s no all-inclusive framework for building up rice quality than the use of Spectrophotometer. There are, in any case, an assortment of elements known to show quality and ranchers utilize these elements to build up their own quality criteria. They include: Milling degree, whole versus harmed grains, Chalkiness, and Whiteness/Color.',
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey[800],
                                height: 1.6,
                              ),
                              textAlign: TextAlign.justify,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'With a high volume of rice to test, most makers confront challenges in finding viable approaches to survey issues of value in rice creation and streamline their frameworks. Since shading can give vital direction with respect to various quality parameters, shading estimation is an essential technique rice ranchers can actualize to beat these difficulties and guarantee quality, streamline generation, and expand productivity. All things considered, spectrophotometers are progressively being utilized as a part of both cultivating and processing, encouraging quick and precise quality appraisal.',
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey[800],
                                height: 1.6,
                              ),
                              textAlign: TextAlign.justify,
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Use of Spectrophotometry in the Rice Industry',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Portable Spectrophotometers can be utilized to support useable volume generation in for all intents and purposes all parts of the rice cultivating process, from development to processing, as shading can offer a reasonable pointer to guarantee rice is sufficiently nurtured and processed adequately. With a specific end goal to acquire the important shading information important to advance quality, spectrophotometric testing can be executed at various focuses in the generation procedure, including During development, Before and amid processing and After processing.',
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey[800],
                                height: 1.6,
                              ),
                              textAlign: TextAlign.justify,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'It offer demonstrated outcomes with regards to setting up the perfect nature of rice. In any case, picking the correct device is basic to guarantee exactness, accuracy, and speed of shading estimation.',
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey[800],
                                height: 1.6,
                              ),
                              textAlign: TextAlign.justify,
                            ),
                          ],
                        ),
                        crossFadeState: _isArticleExpanded
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                        duration: const Duration(milliseconds: 300),
                      ),
                      const SizedBox(height: 16),
                      // Read More Button
                      Center(
                        child: TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _isArticleExpanded = !_isArticleExpanded;
                            });
                          },
                          icon: Icon(
                            _isArticleExpanded
                                ? Icons.expand_less
                                : Icons.expand_more,
                            color: const Color(0xFF2E7D32),
                          ),
                          label: Text(
                            _isArticleExpanded ? 'Read Less' : 'Read More',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiceVarietiesArticleSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: EdgeInsets.only(
              left: 4,
              bottom: _isArticle2Expanded ? 16 : 8,
            ),
            child: Text(
              'Rice Varieties Guide',
              style: TextStyle(
                fontSize: _isArticle2Expanded ? 24 : 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          // Card Content
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Section with Overlapping Title (when collapsed)
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                      child: Image.asset(
                        'assets/002.jpg',
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 200,
                            color: Colors.grey[300],
                            child: const Center(
                              child: Icon(
                                Icons.image_not_supported,
                                size: 50,
                                color: Colors.grey,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    // Overlapping title when collapsed
                    if (!_isArticle2Expanded)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.85),
                              ],
                            ),
                          ),
                          padding: const EdgeInsets.all(20),
                          child: const Text(
                            'Understanding Different Rice Colors',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF66BB6A),
                              height: 1.3,
                              shadows: [
                                Shadow(
                                  color: Colors.black87,
                                  offset: Offset(0, 2),
                                  blurRadius: 6,
                                ),
                                Shadow(
                                  color: Colors.black45,
                                  offset: Offset(0, 4),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                // Content Section
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Headline (shown when expanded)
                      if (_isArticle2Expanded)
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Understanding Different Rice Colors',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2E7D32),
                                height: 1.3,
                              ),
                            ),
                            SizedBox(height: 16),
                          ],
                        ),
                      // Content Text
                      _buildRiceVarietiesContent(),
                      const SizedBox(height: 16),
                      // Read More Button
                      Center(
                        child: TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _isArticle2Expanded = !_isArticle2Expanded;
                            });
                          },
                          icon: Icon(
                            _isArticle2Expanded
                                ? Icons.expand_less
                                : Icons.expand_more,
                            color: const Color(0xFF2E7D32),
                          ),
                          label: Text(
                            _isArticle2Expanded ? 'Read Less' : 'Read More',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiceVarietiesContent() {
    return AnimatedCrossFade(
      firstChild: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rice varieties differ in color, processing, and nutritional content. Each type offers unique health benefits for different...',
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[800],
              height: 1.6,
            ),
            textAlign: TextAlign.justify,
          ),
        ],
      ),
      secondChild: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rice is a staple food for over half the world\'s population, with numerous varieties distinguished by color and processing methods. Each type offers unique nutritional benefits suited to different dietary needs.',
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[800],
              height: 1.6,
            ),
            textAlign: TextAlign.justify,
          ),
          const SizedBox(height: 20),
          const Text(
            'White Rice',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'The most processed variety with hull, bran, and germ removed. Quick-cooking (about 30 minutes) and easily digestible, making it ideal for those on low-fiber diets or with digestive sensitivities. However, it has a higher glycemic index and fewer nutrients than whole grain varieties.',
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[800],
              height: 1.6,
            ),
            textAlign: TextAlign.justify,
          ),
          const SizedBox(height: 20),
          const Text(
            'Brown Rice',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Retains bran and germ layers, providing more fiber, antioxidants, vitamins, and minerals. Regular consumption helps lower blood sugar levels and reduces type 2 diabetes risk by up to 20% when replacing white rice. Rich in powerful antioxidants that combat inflammation.',
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[800],
              height: 1.6,
            ),
            textAlign: TextAlign.justify,
          ),
          const SizedBox(height: 20),
          const Text(
            'Germinated Brown Rice',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Sprouted brown rice with enhanced nutritional value and easier nutrient absorption. Contains 15 times more GABA (gamma aminobutyric acid) than regular brown rice, which helps protect brain function and may prevent Alzheimer\'s disease. Softer texture and shorter cooking time.',
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[800],
              height: 1.6,
            ),
            textAlign: TextAlign.justify,
          ),
          const SizedBox(height: 20),
          const Text(
            'Red Rice',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Similar to brown rice but with a red hue from proanthocyanidins in the bran. Low glycemic index makes it excellent for diabetics. Rich in zinc, calcium, iron, and antioxidants that support bone health and may prevent arthritis and osteoporosis.',
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[800],
              height: 1.6,
            ),
            textAlign: TextAlign.justify,
          ),
          const SizedBox(height: 20),
          const Text(
            'Black/Purple Rice',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Contains the highest antioxidants among all rice varieties, thanks to anthocyanins that give it a dark color. Excellent protein source for vegetarians, promoting muscle maintenance and bone strength. Rich in dietary fiber for digestive health and helps reduce cancer risk and promote heart health by eliminating free radicals.',
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[800],
              height: 1.6,
            ),
            textAlign: TextAlign.justify,
          ),
        ],
      ),
      crossFadeState: _isArticle2Expanded
          ? CrossFadeState.showSecond
          : CrossFadeState.showFirst,
      duration: const Duration(milliseconds: 300),
    );
  }

  Widget _buildRiceQualityTipsSection(BuildContext context) {
    final tips = [
      {
        'title': 'Check Rice Moisture',
        'description': 'Optimal moisture content is between 12-14% for storage',
        'icon': Icons.water_drop_outlined,
      },
      {
        'title': 'Grain Appearance',
        'description': 'Look for uniform color and minimal broken grains',
        'icon': Icons.visibility_outlined,
      },
      {
        'title': 'Storage Tips',
        'description': 'Store in cool, dry place to maintain quality',
        'icon': Icons.store_outlined,
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rice Quality Tips',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          ...tips.map(
            (tip) => _buildTipCard(
              title: tip['title'] as String,
              description: tip['description'] as String,
              icon: tip['icon'] as IconData,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipCard({
    required String title,
    required String description,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF2E7D32), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
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

  Widget _buildSideDrawer() {
    return Drawer(
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            // Header section with close button
            Container(
              width: double.infinity,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 20,
                left: 20,
                right: 20,
                bottom: 20,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Menu',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),

            // Menu items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 20),
                children: [
                  _buildMenuItem(
                    icon: Icons.home_outlined,
                    title: 'Home',
                    onTap: () {
                      Navigator.of(context).pop();
                      // Already on home page
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.qr_code_scanner,
                    title: 'Scan',
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RecordPage(),
                        ),
                      );
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.history_outlined,
                    title: 'History',
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HistoryPage(),
                        ),
                      );
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.chat_outlined,
                    title: 'Chat',
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ChatbotScreen(),
                        ),
                      );
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.person_outline,
                    title: 'Profile',
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProfilePage(),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 40, thickness: 1),
                  _buildMenuItem(
                    icon: Icons.logout_outlined,
                    title: 'Logout',
                    onTap: () {
                      Navigator.of(context).pop();
                      _showLogoutDialog();
                    },
                    isLogout: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isLogout ? Colors.red : const Color(0xFF2E7D32),
        size: 24,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: isLogout ? Colors.red : Colors.black87,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Logout',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          content: const Text(
            'Are you sure you want to logout?',
            style: TextStyle(color: Colors.black54),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }
}
