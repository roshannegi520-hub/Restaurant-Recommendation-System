import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart'; // Added Firebase import
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'restaurant_api_service.dart';
import 'gemini_service.dart';

// ==========================================
// 1. GLOBAL STATE (To hold reservations)
// ==========================================
List<Map<String, dynamic>> myGlobalReservations = [];

// ==========================================
// 2. INITIALIZATION
// ==========================================
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Wakes up the Firebase database before the app loads
  await Firebase.initializeApp();

  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Recommender',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}

// ==========================================
// 3. LOGIN & SIGNUP SCREENS
// ==========================================
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  Future<void> loginUser(String email, String password) async {
    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      debugPrint("Success! Logged in: ${credential.user?.uid}");

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainAppScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.message}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.travel_explore, size: 100, color: Colors.blue),
              const SizedBox(height: 20),
              const Text("Smart Recommender",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 40),
              TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15)))),
              const SizedBox(height: 20),
              TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15)))),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15))),
                  onPressed: () {
                    loginUser(emailController.text.trim(),
                        passwordController.text.trim());
                  },
                  child: const Text("LOGIN",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account?"),
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const SignupScreen()),
                    ),
                    child: const Text("Sign Up",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  Future<void> signUpUser(String email, String password) async {
    try {
      final credential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      debugPrint("Success! User created: ${credential.user?.uid}");

      if (mounted) {
        // Teleports directly to the app after signing up!
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainAppScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.message}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Account")),
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          children: [
            TextField(
                controller: nameController,
                decoration: InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15)))),
            const SizedBox(height: 20),
            TextField(
                controller: emailController,
                decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15)))),
            const SizedBox(height: 20),
            TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15)))),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15))),
                onPressed: () {
                  signUpUser(emailController.text.trim(),
                      passwordController.text.trim());
                },
                child: const Text("SIGN UP"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 4. MAIN NAVIGATION CONTROLLER
// ==========================================
class MainAppScreen extends StatefulWidget {
  const MainAppScreen({super.key});
  @override
  State<MainAppScreen> createState() => _MainAppScreenState();
}

class _MainAppScreenState extends State<MainAppScreen> {
  int _currentIndex = 0;
  String _currentSearchLocation = "Dehradun";

  void _executeSearch(String location) {
    setState(() {
      _currentSearchLocation = location;
      _currentIndex = 2; // Jump to Suggest tab
    });
  }

  Widget _getPage(int index) {
    switch (index) {
      case 0:
        return HomeScreen(onSearch: _executeSearch);
      case 1:
        return SearchScreen(onSearch: _executeSearch);
      case 2:
        return HotelRecommendationScreen(
            locationContext: _currentSearchLocation);
      case 3:
        return const MyReservationsScreen();
      default:
        return HomeScreen(onSearch: _executeSearch);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Smart Recommender",
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        // --- NEW: Logout Button ---
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (context) => const LoginScreen())),
          )
        ],
      ),
      body: _getPage(_currentIndex),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(
              icon: Icon(Icons.auto_awesome), label: 'Suggest'),
          BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long), label: 'Reservations'),
        ],
      ),
    );
  }
}

// ==========================================
// 5. SUB-SCREENS (HOME)
// ==========================================
class HomeScreen extends StatelessWidget {
  final Function(String) onSearch;

