import 'package:flutter/material.dart';
import 'api_service.dart';
import 'models.dart';
import 'storage_helper.dart';

void main() {
  runApp(const MyApp());
}

// ==================== SPLASH SCREEN ====================
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _controller.forward();

    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1976D2), Color(0xFF64B5F6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _animation,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.5),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.photo_camera,
                    size: 80,
                    color: Color(0xFF1976D2),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                'App Foto',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      blurRadius: 10,
                      color: Colors.black26,
                      offset: Offset(2, 2),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Pexels Gallery',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== MAIN APP ====================
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pexels App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Poppins',
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Color(0xFF1976D2),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

// ==================== NAVIGATION PRENSIPAL ====================
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    PhotographersScreen(),
    FavoritesScreen(),
    LocalScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF1976D2),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.photo_library), label: 'Fotograf'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Favori'),
          BottomNavigationBarItem(icon: Icon(Icons.folder), label: 'Lokal'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Pwofil'),
        ],
      ),
    );
  }
}

// ==================== EKRAN FOTOGRAF ====================
class PhotographersScreen extends StatefulWidget {
  const PhotographersScreen({super.key});

  @override
  State<PhotographersScreen> createState() => _PhotographersScreenState();
}

class _PhotographersScreenState extends State<PhotographersScreen> {
  Map<int, Photographer> _photographers = {};
  Map<int, List<Photo>> _photographerPhotos = {};
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  List<Photographer> _filteredPhotographers = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final photos = await APIService.getCuratedPhotos(perPage: 80);

      for (var photo in photos) {
        if (!_photographers.containsKey(photo.photographerId)) {
          _photographers[photo.photographerId] = Photographer(
            photographerId: photo.photographerId,
            photographer: photo.photographer,
            photographerUrl: photo.photographerUrl,
          );
          _photographerPhotos[photo.photographerId] = [];
        }
        _photographerPhotos[photo.photographerId]?.add(photo);
      }

      for (var photographer in _photographers.values) {
        try {
          final count = await APIService.getPhotographerPhotoCount(
            photographer.photographer,
          );
          photographer.totalPhotos = count;
        } catch (e) {
          photographer.totalPhotos =
              _photographerPhotos[photographer.photographerId]?.length ?? 0;
        }
      }

