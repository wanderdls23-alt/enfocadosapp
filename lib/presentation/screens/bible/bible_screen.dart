import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/themes/app_colors.dart';
import '../../../core/constants/route_names.dart';
import '../../../data/models/bible_models.dart';
import '../../providers/bible_provider.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/error_widget.dart';

class BibleScreen extends ConsumerStatefulWidget {
  const BibleScreen({super.key});

  @override
  ConsumerState<BibleScreen> createState() => _BibleScreenState();
}

class _BibleScreenState extends ConsumerState<BibleScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Cargar datos iniciales
    Future.microtask(() {
      ref.read(bibleVersionsProvider.notifier).loadVersions();
      ref.read(bibleBooksProvider.notifier).loadBooks();
      ref.read(readingPlansProvider.notifier).loadPlans();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final versions = ref.watch(bibleVersionsProvider);
    final selectedVersion = ref.watch(selectedVersionProvider);
    final books = ref.watch(bibleBooksProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            // App Bar
            SliverAppBar(
              expandedHeight: 200,
              floating: true,
              pinned: true,
              backgroundColor: AppColors.primary,
              flexibleSpace: FlexibleSpaceBar(
                title: const Text(
                  'Santa Biblia',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary,
                        AppColors.primary.withOpacity(0.7),
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Patrón de fondo
                      Positioned(
                        right: -50,
                        bottom: -50,
                        child: Icon(
                          Icons.menu_book,
                          size: 200,
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      // Selector de versión
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              versions.when(
                                data: (versionList) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: DropdownButton<BibleVersion>(
                                      value: selectedVersion,
                                      isDense: true,
                                      underline: const SizedBox(),
                                      dropdownColor: AppColors.primary,
                                      icon: const Icon(
                                        Icons.arrow_drop_down,
                                        color: Colors.white,
                                      ),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
                                      items: versionList.map((version) {
                                        return DropdownMenuItem(
                                          value: version,
                                          child: Text(
                                            '${version.name} (${version.code})',
                                            style: const TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (version) {
                                        if (version != null) {
                                          ref
                                              .read(selectedVersionProvider
                                                  .notifier)
                                              .state = version;
                                        }
                                      },
                                    ),
                                  );
                                },
                                loading: () => const SizedBox(
                                  height: 40,
                                  child: ShimmerBox(width: 150, height: 32),
                                ),
                                error: (_, __) => const SizedBox(),
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
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: Container(
                  color: AppColors.primary,
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: AppColors.gold,
                    indicatorWeight: 3,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white.withOpacity(0.7),
                    tabs: const [
                      Tab(text: 'LIBROS'),
                      Tab(text: 'PLANES DE LECTURA'),
                    ],
                  ),
                ),
              ),
            ),

            // Barra de búsqueda
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar versículo, palabra o referencia...',
                    prefixIcon: Icon(
                      Icons.search,
                      color: AppColors.textSecondary,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (query) {
                    if (query.isNotEmpty) {
                      context.push(
                        '${Routes.bibleSearch}?q=${Uri.encodeComponent(query)}',
                      );
                    }
                  },
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            // Tab de Libros
            books.when(
              data: (bookList) => _buildBooksTab(bookList),
              loading: () => const LoadingIndicator(),
              error: (error, _) => CustomErrorWidget(
                message: 'Error al cargar los libros',
                onRetry: () {
                  ref.read(bibleBooksProvider.notifier).loadBooks();
                },
              ),
            ),

            // Tab de Planes de Lectura
            _buildReadingPlansTab(),
          ],
        ),
      ),

      // FAB para acciones rápidas
      floatingActionButton: FloatingActionButton(
        onPressed: _showQuickActions,
        backgroundColor: AppColors.gold,
        child: const Icon(Icons.bookmark_outline),
      ),
    );
  }

  Widget _buildBooksTab(List<BibleBook> books) {
    final oldTestamentBooks = books
        .where((book) => book.testament == Testament.old)
        .toList();
    final newTestamentBooks = books
        .where((book) => book.testament == Testament.newT)
        .toList();

    return CustomScrollView(
      slivers: [
        // Antiguo Testamento
        SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppColors.primary.withOpacity(0.1),
            child: Text(
              'ANTIGUO TESTAMENTO',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 2.5,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final book = oldTestamentBooks[index];
                return _buildBookTile(book);
              },
              childCount: oldTestamentBooks.length,
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 16)),

        // Nuevo Testamento
        SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppColors.gold.withOpacity(0.1),
            child: Text(
              'NUEVO TESTAMENTO',
              style: TextStyle(
                color: AppColors.gold.shade700,
                fontWeight: FontWeight.bold,
                fontSize: 14,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 2.5,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final book = newTestamentBooks[index];
                return _buildBookTile(book);
              },
              childCount: newTestamentBooks.length,
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _buildBookTile(BibleBook book) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: () => _showChapterSelector(book),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                book.abbreviation,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '${book.chapters} cap.',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReadingPlansTab() {
    final plans = ref.watch(readingPlansProvider);

    return plans.when(
      data: (planList) {
        if (planList.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.calendar_today_outlined,
            title: 'Sin planes de lectura',
            message: 'No tienes planes de lectura activos.\n¡Comienza uno hoy!',
            buttonText: 'Explorar Planes',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: planList.length,
          itemBuilder: (context, index) {
            final plan = planList[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: Icon(
                    Icons.calendar_month,
                    color: AppColors.primary,
                  ),
                ),
                title: Text(
                  plan['title'],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(plan['description']),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: plan['progress'],
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation(AppColors.success),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${(plan['progress'] * 100).toInt()}% completado',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // Navegar a detalles del plan
                },
              ),
            );
          },
        );
      },
      loading: () => const LoadingIndicator(),
      error: (error, _) => CustomErrorWidget(
        message: 'Error al cargar los planes',
        onRetry: () {
          ref.read(readingPlansProvider.notifier).loadPlans();
        },
      ),
    );
  }

  void _showChapterSelector(BibleBook book) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                book.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    childAspectRatio: 1,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: book.chapters,
                  itemBuilder: (context, index) {
                    final chapter = index + 1;
                    return InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        final versionId = ref.read(selectedVersionProvider)?.id ?? 1;
                        context.push(
                          '${Routes.bible}/chapter/${book.id}/$chapter?version=$versionId',
                        );
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.3),
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          chapter.toString(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showQuickActions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.bookmark, color: AppColors.gold),
                title: const Text('Versículos Favoritos'),
                onTap: () {
                  Navigator.pop(context);
                  context.push(Routes.bibleFavorites);
                },
              ),
              ListTile(
                leading: Icon(Icons.highlight, color: AppColors.primary),
                title: const Text('Versículos Subrayados'),
                onTap: () {
                  Navigator.pop(context);
                  context.push(Routes.bibleHighlights);
                },
              ),
              ListTile(
                leading: Icon(Icons.note, color: AppColors.info),
                title: const Text('Mis Notas'),
                onTap: () {
                  Navigator.pop(context);
                  context.push(Routes.bibleNotes);
                },
              ),
              ListTile(
                leading: Icon(Icons.history, color: AppColors.textSecondary),
                title: const Text('Historial de Lectura'),
                onTap: () {
                  Navigator.pop(context);
                  // Navegar al historial
                },
              ),
            ],
          ),
        );
      },
    );
  }
}