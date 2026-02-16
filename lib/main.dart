import 'package:flutter/material.dart';
import 'api_service.dart';
import 'models.dart';
import 'storage_helper.dart';

const kPrimaryColor = Color(0xFF1976D2);
const kBlueGradient = [Color(0xFF1976D2), Color(0xFF64B5F6)];

void main() => runApp(const MyApp());

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
          backgroundColor: kPrimaryColor,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

// ==================== SPLASH ====================
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
    _controller =
        AnimationController(duration: const Duration(seconds: 2), vsync: this);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _controller.forward();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
        );
      }
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
              colors: kBlueGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
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
                          spreadRadius: 5)
                    ],
                  ),
                  child: const Icon(Icons.photo_camera,
                      size: 80, color: kPrimaryColor),
                ),
              ),
              const SizedBox(height: 30),
              const Text('App Foto',
                  style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                            blurRadius: 10,
                            color: Colors.black26,
                            offset: Offset(2, 2))
                      ])),
              const SizedBox(height: 10),
              const Text('Pexels Gallery',
                  style: TextStyle(fontSize: 18, color: Colors.white70)),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== NAVIGATION ====================
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});
  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  final _screens = const [
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
        onTap: (i) => setState(() => _selectedIndex = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: kPrimaryColor,
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

// ==================== FOTOGRAF ====================
class PhotographersScreen extends StatefulWidget {
  const PhotographersScreen({super.key});
  @override
  State<PhotographersScreen> createState() => _PhotographersScreenState();
}

class _PhotographersScreenState extends State<PhotographersScreen> {
  final _photographers = <int, Photographer>{};
  final _photographerPhotos = <int, List<Photo>>{};
  var _filtered = <Photographer>[];
  var _isLoading = true;
  var _isSearching = false;
  final _searchController = TextEditingController();

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
              photographerUrl: photo.photographerUrl),
        );
        _photographerPhotos
            .putIfAbsent(photo.photographerId, () => [])
            .add(photo);
      }

      for (var photographer in _photographers.values) {
        try {
          photographer.totalPhotos = await APIService.getPhotographerPhotoCount(
              photographer.photographer);
        } catch (_) {
          photographer.totalPhotos =
              _photographerPhotos[photographer.photographerId]?.length ?? 0;
        }
      }

      setState(() {
        _filtered = _photographers.values.toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showMsg('Erè: $e');
    }
  }

  void _filter(String q) {
    final normalized = q.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? _photographers.values.toList()
          : _photographers.values
              .where((p) => p.photographer.toLowerCase().contains(normalized))
              .toList();
    });
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _filtered = _photographers.values.toList();
      }
    });
  }

  void _showMsg(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

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
                    border: InputBorder.none),
                onChanged: _filter,
              )
            : const Text('Fotograf yo'),
        actions: [
          IconButton(
              icon: Icon(_isSearching ? Icons.close : Icons.search),
              onPressed: _toggleSearch)
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _filtered.length,
              itemBuilder: (context, i) {
                final photographer = _filtered[i];
                final previewPhotos =
                    _photographerPhotos[photographer.photographerId] ?? [];
                return _PhotographerCard(
                  photographer: photographer,
                  previewPhotos: previewPhotos,
                  onTap: () => _openPhotographer(photographer),
                );
              },
            ),
    );
  }

  Future<void> _openPhotographer(Photographer photographer) async {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()));
    try {
      final photos = await APIService.getAllPhotosByPhotographer(
          photographer.photographer,
          perPage: 80);
      if (mounted) {
        Navigator.pop(context);
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => PhotoScreen(
                    photographer: photographer, initialPhotos: photos)));
      }
    } catch (_) {
      if (mounted) {
        Navigator.pop(context);
        _showMsg('Pa ka chaje tout foto yo');
      }
    }
  }
}

class _PhotographerCard extends StatelessWidget {
  final Photographer photographer;
  final List<Photo> previewPhotos;
  final VoidCallback onTap;

