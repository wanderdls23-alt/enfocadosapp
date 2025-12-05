import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Modelo para video descargado
class DownloadedVideo {
  final String id;
  final String title;
  final String thumbnail;
  final String duration;
  final double sizeInMB;
  final DateTime downloadDate;
  final String filePath;

  const DownloadedVideo({
    required this.id,
    required this.title,
    required this.thumbnail,
    required this.duration,
    required this.sizeInMB,
    required this.downloadDate,
    required this.filePath,
  });
}

/// Modelo para curso descargado
class DownloadedCourse {
  final String id;
  final String title;
  final String instructor;
  final String level;
  final int totalLessons;
  final int completedLessons;
  final String duration;
  final double sizeInMB;
  final DateTime downloadDate;
  final String folderPath;

  const DownloadedCourse({
    required this.id,
    required this.title,
    required this.instructor,
    required this.level,
    required this.totalLessons,
    required this.completedLessons,
    required this.duration,
    required this.sizeInMB,
    required this.downloadDate,
    required this.folderPath,
  });
}

/// Modelo para libro de la Biblia descargado
class DownloadedBibleBook {
  final String id;
  final String name;
  final int chapters;
  final String version;
  final double sizeInMB;
  final DateTime downloadDate;
  final String filePath;

  const DownloadedBibleBook({
    required this.id,
    required this.name,
    required this.chapters,
    required this.version,
    required this.sizeInMB,
    required this.downloadDate,
    required this.filePath,
  });
}

/// Estado de descargas
class DownloadsState {
  final List<DownloadedVideo> videos;
  final List<DownloadedCourse> courses;
  final List<DownloadedBibleBook> bibleBooks;
  final double totalSizeInMB;
  final double availableSpaceInGB;
  final bool isLoading;

  const DownloadsState({
    this.videos = const [],
    this.courses = const [],
    this.bibleBooks = const [],
    this.totalSizeInMB = 0,
    this.availableSpaceInGB = 0,
    this.isLoading = false,
  });

