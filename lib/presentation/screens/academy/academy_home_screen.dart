import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

import '../../../data/models/academy_models.dart';
import '../../providers/academy_provider.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/empty_state_widget.dart';

class AcademyHomeScreen extends ConsumerStatefulWidget {
  const AcademyHomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AcademyHomeScreen> createState() => _AcademyHomeScreenState();
}

class _AcademyHomeScreenState extends ConsumerState<AcademyHomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  CourseCategory? _selectedCategory;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 200,
            floating: true,
            pinned: true,
            backgroundColor: const Color(0xFFCC0000),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Academia Bíblica'),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFFCC0000),
                          Color(0xFF990000),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    right: -50,
                    top: -50,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                  ),
                  Positioned(
                    left: -30,
                    bottom: -30,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFFFD700).withOpacity(0.2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () => _showSearchDialog(),
              ),
              IconButton(
                icon: const Icon(Icons.workspace_premium),
                onPressed: () => context.push('/certificates'),
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFFFFD700),
              indicatorWeight: 3,
              tabs: const [
                Tab(text: 'EXPLORAR'),
                Tab(text: 'MIS CURSOS'),
                Tab(text: 'DESTACADOS'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildExploreTab(),
            _buildMyCoursesTab(),
            _buildFeaturedTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildExploreTab() {
    final categoriesAsync = ref.watch(courseCategoriesProvider);
    final coursesAsync = ref.watch(allCoursesProvider);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Categorías
          categoriesAsync.when(
            data: (categories) => SizedBox(
              height: 110,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(16),
                itemCount: categories.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _buildCategoryCard(
                      null,
                      'Todos',
                      Icons.apps,
                      const Color(0xFFCC0000),
                    );
                  }
                  final category = categories[index - 1];
                  return _buildCategoryCard(
                    category,
                    category.name,
                    _getCategoryIcon(category.id),
                    _getCategoryColor(category.id),
                  );
                },
              ),
            ),
            loading: () => const SizedBox(
              height: 110,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => const SizedBox(),
          ),

          // Título de sección
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedCategory == null
                      ? 'Todos los Cursos'
                      : _selectedCategory!.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_selectedCategory != null)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedCategory = null;
                      });
                    },
                    child: const Text('Ver todos'),
                  ),
              ],
            ),
          ),

          // Lista de cursos
          coursesAsync.when(
            data: (courses) {
              final filteredCourses = _filterCourses(courses);

              if (filteredCourses.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(32),
                  child: EmptyStateWidget(
                    icon: Icons.school,
                    title: 'No hay cursos',
                    message: 'No se encontraron cursos en esta categoría',
                  ),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: filteredCourses.length,
                itemBuilder: (context, index) {
                  final course = filteredCourses[index];
                  return _buildCourseCard(course);
                },
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: LoadingWidget(),
              ),
            ),
            error: (error, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text('Error: $error'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyCoursesTab() {
    final myCoursesAsync = ref.watch(userCoursesProvider);

    return myCoursesAsync.when(
      data: (enrollments) {
        if (enrollments.isEmpty) {
          return EmptyStateWidget(
            icon: Icons.school,
            title: 'No tienes cursos',
            message: 'Inscríbete en cursos para verlos aquí',
            actionLabel: 'Explorar Cursos',
            onAction: () => _tabController.animateTo(0),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: enrollments.length,
          itemBuilder: (context, index) {
            final enrollment = enrollments[index];
            return _buildEnrollmentCard(enrollment);
          },
        );
      },
      loading: () => const Center(child: LoadingWidget()),
      error: (error, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $error'),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedTab() {
    final featuredAsync = ref.watch(featuredCoursesProvider);

    return featuredAsync.when(
      data: (courses) {
        if (courses.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.star,
            title: 'No hay cursos destacados',
            message: 'Vuelve pronto para ver nuevos cursos destacados',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: courses.length,
          itemBuilder: (context, index) {
            final course = courses[index];
            return _buildFeaturedCourseCard(course);
          },
        );
      },
      loading: () => const Center(child: LoadingWidget()),
      error: (error, _) => Center(
        child: Text('Error: $error'),
      ),
    );
  }

  Widget _buildCategoryCard(
    CourseCategory? category,
    String name,
    IconData icon,
    Color color,
  ) {
    final isSelected = _selectedCategory == category ||
        (category == null && _selectedCategory == null);

    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedCategory = category;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 80,
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 28,
                color: isSelected ? Colors.white : color,
              ),
              const SizedBox(height: 8),
              Text(
                name,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.black87,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCourseCard(CourseModel course) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => context.push('/academy/course/${course.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen del curso
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: CachedNetworkImage(
                  imageUrl: course.imageUrl ?? '',
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.school, size: 50),
                  ),
                ),
              ),
            ),

            // Información del curso
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (course.level != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getLevelColor(course.level!),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _getLevelLabel(course.level!),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (course.isFree) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'GRATIS',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
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
                  if (course.description != null) ...[
                    Text(
                      course.description!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                  ],
                  Row(
                    children: [
                      if (course.instructor != null) ...[
                        CircleAvatar(
                          radius: 12,
                          backgroundImage: course.instructor!.photoUrl != null
                              ? CachedNetworkImageProvider(course.instructor!.photoUrl!)
                              : null,
                          child: course.instructor!.photoUrl == null
                              ? Text(course.instructor!.name[0])
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            course.instructor!.name,
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                      Icon(Icons.people, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${course.enrolledCount}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.star, size: 14, color: Colors.amber[700]),
                      const SizedBox(width: 4),
                      Text(
                        course.rating.toStringAsFixed(1),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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

  Widget _buildEnrollmentCard(CourseEnrollment enrollment) {
    final progress = enrollment.progress / 100;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => context.push('/academy/course/${enrollment.course.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Imagen del curso
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: enrollment.course.imageUrl ?? '',
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey[300],
                    child: const Icon(Icons.school),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Información
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      enrollment.course.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    LinearPercentIndicator(
                      lineHeight: 8,
                      percent: progress,
                      backgroundColor: Colors.grey[300],
                      progressColor: const Color(0xFFCC0000),
                      barRadius: const Radius.circular(4),
                      padding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${enrollment.progress}% completado',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          '${enrollment.completedLessons}/${enrollment.course.totalLessons} lecciones',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Flecha
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedCourseCard(CourseModel course) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => context.push('/academy/course/${course.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner destacado
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: CachedNetworkImage(
                      imageUrl: course.imageUrl ?? '',
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.school, size: 50),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD700),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.star, size: 16, color: Colors.black),
                        SizedBox(width: 4),
                        Text(
                          'DESTACADO',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
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
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (course.description != null)
                    Text(
                      course.description!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => context.push('/academy/course/${course.id}'),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Ver Curso'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFCC0000),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<CourseModel> _filterCourses(List<CourseModel> courses) {
    var filtered = courses;

    if (_selectedCategory != null) {
      filtered = filtered.where((course) =>
        course.categoryId == _selectedCategory!.id
      ).toList();
    }

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((course) =>
        course.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        (course.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)
      ).toList();
    }

    return filtered;
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Buscar Cursos'),
        content: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Ingresa tu búsqueda...',
            prefixIcon: Icon(Icons.search),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _searchQuery = _searchController.text;
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFCC0000),
            ),
            child: const Text('Buscar'),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String categoryId) {
    switch (categoryId) {
      case 'biblical-studies':
        return Icons.menu_book;
      case 'theology':
        return Icons.church;
      case 'ministry':
        return Icons.groups;
      case 'leadership':
        return Icons.psychology;
      case 'family':
        return Icons.family_restroom;
      default:
        return Icons.school;
    }
  }

  Color _getCategoryColor(String categoryId) {
    switch (categoryId) {
      case 'biblical-studies':
        return const Color(0xFF8B4513);
      case 'theology':
        return const Color(0xFF4169E1);
      case 'ministry':
        return const Color(0xFF228B22);
      case 'leadership':
        return const Color(0xFFFF8C00);
      case 'family':
        return const Color(0xFF9370DB);
      default:
        return const Color(0xFFCC0000);
    }
  }

  Color _getLevelColor(CourseLevel level) {
    switch (level) {
      case CourseLevel.beginner:
        return Colors.green;
      case CourseLevel.intermediate:
        return Colors.orange;
      case CourseLevel.advanced:
        return Colors.red;
    }
  }

  String _getLevelLabel(CourseLevel level) {
    switch (level) {
      case CourseLevel.beginner:
        return 'Principiante';
      case CourseLevel.intermediate:
        return 'Intermedio';
      case CourseLevel.advanced:
        return 'Avanzado';
    }
  }
}