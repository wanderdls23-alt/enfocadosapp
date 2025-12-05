import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/themes/app_colors.dart';
import '../../../core/constants/route_names.dart';
import '../../../domain/entities/reading_plan.dart';
import '../../providers/bible_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/loading_indicator.dart';

class ReadingPlansScreen extends ConsumerStatefulWidget {
  const ReadingPlansScreen({super.key});

  @override
  ConsumerState<ReadingPlansScreen> createState() => _ReadingPlansScreenState();
}

class _ReadingPlansScreenState extends ConsumerState<ReadingPlansScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _selectedCategory = 'all';
  String _selectedDuration = 'all';
  String _sortBy = 'popular';

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
    final user = ref.watch(authStateProvider).value?.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // App Bar with Hero
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
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
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.auto_stories,
                          size: 60,
                          color: Colors.white.withOpacity(0.9),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Planes de Lectura',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Desarrolla el hábito de leer la Biblia diariamente',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        // Current Streak
                        if (user != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.local_fire_department,
                                  color: AppColors.gold,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${user.statistics.bibleReadingStreak} días seguidos',
                                  style: TextStyle(
                                    color: AppColors.gold,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              title: const Text(
                'Planes de Lectura',
                style: TextStyle(color: Colors.white),
              ),
              centerTitle: true,
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => context.pop(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.search, color: Colors.white),
                onPressed: _showSearchDialog,
              ),
            ],
          ),

          // Filters
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              child: Column(
                children: [
                  // Category Filter
                  _buildCategoryFilter(),

                  // Tabs
                  TabBar(
                    controller: _tabController,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: AppColors.textSecondary,
                    indicatorColor: AppColors.primary,
                    tabs: const [
                      Tab(text: 'EXPLORAR'),
                      Tab(text: 'MIS PLANES'),
                      Tab(text: 'COMPLETADOS'),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Content
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildExplorePlans(),
                _buildMyPlans(),
                _buildCompletedPlans(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createCustomPlan,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    final categories = [
      {'id': 'all', 'name': 'Todos', 'icon': Icons.dashboard},
      {'id': 'beginner', 'name': 'Principiante', 'icon': Icons.child_care},
      {'id': 'topical', 'name': 'Temático', 'icon': Icons.topic},
      {'id': 'chronological', 'name': 'Cronológico', 'icon': Icons.timeline},
      {'id': 'devotional', 'name': 'Devocional', 'icon': Icons.favorite},
      {'id': 'books', 'name': 'Por Libro', 'icon': Icons.menu_book},
    ];

    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = _selectedCategory == category['id'];

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = category['id'] as String;
              });
            },
            child: Container(
              width: 80,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ]
                          : [],
                    ),
                    child: Icon(
                      category['icon'] as IconData,
                      color: isSelected
                          ? Colors.white
                          : AppColors.textSecondary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    category['name'] as String,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildExplorePlans() {
    final plansAsync = ref.watch(readingPlansProvider);

    return plansAsync.when(
      data: (plans) {
        final filteredPlans = _filterPlans(plans);

        if (filteredPlans.isEmpty) {
          return _buildEmptyState(
            icon: Icons.search_off,
            message: 'No se encontraron planes',
            actionLabel: 'Ver todos',
            onAction: () {
              setState(() {
                _selectedCategory = 'all';
                _selectedDuration = 'all';
              });
            },
          );
        }

        return RefreshIndicator(
          onRefresh: () => ref.refresh(readingPlansProvider.future),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredPlans.length,
            itemBuilder: (context, index) {
              final plan = filteredPlans[index];
              return _PlanCard(
                plan: plan,
                onTap: () => _showPlanDetails(plan),
                onStart: () => _startPlan(plan),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: LoadingIndicator()),
      error: (error, stack) => _buildErrorState(),
    );
  }

  Widget _buildMyPlans() {
    final myPlansAsync = ref.watch(userReadingPlansProvider);

    return myPlansAsync.when(
      data: (plans) {
        if (plans.isEmpty) {
          return _buildEmptyState(
            icon: Icons.auto_stories,
            message: 'No tienes planes activos',
            actionLabel: 'Explorar planes',
            onAction: () {
              _tabController.animateTo(0);
            },
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: plans.length,
          itemBuilder: (context, index) {
            final plan = plans[index];
            return _ActivePlanCard(
              plan: plan,
              onContinue: () => _continuePlan(plan),
              onPause: () => _pausePlan(plan),
            );
          },
        );
      },
      loading: () => const Center(child: LoadingIndicator()),
      error: (error, stack) => _buildErrorState(),
    );
  }

  Widget _buildCompletedPlans() {
    final completedAsync = ref.watch(completedPlansProvider);

    return completedAsync.when(
      data: (plans) {
        if (plans.isEmpty) {
          return _buildEmptyState(
            icon: Icons.emoji_events_outlined,
            message: 'Aún no has completado ningún plan',
            actionLabel: null,
            onAction: null,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: plans.length,
          itemBuilder: (context, index) {
            final plan = plans[index];
            return _CompletedPlanCard(
              plan: plan,
              onRestart: () => _restartPlan(plan),
              onShare: () => _sharePlan(plan),
            );
          },
        );
      },
      loading: () => const Center(child: LoadingIndicator()),
      error: (error, stack) => _buildErrorState(),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: Text(actionLabel),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: AppColors.error.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'Error al cargar los planes',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              ref.refresh(readingPlansProvider);
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  List<ReadingPlan> _filterPlans(List<ReadingPlan> plans) {
    var filtered = plans;

    // Filter by category
    if (_selectedCategory != 'all') {
      filtered = filtered.where((plan) => plan.category == _selectedCategory).toList();
    }

    // Filter by duration
    if (_selectedDuration != 'all') {
      switch (_selectedDuration) {
        case 'week':
          filtered = filtered.where((plan) => plan.durationDays <= 7).toList();
          break;
        case 'month':
          filtered = filtered.where((plan) =>
            plan.durationDays > 7 && plan.durationDays <= 30
          ).toList();
          break;
        case 'quarter':
          filtered = filtered.where((plan) =>
            plan.durationDays > 30 && plan.durationDays <= 90
          ).toList();
          break;
        case 'year':
          filtered = filtered.where((plan) => plan.durationDays > 90).toList();
          break;
      }
    }

    // Sort
    switch (_sortBy) {
      case 'popular':
        filtered.sort((a, b) => b.enrolledCount.compareTo(a.enrolledCount));
        break;
      case 'newest':
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'shortest':
        filtered.sort((a, b) => a.durationDays.compareTo(b.durationDays));
        break;
    }

    return filtered;
  }

  void _showSearchDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.4,
              maxChildSize: 0.9,
              expand: false,
              builder: (context, scrollController) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Filtros y Ordenamiento',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: SingleChildScrollView(
                          controller: scrollController,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Duration Filter
                              const Text(
                                'Duración',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _buildFilterChip(
                                    label: 'Todos',
                                    value: 'all',
                                    groupValue: _selectedDuration,
                                    onSelected: (value) {
                                      setModalState(() {
                                        _selectedDuration = value;
                                      });
                                    },
                                  ),
                                  _buildFilterChip(
                                    label: '1 Semana',
                                    value: 'week',
                                    groupValue: _selectedDuration,
                                    onSelected: (value) {
                                      setModalState(() {
                                        _selectedDuration = value;
                                      });
                                    },
                                  ),
                                  _buildFilterChip(
                                    label: '1 Mes',
                                    value: 'month',
                                    groupValue: _selectedDuration,
                                    onSelected: (value) {
                                      setModalState(() {
                                        _selectedDuration = value;
                                      });
                                    },
                                  ),
                                  _buildFilterChip(
                                    label: '3 Meses',
                                    value: 'quarter',
                                    groupValue: _selectedDuration,
                                    onSelected: (value) {
                                      setModalState(() {
                                        _selectedDuration = value;
                                      });
                                    },
                                  ),
                                  _buildFilterChip(
                                    label: '1 Año',
                                    value: 'year',
                                    groupValue: _selectedDuration,
                                    onSelected: (value) {
                                      setModalState(() {
                                        _selectedDuration = value;
                                      });
                                    },
                                  ),
                                ],
                              ),

                              const SizedBox(height: 24),

                              // Sort By
                              const Text(
                                'Ordenar por',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Column(
                                children: [
                                  RadioListTile<String>(
                                    title: const Text('Más populares'),
                                    value: 'popular',
                                    groupValue: _sortBy,
                                    onChanged: (value) {
                                      setModalState(() {
                                        _sortBy = value!;
                                      });
                                    },
                                    activeColor: AppColors.primary,
                                  ),
                                  RadioListTile<String>(
                                    title: const Text('Más recientes'),
                                    value: 'newest',
                                    groupValue: _sortBy,
                                    onChanged: (value) {
                                      setModalState(() {
                                        _sortBy = value!;
                                      });
                                    },
                                    activeColor: AppColors.primary,
                                  ),
                                  RadioListTile<String>(
                                    title: const Text('Más cortos'),
                                    value: 'shortest',
                                    groupValue: _sortBy,
                                    onChanged: (value) {
                                      setModalState(() {
                                        _sortBy = value!;
                                      });
                                    },
                                    activeColor: AppColors.primary,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.only(top: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  setModalState(() {
                                    _selectedCategory = 'all';
                                    _selectedDuration = 'all';
                                    _sortBy = 'popular';
                                  });
                                },
                                child: const Text('Restablecer'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() {});
                                  Navigator.pop(context);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                ),
                                child: const Text('Aplicar'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildFilterChip({
    required String label,
    required String value,
    required String groupValue,
    required ValueChanged<String> onSelected,
  }) {
    final isSelected = value == groupValue;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(value),
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textPrimary,
      ),
      checkmarkColor: Colors.white,
    );
  }

  void _showPlanDetails(ReadingPlan plan) {
    context.push('${Routes.readingPlanDetails}/${plan.id}');
  }

  void _startPlan(ReadingPlan plan) {
    ref.read(readingPlanProvider.notifier).startPlan(plan.id);
  }

  void _continuePlan(ReadingPlan plan) {
    context.push('${Routes.readingPlanProgress}/${plan.id}');
  }

  void _pausePlan(ReadingPlan plan) {
    ref.read(readingPlanProvider.notifier).pausePlan(plan.id);
  }

  void _restartPlan(ReadingPlan plan) {
    ref.read(readingPlanProvider.notifier).restartPlan(plan.id);
  }

  void _sharePlan(ReadingPlan plan) {
    // Implement share functionality
  }

  void _createCustomPlan() {
    context.push(Routes.createReadingPlan);
  }
}

// Plan Card Widget
class _PlanCard extends StatelessWidget {
  final ReadingPlan plan;
  final VoidCallback onTap;
  final VoidCallback onStart;

  const _PlanCard({
    required this.plan,
    required this.onTap,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header with image
            Container(
              height: 150,
              decoration: BoxDecoration(
                color: _getCategoryColor(plan.category).withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: Stack(
                children: [
                  if (plan.imageUrl != null)
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      child: CachedNetworkImage(
                        imageUrl: plan.imageUrl!,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    )
                  else
                    Center(
                      child: Icon(
                        _getCategoryIcon(plan.category),
                        size: 60,
                        color: _getCategoryColor(plan.category),
                      ),
                    ),

                  // Overlay gradient
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
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

                  // Title and badge
                  Positioned(
                    bottom: 12,
                    left: 12,
                    right: 12,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            plan.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (plan.isFeatured)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.gold,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'DESTACADO',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Author
                  if (plan.author != null)
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: AppColors.surface,
                          child: Icon(
                            Icons.person,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          plan.author!,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 12),

                  // Description
                  Text(
                    plan.description,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      height: 1.5,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),

                  // Stats
                  Row(
                    children: [
                      _StatChip(
                        icon: Icons.calendar_today,
                        label: '${plan.durationDays} días',
                      ),
                      const SizedBox(width: 12),
                      _StatChip(
                        icon: Icons.timer,
                        label: '${plan.dailyReadingTime} min/día',
                      ),
                      const SizedBox(width: 12),
                      _StatChip(
                        icon: Icons.people,
                        label: _formatCount(plan.enrolledCount),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Action button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onStart,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Comenzar Plan'),
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

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'beginner':
        return Colors.green;
      case 'topical':
        return Colors.blue;
      case 'chronological':
        return Colors.orange;
      case 'devotional':
        return Colors.pink;
      case 'books':
        return Colors.purple;
      default:
        return AppColors.primary;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'beginner':
        return Icons.child_care;
      case 'topical':
        return Icons.topic;
      case 'chronological':
        return Icons.timeline;
      case 'devotional':
        return Icons.favorite;
      case 'books':
        return Icons.menu_book;
      default:
        return Icons.auto_stories;
    }
  }

  String _formatCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}

// Active Plan Card
class _ActivePlanCard extends StatelessWidget {
  final ReadingPlan plan;
  final VoidCallback onContinue;
  final VoidCallback onPause;

  const _ActivePlanCard({
    required this.plan,
    required this.onContinue,
    required this.onPause,
  });

  @override
  Widget build(BuildContext context) {
    final progress = plan.completedDays / plan.durationDays;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircularPercentIndicator(
                  radius: 30,
                  lineWidth: 6,
                  percent: progress,
                  center: Text(
                    '${(progress * 100).toInt()}%',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  progressColor: AppColors.primary,
                  backgroundColor: AppColors.surface,
                  circularStrokeCap: CircularStrokeCap.round,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Día ${plan.completedDays} de ${plan.durationDays}',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'pause') {
                      onPause();
                    } else if (value == 'restart') {
                      // Implement restart
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'pause',
                      child: Row(
                        children: [
                          Icon(Icons.pause),
                          SizedBox(width: 8),
                          Text('Pausar'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'restart',
                      child: Row(
                        children: [
                          Icon(Icons.restart_alt),
                          SizedBox(width: 8),
                          Text('Reiniciar'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Today's reading
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.menu_book,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Lectura de hoy',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          plan.todayReading ?? 'Juan 3:1-21',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!plan.todayCompleted)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.gold,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'PENDIENTE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else
                    Icon(
                      Icons.check_circle,
                      color: AppColors.success,
                      size: 20,
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Continue button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onContinue,
                icon: const Icon(Icons.play_arrow),
                label: Text(
                  plan.todayCompleted ? 'Ver progreso' : 'Continuar leyendo',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Completed Plan Card
class _CompletedPlanCard extends StatelessWidget {
  final ReadingPlan plan;
  final VoidCallback onRestart;
  final VoidCallback onShare;

  const _CompletedPlanCard({
    required this.plan,
    required this.onRestart,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.gold.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Achievement badge
            Icon(
              Icons.emoji_events,
              size: 50,
              color: AppColors.gold,
            ),
            const SizedBox(height: 12),

            // Title
            Text(
              plan.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Completion date
            Text(
              'Completado el ${_formatDate(plan.completedAt!)}',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),

            // Stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _CompletionStat(
                  value: plan.durationDays.toString(),
                  label: 'Días',
                ),
                _CompletionStat(
                  value: plan.totalChaptersRead.toString(),
                  label: 'Capítulos',
                ),
                _CompletionStat(
                  value: _formatDuration(plan.totalReadingTime),
                  label: 'Tiempo',
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onRestart,
                    icon: const Icon(Icons.restart_alt),
                    label: const Text('Repetir'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onShare,
                    icon: const Icon(Icons.share),
                    label: const Text('Compartir'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }
}

// Supporting Widgets
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _CompletionStat extends StatelessWidget {
  final String value;
  final String label;

  const _CompletionStat({
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: AppColors.gold,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}