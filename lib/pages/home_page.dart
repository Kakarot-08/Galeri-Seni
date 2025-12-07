import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../main.dart';
import '../database_helper.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> _photos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeDatabase();
    _loadPhotos();
  }

  Future<void> _initializeDatabase() async {
    try {
      await DatabaseHelper.instance.init();
    } catch (e) {
      // Database initialization error (normal for web)
      print('Database initialization: $e');
    }
  }

  Future<void> _loadPhotos() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final photos = await DatabaseHelper.instance.getAllPhotos();
      print('Loaded ${photos.length} photos from database');
      if (photos.isNotEmpty) {
        print('First photo data: ${photos.first.keys}');
        print('First photo image_data type: ${photos.first['image_data'].runtimeType}');
        print('First photo image_data length: ${(photos.first['image_data'] as List).length}');
      }
      setState(() {
        _photos = photos;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading photos: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error memuat foto: $e')),
        );
      }
    }
  }

  Future<void> _deletePhoto(int id) async {
    try {
      await DatabaseHelper.instance.deletePhoto(id);
      await _loadPhotos();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto berhasil dihapus')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error menghapus foto: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AtelierScaffold(
      currentRoute: '/',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 800;

              final heroContent = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Galeri Fotoku',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontSize: 32,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Jelajahi koleksi foto-foto tersimpan di database lokal.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[700],
                        ),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/upload').then((_) {
                            _loadPhotos();
                          });
                        },
                        child: const Text('Upload Foto'),
                      ),
                      OutlinedButton(
                        onPressed: _loadPhotos,
                        child: const Text('Refresh'),
                      ),
                    ],
                  ),
                ],
              );

              final heroShowcase = _HeroShowcase(colorScheme: colorScheme);

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 6, child: heroContent),
                    const SizedBox(width: 24),
                    Expanded(flex: 4, child: heroShowcase),
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  heroContent,
                  const SizedBox(height: 24),
                  heroShowcase,
                ],
              );
            },
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Koleksi Fotoku (${_photos.length})',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (_isLoading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_photos.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.photo_library_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Belum ada foto',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Upload foto pertamamu untuk memulai',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[500],
                          ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/upload').then((_) {
                          _loadPhotos();
                        });
                      },
                      child: const Text('Upload Foto Pertama'),
                    ),
                  ],
                ),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                int crossAxisCount = 2;
                if (constraints.maxWidth > 900) {
                  crossAxisCount = 4;
                } else if (constraints.maxWidth > 600) {
                  crossAxisCount = 3;
                }

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _photos.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 3 / 4,
                  ),
                  itemBuilder: (context, index) {
                    final photo = _photos[index];
                    return _PhotoCard(
                      photo: photo,
                      colorScheme: colorScheme,
                      onDelete: () => _deletePhoto(photo['id']),
                    );
                  },
                );
              },
            ),
        ],
      ),
    );
  }
}

class _HeroShowcase extends StatelessWidget {
  final ColorScheme colorScheme;

  const _HeroShowcase({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          _FloatingCard(
            color: colorScheme.primary.withValues(alpha: 0.9),
            left: 0,
            top: 24,
          ),
          _FloatingCard(
            color: colorScheme.secondary.withValues(alpha: 0.9),
            left: 80,
            top: 0,
          ),
          _FloatingCard(
            color: colorScheme.primaryContainer.withValues(alpha: 0.9),
            left: 160,
            top: 40,
          ),
        ],
      ),
    );
  }
}

class _FloatingCard extends StatelessWidget {
  final Color color;
  final double left;
  final double top;

  const _FloatingCard({
    required this.color,
    required this.left,
    required this.top,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: top,
      child: Container(
        width: 120,
        height: 160,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoCard extends StatelessWidget {
  final Map<String, dynamic> photo;
  final ColorScheme colorScheme;
  final VoidCallback onDelete;

  const _PhotoCard({
    required this.photo,
    required this.colorScheme,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final rawImageData = photo['image_data'];
    late Uint8List imageBytes;

    if (rawImageData is Uint8List) {
      imageBytes = rawImageData;
    } else if (rawImageData is List<int>) {
      imageBytes = Uint8List.fromList(rawImageData);
    } else if (rawImageData is List<dynamic>) {
      imageBytes = Uint8List.fromList(rawImageData.cast<int>());
    } else if (rawImageData is String) {
      imageBytes = base64Decode(rawImageData);
    } else {
      imageBytes = Uint8List(0);
    }

    print('PhotoCard: image_data length = ${imageBytes.length}');
    final title = photo['title'] as String;
    final createdAt = photo['created_at'] as String;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => _PhotoDialog(
              title: title,
              imageBytes: imageBytes,
              createdAt: createdAt,
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primary.withValues(alpha: 0.1),
                      colorScheme.secondary.withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Image.memory(
                  imageBytes,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDate(createdAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                      IconButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Hapus Foto'),
                              content: Text('Apakah kamu yakin ingin menghapus foto "$title"?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Batal'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    onDelete();
                                  },
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.red,
                                  ),
                                  child: const Text('Hapus'),
                                ),
                              ],
                            ),
                          );
                        },
                        icon: const Icon(Icons.delete_outline, size: 20),
                        iconSize: 20,
                        color: Colors.grey[600],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}

class _PhotoDialog extends StatelessWidget {
  final String title;
  final Uint8List imageBytes;
  final String createdAt;

  const _PhotoDialog({
    required this.title,
    required this.imageBytes,
    required this.createdAt,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.9,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: Text(title),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            Flexible(
              child: InteractiveViewer(
                child: Image.memory(
                  imageBytes,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Diunggah: ${_formatFullDate(createdAt)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatFullDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }
}
