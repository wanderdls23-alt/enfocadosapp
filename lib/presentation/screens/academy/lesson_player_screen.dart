import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/course_model.dart';
import '../../providers/course_provider.dart';
import '../../widgets/common/loading_widget.dart';

/// Pantalla de reproducción de lecciones
class LessonPlayerScreen extends ConsumerStatefulWidget {
  final String lessonId;

  const LessonPlayerScreen({
    Key? key,
    required this.lessonId,
  }) : super(key: key);

  @override
  ConsumerState<LessonPlayerScreen> createState() => _LessonPlayerScreenState();
}

class _LessonPlayerScreenState extends ConsumerState<LessonPlayerScreen>
    with TickerProviderStateMixin {
  YoutubePlayerController? _youtubeController;
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  late TabController _tabController;

  bool _isCompleted = false;
  bool _showNotes = false;
  final TextEditingController _notesController = TextEditingController();
  final List<LessonNote> _notes = [];
  double _videoProgress = 0.0;
  Duration? _currentPosition;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadLesson();
  }

  void _loadLesson() {
    final lessonAsync = ref.read(lessonDetailProvider(widget.lessonId));
    lessonAsync.whenData((lesson) {
      if (lesson != null) {
        _initializePlayer(lesson);
        setState(() {
          _isCompleted = lesson.isCompleted;
        });
        _loadNotes(lesson);
      }
    });
  }

  void _initializePlayer(Lesson lesson) {
    if (lesson.videoUrl != null) {
      if (lesson.videoUrl!.contains('youtube.com') ||
          lesson.videoUrl!.contains('youtu.be')) {
        // YouTube video
        final videoId = YoutubePlayer.convertUrlToId(lesson.videoUrl!);
        if (videoId != null) {
          _youtubeController = YoutubePlayerController(
            initialVideoId: videoId,
            flags: const YoutubePlayerFlags(
              autoPlay: true,
              mute: false,
              enableCaption: true,
            ),
          );

          _youtubeController!.addListener(() {
            final position = _youtubeController!.value.position;
            final duration = _youtubeController!.metadata.duration;

            if (duration.inSeconds > 0) {
              setState(() {
                _currentPosition = position;
                _videoProgress = position.inSeconds / duration.inSeconds;
              });

              // Marcar como completado al 90%
              if (_videoProgress >= 0.9 && !_isCompleted) {
                _markAsCompleted();
              }
            }
          });
        }
      } else {
        // Video directo
        _videoController = VideoPlayerController.network(lesson.videoUrl!)
          ..initialize().then((_) {
            setState(() {});
            _chewieController = ChewieController(
              videoPlayerController: _videoController!,
              autoPlay: true,
              looping: false,
              aspectRatio: _videoController!.value.aspectRatio,
              autoInitialize: true,
              showControls: true,
              materialProgressColors: ChewieProgressColors(
                playedColor: AppColors.primary,
                handleColor: AppColors.primary,
                backgroundColor: Colors.grey,
                bufferedColor: AppColors.primary.withOpacity(0.3),
              ),
            );

            _videoController!.addListener(() {
              final position = _videoController!.value.position;
              final duration = _videoController!.value.duration;

              if (duration.inSeconds > 0) {
                setState(() {
                  _currentPosition = position;
                  _videoProgress = position.inSeconds / duration.inSeconds;
                });

                // Marcar como completado al 90%
                if (_videoProgress >= 0.9 && !_isCompleted) {
                  _markAsCompleted();
                }
              }
            });
          });
      }
    }
  }

  void _loadNotes(Lesson lesson) {
    // Cargar notas guardadas
    final notesAsync = ref.read(lessonNotesProvider(widget.lessonId));
    notesAsync.whenData((notes) {
      setState(() {
        _notes.clear();
        _notes.addAll(notes);
      });
    });
  }

  @override
  void dispose() {
    _youtubeController?.dispose();
    _videoController?.dispose();
    _chewieController?.dispose();
    _tabController.dispose();
    _notesController.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lessonAsync = ref.watch(lessonDetailProvider(widget.lessonId));

    return lessonAsync.when(
      data: (lesson) {
        if (lesson == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Lección no encontrada')),
            body: const Center(child: Text('La lección no existe')),
          );
        }
        return _buildLessonContent(lesson);
      },
      loading: () => const Scaffold(
        backgroundColor: Colors.black,
        body: LoadingWidget(),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildLessonContent(Lesson lesson) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          lesson.title,
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: Icon(_showNotes ? Icons.videocam : Icons.note),
            onPressed: () {
              setState(() {
                _showNotes = !_showNotes;
              });
            },
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'download',
                child: Row(
                  children: [
                    Icon(Icons.download, size: 20),
                    SizedBox(width: 12),
                    Text('Descargar'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'speed',
                child: Row(
                  children: [
                    Icon(Icons.speed, size: 20),
                    SizedBox(width: 12),
                    Text('Velocidad'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'quality',
                child: Row(
                  children: [
                    Icon(Icons.hd, size: 20),
                    SizedBox(width: 12),
                    Text('Calidad'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Player de video
          AspectRatio(
            aspectRatio: 16 / 9,
            child: _buildVideoPlayer(lesson),
          ),

          // Barra de progreso del curso
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[900],
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progreso de la lección',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '${(_videoProgress * 100).toInt()}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: _videoProgress,
                  backgroundColor: Colors.grey[800],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _isCompleted ? Colors.green : AppColors.primary,
                  ),
                ),
              ],
            ),
          ),

          // Contenido adicional
          Expanded(
            child: Container(
              color: Colors.white,
              child: Column(
                children: [
                  // Información de la lección
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                lesson.title,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Duración: ${lesson.duration} min',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_isCompleted)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Completado',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Tabs
                  TabBar(
                    controller: _tabController,
                    indicatorColor: AppColors.primary,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: Colors.grey,
                    tabs: const [
                      Tab(text: 'DESCRIPCIÓN'),
                      Tab(text: 'RECURSOS'),
                      Tab(text: 'NOTAS'),
                    ],
                  ),

                  // Contenido de tabs
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _DescriptionTab(lesson: lesson),
                        _ResourcesTab(lesson: lesson),
                        _NotesTab(
                          notes: _notes,
                          onAddNote: _addNote,
                          currentPosition: _currentPosition,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),

      // Panel lateral de notas (opcional)
      endDrawer: _showNotes ? _buildNotesDrawer() : null,

      // Botones de navegación
      bottomNavigationBar: _buildNavigationBar(lesson),
    );
  }

  Widget _buildVideoPlayer(Lesson lesson) {
    if (lesson.type == 'reading' || lesson.type == 'article') {
      return Container(
        color: Colors.grey[900],
        child: const Center(
          child: Icon(
            Icons.article,
            size: 64,
            color: Colors.white54,
          ),
        ),
      );
    }

    if (_youtubeController != null) {
      return YoutubePlayer(
        controller: _youtubeController!,
        showVideoProgressIndicator: true,
        progressIndicatorColor: AppColors.primary,
        onReady: () {
          print('YouTube Player Ready');
        },
      );
    } else if (_chewieController != null && _videoController!.value.isInitialized) {
      return Chewie(controller: _chewieController!);
    } else if (lesson.type == 'audio') {
      return Container(
        color: Colors.grey[900],
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.audiotrack,
              size: 64,
              color: AppColors.primary,
            ),
            const SizedBox(height: 16),
            const Text(
              'Reproduciendo audio...',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      );
    } else {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
  }

  Widget _buildNotesDrawer() {
    return Drawer(
      child: Column(
        children: [
          AppBar(
            title: const Text('Notas de la lección'),
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _notes.length,
              itemBuilder: (context, index) {
                final note = _notes[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Text(
                      _formatTime(note.timestamp),
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    title: Text(note.content),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, size: 18),
                      onPressed: () => _deleteNote(note),
                    ),
                    onTap: () => _seekToTimestamp(note.timestamp),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      hintText: 'Agregar nota...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  mini: true,
                  onPressed: () => _addNote(_notesController.text),
                  child: const Icon(Icons.add),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationBar(Lesson lesson) {
    final courseAsync = ref.watch(courseByLessonProvider(widget.lessonId));

    return courseAsync.when(
      data: (courseData) {
        if (courseData == null) return const SizedBox.shrink();

        final nextLesson = _getNextLesson(courseData.course, lesson);
        final previousLesson = _getPreviousLesson(courseData.course, lesson);

        return Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Lección anterior
              if (previousLesson != null)
                TextButton.icon(
                  onPressed: () => _navigateToLesson(previousLesson),
                  icon: const Icon(Icons.chevron_left),
                  label: const Text('Anterior'),
                )
              else
                const SizedBox(width: 100),

              // Marcar como completado
              if (!_isCompleted)
                ElevatedButton(
                  onPressed: _markAsCompleted,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text('Marcar completado'),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check, color: Colors.green, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'Completado',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

              // Siguiente lección
              if (nextLesson != null)
                TextButton.icon(
                  onPressed: () => _navigateToLesson(nextLesson),
                  icon: const Text('Siguiente'),
                  label: const Icon(Icons.chevron_right),
                )
              else
                TextButton.icon(
                  onPressed: () => _finishCourse(courseData.course),
                  icon: const Text('Finalizar'),
                  label: const Icon(Icons.check),
                ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'download':
        _downloadLesson();
        break;
      case 'speed':
        _showSpeedOptions();
        break;
      case 'quality':
        _showQualityOptions();
        break;
    }
  }

  void _downloadLesson() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Descargando lección...')),
    );
  }

  void _showSpeedOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Velocidad de reproducción',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...['0.5x', '0.75x', '1x', '1.25x', '1.5x', '2x'].map((speed) {
              return ListTile(
                title: Text(speed),
                trailing: speed == '1x' ? const Icon(Icons.check) : null,
                onTap: () {
                  // Cambiar velocidad
                  Navigator.pop(context);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showQualityOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Calidad de video',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...['Auto', '1080p', '720p', '480p', '360p'].map((quality) {
              return ListTile(
                title: Text(quality),
                trailing: quality == 'Auto' ? const Icon(Icons.check) : null,
                onTap: () {
                  // Cambiar calidad
                  Navigator.pop(context);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  void _markAsCompleted() {
    if (!_isCompleted) {
      setState(() {
        _isCompleted = true;
      });

      ref.read(courseProvider.notifier).markLessonAsCompleted(widget.lessonId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Lección completada!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _addNote(String content) {
    if (content.trim().isEmpty) return;

    final note = LessonNote(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      lessonId: widget.lessonId,
      content: content,
      timestamp: _currentPosition ?? Duration.zero,
      createdAt: DateTime.now(),
    );

    setState(() {
      _notes.add(note);
    });

    ref.read(courseProvider.notifier).addLessonNote(widget.lessonId, note);

    _notesController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Nota agregada')),
    );
  }

  void _deleteNote(LessonNote note) {
    setState(() {
      _notes.remove(note);
    });

    ref.read(courseProvider.notifier).deleteLessonNote(widget.lessonId, note.id);
  }

  void _seekToTimestamp(Duration timestamp) {
    if (_youtubeController != null) {
      _youtubeController!.seekTo(timestamp);
    } else if (_videoController != null) {
      _videoController!.seekTo(timestamp);
    }
    Navigator.pop(context); // Cerrar drawer de notas
  }

  String _formatTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  Lesson? _getNextLesson(Course course, Lesson currentLesson) {
    // Buscar siguiente lección en el curso
    bool foundCurrent = false;
    for (final module in course.modules ?? []) {
      for (final lesson in module.lessons) {
        if (foundCurrent) {
          return lesson;
        }
        if (lesson.id == currentLesson.id) {
          foundCurrent = true;
        }
      }
    }
    return null;
  }

  Lesson? _getPreviousLesson(Course course, Lesson currentLesson) {
    // Buscar lección anterior en el curso
    Lesson? previous;
    for (final module in course.modules ?? []) {
      for (final lesson in module.lessons) {
        if (lesson.id == currentLesson.id) {
          return previous;
        }
        previous = lesson;
      }
    }
    return null;
  }

  void _navigateToLesson(Lesson lesson) {
    context.pushReplacement('/academy/lesson/${lesson.id}');
  }

  void _finishCourse(Course course) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¡Felicitaciones!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.celebration,
              size: 64,
              color: AppColors.gold,
            ),
            const SizedBox(height: 16),
            Text(
              'Has completado el curso\n"${course.title}"',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/academy');
            },
            child: const Text('Ir a cursos'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.push('/academy/certificate/${course.id}');
            },
            child: const Text('Ver certificado'),
          ),
        ],
      ),
    );
  }
}

/// Tab de descripción
class _DescriptionTab extends StatelessWidget {
  final Lesson lesson;

  const _DescriptionTab({required this.lesson});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (lesson.description != null) ...[
            const Text(
              'Descripción',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              lesson.description!,
              style: const TextStyle(height: 1.5),
            ),
            const SizedBox(height: 20),
          ],

          if (lesson.objectives != null && lesson.objectives!.isNotEmpty) ...[
            const Text(
              'Objetivos de aprendizaje',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...lesson.objectives!.map((objective) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(objective),
                      ),
                    ],
                  ),
                )),
          ],

          if (lesson.content != null) ...[
            const SizedBox(height: 20),
            const Text(
              'Contenido',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              lesson.content!,
              style: const TextStyle(height: 1.5),
            ),
          ],
        ],
      ),
    );
  }
}

/// Tab de recursos
class _ResourcesTab extends StatelessWidget {
  final Lesson lesson;

  const _ResourcesTab({required this.lesson});

  @override
  Widget build(BuildContext context) {
    if (lesson.resources == null || lesson.resources!.isEmpty) {
      return const Center(
        child: Text('No hay recursos disponibles para esta lección'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: lesson.resources!.length,
      itemBuilder: (context, index) {
        final resource = lesson.resources![index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Icon(
              _getResourceIcon(resource['type']),
              color: AppColors.primary,
            ),
            title: Text(resource['title']),
            subtitle: Text(resource['description'] ?? ''),
            trailing: IconButton(
              icon: const Icon(Icons.download),
              onPressed: () {
                // Descargar recurso
              },
            ),
          ),
        );
      },
    );
  }

  IconData _getResourceIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'document':
        return Icons.description;
      case 'link':
        return Icons.link;
      case 'video':
        return Icons.video_library;
      default:
        return Icons.attach_file;
    }
  }
}

/// Tab de notas
class _NotesTab extends StatelessWidget {
  final List<LessonNote> notes;
  final Function(String) onAddNote;
  final Duration? currentPosition;

  const _NotesTab({
    required this.notes,
    required this.onAddNote,
    this.currentPosition,
  });

  @override
  Widget build(BuildContext context) {
    final textController = TextEditingController();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: textController,
                  decoration: InputDecoration(
                    hintText: currentPosition != null
                        ? 'Agregar nota en ${_formatTime(currentPosition!)}'
                        : 'Agregar nota...',
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.add),
                color: AppColors.primary,
                onPressed: () {
                  onAddNote(textController.text);
                  textController.clear();
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: notes.isEmpty
              ? const Center(
                  child: Text('No hay notas aún'),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: notes.length,
                  itemBuilder: (context, index) {
                    final note = notes[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _formatTime(note.timestamp),
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        title: Text(note.content),
                        subtitle: Text(
                          _formatDate(note.createdAt),
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  String _formatTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      return 'hace ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'hace ${difference.inHours} h';
    } else {
      return 'hace ${difference.inDays} días';
    }
  }
}

/// Modelo para nota de lección
class LessonNote {
  final String id;
  final String lessonId;
  final String content;
  final Duration timestamp;
  final DateTime createdAt;

  const LessonNote({
    required this.id,
    required this.lessonId,
    required this.content,
    required this.timestamp,
    required this.createdAt,
  });
}