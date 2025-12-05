import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/course_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/course_provider.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/custom_app_bar.dart';

/// Pantalla de detalles del curso
class CourseDetailScreen extends ConsumerStatefulWidget {
  final String courseId;

  const CourseDetailScreen({
    Key? key,
    required this.courseId,
  }) : super(key: key);

  @override
  ConsumerState<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends ConsumerState<CourseDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isEnrolled = false;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _checkEnrollment();
  }

  void _checkEnrollment() {
    final enrollmentStatus = ref.read(courseEnrollmentProvider(widget.courseId));
    enrollmentStatus.whenData((enrolled) {
      setState(() {
        _isEnrolled = enrolled;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final courseAsync = ref.watch(courseDetailProvider(widget.courseId));
    final user = ref.watch(currentUserProvider);

    return courseAsync.when(
      data: (course) => _buildCourseContent(course, user),
      loading: () => const Scaffold(
        body: LoadingWidget(),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(courseDetailProvider(widget.courseId)),
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCourseContent(Course course, dynamic user) {
    final theme = Theme.of(context);
    final progress = course.progress ?? 0.0;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // AppBar con imagen de fondo
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                course.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      offset: Offset(0, 1),
                      blurRadius: 3,
                      color: Colors.black54,
                    ),
                  ],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    course.imageUrl ?? 'https://via.placeholder.com/800x400',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: AppColors.primary,
                        child: const Icon(
                          Icons.school,
                          size: 100,
                          color: Colors.white30,
                        ),
                      );
                    },
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                  if (_isEnrolled && progress > 0)
                    Positioned(
                      bottom: 60,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularPercentIndicator(
                              radius: 20,
                              lineWidth: 3,
                              percent: progress / 100,
                              progressColor: AppColors.gold,
                              backgroundColor: Colors.white30,
                              center: Text(
                                '${progress.toInt()}%',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Completado',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border),
                onPressed: _toggleFavorite,
              ),
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () => _shareCourse(course),
              ),
            ],
          ),

          // Información principal del curso
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Instructor y categoría
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 25,
                        backgroundImage: course.instructor.avatarUrl != null
                            ? NetworkImage(course.instructor.avatarUrl!)
                            : null,
                        backgroundColor: AppColors.primary,
                        child: course.instructor.avatarUrl == null
                            ? Text(
                                course.instructor.name[0].toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              course.instructor.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            if (course.instructor.title != null)
                              Text(
                                course.instructor.title!,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getLevelColor(course.level).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: _getLevelColor(course.level),
                          ),
                        ),
                        child: Text(
                          course.level,
                          style: TextStyle(
                            color: _getLevelColor(course.level),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Estadísticas del curso
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatItem(
                          icon: Icons.video_library,
                          label: 'Lecciones',
                          value: '${course.totalLessons}',
                        ),
                        _StatItem(
                          icon: Icons.timer,
                          label: 'Duración',
                          value: course.duration ?? '0h',
                        ),
                        _StatItem(
                          icon: Icons.people,
                          label: 'Estudiantes',
                          value: _formatNumber(course.enrolledCount ?? 0),
                        ),
                        _StatItem(
                          icon: Icons.star,
                          label: 'Calificación',
                          value: '${course.rating ?? 0}',
                          color: AppColors.gold,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Descripción
                  Text(
                    'Acerca del curso',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    course.description ?? 'Sin descripción disponible',
                    style: const TextStyle(
                      height: 1.5,
                      fontSize: 15,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Lo que aprenderás
                  if (course.learningObjectives != null &&
                      course.learningObjectives!.isNotEmpty) ...[
                    Text(
                      'Lo que aprenderás',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...course.learningObjectives!.map((objective) => Padding(
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
                                child: Text(
                                  objective,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Tabs del curso
          SliverPersistentHeader(
            pinned: true,
            delegate: _StickyTabBarDelegate(
              TabBar(
                controller: _tabController,
                indicatorColor: AppColors.primary,
                labelColor: AppColors.primary,
                unselectedLabelColor: Colors.grey,
                tabs: const [
                  Tab(text: 'CONTENIDO'),
                  Tab(text: 'RECURSOS'),
                  Tab(text: 'DISCUSIÓN'),
                  Tab(text: 'CERTIFICADO'),
                ],
              ),
            ),
          ),

          // Contenido de tabs
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _ContentTab(course: course, isEnrolled: _isEnrolled),
                _ResourcesTab(course: course),
                _DiscussionTab(course: course),
                _CertificateTab(course: course),
              ],
            ),
          ),
        ],
      ),

      // Botón de inscripción/continuar
      bottomNavigationBar: _buildBottomBar(course, user),
    );
  }

  Widget _buildBottomBar(Course course, dynamic user) {
    if (user == null) {
      return Container(
        padding: const EdgeInsets.all(16),
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
        child: ElevatedButton(
          onPressed: () => context.push('/login'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'INICIAR SESIÓN PARA INSCRIBIRSE',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    if (_isEnrolled) {
      final nextLesson = _getNextLesson(course);

      return Container(
        padding: const EdgeInsets.all(16),
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
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nextLesson != null
                        ? 'Continuar con: ${nextLesson.title}'
                        : '¡Curso completado!',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (course.progress != null)
                    Text(
                      'Progreso: ${course.progress!.toInt()}%',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: nextLesson != null
                  ? () => _navigateToLesson(nextLesson)
                  : () => _viewCertificate(course),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                nextLesson != null ? 'CONTINUAR' : 'VER CERTIFICADO',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // No inscrito
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (course.price != null && course.price! > 0) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (course.originalPrice != null &&
                        course.originalPrice! > course.price!)
                      Text(
                        '\$${course.originalPrice!.toStringAsFixed(2)}',
                        style: const TextStyle(
                          decoration: TextDecoration.lineThrough,
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    Text(
                      '\$${course.price!.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                if (course.originalPrice != null &&
                    course.originalPrice! > course.price!)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${_calculateDiscount(course)}% OFF',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          ElevatedButton(
            onPressed: () => _enrollInCourse(course),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              course.price == null || course.price == 0
                  ? 'INSCRIBIRSE GRATIS'
                  : 'COMPRAR CURSO',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getLevelColor(String level) {
    switch (level.toLowerCase()) {
      case 'básico':
      case 'principiante':
        return Colors.green;
      case 'intermedio':
        return Colors.orange;
      case 'avanzado':
        return AppColors.primary;
      default:
        return Colors.grey;
    }
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  int _calculateDiscount(Course course) {
    if (course.originalPrice == null || course.price == null) return 0;
    return ((1 - course.price! / course.originalPrice!) * 100).round();
  }

  Lesson? _getNextLesson(Course course) {
    // Obtener la siguiente lección no completada
    if (course.modules == null) return null;

    for (final module in course.modules!) {
      for (final lesson in module.lessons) {
        if (!lesson.isCompleted) {
          return lesson;
        }
      }
    }
    return null;
  }

  void _toggleFavorite() {
    setState(() {
      _isFavorite = !_isFavorite;
    });

    if (_isFavorite) {
      ref.read(courseProvider.notifier).addToFavorites(widget.courseId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Curso agregado a favoritos')),
      );
    } else {
      ref.read(courseProvider.notifier).removeFromFavorites(widget.courseId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Curso eliminado de favoritos')),
      );
    }
  }

  void _shareCourse(Course course) {
    // Compartir curso
    final url = 'https://enfocadosendiostv.com/academy/course/${course.id}';
    final text = '¡Mira este curso increíble!\n\n${course.title}\n\n$url';
    // Share.share(text);
  }

  void _enrollInCourse(Course course) {
    if (course.price == null || course.price == 0) {
      // Inscripción gratuita
      ref.read(courseProvider.notifier).enrollInCourse(course.id);
      setState(() {
        _isEnrolled = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Te has inscrito exitosamente!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      // Ir a pantalla de pago
      context.push('/academy/checkout/${course.id}');
    }
  }

  void _navigateToLesson(Lesson lesson) {
    context.push('/academy/lesson/${lesson.id}');
  }

  void _viewCertificate(Course course) {
    context.push('/academy/certificate/${course.id}');
  }
}

/// Tab de contenido del curso
class _ContentTab extends StatelessWidget {
  final Course course;
  final bool isEnrolled;

  const _ContentTab({
    required this.course,
    required this.isEnrolled,
  });

  @override
  Widget build(BuildContext context) {
    if (course.modules == null || course.modules!.isEmpty) {
      return const Center(
        child: Text('No hay contenido disponible'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: course.modules!.length,
      itemBuilder: (context, index) {
        final module = course.modules![index];
        return _ModuleCard(
          module: module,
          moduleNumber: index + 1,
          isEnrolled: isEnrolled,
        );
      },
    );
  }
}

/// Tarjeta de módulo
class _ModuleCard extends StatefulWidget {
  final Module module;
  final int moduleNumber;
  final bool isEnrolled;

  const _ModuleCard({
    required this.module,
    required this.moduleNumber,
    required this.isEnrolled,
  });

  @override
  State<_ModuleCard> createState() => _ModuleCardState();
}

class _ModuleCardState extends State<_ModuleCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final completedLessons = widget.module.lessons.where((l) => l.isCompleted).length;
    final totalLessons = widget.module.lessons.length;
    final progress = totalLessons > 0 ? completedLessons / totalLessons : 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(12),
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: progress == 1.0
                    ? Colors.green.withOpacity(0.1)
                    : null,
                borderRadius: BorderRadius.vertical(
                  top: const Radius.circular(12),
                  bottom: Radius.circular(_isExpanded ? 0 : 12),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: progress == 1.0
                              ? Colors.green
                              : AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${widget.moduleNumber}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: progress == 1.0
                                ? Colors.white
                                : AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.module.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$totalLessons lecciones • ${widget.module.duration}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        _isExpanded ? Icons.expand_less : Icons.expand_more,
                      ),
                    ],
                  ),
                  if (widget.isEnrolled && progress > 0) ...[
                    const SizedBox(height: 12),
                    LinearPercentIndicator(
                      lineHeight: 6,
                      percent: progress,
                      backgroundColor: Colors.grey[300],
                      progressColor: progress == 1.0
                          ? Colors.green
                          : AppColors.primary,
                      padding: EdgeInsets.zero,
                      barRadius: const Radius.circular(3),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$completedLessons de $totalLessons completadas',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (_isExpanded)
            Container(
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey, width: 0.2),
                ),
              ),
              child: Column(
                children: widget.module.lessons.map((lesson) {
                  return _LessonTile(
                    lesson: lesson,
                    isEnrolled: widget.isEnrolled,
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

/// Tile de lección
class _LessonTile extends StatelessWidget {
  final Lesson lesson;
  final bool isEnrolled;

  const _LessonTile({
    required this.lesson,
    required this.isEnrolled,
  });

  @override
  Widget build(BuildContext context) {
    final isLocked = !isEnrolled && !lesson.isFree;

    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: lesson.isCompleted
              ? Colors.green
              : isLocked
                  ? Colors.grey[300]
                  : AppColors.primary.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          lesson.isCompleted
              ? Icons.check
              : _getLessonIcon(lesson.type),
          size: 20,
          color: lesson.isCompleted
              ? Colors.white
              : isLocked
                  ? Colors.grey
                  : AppColors.primary,
        ),
      ),
      title: Text(
        lesson.title,
        style: TextStyle(
          fontSize: 14,
          decoration: lesson.isCompleted
              ? TextDecoration.lineThrough
              : null,
          color: isLocked ? Colors.grey : null,
        ),
      ),
      subtitle: Text(
        '${lesson.duration} min',
        style: const TextStyle(fontSize: 12),
      ),
      trailing: isLocked
          ? const Icon(Icons.lock, size: 20, color: Colors.grey)
          : lesson.isFree && !isEnrolled
              ? Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'GRATIS',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                )
              : null,
      onTap: isLocked
          ? null
          : () => context.push('/academy/lesson/${lesson.id}'),
    );
  }

  IconData _getLessonIcon(String type) {
    switch (type.toLowerCase()) {
      case 'video':
        return Icons.play_circle_outline;
      case 'reading':
      case 'article':
        return Icons.article;
      case 'quiz':
        return Icons.quiz;
      case 'assignment':
        return Icons.assignment;
      case 'audio':
        return Icons.headphones;
      default:
        return Icons.play_circle_outline;
    }
  }
}

/// Tab de recursos
class _ResourcesTab extends StatelessWidget {
  final Course course;

  const _ResourcesTab({required this.course});

  @override
  Widget build(BuildContext context) {
    if (course.resources == null || course.resources!.isEmpty) {
      return const Center(
        child: Text('No hay recursos disponibles'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: course.resources!.length,
      itemBuilder: (context, index) {
        final resource = course.resources![index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Icon(
              _getResourceIcon(resource.type),
              color: AppColors.primary,
            ),
            title: Text(resource.title),
            subtitle: Text(resource.description ?? ''),
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

  IconData _getResourceIcon(String type) {
    switch (type.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'video':
        return Icons.video_library;
      case 'audio':
        return Icons.audiotrack;
      case 'document':
        return Icons.description;
      case 'link':
        return Icons.link;
      default:
        return Icons.attach_file;
    }
  }
}

/// Tab de discusión
class _DiscussionTab extends StatelessWidget {
  final Course course;

  const _DiscussionTab({required this.course});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.forum,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Foro de discusión',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Próximamente disponible',
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}

/// Tab de certificado
class _CertificateTab extends StatelessWidget {
  final Course course;

  const _CertificateTab({required this.course});

  @override
  Widget build(BuildContext context) {
    final progress = course.progress ?? 0;
    final isCompleted = progress >= 100;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.workspace_premium,
              size: 100,
              color: isCompleted ? AppColors.gold : Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              isCompleted
                  ? '¡Felicitaciones!'
                  : 'Certificado de finalización',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isCompleted
                  ? 'Has completado exitosamente este curso'
                  : 'Completa todas las lecciones para obtener tu certificado',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            if (isCompleted)
              ElevatedButton.icon(
                onPressed: () => context.push('/academy/certificate/${course.id}'),
                icon: const Icon(Icons.download),
                label: const Text('DESCARGAR CERTIFICADO'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              )
            else
              Column(
                children: [
                  CircularPercentIndicator(
                    radius: 60,
                    lineWidth: 8,
                    percent: progress / 100,
                    center: Text(
                      '${progress.toInt()}%',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    progressColor: AppColors.primary,
                    backgroundColor: Colors.grey[300]!,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Progreso del curso',
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// Widget de estadística
class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          color: color ?? AppColors.primary,
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

/// Delegado para tab bar sticky
class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _StickyTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_StickyTabBarDelegate oldDelegate) {
    return false;
  }
}