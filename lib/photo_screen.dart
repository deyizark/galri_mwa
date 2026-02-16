import 'package:flutter/material.dart';
import 'models.dart';
import 'api_service.dart';

class PhotoScreen extends StatefulWidget {
  final Photographer photographer;

  const PhotoScreen({super.key, required this.photographer});

  @override
  State<PhotoScreen> createState() => _PhotoScreenState();
}

class _PhotoScreenState extends State<PhotoScreen> {

  final url = "https://api.pexels.com/v1/curated";
  List allInfo = [];
  List<Photo> allPhotos = [];
  // List<Photographer> AllPhotographers = [];


  void getAllPhotosAndPhotographer() async {
    dynamic info = await APIService.get(url);

    List data = info["photos"];

    setState(() {
      allInfo = info;

      allPhotos = data.map((item) {
        return Photo(
          id: item["id"],
          url: item["src"]["original"],
          photographerId: item["photographer_id"],
        );
      }).toList();

      // AllPhotographers = data.map((item) {
      //   return Photographer(
      //     photographerId: item["photographer_id"],
      //     photographer: item["photographer"],
      //   );
      // }).toList();
    });
  }

  @override
  void initState() {
    super.initState();
    getAllPhotosAndPhotographer();
  }

  @override

  // final List<Photo> allPhotos = [
  //   Photo(id: 1, url: "https://picsum.photos/300", photographerId: 1),
  //   Photo(id: 2, url: "https://picsum.photos/301", photographerId: 1),
  //   Photo(id: 3, url: "https://picsum.photos/302", photographerId: 1),
  //   Photo(id: 4, url: "https://picsum.photos/303", photographerId: 2),
  // ];

  final Set<String> favoritePhotos = {};
  final Set<String> localPhotos = {};

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1976D2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final photos = allPhotos
        .where((p) => p.photographerId == widget.photographer.photographerId)
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FF),

      appBar: AppBar(
        backgroundColor: const Color(0xFF1976D2),
        elevation: 0,
        title: Text(
          widget.photographer.photographer,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),

      body: GridView.builder(
        padding: const EdgeInsets.all(14),
        itemCount: photos.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1,
        ),
        itemBuilder: (context, index) {
          final photo = photos[index];
          final isFavorite = favoritePhotos.contains(photo.id);
          final isLocal = localPhotos.contains(photo.id);

          return GestureDetector(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image.network(photo.url, fit: BoxFit.cover),
                    ),

                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.transparent, Colors.black54],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: Icon(
                                isFavorite
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: isFavorite ? Colors.red : Colors.white,
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  if (isFavorite) {
                                    favoritePhotos.remove(photo.id.toString());
                                    showMessage("Foto retire nan favori");
                                  } else {
                                    favoritePhotos.add(photo.id.toString());
                                    showMessage("Foto ajoute nan favori");
                                  }
                                });
                              },
                            ),

                            IconButton(
                              icon: Icon(
                                isLocal
                                    ? Icons.check_circle
                                    : Icons.add_circle_outline,
                                color: isLocal
                                    ? Colors.greenAccent
                                    : Colors.white,
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  if (isLocal) {
                                    localPhotos.remove(photo.id.toString());
                                    showMessage("Foto retire nan lokal");
                                  } else {
                                    localPhotos.add(photo.id.toString());
                                    showMessage("Foto ajoute nan lokal");
                                  }
                                });
                              },
                            ),
                          ],
                        ),
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
}
