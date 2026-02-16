import 'package:flutter/material.dart';
import 'api_service.dart';
import 'models.dart';
import 'storage_helper.dart';

const _kPrimaryColor = Color(0xFF1976D2);
const _kSecondaryColor = Color(0xFF64B5F6);
const _kBlueGradient = [Color(0xFF1976D2), Color(0xFF64B5F6)];

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
            colors: _kBlueGradient,
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
                    color: _kPrimaryColor,
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
                style: TextStyle(fontSize: 18, color: Colors.white70),
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
          backgroundColor: _kPrimaryColor,
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
        selectedItemColor: _kPrimaryColor,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.photo_library),
            label: 'Fotograf',
          ),
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
  final Map<int, Photographer> _photographers = {};
  final Map<int, List<Photo>> _photographerPhotos = {};
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
        _photographers.putIfAbsent(
          photo.photographerId,
          () => Photographer(
            photographerId: photo.photographerId,
            photographer: photo.photographer,
            photographerUrl: photo.photographerUrl,
          ),
        );
        _photographerPhotos
            .putIfAbsent(photo.photographerId, () => [])
            .add(photo);
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _filterPhotographers(String query) {
    final normalizedQuery = query.toLowerCase();
    setState(() {
      _filteredPhotographers = query.isEmpty
          ? _photographers.values.toList()
          : _photographers.values
              .where(
                (p) => p.photographer.toLowerCase().contains(normalizedQuery),
              )
              .toList();
    });
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _filteredPhotographers = _photographers.values.toList();
      }
    });
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
                onChanged: _filterPhotographers,
              )
            : const Text('Fotograf yo'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: _toggleSearch,
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
                        builder: (context) =>
                            const Center(child: CircularProgressIndicator()),
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
                                    colors: _kBlueGradient,
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
                                color: _kPrimaryColor,
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
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
    final results = await Future.wait<Set<String>>([
      StorageHelper.getFavoriteIds(),
      StorageHelper.getLocalPhotoIds(),
    ]);

    setState(() {
      favoritePhotos = results[0];
      localPhotos = results[1];
      _isLoading = false;
    });
  }

  Future<void> _toggleSavedPhoto({
    required String photoId,
    required Set<String> targetIds,
    required Future<void> Function(Photo) addAction,
    required Future<void> Function(String) removeAction,
    required String addMessage,
    required String removeMessage,
  }) async {
    final photo = photos.firstWhere((p) => p.id.toString() == photoId);
    final wasPresent = targetIds.contains(photoId);

    setState(() {
      if (wasPresent) {
        targetIds.remove(photoId);
      } else {
        targetIds.add(photoId);
      }
    });

    if (wasPresent) {
      await removeAction(photoId);
      _showMessage(removeMessage);
    } else {
      await addAction(photo);
      _showMessage(addMessage);
    }
  }

  Future<void> _toggleFavorite(String photoId) => _toggleSavedPhoto(
        photoId: photoId,
        targetIds: favoritePhotos,
        addAction: StorageHelper.addFavorite,
        removeAction: StorageHelper.removeFavorite,
        addMessage: 'Foto ajoute nan favori',
        removeMessage: 'Foto retire nan favori',
      );

  Future<void> _toggleLocal(String photoId) => _toggleSavedPhoto(
        photoId: photoId,
        targetIds: localPhotos,
        addAction: StorageHelper.addLocalPhoto,
        removeAction: StorageHelper.removeLocalPhoto,
        addMessage: 'Foto ajoute nan lokal',
        removeMessage: 'Foto retire nan lokal',
      );

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: _kPrimaryColor,
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
              ? const _EmptyState(
                  icon: Icons.photo_library_outlined,
                  text: 'Pa gen foto',
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
                    final photoId = photo.id.toString();
                    final isFavorite = favoritePhotos.contains(photoId);
                    final isLocal = localPhotos.contains(photoId);

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
                              Image.network(photo.src, fit: BoxFit.cover),
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
                                        Colors.black.withOpacity(0.5),
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
                                      onPressed: () => _toggleFavorite(photoId),
                                    ),
                                    _buildMiniIconButton(
                                      icon: isLocal
                                          ? Icons.check_circle
                                          : Icons.add_circle_outline,
                                      color: isLocal
                                          ? Colors.greenAccent
                                          : Colors.white,
                                      onPressed: () => _toggleLocal(photoId),
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
        child: Icon(icon, color: color, size: 10),
      ),
    );
  }
}

