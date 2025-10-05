import 'package:flutter/material.dart';
import 'camera_screen.dart';
import 'birth_flowers_screen.dart';
import 'popular_flowers_screen.dart';
import 'favorites_screen.dart'; // Commented out - favorite button disabled
import 'dart:io';
// import 'services/favorites_service.dart'; // Commented out - debug button disabled
// import 'models/flower.dart'; // Commented out - debug button disabled

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  
  // Database debug method - COMMENTED OUT
  /*
  void _showDatabaseDebug() async {
    try {
      final favoritesService = FavoritesService();
      final allFlowers = await favoritesService.getAllFlowersDebug();
      
      if (!mounted) return;
      
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Database Debug (${allFlowers.length} flowers)'),
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child: ListView.builder(
                itemCount: allFlowers.length,
                itemBuilder: (context, index) {
                  final flower = allFlowers[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${index + 1}. ${flower.nameThai} (${flower.nameEnglish})',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text('Day: ${flower.day}'),
                          Text('Favorite: ${flower.isFavorite}'),
                          Text('Image URL: ${flower.imageUrl ?? "None"}'),
                          Text('Has Base64: ${flower.imageBase64 != null ? "Yes" : "No"}'),
                          if (flower.meanings.colorMeanings != null && flower.meanings.colorMeanings!.isNotEmpty)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Color Meanings:', style: TextStyle(fontWeight: FontWeight.w500)),
                                ...flower.meanings.colorMeanings!.map((cm) => 
                                  Text('  • ${cm.color}: ${cm.meaning}', style: const TextStyle(fontSize: 12))
                                ),
                              ],
                            ),
                          if (flower.meanings.other != null)
                            Text('Other Meanings: ${flower.meanings.other}'),
                          if (flower.useFor != null && flower.useFor!.isNotEmpty)
                            Text('Use For: ${flower.useFor!.join(", ")}'),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading database: $e')),
      );
    }
  }
  */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('asset/start_screen.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          top: true,
          bottom: false,
          child: Column(
            children: [
              // Top row with logo and favorite
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo on the left
                    Image.asset(
                      'asset/logo.png',
                      width: 150,
                      height: 105,
                    ),
                    // Debug and Favorite buttons on the right
                    Row(
                      children: [
                        // Database Debug button - COMMENTED OUT
                        /*
                        InkWell(
                          onTap: _showDatabaseDebug,
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.blue.shade600,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.storage,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                        ),
                        */
                        // Favorite button - COMMENTED OUT
                        
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const FavoritesScreen(),
                              ),
                            );
                          },
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.pink.shade200,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.favorite,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Content cards
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      _buildFlowerCard(
                        'Birth Flowers',
                        'asset/birthflowers.png',
                        () {
                          print('Birth Flowers card pressed');
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const BirthFlowersScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      _buildFlowerCard(
                        'Popular Flowers ',
                        'asset/popularflowers.png',
                        () {
                          print('Popular Flowers card pressed');
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SeasonalFlowersScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Camera button
              Padding(
                padding: const EdgeInsets.all(20),
                child: InkWell(
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CameraScreen(),
                      ),
                    );
                    if (result != null) {
                      print('Photo saved at: $result');
                      // Ready to send to API
                      _sendImageToAPI(result);
                    }
                  },
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.pink.shade300,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Method to send image to API
  Future<void> _sendImageToAPI(String imagePath) async {
    try {
      // Image file is ready
      File imageFile = File(imagePath);

      // TODO: Implement your API call here
      // Example structure:
      /*
      var request = http.MultipartRequest('POST', Uri.parse('YOUR_API_URL'));
      request.files.add(await http.MultipartFile.fromPath('image', imagePath));
      var response = await request.send();

      if (response.statusCode == 200) {
        print('Image uploaded successfully');
        // Handle API response
      }
      */

      print('Image ready to send to API: $imagePath');
      print('File exists: ${imageFile.existsSync()}');
      print('File size: ${imageFile.lengthSync()} bytes');

      // You can add your API implementation here

    } catch (e) {
      print('Error preparing image for API: $e');
    }
  }

  Widget _buildFlowerCard(String title, String imagePath, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 335,
        height: 224,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                imagePath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey.shade300,
                    child: const Center(
                      child: Icon(Icons.image, size: 50),
                    ),
                  );
                },
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.3),
                    ],
                  ),
                ),
              ),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