  const HomeScreen({super.key, required this.onSearch});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Ready to explore?",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Text("Discover the best spots in Dehradun",
              style: TextStyle(fontSize: 16, color: Colors.grey[600])),
          const SizedBox(height: 30),
          const Text("Quick Categories",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildCategoryCard(Icons.local_cafe, "Cafes", Colors.brown,
                  () => onSearch("Best cafes in Dehradun")),
              _buildCategoryCard(Icons.restaurant, "Dining", Colors.orange,
                  () => onSearch("Top rated dinner in Dehradun")),
              _buildCategoryCard(Icons.hotel, "Stays", Colors.blue,
                  () => onSearch("Luxury stays in Dehradun")),
              _buildCategoryCard(Icons.local_pizza, "Fast Food", Colors.red,
                  () => onSearch("Fast food in Dehradun")),
            ],
          ),
          const SizedBox(height: 35),
          const Text("Trending Near You",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          SizedBox(
            height: 200,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildTrendingCard("The Orchard", "⭐ 4.8",
                    "https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=60"),
                _buildTrendingCard("Cafe Cibo", "⭐ 4.6",
                    "https://images.unsplash.com/photo-1555396273-367ea4eb4db5?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=60"),
                _buildTrendingCard("Town Table", "⭐ 4.5",
                    "https://images.unsplash.com/photo-1552566626-52f8b828add9?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=60"),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildCategoryCard(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: color.withAlpha(26),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(height: 8),
          Text(label,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildTrendingCard(String name, String rating, String imageUrl) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: DecorationImage(
          image: NetworkImage(imageUrl),
          fit: BoxFit.cover,
          colorFilter:
              ColorFilter.mode(Colors.black.withAlpha(102), BlendMode.darken),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18)),
            const SizedBox(height: 4),
            Text(rating,
                style: const TextStyle(
                    color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 6. THE NEW "MY RESERVATIONS" SCREEN (TABBED)
// ==========================================
class MyReservationsScreen extends StatefulWidget {
  const MyReservationsScreen({super.key});
  @override
  State<MyReservationsScreen> createState() => _MyReservationsScreenState();
}

class _MyReservationsScreenState extends State<MyReservationsScreen> {
  // Updated: We now pass the exact reservation map to remove,
  // because using the list index will be wrong when we split the lists!
  void _cancelReservation(Map<String, dynamic> reservation) {
    setState(() {
      myGlobalReservations.remove(reservation);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Get today's date at midnight for accurate comparison
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);

    // Filter into two separate lists
    List<Map<String, dynamic>> upcoming = myGlobalReservations.where((res) {
      return !DateTime.parse(res['date']).isBefore(today);
    }).toList();

    List<Map<String, dynamic>> past = myGlobalReservations.where((res) {
      return DateTime.parse(res['date']).isBefore(today);
    }).toList();

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          // The Tab Bar Header
          Container(
            color: Colors.white,
            child: const TabBar(
              labelColor: Colors.blue,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.blue,
              indicatorSize: TabBarIndicatorSize.tab,
              tabs: [
                Tab(text: "Upcoming"),
                Tab(text: "History"),
              ],
            ),
          ),
          // The Tab Content
          Expanded(
            child: TabBarView(
              children: [
                _buildReservationList(upcoming, isPast: false),
                _buildReservationList(past, isPast: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // A helper widget to build the lists so we don't repeat code
  Widget _buildReservationList(List<Map<String, dynamic>> reservations,
      {required bool isPast}) {
    if (reservations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isPast ? Icons.history : Icons.chair_alt,
                size: 80, color: Colors.grey[400]),
            const SizedBox(height: 15),
            Text(
                isPast
                    ? "No past reservations."
                    : "You don't have any upcoming reservations.",
                style: const TextStyle(color: Colors.grey, fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: reservations.length,
      itemBuilder: (context, index) {
        final res = reservations[index];

        return Card(
          elevation: isPast ? 0 : 2, // Flat look for past history
          color: isPast
              ? Colors.grey[100]
              : Colors.white, // Gray background for past history
          margin: const EdgeInsets.only(bottom: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: isPast
                ? BorderSide(color: Colors.grey.shade300)
                : BorderSide.none,
          ),
          child: Padding(
            padding: const EdgeInsets.all(15.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(res['name'],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: isPast
                                ? Colors.grey[700]
                                : Colors.black, // Dark gray text for past
                          )),
                      const SizedBox(height: 5),
                      Text(
                          "📅 ${res['date']}   🕒 ${res['time']}\n👥 Table for ${res['guests']}",
                          style:
                              TextStyle(color: Colors.grey[600], height: 1.5)),
                    ],
                  ),
                ),
                // Dynamic Badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: isPast ? Colors.grey[300] : Colors.green[50],
                      borderRadius: BorderRadius.circular(5)),
                  child: Text(isPast ? "Completed" : "Confirmed ✅",
                      style: TextStyle(
                          color: isPast ? Colors.grey[700] : Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                ),
                // Dynamic Cancel Button (Only show if upcoming)
                if (!isPast)
                  IconButton(
                    icon: const Icon(Icons.cancel, color: Colors.red),
                    onPressed: () => _cancelReservation(res),
                  )
              ],
            ),
          ),
        );
      },
    );
  }
}

// ==========================================
// 7. THE SEARCH SCREEN
// ==========================================
class SearchScreen extends StatefulWidget {
  final Function(String) onSearch;
  const SearchScreen({super.key, required this.onSearch});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _locationController = TextEditingController();
  bool _isGettingLocation = false;

  Future<void> _searchNearMe() async {
    setState(() => _isGettingLocation = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception('Location services are disabled.');

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied.');
      }

      Position position = await Geolocator.getCurrentPosition();
      String gpsQuery = "${position.latitude},${position.longitude}";

      widget.onSearch(gpsQuery);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) {
        setState(() => _isGettingLocation = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("What are you looking for?",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          TextField(
            controller: _locationController,
            decoration: InputDecoration(
              hintText: 'e.g. best momo in dehradun',
              prefixIcon: const Icon(Icons.search, color: Colors.red),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15))),
              onPressed: () {
                if (_locationController.text.isNotEmpty) {
                  widget.onSearch(_locationController.text.trim());
                }
              },
              child: const Text("SMART SEARCH",
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 20),
          const Text("OR",
              style:
                  TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blue,
                  side: const BorderSide(color: Colors.blue, width: 2),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15))),
              onPressed: _isGettingLocation ? null : _searchNearMe,
              icon: _isGettingLocation
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.my_location),
              label: Text(
                  _isGettingLocation ? "Finding you..." : "Find places near me",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 8. THE SMART HOTEL LIST & AI LOGIC
// ==========================================
class HotelRecommendationScreen extends StatefulWidget {
  final String locationContext;
  const HotelRecommendationScreen({super.key, required this.locationContext});
  @override
  State<HotelRecommendationScreen> createState() =>
      _HotelRecommendationScreenState();
}

class _HotelRecommendationScreenState extends State<HotelRecommendationScreen> {
  List hotels = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchHotels();
  }

  @override
  void didUpdateWidget(covariant HotelRecommendationScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.locationContext != widget.locationContext) fetchHotels();
  }

  Future<void> _launchMaps(String destination) async {
    final String encodedAddress = Uri.encodeComponent(destination);
    final Uri googleMapsUrl = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$encodedAddress');

    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Could not open Google Maps.",
                  style: TextStyle(color: Colors.white)),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> fetchHotels() async {
    setState(() {
      isLoading = true;
      hotels = [];
    });

    try {
      final apiService = RestaurantApiService();
      final rawData = await apiService.fetchRestaurants(widget.locationContext);

      final mappedData = rawData.map((place) {
        // --- UPDATED IMAGE EXTRACTION FOR LOCAL BUSINESS DATA API ---
        String realImage =
            'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=60';

        if (place['photo_url_large'] != null) {
          realImage = place['photo_url_large'];
        } else if (place['photo_url'] != null) {
          realImage = place['photo_url'];
        } else if (place['photos_sample'] != null &&
            place['photos_sample'].isNotEmpty) {
          realImage = place['photos_sample'][0]['photo_url_large'] ??
              place['photos_sample'][0]['photo_url'];
        }

        return {
          'name': place['name'] ?? 'Unknown Place',
          'image': realImage, // Using the extracted real photo URL
          'rating': place['rating']?.toString() ?? 'New',
          'address': place['full_address'] ??
              place['address'] ??
              'Address not available',
          'review': place['review_snippet'] ??
              'A highly rated spot based on local popularity.',
          'context_tag': 'Top Match for "${widget.locationContext}"',
        };
      }).toList();

      setState(() {
        hotels = mappedData;
        isLoading = false;
      });
    } catch (e) {
      // THE MOCK DATA FALLBACK
      List<Map<String, dynamic>> rawMockData = [
        {
          'name': 'Luigi\'s Pizzeria',
          'image':
              'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=60',
          'rating': '4.6',
          'address': 'Rajpur Road, Dehradun',
          'review':
              'Best crust in town! The ambiance is amazing and the service is incredibly fast.',
        },
        {
          'name': 'Green Gourmet',
          'image':
              'https://images.unsplash.com/photo-1552566626-52f8b828add9?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=60',
          'rating': '4.1',
          'address': 'Hathibarkala, Dehradun',
          'review':
              'A solid choice for vegetarians. The staff was very polite.',
        }
      ];

      try {
        final aiService = GeminiService();
        List<Map<String, dynamic>> aiEnhancedData = [];

        for (var place in rawMockData) {
          String smartTag = await aiService.generateSmartTag(
              place['name'], widget.locationContext);
          place['context_tag'] = smartTag;
          aiEnhancedData.add(place);
        }

        setState(() {
          hotels = aiEnhancedData;
          isLoading = false;
        });
      } catch (geminiError) {
        setState(() {
          hotels = rawMockData;
          isLoading = false;
        });
      }
    }
  }

  void _showBookingDialog(BuildContext context, String hotelName) {
    DateTime? selectedDate;
    TimeOfDay? selectedTime;
    int selectedGuests = 2;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(25.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Reserve at $hotelName",
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),

                  // DATE PICKER
                  ListTile(
                    tileColor: Colors.grey[100],
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                    leading:
                        const Icon(Icons.calendar_today, color: Colors.blue),
                    title: Text(selectedDate == null
                        ? "Select Check-in Date"
                        : "${selectedDate!.toLocal()}".split(' ')[0]),
                    onTap: () async {
                      DateTime? p = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2027));
                      if (p != null) setModalState(() => selectedDate = p);
                    },
                  ),
                  const SizedBox(height: 10),

                  // TIME PICKER
                  ListTile(
                    tileColor: Colors.grey[100],
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                    leading: const Icon(Icons.access_time, color: Colors.blue),
                    title: Text(selectedTime == null
                        ? "Select Arrival Time"
                        : selectedTime!.format(context)),
                    onTap: () async {
                      TimeOfDay? t = await showTimePicker(
                          context: context, initialTime: TimeOfDay.now());
                      if (t != null) setModalState(() => selectedTime = t);
                    },
                  ),
                  const SizedBox(height: 10),

                  // GUEST SELECTOR DROPDOWN
                  ListTile(
                    tileColor: Colors.grey[100],
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                    leading: const Icon(Icons.people, color: Colors.blue),
                    title: const Text("Party Size"),
                    trailing: DropdownButton<int>(
                      value: selectedGuests,
                      underline: const SizedBox(),
                      dropdownColor: Colors.white,
                      items: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10].map((int value) {
                        return DropdownMenuItem<int>(
                          value: value,
                          child: Text("$value Guests",
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue)),
                        );
                      }).toList(),
                      onChanged: (int? newValue) {
                        if (newValue != null) {
                          setModalState(() => selectedGuests = newValue);
                        }
                      },
                    ),
                  ),

                  const SizedBox(height: 30),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("CANCEL",
                              style: TextStyle(color: Colors.red)),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white),
                          onPressed: () {
                            Navigator.pop(context);

                            myGlobalReservations.add({
                              'name': hotelName,
                              'date': selectedDate != null
                                  ? "${selectedDate!.toLocal()}".split(' ')[0]
                                  : "Today",
                              'time': selectedTime != null
                                  ? selectedTime!.format(context)
                                  : "Now",
                              'guests': selectedGuests,
                            });

                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content:
                                    Text("Table for $selectedGuests Reserved!"),
                                backgroundColor: Colors.green));
                          },
                          child: const Text("CONFIRM"),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(15.0),
          child: Text("Smart Results for: ${widget.locationContext}",
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey)),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: hotels.length,
            itemBuilder: (context, index) {
              final hotel = hotels[index];
              return Card(
                margin:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                elevation: 2,
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                child: Column(
                  children: [
                    Image.network(hotel['image'],
                        height: 180, width: double.infinity, fit: BoxFit.cover),
                    Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(hotel['name'],
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18),
                                    overflow: TextOverflow.ellipsis),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                    color: Colors.orange[50],
                                    borderRadius: BorderRadius.circular(8)),
                                child: Text("⭐ ${hotel['rating']}",
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (hotel['context_tag'] != null)
                            Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  borderRadius: BorderRadius.circular(5)),
                              child: Text(hotel['context_tag'],
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue[700],
                                      fontWeight: FontWeight.bold)),
                            ),
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.format_quote,
                                  color: Colors.grey, size: 16),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  '"${hotel['review']}"',
                                  style: const TextStyle(
                                      fontStyle: FontStyle.italic,
                                      color: Colors.grey,
                                      fontSize: 13),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 15),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.blue,
                                    side: const BorderSide(color: Colors.blue),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                  ),
                                  icon: const Icon(Icons.directions, size: 18),
                                  label: const Text("Directions"),
                                  onPressed: () => _launchMaps(
                                      hotel['address'] ?? hotel['name']),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10))),
                                  onPressed: () => _showBookingDialog(
                                      context, hotel['name']),
                                  child: const Text("Reserve"),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