// ==================== EKRAN FAVORI ====================
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const _PhotoCollectionScreen(
      titlePrefix: 'Favori mwen',
      loadPhotos: StorageHelper.getFavoritePhotos,
      loadIds: StorageHelper.getFavoriteIds,
      removePhoto: StorageHelper.removeFavorite,
      emptyIcon: Icons.favorite_border,
      emptyText: 'Pa gen foto favori',
      loadErrorText: 'Pa ka chaje foto favori yo',
      removeSuccessText: 'Foto retire nan favori',
    );
  }
}

// ==================== EKRAN LOKAL ====================
class LocalScreen extends StatelessWidget {
  const LocalScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const _PhotoCollectionScreen(
      titlePrefix: 'Foto lokal',
      loadPhotos: StorageHelper.getLocalPhotos,
      loadIds: StorageHelper.getLocalPhotoIds,
      removePhoto: StorageHelper.removeLocalPhoto,
      emptyIcon: Icons.folder_open,
      emptyText: 'Pa gen foto lokal',
      loadErrorText: 'Pa ka chaje foto lokal yo',
      removeSuccessText: 'Foto retire nan lokal',
    );
  }
}

class _PhotoCollectionScreen extends StatefulWidget {
  final String titlePrefix;
  final Future<List<Photo>> Function() loadPhotos;
  final Future<Set<String>> Function() loadIds;
  final Future<void> Function(String) removePhoto;
  final IconData emptyIcon;
  final String emptyText;
  final String loadErrorText;
  final String removeSuccessText;

  const _PhotoCollectionScreen({
    required this.titlePrefix,
    required this.loadPhotos,
    required this.loadIds,
    required this.removePhoto,
    required this.emptyIcon,
    required this.emptyText,
    required this.loadErrorText,
    required this.removeSuccessText,
  });

  @override
  State<_PhotoCollectionScreen> createState() => _PhotoCollectionScreenState();
}

class _PhotoCollectionScreenState extends State<_PhotoCollectionScreen> {
  List<Photo> _photos = [];
  Set<String> _ids = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final photos = await widget.loadPhotos();
      final ids = await widget.loadIds();
      setState(() {
        _photos = photos;
        _ids = ids;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
      _showMessage(widget.loadErrorText);
    }
  }

  Future<void> _remove(String id) async {
    await widget.removePhoto(id);
    await _load();
    _showMessage(widget.removeSuccessText);
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.titlePrefix} (${_ids.length})')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _ids.isEmpty
              ? _EmptyState(
                  icon: widget.emptyIcon,
                  text: widget.emptyText,
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(6),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 6,
                    mainAxisSpacing: 6,
                    childAspectRatio: 1,
                  ),
                  itemCount: _photos.length,
                  itemBuilder: (context, index) {
                    final photo = _photos[index];
                    return _PhotoGridItem(
                      photo: photo,
                      onDelete: () => _remove(photo.id.toString()),
                    );
                  },
                ),
    );
  }
}

class _PhotoGridItem extends StatelessWidget {
  final Photo photo;
  final VoidCallback onDelete;

  const _PhotoGridItem({required this.photo, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Image.network(photo.src, fit: BoxFit.cover),
        ),
        Positioned(
          top: 2,
          right: 2,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red, size: 14),
              onPressed: onDelete,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 22, height: 22),
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String text;

  const _EmptyState({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(text,
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}

// EKRAN PWOFIL
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pwofil'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1976D2), Color(0xFF64B5F6)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(
                Icons.person,
                size: 60,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'App Foto',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1976D2),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Vèsyon 1.1.0',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 40),
            Container(
              width: 280,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                children: [
                  const ListTile(
                    leading: Icon(Icons.info, color: Color(0xFF1976D2)),
                    title: Text('Sou app la'),
                    subtitle: Text('App Pexels pou gade foto'),
                  ),
                  const Divider(),
                  const ListTile(
                    leading: Icon(Icons.settings, color: Color(0xFF1976D2)),
                    title: Text('API Key'),
                    subtitle: Text('Pexels API'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