      setState(() {
        _filteredPhotographers = _photographers.values.toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showMessage('Erè: $e');
    }
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Chèche fotograf...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                onChanged: (query) {
                  setState(() {
                    if (query.isEmpty) {
                      _filteredPhotographers = _photographers.values.toList();
                    } else {
                      _filteredPhotographers = _photographers.values
                          .where((p) => p.photographer
                              .toLowerCase()
                              .contains(query.toLowerCase()))
                          .toList();
                    }
                  });
                },
              )
            : const Text('Fotograf yo'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _filteredPhotographers = _photographers.values.toList();
                }
              });
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _filteredPhotographers.length,
              itemBuilder: (context, index) {
                final photographer = _filteredPhotographers[index];
                final previewPhotos =
                    _photographerPhotos[photographer.photographerId] ?? [];

                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: InkWell(
                    onTap: () async {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => const Center(
                          child: CircularProgressIndicator(),
                        ),
                      );

                      try {
                        final allPhotos =
                            await APIService.getAllPhotosByPhotographer(
                          photographer.photographer,
                          perPage: 80,
                        );

                        if (context.mounted) {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PhotoScreen(
                                photographer: photographer,
                                initialPhotos: allPhotos,
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          Navigator.pop(context);
                          _showMessage('Pa ka chaje tout foto yo');
                        }
                      }
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF1976D2),
                                      Color(0xFF64B5F6)
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    photographer.photographer[0].toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      photographer.photographer,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '${photographer.totalPhotos} foto',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_ios,
                                color: Color(0xFF1976D2),
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                        if (previewPhotos.isNotEmpty)
                          SizedBox(
                            height: 100,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              itemCount: previewPhotos.length > 8
                                  ? 8
                                  : previewPhotos.length,
                              itemBuilder: (context, photoIndex) {
                                final photo = previewPhotos[photoIndex];
                                return Container(
                                  width: 70,
                                  height: 70,
                                  margin: const EdgeInsets.only(right: 6),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    image: DecorationImage(
                                      image: NetworkImage(photo.src),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// ==================== EKRAN DETAY FOTO ====================
class PhotoDetailScreen extends StatefulWidget {
  final Photo photo;
  final bool isFavorite;
  final bool isLocal;
  final Function(String) onToggleFavorite;
  final Function(String) onToggleLocal;

  const PhotoDetailScreen({
    super.key,
    required this.photo,
    required this.isFavorite,
    required this.isLocal,
    required this.onToggleFavorite,
    required this.onToggleLocal,
  });

  @override
  State<PhotoDetailScreen> createState() => _PhotoDetailScreenState();
}

class _PhotoDetailScreenState extends State<PhotoDetailScreen> {
  late bool _isFavorite;
  late bool _isLocal;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.isFavorite;
    _isLocal = widget.isLocal;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? Colors.red : Colors.white,
              size: 28,
            ),
            onPressed: () {
              setState(() {
                _isFavorite = !_isFavorite;
              });
              widget.onToggleFavorite(widget.photo.id.toString());
            },
          ),
          IconButton(
            icon: Icon(
              _isLocal ? Icons.check_circle : Icons.add_circle_outline,
              color: _isLocal ? Colors.green : Colors.white,
              size: 28,
            ),
            onPressed: () {
              setState(() {
                _isLocal = !_isLocal;
              });
              widget.onToggleLocal(widget.photo.id.toString());
            },
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          panEnabled: true,
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.network(
            widget.photo.src.replaceFirst('medium', 'large'),
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

// ==================== EKRAN FOTO PA FOTOGRAF ====================
class PhotoScreen extends StatefulWidget {
  final Photographer photographer;
  final List<Photo> initialPhotos;

  const PhotoScreen({
    super.key,
    required this.photographer,
    required this.initialPhotos,
  });

  @override
  State<PhotoScreen> createState() => _PhotoScreenState();
}

class _PhotoScreenState extends State<PhotoScreen> {
  late List<Photo> photos;
  Set<String> favoritePhotos = {};
  Set<String> localPhotos = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    photos = widget.initialPhotos;
    _loadSavedData();
  }

  Future<void> _loadSavedData() async {
    final favIds = await StorageHelper.getFavoriteIds();
    final locIds = await StorageHelper.getLocalPhotoIds();

    setState(() {
      favoritePhotos = favIds;
      localPhotos = locIds;
      _isLoading = false;
    });
  }

  void _toggleFavorite(String photoId) async {
    final photo = photos.firstWhere((p) => p.id.toString() == photoId);

    setState(() {
      if (favoritePhotos.contains(photoId)) {
        favoritePhotos.remove(photoId);
      } else {
        favoritePhotos.add(photoId);
      }
    });

    if (favoritePhotos.contains(photoId)) {
      await StorageHelper.addFavorite(photo);
      _showMessage('Foto ajoute nan favori');
    } else {
      await StorageHelper.removeFavorite(photoId);
      _showMessage('Foto retire nan favori');
    }
  }

  void _toggleLocal(String photoId) async {
    final photo = photos.firstWhere((p) => p.id.toString() == photoId);

    setState(() {
      if (localPhotos.contains(photoId)) {
        localPhotos.remove(photoId);
      } else {
        localPhotos.add(photoId);
      }
    });

    if (localPhotos.contains(photoId)) {
      await StorageHelper.addLocalPhoto(photo);
      _showMessage('Foto ajoute nan lokal');
    } else {
      await StorageHelper.removeLocalPhoto(photoId);
      _showMessage('Foto retire nan lokal');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1976D2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FF),
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              widget.photographer.photographer,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              '${photos.length} foto',
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : photos.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.photo_library_outlined,
                          size: 80, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'Pa gen foto',
                        style: TextStyle(
                            fontSize: 18, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(4),
                  itemCount: photos.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                    childAspectRatio: 1,
                  ),
                  itemBuilder: (context, index) {
                    final photo = photos[index];
                    final isFavorite =
                        favoritePhotos.contains(photo.id.toString());
                    final isLocal = localPhotos.contains(photo.id.toString());

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PhotoDetailScreen(
                              photo: photo,
                              isFavorite: isFavorite,
                              isLocal: isLocal,
                              onToggleFavorite: _toggleFavorite,
                              onToggleLocal: _toggleLocal,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.network(
                                photo.src,
                                fit: BoxFit.cover,
                              ),
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: Container(
                                  height: 16,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withOpacity(0.5)
                                      ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 1,
                                left: 1,
                                right: 1,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _buildMiniIconButton(
                                      icon: isFavorite
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      color: isFavorite
                                          ? Colors.red
                                          : Colors.white,
                                      onPressed: () =>
                                          _toggleFavorite(photo.id.toString()),
                                    ),
                                    _buildMiniIconButton(
                                      icon: isLocal
                                          ? Icons.check_circle
                                          : Icons.add_circle_outline,
                                      color: isLocal
                                          ? Colors.greenAccent
                                          : Colors.white,
                                      onPressed: () =>
                                          _toggleLocal(photo.id.toString()),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildMiniIconButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: color,
          size: 10,
        ),
      ),
    );
  }
}
