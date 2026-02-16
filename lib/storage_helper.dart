import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

class StorageHelper {
  static const String _favoritesKey = 'favorites';
  static const String _localKey = 'local_photos';

  static Future<List<Photo>> _getPhotos(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(key) ?? [])
        .map((s) => Photo.fromJson(jsonDecode(s)))
        .toList();
  }

  static Future<void> _savePhotos(String key, List<Photo> photos) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      key,
      photos.map((p) => jsonEncode(p.toJson())).toList(),
    );
  }

  static Future<void> _addPhoto(String key, Photo photo) async {
    final photos = await _getPhotos(key);
    if (photos.any((p) => p.id == photo.id)) return;
    photos.add(photo);
    await _savePhotos(key, photos);
  }

  static Future<void> _removePhoto(String key, String photoId) async {
    final photos = await _getPhotos(key)
      ..removeWhere((p) => p.id.toString() == photoId);
    await _savePhotos(key, photos);
  }

  static Future<Set<String>> _getIds(String key) async =>
      (await _getPhotos(key)).map((p) => p.id.toString()).toSet();

  static Future<bool> _containsPhoto(String key, String photoId) async =>
      (await _getPhotos(key)).any((p) => p.id.toString() == photoId);

  static Future<List<Photo>> getFavoritePhotos() => _getPhotos(_favoritesKey);

  static Future<void> addFavorite(Photo photo) => _addPhoto(_favoritesKey, photo);

  static Future<void> removeFavorite(String photoId) =>
      _removePhoto(_favoritesKey, photoId);

  static Future<bool> isFavorite(String photoId) =>
      _containsPhoto(_favoritesKey, photoId);

  static Future<Set<String>> getFavoriteIds() => _getIds(_favoritesKey);

  static Future<List<Photo>> getLocalPhotos() => _getPhotos(_localKey);

  static Future<void> addLocalPhoto(Photo photo) => _addPhoto(_localKey, photo);

  static Future<void> removeLocalPhoto(String photoId) =>
      _removePhoto(_localKey, photoId);

  static Future<bool> isLocal(String photoId) => _containsPhoto(_localKey, photoId);

  static Future<Set<String>> getLocalPhotoIds() => _getIds(_localKey);
}
