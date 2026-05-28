import 'package:flutter/material.dart';
import 'package:theme_provider/theme_provider.dart';
import 'package:photo_view/photo_view.dart';

class HowToUsePage extends StatelessWidget {
  const HowToUsePage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkTheme = ThemeProvider.themeOf(context).id == "dark_theme";

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
            'Search, Download and Bookmark Papers',
            'assets/banners/OpenScholarXIV.png',
            'Use the search bar at the top to find research papers. Enter keywords or author names. Once you find what you like you can bookmark it to read later or download to save the pdf.',
            isDarkTheme,
            context,
          ),
          _buildSection(
            'View and Listen to Summaries',
            'assets/banners/OpenScholarXIV2.png',
            'Tap the summary button on any paper to view its summary and click on the volume icon to listen to it. You can also adjust the speed of the audio.',
            isDarkTheme,
            context,
          ),
          _buildSection(
            'AI Chat',
            'assets/banners/OpenScholarXIV7.png',
            'Discuss papers with AI by tapping the AI icon or click on the AI icon on the app bar to have a general conversation.',
            isDarkTheme,
            context,
          ),
          _buildSection(
            'API configuration',
            'assets/banners/OpenScholarXIV6.png',
            "You can grab your own Gemini API key in the settings page to enable AI chat. Click on the 'GET API KEY' button to get your key.",
            isDarkTheme,
            context,
          ),
          _buildSection(
            'Change Theme',
            'assets/banners/OpenScholarXIV3.png',
            'Toggle between light, dark and mixed themes using the theme icon in the app bar.',
            isDarkTheme,
            context,
          ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String imagePath, String description,
      bool isDarkTheme, BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: isDarkTheme ? Colors.grey[900] : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => _showFullScreenImage(context, imagePath),
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
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
                    color: isDarkTheme ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkTheme ? Colors.grey[300] : Colors.grey[600],
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
              child: PhotoView(
                imageProvider: AssetImage(imagePath),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
