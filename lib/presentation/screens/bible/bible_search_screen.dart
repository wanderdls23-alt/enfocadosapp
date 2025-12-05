import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/themes/app_colors.dart';
import '../../../core/constants/route_names.dart';
import '../../../domain/entities/bible_book.dart';
import '../../../domain/entities/bible_verse.dart';
import '../../providers/bible_provider.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/error_view.dart';

class BibleSearchScreen extends ConsumerStatefulWidget {
  const BibleSearchScreen({super.key});

  @override
  ConsumerState<BibleSearchScreen> createState() => _BibleSearchScreenState();
}

class _BibleSearchScreenState extends ConsumerState<BibleSearchScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  late TabController _tabController;

  String _searchQuery = '';
  bool _isSearching = false;
  bool _searchInStrongs = false;
  bool _searchExactPhrase = false;
  bool _caseSensitive = false;

  String _selectedTestament = 'all'; // all, old, new
  List<String> _selectedBooks = [];

  final List<String> _recentSearches = [];
  final List<String> _popularSearches = [
    'amor',
    'fe',
    'esperanza',
    'salvación',
    'oración',
    'perdón',
    'paz',
    'vida eterna',
    'Jesús',
    'gracia',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchFocusNode.requestFocus();
    _loadRecentSearches();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _loadRecentSearches() async {
    final searches = await ref.read(bibleRepositoryProvider).getRecentSearches();
    setState(() {
      _recentSearches.clear();
      _recentSearches.addAll(searches.take(10));
    });
  }

  void _performSearch() {
    if (_searchController.text.trim().isEmpty) return;

    setState(() {
      _searchQuery = _searchController.text.trim();
      _isSearching = true;
    });

    // Guardar búsqueda reciente
    _saveRecentSearch(_searchQuery);

    // Actualizar provider de búsqueda
    ref.read(bibleSearchProvider.notifier).search(
      query: _searchQuery,
      searchInStrongs: _searchInStrongs,
      exactPhrase: _searchExactPhrase,
      caseSensitive: _caseSensitive,
      testament: _selectedTestament,
      books: _selectedBooks,
    );
  }

  void _saveRecentSearch(String query) {
    if (!_recentSearches.contains(query)) {
      _recentSearches.insert(0, query);
      if (_recentSearches.length > 10) {
        _recentSearches.removeLast();
      }
      ref.read(bibleRepositoryProvider).saveRecentSearch(query);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header con búsqueda
            _buildSearchHeader(),

            // Opciones de búsqueda
            if (_isSearching) _buildSearchOptions(),

            // Contenido
            Expanded(
              child: _isSearching
                  ? _buildSearchResults()
                  : _buildSearchSuggestions(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
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
          // Search bar
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Back button
                IconButton(
                  onPressed: () => context.pop(),
                  icon: Icon(
                    Icons.arrow_back,
                    color: AppColors.textPrimary,
                  ),
                ),

                // Search field
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    decoration: InputDecoration(
                      hintText: 'Buscar en la Biblia...',
                      hintStyle: TextStyle(
                        color: AppColors.textSecondary,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(
                          color: AppColors.border,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(
                          color: AppColors.primary,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _isSearching = false;
                                      _searchQuery = '';
                                    });
                                  },
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.search,
                                    color: AppColors.primary,
                                  ),
                                  onPressed: _performSearch,
                                ),
                              ],
                            )
                          : IconButton(
                              icon: Icon(
                                Icons.search,
                                color: AppColors.textSecondary,
                              ),
                              onPressed: _performSearch,
                            ),
                    ),
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _performSearch(),
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),
                ),

                // Filter button
                IconButton(
                  onPressed: _showFilterDialog,
                  icon: Stack(
                    children: [
                      Icon(
                        Icons.tune,
                        color: AppColors.textPrimary,
                      ),
                      if (_selectedBooks.isNotEmpty ||
                          _selectedTestament != 'all' ||
                          _searchInStrongs ||
                          _searchExactPhrase ||
                          _caseSensitive)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Quick filters
          if (!_isSearching)
            Container(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildQuickFilter(
                    'Concordancia Strong',
                    _searchInStrongs,
                    (value) {
                      setState(() => _searchInStrongs = value);
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildQuickFilter(
                    'Frase exacta',
                    _searchExactPhrase,
                    (value) {
                      setState(() => _searchExactPhrase = value);
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildQuickFilter(
                    'Mayúsculas',
                    _caseSensitive,
                    (value) {
                      setState(() => _caseSensitive = value);
                    },
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildQuickFilter(String label, bool value, Function(bool) onChanged) {
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: value ? Colors.white : AppColors.textPrimary,
        ),
      ),
      selected: value,
      onSelected: onChanged,
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.surface,
      checkmarkColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }

  Widget _buildSearchOptions() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Tabs
          TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            tabs: const [
              Tab(text: 'VERSÍCULOS'),
              Tab(text: 'CAPÍTULOS'),
              Tab(text: 'CONCORDANCIA'),
            ],
          ),

          // Active filters summary
          if (_selectedBooks.isNotEmpty || _selectedTestament != 'all')
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  bottom: BorderSide(color: AppColors.border),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.filter_list,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getFilterSummary(),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedTestament = 'all';
                        _selectedBooks.clear();
                      });
                    },
                    child: const Text(
                      'Limpiar',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    final searchResults = ref.watch(bibleSearchResultsProvider);

    return TabBarView(
      controller: _tabController,
      children: [
        // Versículos
        searchResults.when(
          data: (results) {
            if (results.verses.isEmpty) {
              return _buildNoResults();
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: results.verses.length,
              itemBuilder: (context, index) {
                final verse = results.verses[index];
                return _buildVerseCard(verse);
              },
            );
          },
          loading: () => const Center(child: LoadingIndicator()),
          error: (error, stack) => ErrorView(
            message: 'Error al buscar',
            onRetry: _performSearch,
          ),
        ),

        // Capítulos
        searchResults.when(
          data: (results) {
            if (results.chapters.isEmpty) {
              return _buildNoResults();
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: results.chapters.length,
              itemBuilder: (context, index) {
                final chapter = results.chapters[index];
                return _buildChapterCard(chapter);
              },
            );
          },
          loading: () => const Center(child: LoadingIndicator()),
          error: (error, stack) => ErrorView(
            message: 'Error al buscar capítulos',
            onRetry: _performSearch,
          ),
        ),

        // Concordancia Strong
        searchResults.when(
          data: (results) {
            if (results.strongsResults.isEmpty) {
              return _buildNoResults();
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: results.strongsResults.length,
              itemBuilder: (context, index) {
                final strong = results.strongsResults[index];
                return _buildStrongCard(strong);
              },
            );
          },
          loading: () => const Center(child: LoadingIndicator()),
          error: (error, stack) => ErrorView(
            message: 'Error al buscar en concordancia',
            onRetry: _performSearch,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchSuggestions() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Búsquedas recientes
          if (_recentSearches.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Búsquedas recientes',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() => _recentSearches.clear());
                    ref.read(bibleRepositoryProvider).clearRecentSearches();
                  },
                  child: const Text('Limpiar'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _recentSearches.map((search) {
                return GestureDetector(
                  onTap: () {
                    _searchController.text = search;
                    _performSearch();
                  },
                  child: Chip(
                    avatar: Icon(
                      Icons.history,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    label: Text(
                      search,
                      style: const TextStyle(fontSize: 13),
                    ),
                    backgroundColor: AppColors.surface,
                    deleteIcon: Icon(
                      Icons.close,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    onDeleted: () {
                      setState(() => _recentSearches.remove(search));
                      ref.read(bibleRepositoryProvider).removeRecentSearch(search);
                    },
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],

          // Búsquedas populares
          Text(
            'Búsquedas populares',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _popularSearches.map((search) {
              return GestureDetector(
                onTap: () {
                  _searchController.text = search;
                  _performSearch();
                },
                child: Chip(
                  avatar: Icon(
                    Icons.trending_up,
                    size: 16,
                    color: AppColors.gold,
                  ),
                  label: Text(
                    search,
                    style: const TextStyle(fontSize: 13),
                  ),
                  backgroundColor: AppColors.gold.withOpacity(0.1),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 32),

          // Consejos de búsqueda
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Consejos de búsqueda',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildTip('Usa comillas para buscar frases exactas: "vida eterna"'),
                _buildTip('Usa AND/OR para combinar términos: amor AND fe'),
                _buildTip('Usa * como comodín: esper* (encuentra esperanza, esperar, etc.)'),
                _buildTip('Activa Strong\'s para buscar palabras en hebreo/griego'),
                _buildTip('Filtra por libros o testamentos para resultados más precisos'),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Búsquedas por tema
          Text(
            'Buscar por tema',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _buildThemeGrid(),
        ],
      ),
    );
  }

  Widget _buildTip(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeGrid() {
    final themes = [
      {'icon': Icons.favorite, 'label': 'Amor', 'color': Colors.red},
      {'icon': Icons.church, 'label': 'Fe', 'color': Colors.blue},
      {'icon': Icons.spa, 'label': 'Paz', 'color': Colors.green},
      {'icon': Icons.people, 'label': 'Familia', 'color': Colors.orange},
      {'icon': Icons.healing, 'label': 'Sanidad', 'color': Colors.purple},
      {'icon': Icons.attach_money, 'label': 'Prosperidad', 'color': Colors.amber},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: themes.length,
      itemBuilder: (context, index) {
        final theme = themes[index];
        return GestureDetector(
          onTap: () {
            _searchController.text = theme['label'] as String;
            _performSearch();
          },
          child: Container(
            decoration: BoxDecoration(
              color: (theme['color'] as Color).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: (theme['color'] as Color).withOpacity(0.3),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  theme['icon'] as IconData,
                  color: theme['color'] as Color,
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  theme['label'] as String,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No se encontraron resultados',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Intenta con otros términos o filtros',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _selectedTestament = 'all';
                _selectedBooks.clear();
                _searchInStrongs = false;
                _searchExactPhrase = false;
                _caseSensitive = false;
              });
              _performSearch();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Buscar sin filtros'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerseCard(BibleVerse verse) {
    return GestureDetector(
      onTap: () {
        context.push(
          '${Routes.bibleReader}/${verse.book.id}/${verse.chapter}',
          extra: {'highlightVerse': verse.verseNumber},
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Reference
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${verse.book.name} ${verse.chapter}:${verse.verseNumber}',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => _shareVerse(verse),
                  icon: Icon(
                    Icons.share,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Highlighted text
            RichText(
              text: _highlightText(
                verse.text,
                _searchQuery,
                _searchExactPhrase,
              ),
            ),

            // Strong's if available
            if (verse.strongsNumbers != null &&
                verse.strongsNumbers!.isNotEmpty &&
                _searchInStrongs) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: verse.strongsNumbers!.take(5).map((strong) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.gold.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      strong,
                      style: TextStyle(
                        color: AppColors.gold.shade700,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChapterCard(dynamic chapter) {
    return GestureDetector(
      onTap: () {
        context.push(
          '${Routes.bibleReader}/${chapter.bookId}/${chapter.number}',
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
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
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  '${chapter.number}',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chapter.bookName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${chapter.matchCount} coincidencias',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: AppColors.textSecondary,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStrongCard(dynamic strong) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.gold.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  strong.number,
                  style: TextStyle(
                    color: AppColors.gold.shade700,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                strong.language == 'hebrew' ? 'Hebreo' : 'Griego',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            strong.original,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            strong.transliteration,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            strong.definition,
            style: const TextStyle(
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${strong.occurrences} apariciones',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  TextSpan _highlightText(String text, String query, bool exactPhrase) {
    if (query.isEmpty) {
      return TextSpan(
        text: text,
        style: const TextStyle(
          fontSize: 14,
          height: 1.6,
        ),
      );
    }

    final List<TextSpan> spans = [];
    final String lowerText = _caseSensitive ? text : text.toLowerCase();
    final String lowerQuery = _caseSensitive ? query : query.toLowerCase();

    if (exactPhrase) {
      int start = 0;
      int index = lowerText.indexOf(lowerQuery, start);

      while (index != -1) {
        if (index > start) {
          spans.add(TextSpan(
            text: text.substring(start, index),
            style: const TextStyle(
              fontSize: 14,
              height: 1.6,
            ),
          ));
        }

        spans.add(TextSpan(
          text: text.substring(index, index + query.length),
          style: TextStyle(
            fontSize: 14,
            height: 1.6,
            backgroundColor: AppColors.gold.withOpacity(0.3),
            fontWeight: FontWeight.bold,
          ),
        ));

        start = index + query.length;
        index = lowerText.indexOf(lowerQuery, start);
      }

      if (start < text.length) {
        spans.add(TextSpan(
          text: text.substring(start),
          style: const TextStyle(
            fontSize: 14,
            height: 1.6,
          ),
        ));
      }
    } else {
      // Highlight individual words
      final words = query.split(' ');
      String remaining = text;

      for (final word in words) {
        if (word.isEmpty) continue;

        final pattern = RegExp(
          word,
          caseSensitive: _caseSensitive,
        );

        final matches = pattern.allMatches(remaining);

        if (matches.isNotEmpty) {
          int lastEnd = 0;
          for (final match in matches) {
            if (match.start > lastEnd) {
              spans.add(TextSpan(
                text: remaining.substring(lastEnd, match.start),
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.6,
                ),
              ));
            }

            spans.add(TextSpan(
              text: remaining.substring(match.start, match.end),
              style: TextStyle(
                fontSize: 14,
                height: 1.6,
                backgroundColor: AppColors.gold.withOpacity(0.3),
                fontWeight: FontWeight.bold,
              ),
            ));

            lastEnd = match.end;
          }

          if (lastEnd < remaining.length) {
            remaining = remaining.substring(lastEnd);
          }
        }
      }

      if (remaining.isNotEmpty && spans.isEmpty) {
        spans.add(TextSpan(
          text: remaining,
          style: const TextStyle(
            fontSize: 14,
            height: 1.6,
          ),
        ));
      }
    }

    return TextSpan(children: spans);
  }

  void _showFilterDialog() {
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
              initialChildSize: 0.7,
              minChildSize: 0.5,
              maxChildSize: 0.9,
              expand: false,
              builder: (context, scrollController) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Filtros de búsqueda',
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
                              // Testament filter
                              const Text(
                                'Testamento',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _TestamentChip(
                                      label: 'Todos',
                                      isSelected: _selectedTestament == 'all',
                                      onTap: () {
                                        setModalState(() {
                                          _selectedTestament = 'all';
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _TestamentChip(
                                      label: 'A. T.',
                                      isSelected: _selectedTestament == 'old',
                                      onTap: () {
                                        setModalState(() {
                                          _selectedTestament = 'old';
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _TestamentChip(
                                      label: 'N. T.',
                                      isSelected: _selectedTestament == 'new',
                                      onTap: () {
                                        setModalState(() {
                                          _selectedTestament = 'new';
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 24),

                              // Books filter
                              const Text(
                                'Libros específicos',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildBookSelector(setModalState),

                              const SizedBox(height: 24),

                              // Search options
                              const Text(
                                'Opciones de búsqueda',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              SwitchListTile(
                                value: _searchInStrongs,
                                onChanged: (value) {
                                  setModalState(() {
                                    _searchInStrongs = value;
                                  });
                                },
                                title: const Text('Concordancia Strong'),
                                subtitle: const Text(
                                  'Buscar en palabras hebreas y griegas',
                                  style: TextStyle(fontSize: 12),
                                ),
                                activeColor: AppColors.primary,
                                contentPadding: EdgeInsets.zero,
                              ),
                              SwitchListTile(
                                value: _searchExactPhrase,
                                onChanged: (value) {
                                  setModalState(() {
                                    _searchExactPhrase = value;
                                  });
                                },
                                title: const Text('Frase exacta'),
                                subtitle: const Text(
                                  'Buscar palabras en el orden exacto',
                                  style: TextStyle(fontSize: 12),
                                ),
                                activeColor: AppColors.primary,
                                contentPadding: EdgeInsets.zero,
                              ),
                              SwitchListTile(
                                value: _caseSensitive,
                                onChanged: (value) {
                                  setModalState(() {
                                    _caseSensitive = value;
                                  });
                                },
                                title: const Text('Distinguir mayúsculas'),
                                subtitle: const Text(
                                  'Diferenciar entre mayúsculas y minúsculas',
                                  style: TextStyle(fontSize: 12),
                                ),
                                activeColor: AppColors.primary,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Apply button
                      Container(
                        padding: const EdgeInsets.only(top: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  setModalState(() {
                                    _selectedTestament = 'all';
                                    _selectedBooks.clear();
                                    _searchInStrongs = false;
                                    _searchExactPhrase = false;
                                    _caseSensitive = false;
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
                                  if (_searchQuery.isNotEmpty) {
                                    _performSearch();
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                ),
                                child: const Text('Aplicar filtros'),
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

  Widget _buildBookSelector(Function setModalState) {
    // This would typically load from the Bible provider
    final books = [
      'Génesis', 'Éxodo', 'Levítico', 'Números', 'Deuteronomio',
      'Mateo', 'Marcos', 'Lucas', 'Juan', 'Hechos',
      'Romanos', '1 Corintios', '2 Corintios', 'Gálatas',
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: books.map((book) {
        final isSelected = _selectedBooks.contains(book);
        return FilterChip(
          label: Text(
            book,
            style: TextStyle(
              fontSize: 12,
              color: isSelected ? Colors.white : AppColors.textPrimary,
            ),
          ),
          selected: isSelected,
          onSelected: (selected) {
            setModalState(() {
              if (selected) {
                _selectedBooks.add(book);
              } else {
                _selectedBooks.remove(book);
              }
            });
          },
          selectedColor: AppColors.primary,
          backgroundColor: AppColors.surface,
          checkmarkColor: Colors.white,
        );
      }).toList(),
    );
  }

  String _getFilterSummary() {
    final List<String> filters = [];

    if (_selectedTestament == 'old') {
      filters.add('Antiguo Testamento');
    } else if (_selectedTestament == 'new') {
      filters.add('Nuevo Testamento');
    }

    if (_selectedBooks.isNotEmpty) {
      if (_selectedBooks.length == 1) {
        filters.add(_selectedBooks.first);
      } else {
        filters.add('${_selectedBooks.length} libros');
      }
    }

    return filters.isEmpty ? 'Sin filtros' : filters.join(' • ');
  }

  void _shareVerse(BibleVerse verse) {
    // Implement share functionality
  }
}

class _TestamentChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TestamentChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.textPrimary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}