  const _PhotographerCard(
      {required this.photographer,
      required this.previewPhotos,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
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
                    decoration: const BoxDecoration(
                        gradient: LinearGradient(colors: kBlueGradient),
                        shape: BoxShape.circle),
                    child: Center(
                        child: Text(photographer.photographer[0].toUpperCase(),
                            style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(photographer.photographer,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('${photographer.totalPhotos} foto',
                            style: TextStyle(color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios,
                      color: kPrimaryColor, size: 16),
                ],
              ),
            ),
            if (previewPhotos.isNotEmpty)
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount:
                      previewPhotos.length > 8 ? 8 : previewPhotos.length,
                  itemBuilder: (_, i) => Container(
                    width: 70,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        image: DecorationImage(
                            image: NetworkImage(previewPhotos[i].src),
                            fit: BoxFit.cover)),
                  ),
                ),
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

// ==================== PHOTO SCREEN ====================
class PhotoScreen extends StatefulWidget {
  final Photographer photographer;
  final List<Photo> initialPhotos;

  const PhotoScreen(
      {super.key, required this.photographer, required this.initialPhotos});

  @override
  State<PhotoScreen> createState() => _PhotoScreenState();
}

class _PhotoScreenState extends State<PhotoScreen> {
  late List<Photo> photos;
  var favoriteIds = <String>{};
  var localIds = <String>{};
  var _isLoading = true;

  @override
  void initState() {
    super.initState();
    photos = widget.initialPhotos;
    _loadSavedData();
  }

  Future<void> _loadSavedData() async {
    final results = await Future.wait(
        [StorageHelper.getFavoriteIds(), StorageHelper.getLocalPhotoIds()]);
    setState(() {
      favoriteIds = results[0];
      localIds = results[1];
      _isLoading = false;
    });
  }

  Future<void> _toggle(
      String id,
      Set<String> ids,
      Future<void> Function(Photo) add,
      Future<void> Function(String) remove,
      String addMsg,
      String removeMsg) async {
    final photo = photos.firstWhere((p) => p.id.toString() == id);
    final wasPresent = ids.contains(id);
    setState(() => wasPresent ? ids.remove(id) : ids.add(id));
    wasPresent ? await remove(id) : await add(photo);
    _showMsg(wasPresent ? removeMsg : addMsg);
  }

  void _showMsg(String m) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(m),
          behavior: SnackBarBehavior.floating,
          backgroundColor: kPrimaryColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 1)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FF),
      appBar: AppBar(
        title: Column(
          children: [
            Text(widget.photographer.photographer,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text('${photos.length} foto',
                style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : photos.isEmpty
              ? const EmptyState(
                  icon: Icons.photo_library_outlined, text: 'Pa gen foto')
              : GridView.builder(
                  padding: const EdgeInsets.all(4),
                  itemCount: photos.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 4,
                      mainAxisSpacing: 4,
                      childAspectRatio: 1),
                  itemBuilder: (_, i) {
                    final photo = photos[i];
                    final id = photo.id.toString();
                    return GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PhotoDetailScreen(
                            photo: photo,
                            isFavorite: favoriteIds.contains(id),
                            isLocal: localIds.contains(id),
                            onToggleFavorite: (id) => _toggle(
                                id,
                                favoriteIds,
                                StorageHelper.addFavorite,
                                StorageHelper.removeFavorite,
                                'Foto ajoute nan favori',
                                'Foto retire nan favori'),
                            onToggleLocal: (id) => _toggle(
                                id,
                                localIds,
                                StorageHelper.addLocalPhoto,
                                StorageHelper.removeLocalPhoto,
                                'Foto ajoute nan lokal',
                                'Foto retire nan lokal'),
                          ),
                        ),
                      ),
                      child: _PhotoGridTile(
                          photo: photo,
                          isFavorite: favoriteIds.contains(id),
                          isLocal: localIds.contains(id),
                          onFavTap: () => _toggle(
                              id,
                              favoriteIds,
                              StorageHelper.addFavorite,
                              StorageHelper.removeFavorite,
                              'Foto ajoute nan favori',
                              'Foto retire nan favori'),
                          onLocalTap: () => _toggle(
                              id,
                              localIds,
                              StorageHelper.addLocalPhoto,
                              StorageHelper.removeLocalPhoto,
                              'Foto ajoute nan lokal',
                              'Foto retire nan lokal')),
                    );
                  },
                ),
    );
  }
}

class _PhotoGridTile extends StatelessWidget {
  final Photo photo;
  final bool isFavorite, isLocal;
  final VoidCallback onFavTap, onLocalTap;

  const _PhotoGridTile(
      {required this.photo,
      required this.isFavorite,
      required this.isLocal,
      required this.onFavTap,
      required this.onLocalTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration:
          BoxDecoration(borderRadius: BorderRadius.circular(4), boxShadow: [
        BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 2,
            offset: const Offset(0, 1))
      ]),
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
                      gradient: LinearGradient(colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.5)
                  ], begin: Alignment.topCenter, end: Alignment.bottomCenter))),
            ),
            Positioned(
              bottom: 1,
              left: 1,
              right: 1,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _MiniIconBtn(
                      icon: isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? Colors.red : Colors.white,
                      onTap: onFavTap),
                  _MiniIconBtn(
                      icon: isLocal
                          ? Icons.check_circle
                          : Icons.add_circle_outline,
                      color: isLocal ? Colors.greenAccent : Colors.white,
                      onTap: onLocalTap),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniIconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _MiniIconBtn(
      {required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
          padding: const EdgeInsets.all(1),
          decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 10)),
    );
  }
}

// ==================== PHOTO DETAIL ====================
class PhotoDetailScreen extends StatefulWidget {
  final Photo photo;
  final bool isFavorite, isLocal;
  final Function(String) onToggleFavorite, onToggleLocal;

  const PhotoDetailScreen(
      {super.key,
      required this.photo,
      required this.isFavorite,
      required this.isLocal,
      required this.onToggleFavorite,
      required this.onToggleLocal});

  @override
  State<PhotoDetailScreen> createState() => _PhotoDetailScreenState();
}

