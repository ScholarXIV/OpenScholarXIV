import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

class HowToUsePage extends StatelessWidget {
  const HowToUsePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('How to Use'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSection(
            'OpenScholarXIV',
            'assets/banners/OpenScholarXIV7.png',
            'Completely Free & Open-Source App to browse and explore research papers with AI-powered chat and more features.',
            context,
          ),
          _buildSection(
            'Search and Explore Papers',
            'assets/banners/OpenScholarXIV.png',
            'Use the search bar at the top to find research papers or just brwose the suggested list of papers to discover new research.',
            context,
          ),
          _buildSection(
            'Read Papers In-app',
            'assets/banners/OpenScholarXIV6.png',
            'Read any paper directly in the app for a seamless and distraction free experience.',
            context,
          ),
          _buildSection(
            'Bookmark Papers',
            'assets/banners/OpenScholarXIV8.png',
            'Bookmark papers to read later by tapping the bookmark icon on any paper.',
            context,
          ),
          _buildSection(
            'View and Listen to Summaries',
            'assets/banners/OpenScholarXIV2.png',
            'Tap the summary button on any paper to view its summary and click on the volume icon to listen to it. You can also adjust the speed of the audio.',
            context,
          ),
          _buildSection(
            'AI Chat',
            'assets/banners/OpenScholarXIV3.png',
            'Discuss papers with AI by tapping the AI icon or click on the AI icon on the app bar to have a general conversation.',
            context,
          ),
          _buildSection(
            'API configuration',
            'assets/banners/OpenScholarXIV4.png',
            "You can grab your own Gemini API key in the settings page to enable AI chat. Click on the 'GET API KEY' button to get your key.",
            context,
          ),
          _buildSection(
            'Change Theme',
            'assets/banners/OpenScholarXIV5.png',
            'Toggle between Material You light and dark themes using the theme icon in the app bar.',
            context,
          ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  Widget _buildSection(
    String title,
    String imagePath,
    String description,
    BuildContext context,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => _showFullScreenImage(context, imagePath),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: Image.asset(
                imagePath,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFullScreenImage(BuildContext context, String imagePath) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          body: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Center(
              child: PhotoView(imageProvider: AssetImage(imagePath)),
            ),
          ),
        ),
      ),
    );
  }
}
