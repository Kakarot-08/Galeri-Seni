import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  static const String _photosKey = 'photos_data';

  DatabaseHelper._init();

  Future<void> init() async {
    if (!kIsWeb) {
      await database;
    }
  }

  Future<Database> get database async {
    if (kIsWeb) return throw Exception('SQLite not available on web');
    
    if (_database != null) return _database!;
    _database = await _initDB('atelier.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, filePath);
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const blobType = 'BLOB NOT NULL';

    await db.execute('''
      CREATE TABLE photos (
        id $idType,
        title $textType,
        file_name $textType,
        image_data $blobType,
        created_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _savePhotosToWeb(List<Map<String, dynamic>> photos) async {
    final prefs = await SharedPreferences.getInstance();
    final photosJson = jsonEncode(photos);
    await prefs.setString(_photosKey, photosJson);
  }

  Future<List<Map<String, dynamic>>> _loadPhotosFromWeb() async {
    final prefs = await SharedPreferences.getInstance();
    final photosJson = prefs.getString(_photosKey);
    
    if (photosJson == null) return [];
    
    try {
      final List<dynamic> photosList = jsonDecode(photosJson);
      return photosList.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  Future<int> createPhoto({
    required String title,
    required String fileName,
    required List<int> imageData,
  }) async {
    final now = DateTime.now().toIso8601String();
    final photoData = {
      'title': title,
      'file_name': fileName,
      'image_data': imageData,
      'created_at': now,
    };

    if (kIsWeb) {
      final photos = await _loadPhotosFromWeb();
      final newPhoto = Map<String, dynamic>.from(photoData);
      newPhoto['id'] = photos.isEmpty ? 1 : (photos.last['id'] as int) + 1;
      photos.add(newPhoto);
      await _savePhotosToWeb(photos);
      return newPhoto['id'] as int;
    } else {
      final db = await instance.database;
      return await db.insert('photos', photoData);
    }
  }

  Future<List<Map<String, dynamic>>> getAllPhotos() async {
    if (kIsWeb) {
      return await _loadPhotosFromWeb();
    } else {
      final db = await instance.database;
      return await db.query(
        'photos',
        orderBy: 'created_at DESC',
      );
    }
  }

  Future<Map<String, dynamic>?> getPhotoById(int id) async {
    if (kIsWeb) {
      final photos = await _loadPhotosFromWeb();
      try {
        return photos.firstWhere((photo) => photo['id'] == id);
      } catch (e) {
        return null;
      }
    } else {
      final db = await instance.database;
      final results = await db.query(
        'photos',
        where: 'id = ?',
        whereArgs: [id],
      );
      
      if (results.isNotEmpty) {
        return results.first;
      }
      return null;
    }
  }

  Future<int> deletePhoto(int id) async {
    if (kIsWeb) {
      final photos = await _loadPhotosFromWeb();
      photos.removeWhere((photo) => photo['id'] == id);
      await _savePhotosToWeb(photos);
      return 1;
    } else {
      final db = await instance.database;
      return await db.delete(
        'photos',
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  Future<int> updatePhoto({
    required int id,
    String? title,
    String? fileName,
    List<int>? imageData,
  }) async {
    final Map<String, dynamic> updateData = {};
    
    if (title != null) updateData['title'] = title;
    if (fileName != null) updateData['file_name'] = fileName;
    if (imageData != null) updateData['image_data'] = imageData;

    if (kIsWeb) {
      final photos = await _loadPhotosFromWeb();
      final index = photos.indexWhere((photo) => photo['id'] == id);
      
      if (index != -1) {
        photos[index].addAll(updateData);
        await _savePhotosToWeb(photos);
        return 1;
      }
      return 0;
    } else {
      final db = await instance.database;
      return await db.update(
        'photos',
        updateData,
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  Future<void> close() async {
    if (!kIsWeb && _database != null) {
      final db = await instance.database;
      db.close();
    }
  }
}