  DownloadsState copyWith({
    List<DownloadedVideo>? videos,
    List<DownloadedCourse>? courses,
    List<DownloadedBibleBook>? bibleBooks,
    double? totalSizeInMB,
    double? availableSpaceInGB,
    bool? isLoading,
  }) {
    return DownloadsState(
      videos: videos ?? this.videos,
      courses: courses ?? this.courses,
      bibleBooks: bibleBooks ?? this.bibleBooks,
      totalSizeInMB: totalSizeInMB ?? this.totalSizeInMB,
      availableSpaceInGB: availableSpaceInGB ?? this.availableSpaceInGB,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Notifier de descargas
class DownloadsNotifier extends StateNotifier<DownloadsState> {
  DownloadsNotifier() : super(const DownloadsState()) {
    _loadDownloads();
  }

  Future<void> _loadDownloads() async {
    state = state.copyWith(isLoading: true);

    try {
      // Obtener directorio de documentos
      final directory = await getApplicationDocumentsDirectory();
      final downloadsPath = '${directory.path}/downloads';

      // Cargar videos descargados
      final videos = await _loadVideos(downloadsPath);

      // Cargar cursos descargados
      final courses = await _loadCourses(downloadsPath);

      // Cargar libros de la Biblia descargados
      final bibleBooks = await _loadBibleBooks(downloadsPath);

      // Calcular espacio total usado
      final totalSize = _calculateTotalSize(videos, courses, bibleBooks);

      // Obtener espacio disponible
      final availableSpace = await _getAvailableSpace();

      state = state.copyWith(
        videos: videos,
        courses: courses,
        bibleBooks: bibleBooks,
        totalSizeInMB: totalSize,
        availableSpaceInGB: availableSpace,
        isLoading: false,
      );
    } catch (e) {
      print('Error loading downloads: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  Future<List<DownloadedVideo>> _loadVideos(String basePath) async {
    final videosDir = Directory('$basePath/videos');
    if (!await videosDir.exists()) {
      return [];
    }

    final videos = <DownloadedVideo>[];
    final files = videosDir.listSync();

    for (final file in files) {
      if (file is File && file.path.endsWith('.mp4')) {
        // Simular metadata (en producción vendría de un archivo JSON)
        videos.add(DownloadedVideo(
          id: file.path.split('/').last.replaceAll('.mp4', ''),
          title: 'Video descargado ${videos.length + 1}',
          thumbnail: 'https://img.youtube.com/vi/xxx/mqdefault.jpg',
          duration: '10:30',
          sizeInMB: file.lengthSync() / (1024 * 1024),
          downloadDate: file.lastModifiedSync(),
          filePath: file.path,
        ));
      }
    }

    return videos;
  }

  Future<List<DownloadedCourse>> _loadCourses(String basePath) async {
    final coursesDir = Directory('$basePath/courses');
    if (!await coursesDir.exists()) {
      return [];
    }

    final courses = <DownloadedCourse>[];
    final dirs = coursesDir.listSync();

    for (final dir in dirs) {
      if (dir is Directory) {
        // Calcular tamaño del directorio
        double sizeInMB = 0;
        await for (final entity in dir.list(recursive: true)) {
          if (entity is File) {
            sizeInMB += entity.lengthSync() / (1024 * 1024);
          }
        }

        // Simular metadata
        courses.add(DownloadedCourse(
          id: dir.path.split('/').last,
          title: 'Curso descargado ${courses.length + 1}',
          instructor: 'Pastor Juan',
          level: 'Intermedio',
          totalLessons: 10,
          completedLessons: 3,
          duration: '5h 30m',
          sizeInMB: sizeInMB,
          downloadDate: dir.statSync().modified,
          folderPath: dir.path,
        ));
      }
    }

    return courses;
  }

  Future<List<DownloadedBibleBook>> _loadBibleBooks(String basePath) async {
    final bibleDir = Directory('$basePath/bible');
    if (!await bibleDir.exists()) {
      return [];
    }

    final books = <DownloadedBibleBook>[];
    final files = bibleDir.listSync();

    for (final file in files) {
      if (file is File && file.path.endsWith('.json')) {
        // Simular metadata
        books.add(DownloadedBibleBook(
          id: file.path.split('/').last.replaceAll('.json', ''),
          name: _getBookName(file.path.split('/').last),
          chapters: 10,
          version: 'RVR 1960',
          sizeInMB: file.lengthSync() / (1024 * 1024),
          downloadDate: file.lastModifiedSync(),
          filePath: file.path,
        ));
      }
    }

    return books;
  }

  String _getBookName(String fileName) {
    // Mapeo simple de nombres de archivo a nombres de libros
    final bookNames = {
      'genesis': 'Génesis',
      'exodus': 'Éxodo',
      'leviticus': 'Levítico',
      'numbers': 'Números',
      'deuteronomy': 'Deuteronomio',
      // ... más libros
    };

    final key = fileName.replaceAll('.json', '').toLowerCase();
    return bookNames[key] ?? 'Libro desconocido';
  }

  double _calculateTotalSize(
    List<DownloadedVideo> videos,
    List<DownloadedCourse> courses,
    List<DownloadedBibleBook> books,
  ) {
    double total = 0;

    for (final video in videos) {
      total += video.sizeInMB;
    }

    for (final course in courses) {
      total += course.sizeInMB;
    }

    for (final book in books) {
      total += book.sizeInMB;
    }

    return total;
  }

  Future<double> _getAvailableSpace() async {
    try {
      // En iOS, esto requiere un plugin específico
      // Por ahora retornamos un valor simulado
      return 10.5; // GB
    } catch (e) {
      return 0;
    }
  }

  Future<void> deleteDownload(String itemId) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final downloadsPath = '${directory.path}/downloads';

      if (itemId.startsWith('video_')) {
        // Eliminar video
        final videoId = itemId.replaceAll('video_', '');
        final videoFile = File('$downloadsPath/videos/$videoId.mp4');
        if (await videoFile.exists()) {
          await videoFile.delete();
        }

        state = state.copyWith(
          videos: state.videos.where((v) => v.id != videoId).toList(),
        );
      } else if (itemId.startsWith('course_')) {
        // Eliminar curso
        final courseId = itemId.replaceAll('course_', '');
        final courseDir = Directory('$downloadsPath/courses/$courseId');
        if (await courseDir.exists()) {
          await courseDir.delete(recursive: true);
        }

        state = state.copyWith(
          courses: state.courses.where((c) => c.id != courseId).toList(),
        );
      } else if (itemId.startsWith('bible_')) {
        // Eliminar libro de la Biblia
        final bookId = itemId.replaceAll('bible_', '');
        final bookFile = File('$downloadsPath/bible/$bookId.json');
        if (await bookFile.exists()) {
          await bookFile.delete();
        }

        state = state.copyWith(
          bibleBooks: state.bibleBooks.where((b) => b.id != bookId).toList(),
        );
      }

      // Recalcular tamaño total
      final totalSize = _calculateTotalSize(
        state.videos,
        state.courses,
        state.bibleBooks,
      );
      state = state.copyWith(totalSizeInMB: totalSize);
    } catch (e) {
      print('Error deleting download: $e');
    }
  }

  Future<void> deleteAllDownloads() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final downloadsDir = Directory('${directory.path}/downloads');

      if (await downloadsDir.exists()) {
        await downloadsDir.delete(recursive: true);
      }

      state = const DownloadsState();
    } catch (e) {
      print('Error deleting all downloads: $e');
    }
  }

  Future<void> downloadVideo(String videoId) async {
    // Implementar descarga de video
  }

  Future<void> downloadCourse(String courseId) async {
    // Implementar descarga de curso
  }

  Future<void> downloadBibleBook(String bookId, String version) async {
    // Implementar descarga de libro bíblico
  }

  void refresh() {
    _loadDownloads();
  }
}

/// Provider principal de descargas
final downloadsProvider = StateNotifierProvider<DownloadsNotifier, DownloadsState>((ref) {
  return DownloadsNotifier();
});

/// Provider para verificar si un elemento está descargado
final isDownloadedProvider = Provider.family<bool, String>((ref, itemId) {
  final downloads = ref.watch(downloadsProvider);

  if (itemId.startsWith('video_')) {
    final videoId = itemId.replaceAll('video_', '');
    return downloads.videos.any((v) => v.id == videoId);
  } else if (itemId.startsWith('course_')) {
    final courseId = itemId.replaceAll('course_', '');
    return downloads.courses.any((c) => c.id == courseId);
  } else if (itemId.startsWith('bible_')) {
    final bookId = itemId.replaceAll('bible_', '');
    return downloads.bibleBooks.any((b) => b.id == bookId);
  }

  return false;
});

/// Provider para el progreso de descarga actual
final downloadProgressProvider = StateProvider<Map<String, double>>((ref) => {});