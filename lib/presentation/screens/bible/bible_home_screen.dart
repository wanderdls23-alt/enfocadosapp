import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/bible_provider.dart';
import '../../widgets/common/loading_widget.dart';

class BibleHomeScreen extends ConsumerStatefulWidget {
  const BibleHomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<BibleHomeScreen> createState() => _BibleHomeScreenState();
}

class _BibleHomeScreenState extends ConsumerState<BibleHomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _selectedTestament = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final booksAsync = ref.watch(bibleBooksProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Santa Biblia'),
        backgroundColor: const Color(0xFFCC0000),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.push('/bible/search'),
          ),
          IconButton(
            icon: const Icon(Icons.bookmark_border),
            onPressed: () => context.push('/bible/bookmarks'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Header con información
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFCC0000),
                  Color(0xFF990000),
                ],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                // Versión de la Biblia
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.book,
                              color: Colors.white,
                              size: 16,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'RVR 1960',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.history, color: Colors.white),
                        onPressed: () => _showReadingHistory(),
                        tooltip: 'Historial de lectura',
                      ),
                      IconButton(
                        icon: const Icon(Icons.format_list_bulleted, color: Colors.white),
                        onPressed: () => context.push('/bible/reading-plans'),
                        tooltip: 'Planes de lectura',
                      ),
                    ],
                  ),
                ),

                // Tabs
                TabBar(
                  controller: _tabController,
                  indicatorColor: const Color(0xFFFFD700),
                  indicatorWeight: 3,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  tabs: const [
                    Tab(text: 'LIBROS'),
                    Tab(text: 'CAPÍTULOS'),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),

          // Filtro de testamento
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildTestamentFilter('all', 'Todos'),
                const SizedBox(width: 8),
                _buildTestamentFilter('old', 'Antiguo T.'),
                const SizedBox(width: 8),
                _buildTestamentFilter('new', 'Nuevo T.'),
              ],
            ),
          ),

          // Contenido de tabs
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab de Libros
                booksAsync.when(
                  data: (books) => _buildBooksGrid(books),
                  loading: () => const Center(child: LoadingWidget()),
                  error: (error, _) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Error: $error'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => ref.refresh(bibleBooksProvider),
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                ),

                // Tab de Capítulos Recientes
                _buildRecentChapters(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestamentFilter(String value, String label) {
    final isSelected = _selectedTestament == value;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedTestament = value;
          });
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFCC0000) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? const Color(0xFFCC0000) : Colors.grey[300]!,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBooksGrid(List<BibleBook> books) {
    // Filtrar libros según el testamento seleccionado
    final filteredBooks = _selectedTestament == 'all'
        ? books
        : books.where((book) {
            if (_selectedTestament == 'old') {
              return book.testament == Testament.old;
            } else {
              return book.testament == Testament.new;
            }
          }).toList();

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.0,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: filteredBooks.length,
      itemBuilder: (context, index) {
        final book = filteredBooks[index];
        return _buildBookCard(book);
      },
    );
  }

  Widget _buildBookCard(BibleBook book) {
    final color = book.testament == Testament.old
        ? const Color(0xFF8B4513) // Marrón para AT
        : const Color(0xFF4169E1); // Azul para NT

    return InkWell(
      onTap: () => _showChapterSelector(book),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Text(
                book.abbreviation,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                book.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${book.chapters} cap.',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentChapters() {
    final recentChapters = ref.watch(recentChaptersProvider);

    return recentChapters.when(
      data: (chapters) {
        if (chapters.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.history,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No hay capítulos recientes',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Los capítulos que leas aparecerán aquí',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: chapters.length,
          itemBuilder: (context, index) {
            final chapter = chapters[index];
            return _buildRecentChapterCard(chapter);
          },
        );
      },
      loading: () => const Center(child: LoadingWidget()),
      error: (_, __) => const Center(
        child: Text('Error al cargar historial'),
      ),
    );
  }

  Widget _buildRecentChapterCard(RecentChapter chapter) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: const Color(0xFFCC0000).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              chapter.book.abbreviation,
              style: const TextStyle(
                color: Color(0xFFCC0000),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        title: Text(
          '${chapter.book.name} ${chapter.chapter}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              _formatDate(chapter.lastRead),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            if (chapter.progress > 0) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: chapter.progress / 100,
                backgroundColor: Colors.grey[300],
                valueColor: const AlwaysStoppedAnimation(Color(0xFFCC0000)),
              ),
              const SizedBox(height: 4),
              Text(
                '${chapter.progress}% completado',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey[400],
        ),
        onTap: () => context.push('/bible/chapter/${chapter.book.id}/${chapter.chapter}'),
      ),
    );
  }

  void _showChapterSelector(BibleBook book) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    book.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: GridView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                      childAspectRatio: 1.0,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: book.chapters,
                    itemBuilder: (context, index) {
                      final chapterNumber = index + 1;
                      return InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          context.push('/bible/chapter/${book.id}/$chapterNumber');
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFCC0000).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFFCC0000).withOpacity(0.3),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '$chapterNumber',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFCC0000),
                              ),
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
      ),
    );
  }

  void _showReadingHistory() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Historial de Lectura',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: Consumer(
                    builder: (context, ref, child) {
                      final recentChapters = ref.watch(recentChaptersProvider);
                      return recentChapters.when(
                        data: (chapters) {
                          if (chapters.isEmpty) {
                            return const Center(
                              child: Text('No hay historial de lectura'),
                            );
                          }
                          return ListView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: chapters.length,
                            itemBuilder: (context, index) {
                              final chapter = chapters[index];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: const Color(0xFFCC0000).withOpacity(0.1),
                                  child: Text(
                                    chapter.book.abbreviation,
                                    style: const TextStyle(
                                      color: Color(0xFFCC0000),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text('${chapter.book.name} ${chapter.chapter}'),
                                subtitle: Text(_formatDate(chapter.lastRead)),
                                trailing: Text('${chapter.progress}%'),
                                onTap: () {
                                  Navigator.pop(context);
                                  context.push('/bible/chapter/${chapter.book.id}/${chapter.chapter}');
                                },
                              );
                            },
                          );
                        },
                        loading: () => const Center(child: LoadingWidget()),
                        error: (_, __) => const Center(
                          child: Text('Error al cargar historial'),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Hace un momento';
        }
        return 'Hace ${difference.inMinutes} min';
      }
      return 'Hace ${difference.inHours} h';
    } else if (difference.inDays == 1) {
      return 'Ayer';
    } else if (difference.inDays < 7) {
      return 'Hace ${difference.inDays} días';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

// Modelos temporales (deberían estar en archivos separados)
enum Testament { old, new }

class BibleBook {
  final int id;
  final String name;
  final String abbreviation;
  final Testament testament;
  final int chapters;

  BibleBook({
    required this.id,
    required this.name,
    required this.abbreviation,
    required this.testament,
    required this.chapters,
  });
}

class RecentChapter {
  final BibleBook book;
  final int chapter;
  final DateTime lastRead;
  final int progress;

  RecentChapter({
    required this.book,
    required this.chapter,
    required this.lastRead,
    required this.progress,
  });
}