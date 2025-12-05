import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/video_model.dart';
import '../../../data/models/course_model.dart';
import '../../providers/downloads_provider.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/empty_state_widget.dart';

/// Pantalla de descargas y contenido offline
class DownloadsScreen extends ConsumerStatefulWidget {
  const DownloadsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends ConsumerState<DownloadsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isSelectionMode = false;
  final Set<String> _selectedItems = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final downloads = ref.watch(downloadsProvider);

    return Scaffold(
      appBar: CustomAppBar(
        title: _isSelectionMode
            ? '${_selectedItems.length} seleccionados'
            : 'Descargas',
        showBackButton: true,
        actions: [
          if (_isSelectionMode) ...[
            IconButton(
              icon: const Icon(Icons.select_all),
              onPressed: _selectAll,
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteSelected,
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _isSelectionMode = false;
                  _selectedItems.clear();
                });
              },
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isSelectionMode = true;
                });
              },
            ),
            PopupMenuButton<String>(
              onSelected: _handleMenuAction,
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'sort',
                  child: Row(
                    children: [
                      Icon(Icons.sort, size: 20),
                      SizedBox(width: 12),
                      Text('Ordenar'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete_all',
                  child: Row(
                    children: [
                      Icon(Icons.delete_sweep, size: 20, color: Colors.red),
                      SizedBox(width: 12),
                      Text('Eliminar todo', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Videos'),
            Tab(text: 'Cursos'),
            Tab(text: 'Biblia'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Barra de información de almacenamiento
          _buildStorageInfo(),

          // Contenido por pestañas
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildVideosTab(downloads.videos),
                _buildCoursesTab(downloads.courses),
                _buildBibleTab(downloads.bibleBooks),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStorageInfo() {
    final downloads = ref.watch(downloadsProvider);
    final totalSize = downloads.totalSizeInMB;
    final availableSpace = downloads.availableSpaceInGB;

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[100],
      child: Row(
        children: [
          Icon(Icons.storage, color: Colors.grey[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Espacio utilizado: ${totalSize.toStringAsFixed(1)} MB',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Espacio disponible: ${availableSpace.toStringAsFixed(1)} GB',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          LinearProgressIndicator(
            value: totalSize / (availableSpace * 1024),
            backgroundColor: Colors.grey[300],
            color: totalSize > (availableSpace * 1024 * 0.9)
                ? Colors.red
                : AppColors.primary,
            minHeight: 8,
          ),
        ],
      ),
    );
  }

  Widget _buildVideosTab(List<DownloadedVideo> videos) {
    if (videos.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.video_library,
        title: 'No hay videos descargados',
        subtitle: 'Los videos que descargues aparecerán aquí',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: videos.length,
      itemBuilder: (context, index) {
        final video = videos[index];
        final isSelected = _selectedItems.contains('video_${video.id}');

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: isSelected ? 4 : 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isSelected
                ? const BorderSide(color: AppColors.primary, width: 2)
                : BorderSide.none,
          ),
          child: InkWell(
            onTap: () {
              if (_isSelectionMode) {
                setState(() {
                  if (isSelected) {
                    _selectedItems.remove('video_${video.id}');
                  } else {
                    _selectedItems.add('video_${video.id}');
                  }
                });
              } else {
                context.push('/videos/player/${video.id}');
              }
            },
            onLongPress: () {
              if (!_isSelectionMode) {
                setState(() {
                  _isSelectionMode = true;
                  _selectedItems.add('video_${video.id}');
                });
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Row(
              children: [
                // Thumbnail
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                  child: Stack(
                    children: [
                      Image.network(
                        video.thumbnail,
                        width: 120,
                        height: 90,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 120,
                            height: 90,
                            color: Colors.grey[300],
                            child: const Icon(Icons.video_library),
                          );
                        },
                      ),
                      if (_isSelectionMode)
                        Positioned(
                          top: 4,
                          left: 4,
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary
                                  : Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : Colors.grey,
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              isSelected ? Icons.check : null,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Info
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          video.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${video.duration} • ${video.sizeInMB.toStringAsFixed(1)} MB',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Descargado ${_formatDate(video.downloadDate)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Acciones
                if (!_isSelectionMode)
                  PopupMenuButton<String>(
                    onSelected: (value) => _handleVideoAction(value, video),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'play',
                        child: Row(
                          children: [
                            Icon(Icons.play_arrow, size: 20),
                            SizedBox(width: 12),
                            Text('Reproducir'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 12),
                            Text('Eliminar', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCoursesTab(List<DownloadedCourse> courses) {
    if (courses.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.school,
        title: 'No hay cursos descargados',
        subtitle: 'Los cursos que descargues aparecerán aquí',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: courses.length,
      itemBuilder: (context, index) {
        final course = courses[index];
        final isSelected = _selectedItems.contains('course_${course.id}');
        final progress = course.completedLessons / course.totalLessons;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: isSelected ? 4 : 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isSelected
                ? const BorderSide(color: AppColors.primary, width: 2)
                : BorderSide.none,
          ),
          child: InkWell(
            onTap: () {
              if (_isSelectionMode) {
                setState(() {
                  if (isSelected) {
                    _selectedItems.remove('course_${course.id}');
                  } else {
                    _selectedItems.add('course_${course.id}');
                  }
                });
              } else {
                context.push('/academy/course/${course.id}');
              }
            },
            onLongPress: () {
              if (!_isSelectionMode) {
                setState(() {
                  _isSelectionMode = true;
                  _selectedItems.add('course_${course.id}');
                });
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (_isSelectionMode)
                        Container(
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary : Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? AppColors.primary : Colors.grey,
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            isSelected ? Icons.check : null,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      Expanded(
                        child: Text(
                          course.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          course.level,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.gold,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Por ${course.instructor}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Icon(Icons.video_library, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${course.totalLessons} lecciones',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.timer, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        course.duration,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.storage, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${course.sizeInMB.toStringAsFixed(0)} MB',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Barra de progreso
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Progreso',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            '${(progress * 100).toInt()}%',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.grey[300],
                        color: AppColors.primary,
                        minHeight: 6,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBibleTab(List<DownloadedBibleBook> books) {
    if (books.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.book,
        title: 'No hay libros descargados',
        subtitle: 'Los libros de la Biblia que descargues aparecerán aquí',
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: books.length,
      itemBuilder: (context, index) {
        final book = books[index];
        final isSelected = _selectedItems.contains('bible_${book.id}');

        return GestureDetector(
          onTap: () {
            if (_isSelectionMode) {
              setState(() {
                if (isSelected) {
                  _selectedItems.remove('bible_${book.id}');
                } else {
                  _selectedItems.add('bible_${book.id}');
                }
              });
            } else {
              context.push('/bible/book/${book.id}');
            }
          },
          onLongPress: () {
            if (!_isSelectionMode) {
              setState(() {
                _isSelectionMode = true;
                _selectedItems.add('bible_${book.id}');
              });
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.primary : Colors.grey[300]!,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isSelectionMode)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? AppColors.primary : Colors.grey,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      isSelected ? Icons.check : null,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                Icon(
                  Icons.book,
                  size: 40,
                  color: isSelected ? AppColors.primary : Colors.grey[600],
                ),
                const SizedBox(height: 8),
                Text(
                  book.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isSelected ? AppColors.primary : Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  '${book.chapters} capítulos',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  book.version,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _selectAll() {
    setState(() {
      _selectedItems.clear();
      final downloads = ref.read(downloadsProvider);

      switch (_tabController.index) {
        case 0: // Videos
          for (final video in downloads.videos) {
            _selectedItems.add('video_${video.id}');
          }
          break;
        case 1: // Cursos
          for (final course in downloads.courses) {
            _selectedItems.add('course_${course.id}');
          }
          break;
        case 2: // Biblia
          for (final book in downloads.bibleBooks) {
            _selectedItems.add('bible_${book.id}');
          }
          break;
      }
    });
  }

  Future<void> _deleteSelected() async {
    if (_selectedItems.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar descargas'),
        content: Text(
          '¿Estás seguro de que quieres eliminar ${_selectedItems.length} elemento(s)?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Eliminar elementos seleccionados
      for (final itemId in _selectedItems) {
        await ref.read(downloadsProvider.notifier).deleteDownload(itemId);
      }

      setState(() {
        _isSelectionMode = false;
        _selectedItems.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Elementos eliminados'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'sort':
        _showSortDialog();
        break;
      case 'delete_all':
        _deleteAll();
        break;
    }
  }

  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ordenar por'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            'Nombre',
            'Fecha de descarga',
            'Tamaño',
            'Progreso',
          ].map((option) {
            return RadioListTile<String>(
              title: Text(option),
              value: option,
              groupValue: 'Fecha de descarga',
              onChanged: (value) {
                // Aplicar ordenamiento
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Future<void> _deleteAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar todo'),
        content: const Text(
          '¿Estás seguro de que quieres eliminar todas las descargas? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Eliminar todo'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(downloadsProvider.notifier).deleteAllDownloads();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Todas las descargas han sido eliminadas'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _handleVideoAction(String action, DownloadedVideo video) {
    switch (action) {
      case 'play':
        context.push('/videos/player/${video.id}');
        break;
      case 'delete':
        ref.read(downloadsProvider.notifier).deleteDownload('video_${video.id}');
        break;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'hoy';
    } else if (difference.inDays == 1) {
      return 'ayer';
    } else if (difference.inDays < 7) {
      return 'hace ${difference.inDays} días';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return 'hace $weeks ${weeks == 1 ? 'semana' : 'semanas'}';
    } else {
      final months = (difference.inDays / 30).floor();
      return 'hace $months ${months == 1 ? 'mes' : 'meses'}';
    }
  }
}