import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/themes/app_colors.dart';
import '../../../core/constants/route_names.dart';
import '../../../data/models/course_model.dart';
import '../../providers/course_provider.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/error_widget.dart';

class AcademyScreen extends ConsumerStatefulWidget {
  const AcademyScreen({super.key});

  @override
  ConsumerState<AcademyScreen> createState() => _AcademyScreenState();
}

class _AcademyScreenState extends ConsumerState<AcademyScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  CourseDifficulty? _selectedDifficulty;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Cargar cursos
    Future.microtask(() {
      ref.read(coursesProvider.notifier).loadCourses();
      ref.read(myCoursesProvider.notifier).loadMyCourses();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            // App Bar
            SliverAppBar(
              expandedHeight: 180,
              floating: true,
              pinned: true,
              backgroundColor: AppColors.primary,
              flexibleSpace: FlexibleSpaceBar(
                title: const Text(
                  'Academia Bíblica',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary,
                        AppColors.gold.shade700,
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -50,
                        bottom: -30,
                        child: Icon(
                          Icons.school_outlined,
                          size: 200,
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Aprende y crece en la fe',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 50),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              bottom: TabBar(
                controller: _tabController,
                indicatorColor: AppColors.gold,
                indicatorWeight: 3,
                tabs: const [
                  Tab(text: 'EXPLORAR'),
                  Tab(text: 'MIS CURSOS'),
                  Tab(text: 'CERTIFICADOS'),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _showSearchDialog,
                ),
              ],
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            // Tab Explorar
            _buildExploreTab(),

            // Tab Mis Cursos
            _buildMyCoursesTab(),

            // Tab Certificados
            _buildCertificatesTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildExploreTab() {
    final courses = ref.watch(coursesProvider);

    return Column(
      children: [
        // Filtros
        Container(
          height: 50,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              // Filtro de dificultad
              _buildFilterChip(
                label: 'Todos los niveles',
                isSelected: _selectedDifficulty == null,
                onSelected: (selected) {
                  setState(() => _selectedDifficulty = null);
                  ref.read(coursesProvider.notifier).loadCourses();
                },
              ),
              const SizedBox(width: 8),
              ...CourseDifficulty.values.map((difficulty) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: _selectedDifficulty == difficulty,
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(difficulty.icon),
                        const SizedBox(width: 4),
                        Text(difficulty.displayName),
                      ],
                    ),
                    selectedColor: _getDifficultyColor(difficulty).withOpacity(0.2),
                    checkmarkColor: _getDifficultyColor(difficulty),
                    onSelected: (selected) {
                      setState(() {
                        _selectedDifficulty = selected ? difficulty : null;
                      });
                      ref.read(coursesProvider.notifier).loadCourses(
                        difficulty: selected ? difficulty : null,
                      );
                    },
                  ),
                );
              }).toList(),
            ],
          ),
        ),

        // Lista de cursos
        Expanded(
          child: courses.when(
            data: (courseList) {
              if (courseList.isEmpty) {
                return EmptyStateWidget(
                  icon: Icons.school_outlined,
                  title: 'No hay cursos disponibles',
                  message: 'Pronto agregaremos nuevos cursos.\n¡Mantente atento!',
                );
              }

              return RefreshIndicator(
                onRefresh: () => ref.read(coursesProvider.notifier).refresh(),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: courseList.length,
                  itemBuilder: (context, index) {
                    final course = courseList[index];
                    return CourseCard(
                      course: course,
                      onTap: () {
                        context.push('${Routes.academy}/course/${course.id}');
                      },
                    );
                  },
                ),
              );
            },
            loading: () => const LoadingIndicator(),
            error: (error, _) => CustomErrorWidget(
              message: 'Error al cargar los cursos',
              onRetry: () {
                ref.read(coursesProvider.notifier).refresh();
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMyCoursesTab() {
    final myCourses = ref.watch(myCoursesProvider);

    return myCourses.when(
      data: (courseList) {
        if (courseList.isEmpty) {
          return EmptyStateWidget(
            icon: Icons.book_outlined,
            title: 'No estás inscrito en ningún curso',
            message: 'Explora nuestra biblioteca de cursos\ny comienza tu aprendizaje hoy.',
            buttonText: 'Explorar Cursos',
            onAction: () {
              _tabController.animateTo(0);
            },
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: courseList.length,
          itemBuilder: (context, index) {
            final course = courseList[index];
            return MyCourseCard(
              course: course,
              onTap: () {
                context.push('${Routes.academy}/course/${course.id}');
              },
            );
          },
        );
      },
      loading: () => const LoadingIndicator(),
      error: (error, _) => CustomErrorWidget(
        message: 'Error al cargar tus cursos',
        onRetry: () {
          ref.read(myCoursesProvider.notifier).loadMyCourses();
        },
      ),
    );
  }

  Widget _buildCertificatesTab() {
    final certificates = ref.watch(certificatesProvider);

    return certificates.when(
      data: (certificateList) {
        if (certificateList.isEmpty) {
          return EmptyStateWidget(
            icon: Icons.workspace_premium_outlined,
            title: 'Sin certificados aún',
            message: 'Completa cursos para obtener\ntus certificados de logro.',
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.7,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: certificateList.length,
          itemBuilder: (context, index) {
            final certificate = certificateList[index];
            return CertificateCard(certificate: certificate);
          },
        );
      },
      loading: () => const LoadingIndicator(),
      error: (error, _) => CustomErrorWidget(
        message: 'Error al cargar los certificados',
        onRetry: () {
          ref.invalidate(certificatesProvider);
        },
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required Function(bool) onSelected,
  }) {
    return FilterChip(
      selected: isSelected,
      label: Text(label),
      selectedColor: AppColors.primary.withOpacity(0.2),
      checkmarkColor: AppColors.primary,
      onSelected: onSelected,
    );
  }

  Color _getDifficultyColor(CourseDifficulty difficulty) {
    switch (difficulty) {
      case CourseDifficulty.beginner:
        return AppColors.success;
      case CourseDifficulty.intermediate:
        return AppColors.warning;
      case CourseDifficulty.advanced:
        return AppColors.error;
    }
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String searchQuery = '';

        return AlertDialog(
          title: const Text('Buscar Cursos'),
          content: TextField(
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Buscar por título o tema...',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) => searchQuery = value,
            onSubmitted: (value) {
              if (value.isNotEmpty) {
                Navigator.pop(context);
                // TODO: Implementar búsqueda
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (searchQuery.isNotEmpty) {
                  Navigator.pop(context);
                  // TODO: Implementar búsqueda
                }
              },
              child: const Text('Buscar'),
            ),
          ],
        );
      },
    );
  }
}

/// Tarjeta de curso para explorar
class CourseCard extends StatelessWidget {
  final CourseModel course;
  final VoidCallback onTap;

  const CourseCard({
    super.key,
    required this.course,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  children: [
                    Container(
                      color: AppColors.primary.withOpacity(0.1),
                      child: Center(
                        child: Icon(
                          Icons.school_outlined,
                          size: 48,
                          color: AppColors.primary.withOpacity(0.5),
                        ),
                      ),
                    ),
                    // Badges
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getDifficultyColor(course.difficulty),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          course.difficulty.displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    if (course.isFree)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'GRATIS',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Contenido
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Por ${course.instructor}',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    course.description,
                    style: const TextStyle(fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        course.formattedDuration,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.play_lesson_outlined,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${course.totalLessons} lecciones',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const Spacer(),
                      if (!course.isFree)
                        Text(
                          course.formattedPrice,
                          style: TextStyle(
                            color: AppColors.gold,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
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

  Color _getDifficultyColor(CourseDifficulty difficulty) {
    switch (difficulty) {
      case CourseDifficulty.beginner:
        return AppColors.success;
      case CourseDifficulty.intermediate:
        return AppColors.warning;
      case CourseDifficulty.advanced:
        return AppColors.error;
    }
  }
}

/// Tarjeta de mis cursos
class MyCourseCard extends StatelessWidget {
  final CourseModel course;
  final VoidCallback onTap;

  const MyCourseCard({
    super.key,
    required this.course,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Progress indicator
              SizedBox(
                width: 60,
                height: 60,
                child: Stack(
                  children: [
                    CircularProgressIndicator(
                      value: course.progressPercentage / 100,
                      strokeWidth: 6,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation(
                        course.isCompleted
                            ? AppColors.success
                            : AppColors.primary,
                      ),
                    ),
                    Center(
                      child: Text(
                        '${course.progressPercentage.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // Información
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      course.instructor,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (course.userProgress != null)
                      Text(
                        '${course.userProgress!.completedLessons} de ${course.totalLessons} lecciones completadas',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),

              // Status icon
              Icon(
                course.isCompleted
                    ? Icons.check_circle
                    : Icons.arrow_forward_ios,
                color: course.isCompleted
                    ? AppColors.success
                    : AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tarjeta de certificado
class CertificateCard extends StatelessWidget {
  final Certificate certificate;

  const CertificateCard({
    super.key,
    required this.certificate,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          // TODO: Ver o descargar certificado
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.gold.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.workspace_premium,
                  size: 48,
                  color: AppColors.gold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                certificate.courseName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                'Completado el',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              Text(
                '${certificate.completedAt.day}/${certificate.completedAt.month}/${certificate.completedAt.year}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () {
                  // TODO: Descargar certificado
                },
                icon: const Icon(Icons.download, size: 16),
                label: const Text('Descargar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 36),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}