import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

class StorageHelper {
  static const String _favoritesKey = 'favorites';
  static const String _localKey = 'local_photos';

  // FAVORI
  static Future<List<Photo>> getFavoritePhotos() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_favoritesKey) ?? [];
    return jsonList.map((jsonStr) {
      final json = jsonDecode(jsonStr);
      return Photo.fromJson(json);
    }).toList();
  }

  static Future<void> addFavorite(Photo photo) async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = await getFavoritePhotos();

    if (!favorites.any((p) => p.id == photo.id)) {
      favorites.add(photo);
      final jsonList = favorites
          .map(
            (p) => jsonEncode({
          'id': p.id,
          'photographer_id': p.photographerId,
          'photographer': p.photographer,
          'photographer_url': p.photographerUrl,
          'url': p.url,
          'src': {'medium': p.src},
        }),
      )
          .toList();
      await prefs.setStringList(_favoritesKey, jsonList);
    }
  }

  static Future<void> removeFavorite(String photoId) async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = await getFavoritePhotos();
    favorites.removeWhere((p) => p.id.toString() == photoId);

    final jsonList = favorites
        .map(
          (p) => jsonEncode({
        'id': p.id,
        'photographer_id': p.photographerId,
        'photographer': p.photographer,
        'photographer_url': p.photographerUrl,
        'url': p.url,
        'src': {'medium': p.src},
      }),
    )
        .toList();
    await prefs.setStringList(_favoritesKey, jsonList);
  }

  static Future<bool> isFavorite(String photoId) async {
    final favorites = await getFavoritePhotos();
    return favorites.any((p) => p.id.toString() == photoId);
  }

  static Future<Set<String>> getFavoriteIds() async {
    final favorites = await getFavoritePhotos();
    return favorites.map((p) => p.id.toString()).toSet();
  }

  // LOKAL
  static Future<List<Photo>> getLocalPhotos() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_localKey) ?? [];
    return jsonList.map((jsonStr) {
      final json = jsonDecode(jsonStr);
      return Photo.fromJson(json);
    }).toList();
  }

  static Future<void> addLocalPhoto(Photo photo) async {
    final prefs = await SharedPreferences.getInstance();
    final localPhotos = await getLocalPhotos();

    if (!localPhotos.any((p) => p.id == photo.id)) {
      localPhotos.add(photo);
      final jsonList = localPhotos
          .map(
            (p) => jsonEncode({
          'id': p.id,
          'photographer_id': p.photographerId,
          'photographer': p.photographer,
          'photographer_url': p.photographerUrl,
          'url': p.url,
          'src': {'medium': p.src},
        }),
      )
          .toList();
      await prefs.setStringList(_localKey, jsonList);
    }
  }

  static Future<void> removeLocalPhoto(String photoId) async {
    final prefs = await SharedPreferences.getInstance();
    final localPhotos = await getLocalPhotos();
    localPhotos.removeWhere((p) => p.id.toString() == photoId);

    final jsonList = localPhotos
        .map(
          (p) => jsonEncode({
        'id': p.id,
        'photographer_id': p.photographerId,
        'photographer': p.photographer,
        'photographer_url': p.photographerUrl,
        'url': p.url,
        'src': {'medium': p.src},
      }),
    )
        .toList();
    await prefs.setStringList(_localKey, jsonList);
  }

  static Future<bool> isLocal(String photoId) async {
    final localPhotos = await getLocalPhotos();
    return localPhotos.any((p) => p.id.toString() == photoId);
  }

  static Future<Set<String>> getLocalPhotoIds() async {
    final localPhotos = await getLocalPhotos();
    return localPhotos.map((p) => p.id.toString()).toSet();
  }
}