class _PhotoDetailScreenState extends State<PhotoDetailScreen> {
  late bool _isFavorite, _isLocal;

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
            onPressed: () => Navigator.pop(context)),
        actions: [
          IconButton(
            icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border,
                color: _isFavorite ? Colors.red : Colors.white, size: 28),
            onPressed: () {
              setState(() => _isFavorite = !_isFavorite);
              widget.onToggleFavorite(widget.photo.id.toString());
            },
          ),
          IconButton(
            icon: Icon(_isLocal ? Icons.check_circle : Icons.add_circle_outline,
                color: _isLocal ? Colors.green : Colors.white, size: 28),
            onPressed: () {
              setState(() => _isLocal = !_isLocal);
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
                  fit: BoxFit.contain))),
    );
  }
}

// ==================== FAVORI & LOKAL ====================
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});
  @override
  Widget build(BuildContext context) => const PhotoCollectionScreen(
      title: 'Favori mwen',
      load: StorageHelper.getFavoritePhotos,
      loadIds: StorageHelper.getFavoriteIds,
      remove: StorageHelper.removeFavorite,
      emptyIcon: Icons.favorite_border,
      emptyText: 'Pa gen foto favori',
      errorText: 'Pa ka chaje foto favori yo',
      successText: 'Foto retire nan favori');
}

class LocalScreen extends StatelessWidget {
  const LocalScreen({super.key});
  @override
  Widget build(BuildContext context) => const PhotoCollectionScreen(
      title: 'Foto lokal',
      load: StorageHelper.getLocalPhotos,
      loadIds: StorageHelper.getLocalPhotoIds,
      remove: StorageHelper.removeLocalPhoto,
      emptyIcon: Icons.folder_open,
      emptyText: 'Pa gen foto lokal',
      errorText: 'Pa ka chaje foto lokal yo',
      successText: 'Foto retire nan lokal');
}

class PhotoCollectionScreen extends StatefulWidget {
  final String title, emptyText, errorText, successText;
  final Future<List<Photo>> Function() load;
  final Future<Set<String>> Function() loadIds;
  final Future<void> Function(String) remove;
  final IconData emptyIcon;

  const PhotoCollectionScreen(
      {super.key,
      required this.title,
      required this.load,
      required this.loadIds,
      required this.remove,
      required this.emptyIcon,
      required this.emptyText,
      required this.errorText,
      required this.successText});

  @override
  State<PhotoCollectionScreen> createState() => _PhotoCollectionScreenState();
}

class _PhotoCollectionScreenState extends State<PhotoCollectionScreen> {
  var _photos = <Photo>[];
  var _ids = <String>{};
  var _isLoading = true;

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
      final photos = await widget.load();
      final ids = await widget.loadIds();
      setState(() {
        _photos = photos;
        _ids = ids;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
      _showMsg(widget.errorText);
    }
  }

  Future<void> _remove(String id) async {
    await widget.remove(id);
    await _load();
    _showMsg(widget.successText);
  }

  void _showMsg(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.title} (${_ids.length})')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _ids.isEmpty
              ? EmptyState(icon: widget.emptyIcon, text: widget.emptyText)
              : GridView.builder(
                  padding: const EdgeInsets.all(6),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 6,
                      mainAxisSpacing: 6,
                      childAspectRatio: 1),
                  itemCount: _photos.length,
                  itemBuilder: (_, i) => PhotoGridItem(
                      photo: _photos[i],
                      onDelete: () => _remove(_photos[i].id.toString())),
                ),
    );
  }
}

class PhotoGridItem extends StatelessWidget {
  final Photo photo;
  final VoidCallback onDelete;

  const PhotoGridItem({super.key, required this.photo, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.network(photo.src, fit: BoxFit.cover)),
        Positioned(
          top: 2,
          right: 2,
          child: Container(
            decoration: const BoxDecoration(
                color: Colors.white, shape: BoxShape.circle),
            child: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red, size: 14),
                onPressed: onDelete,
                padding: EdgeInsets.zero,
                constraints:
                    const BoxConstraints.tightFor(width: 22, height: 22)),
          ),
        ),
      ],
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String text;

  const EmptyState({super.key, required this.icon, required this.text});

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

// ==================== PWOFIL ====================
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pwofil')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: kBlueGradient),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5)
                  ]),
              child: const Icon(Icons.person, size: 60, color: Colors.white),
            ),
            const SizedBox(height: 24),
            const Text('App Foto',
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: kPrimaryColor)),
            const SizedBox(height: 8),
            Text('Vèsyon 1.1.0',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
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
                        spreadRadius: 2)
                  ]),
              child: const Column(
                children: [
                  ListTile(
                      leading: Icon(Icons.info, color: kPrimaryColor),
                      title: Text('Sou app la'),
                      subtitle: Text('App Pexels pou gade foto')),
                  Divider(),
                  ListTile(
                      leading: Icon(Icons.settings, color: kPrimaryColor),
                      title: Text('API Key'),
                      subtitle: Text('Pexels API')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
