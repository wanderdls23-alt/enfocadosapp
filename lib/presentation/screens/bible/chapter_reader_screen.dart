import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/bible_models.dart';
import '../../providers/bible_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/common/loading_widget.dart';

/// Pantalla de lectura de capítulo de la Biblia
class ChapterReaderScreen extends ConsumerStatefulWidget {
  final int bookId;
  final int chapter;
  final int? initialVerse;

  const ChapterReaderScreen({
    Key? key,
    required this.bookId,
    required this.chapter,
    this.initialVerse,
  }) : super(key: key);

  @override
  ConsumerState<ChapterReaderScreen> createState() => _ChapterReaderScreenState();
}

class _ChapterReaderScreenState extends ConsumerState<ChapterReaderScreen> {
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _verseKeys = {};
  final Set<int> _selectedVerses = {};
  final Set<int> _highlightedVerses = {};

  bool _isSelectionMode = false;
  bool _showVerseNumbers = true;
  bool _showFootnotes = true;
  double _fontSize = 16.0;
  String _currentVersion = 'RVR 1960';
  Color? _highlightColor;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialVerse != null) {
        _scrollToVerse(widget.initialVerse!);
      }
    });
  }

  void _loadSettings() {
    final settings = ref.read(settingsProvider);
    setState(() {
      _fontSize = settings.bibleFontSize;
      _showVerseNumbers = settings.showVerseNumbers;
      _showFootnotes = settings.showFootnotes;
      _currentVersion = settings.defaultBibleVersion;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chapterAsync = ref.watch(bibleChapterProvider((widget.bookId, widget.chapter)));
    final bookInfo = ref.watch(bibleBookProvider(widget.bookId));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(bookInfo.value),
      body: chapterAsync.when(
        data: (verses) => _buildChapterContent(verses),
        loading: () => const LoadingWidget(),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(bibleChapterProvider((widget.bookId, widget.chapter))),
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _isSelectionMode ? _buildSelectionBar() : _buildNavigationBar(),
      floatingActionButton: !_isSelectionMode ? _buildFloatingButtons() : null,
    );
  }

  AppBar _buildAppBar(BibleBook? book) {
    return AppBar(
      title: Column(
        children: [
          Text(
            book?.name ?? 'Cargando...',
            style: const TextStyle(fontSize: 16),
          ),
          Text(
            'Capítulo ${widget.chapter}',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
          ),
        ],
      ),
      centerTitle: true,
      backgroundColor: AppColors.primary,
      actions: [
        if (_isSelectionMode) ...[
          IconButton(
            icon: const Icon(Icons.select_all),
            onPressed: _selectAll,
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              setState(() {
                _isSelectionMode = false;
                _selectedVerses.clear();
              });
            },
          ),
        ] else ...[
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(),
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'versions',
                child: Row(
                  children: [
                    Icon(Icons.book, size: 20),
                    SizedBox(width: 12),
                    Text('Versiones'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings, size: 20),
                    SizedBox(width: 12),
                    Text('Ajustes de lectura'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'parallel',
                child: Row(
                  children: [
                    Icon(Icons.compare_arrows, size: 20),
                    SizedBox(width: 12),
                    Text('Versículos paralelos'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'audio',
                child: Row(
                  children: [
                    Icon(Icons.headphones, size: 20),
                    SizedBox(width: 12),
                    Text('Escuchar audio'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildChapterContent(List<BibleVerse> verses) {
    // Generar keys para cada versículo
    for (final verse in verses) {
      _verseKeys[verse.verse] ??= GlobalKey();
    }

    return Column(
      children: [
        // Barra de información
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: AppColors.primary.withOpacity(0.1),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _currentVersion,
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${verses.length} versículos',
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),

        // Contenido del capítulo
        Expanded(
          child: Scrollbar(
            controller: _scrollController,
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: verses.length,
              itemBuilder: (context, index) {
                final verse = verses[index];
                return _buildVerseWidget(verse);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVerseWidget(BibleVerse verse) {
    final isSelected = _selectedVerses.contains(verse.verse);
    final isHighlighted = _highlightedVerses.contains(verse.verse);

    return GestureDetector(
      key: _verseKeys[verse.verse],
      onTap: () {
        if (_isSelectionMode) {
          setState(() {
            if (isSelected) {
              _selectedVerses.remove(verse.verse);
            } else {
              _selectedVerses.add(verse.verse);
            }
          });
        } else {
          _showVerseOptions(verse);
        }
      },
      onLongPress: () {
        if (!_isSelectionMode) {
          setState(() {
            _isSelectionMode = true;
            _selectedVerses.add(verse.verse);
          });
          HapticFeedback.mediumImpact();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.1)
              : isHighlighted
                  ? (_highlightColor ?? Colors.yellow).withOpacity(0.2)
                  : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: _fontSize,
              height: 1.6,
              color: Colors.black,
            ),
            children: [
              if (_showVerseNumbers)
                TextSpan(
                  text: '${verse.verse} ',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    fontSize: _fontSize * 0.9,
                  ),
                ),
              TextSpan(
                text: verse.text,
                style: TextStyle(
                  fontSize: _fontSize,
                  backgroundColor: isSelected
                      ? AppColors.primary.withOpacity(0.1)
                      : isHighlighted
                          ? (_highlightColor ?? Colors.yellow).withOpacity(0.2)
                          : null,
                ),
              ),
              if (_showFootnotes && verse.footnotes != null)
                ...verse.footnotes!.map((footnote) => TextSpan(
                      text: ' [$footnote]',
                      style: TextStyle(
                        fontSize: _fontSize * 0.8,
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    )),
              if (verse.strongNumbers != null)
                TextSpan(
                  text: ' 📖',
                  style: TextStyle(
                    fontSize: _fontSize * 0.8,
                    color: AppColors.gold,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionBar() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 8),
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
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _SelectionAction(
            icon: Icons.format_color_text,
            label: 'Resaltar',
            onPressed: () => _showHighlightOptions(),
          ),
          _SelectionAction(
            icon: Icons.copy,
            label: 'Copiar',
            onPressed: () => _copySelectedVerses(),
          ),
          _SelectionAction(
            icon: Icons.share,
            label: 'Compartir',
            onPressed: () => _shareSelectedVerses(),
          ),
          _SelectionAction(
            icon: Icons.bookmark_border,
            label: 'Guardar',
            onPressed: () => _saveSelectedVerses(),
          ),
          _SelectionAction(
            icon: Icons.note_add,
            label: 'Nota',
            onPressed: () => _addNote(),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationBar() {
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
          // Capítulo anterior
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: widget.chapter > 1
                ? () => _navigateToChapter(widget.chapter - 1)
                : null,
            iconSize: 30,
          ),

          // Selector de capítulo
          InkWell(
            onTap: () => _showChapterSelector(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primary),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.menu_book, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Capítulo ${widget.chapter}',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Capítulo siguiente
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => _navigateToChapter(widget.chapter + 1),
            iconSize: 30,
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingButtons() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        FloatingActionButton(
          mini: true,
          heroTag: 'parallels',
          backgroundColor: AppColors.gold,
          onPressed: () => _showParallelVerses(),
          child: const Icon(Icons.compare_arrows),
        ),
        const SizedBox(height: 8),
        FloatingActionButton(
          mini: true,
          heroTag: 'strong',
          backgroundColor: AppColors.primary,
          onPressed: () => _showStrongsDialog(),
          child: const Icon(Icons.translate),
        ),
      ],
    );
  }

  void _showVerseOptions(BibleVerse verse) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${verse.book?.name ?? ''} ${verse.chapter}:${verse.verse}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              verse.text,
              style: const TextStyle(fontSize: 16),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copiar versículo'),
              onTap: () {
                _copyVerse(verse);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Compartir'),
              onTap: () {
                _shareVerse(verse);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.bookmark_border),
              title: const Text('Guardar en favoritos'),
              onTap: () {
                _saveVerse(verse);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.compare_arrows),
              title: const Text('Ver paralelos'),
              onTap: () {
                Navigator.pop(context);
                context.push('/bible/parallel/${verse.id}');
              },
            ),
            if (verse.strongNumbers != null)
              ListTile(
                leading: const Icon(Icons.translate),
                title: const Text('Concordancia Strong'),
                onTap: () {
                  Navigator.pop(context);
                  _showStrongsConcordance(verse);
                },
              ),
            ListTile(
              leading: const Icon(Icons.note_add),
              title: const Text('Agregar nota'),
              onTap: () {
                Navigator.pop(context);
                _addNoteToVerse(verse);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Buscar en el capítulo'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Ingresa palabra a buscar...',
            prefixIcon: Icon(Icons.search),
          ),
          onSubmitted: (query) {
            Navigator.pop(context);
            _searchInChapter(query);
          },
        ),
      ),
    );
  }

  void _searchInChapter(String query) {
    // Implementar búsqueda en el capítulo
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Buscando "$query" en el capítulo...')),
    );
  }

  void _showChapterSelector() {
    final bookAsync = ref.read(bibleBookProvider(widget.bookId));

    bookAsync.whenData((book) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Seleccionar capítulo - ${book.name}'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
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
                final isCurrentChapter = chapter == widget.chapter;

                return InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    if (!isCurrentChapter) {
                      _navigateToChapter(chapter);
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isCurrentChapter
                          ? AppColors.primary
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$chapter',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isCurrentChapter ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );
    });
  }

  void _showReadingSettings() {
    showModalBottomSheet(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ajustes de lectura',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // Tamaño de fuente
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tamaño de fuente'),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: () {
                          setState(() {
                            if (_fontSize > 12) _fontSize -= 2;
                          });
                          this.setState(() {});
                        },
                      ),
                      Text('${_fontSize.toInt()}'),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          setState(() {
                            if (_fontSize < 32) _fontSize += 2;
                          });
                          this.setState(() {});
                        },
                      ),
                    ],
                  ),
                ],
              ),

              // Mostrar números de versículo
              SwitchListTile(
                title: const Text('Mostrar números de versículo'),
                value: _showVerseNumbers,
                onChanged: (value) {
                  setState(() {
                    _showVerseNumbers = value;
                  });
                  this.setState(() {});
                },
              ),

              // Mostrar notas al pie
              SwitchListTile(
                title: const Text('Mostrar notas al pie'),
                value: _showFootnotes,
                onChanged: (value) {
                  setState(() {
                    _showFootnotes = value;
                  });
                  this.setState(() {});
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'versions':
        _showVersionSelector();
        break;
      case 'settings':
        _showReadingSettings();
        break;
      case 'parallel':
        _showParallelVerses();
        break;
      case 'audio':
        _playAudio();
        break;
    }
  }

  void _showVersionSelector() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seleccionar versión'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            'RVR 1960',
            'NVI',
            'LBLA',
            'NTV',
            'DHH',
          ].map((version) => RadioListTile<String>(
                title: Text(version),
                value: version,
                groupValue: _currentVersion,
                onChanged: (value) {
                  setState(() {
                    _currentVersion = value!;
                  });
                  Navigator.pop(context);
                  // Recargar capítulo con nueva versión
                  ref.invalidate(bibleChapterProvider((widget.bookId, widget.chapter)));
                },
              )).toList(),
        ),
      ),
    );
  }

  void _showHighlightOptions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seleccionar color'),
        content: Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            Colors.yellow,
            Colors.green[200]!,
            Colors.blue[200]!,
            Colors.pink[200]!,
            Colors.orange[200]!,
            Colors.purple[200]!,
          ].map((color) => InkWell(
                onTap: () {
                  setState(() {
                    _highlightColor = color;
                    _highlightedVerses.addAll(_selectedVerses);
                    _selectedVerses.clear();
                    _isSelectionMode = false;
                  });
                  Navigator.pop(context);
                },
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey),
                  ),
                ),
              )).toList(),
        ),
      ),
    );
  }

  void _selectAll() {
    final chapterAsync = ref.read(bibleChapterProvider((widget.bookId, widget.chapter)));
    chapterAsync.whenData((verses) {
      setState(() {
        _selectedVerses.clear();
        _selectedVerses.addAll(verses.map((v) => v.verse));
      });
    });
  }

  void _copySelectedVerses() {
    final chapterAsync = ref.read(bibleChapterProvider((widget.bookId, widget.chapter)));
    chapterAsync.whenData((verses) {
      final selectedTexts = verses
          .where((v) => _selectedVerses.contains(v.verse))
          .map((v) => '${v.verse}. ${v.text}')
          .join('\n');

      Clipboard.setData(ClipboardData(text: selectedTexts));

      setState(() {
        _isSelectionMode = false;
        _selectedVerses.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Versículos copiados')),
      );
    });
  }

  void _shareSelectedVerses() {
    final chapterAsync = ref.read(bibleChapterProvider((widget.bookId, widget.chapter)));
    final bookAsync = ref.read(bibleBookProvider(widget.bookId));

    chapterAsync.whenData((verses) {
      bookAsync.whenData((book) {
        final selectedTexts = verses
            .where((v) => _selectedVerses.contains(v.verse))
            .map((v) => '${v.verse}. ${v.text}')
            .join('\n');

        final reference = '${book.name} ${widget.chapter}:${_selectedVerses.join(',')}';
        final shareText = '$selectedTexts\n\n$reference $_currentVersion\n\nCompartido desde Enfocados en Dios TV';

        Share.share(shareText, subject: reference);

        setState(() {
          _isSelectionMode = false;
          _selectedVerses.clear();
        });
      });
    });
  }

  void _saveSelectedVerses() {
    // Guardar versículos seleccionados en favoritos
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Versículos guardados en favoritos')),
    );

    setState(() {
      _isSelectionMode = false;
      _selectedVerses.clear();
    });
  }

  void _addNote() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agregar nota'),
        content: const TextField(
          maxLines: 5,
          decoration: InputDecoration(
            hintText: 'Escribe tu nota aquí...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Nota guardada')),
              );
              setState(() {
                _isSelectionMode = false;
                _selectedVerses.clear();
              });
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _copyVerse(BibleVerse verse) {
    final text = '${verse.text}\n${verse.book?.name ?? ''} ${verse.chapter}:${verse.verse} $_currentVersion';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Versículo copiado')),
    );
  }

  void _shareVerse(BibleVerse verse) {
    final text = '${verse.text}\n\n${verse.book?.name ?? ''} ${verse.chapter}:${verse.verse} $_currentVersion\n\nCompartido desde Enfocados en Dios TV';
    Share.share(text, subject: '${verse.book?.name ?? ''} ${verse.chapter}:${verse.verse}');
  }

  void _saveVerse(BibleVerse verse) {
    ref.read(bibleProvider.notifier).saveFavoriteVerse(verse.id);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Versículo guardado en favoritos')),
    );
  }

  void _addNoteToVerse(BibleVerse verse) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Nota para ${verse.book?.name ?? ''} ${verse.chapter}:${verse.verse}'),
        content: const TextField(
          maxLines: 5,
          decoration: InputDecoration(
            hintText: 'Escribe tu nota aquí...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Nota guardada')),
              );
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _showStrongsConcordance(BibleVerse verse) {
    if (verse.strongNumbers == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                'Concordancia Strong',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: verse.strongNumbers!.length,
                  itemBuilder: (context, index) {
                    final strongNumber = verse.strongNumbers![index];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary,
                          child: Text(
                            strongNumber.substring(0, 1),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(strongNumber),
                        subtitle: const Text('Definición y significado...'),
                        onTap: () {
                          // Mostrar detalles del Strong
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showStrongsDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Concordancia Strong disponible')),
    );
  }

  void _showParallelVerses() {
    context.push('/bible/parallel/chapter/${widget.bookId}/${widget.chapter}');
  }

  void _playAudio() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reproduciendo audio del capítulo...')),
    );
  }

  void _navigateToChapter(int chapter) {
    context.pushReplacement('/bible/read/${widget.bookId}/$chapter');
  }

  void _scrollToVerse(int verseNumber) {
    final key = _verseKeys[verseNumber];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }
}

/// Widget para acciones de selección
class _SelectionAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _SelectionAction({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 11),
          ),
        ],
      ),
    );
  }
}