import 'package:flutter/material.dart';
import 'package:karakana_app/widgets/common/karakana_wave_loader.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/utils/screenshot_prevention.dart';

class EBooksScreen extends StatefulWidget {
  const EBooksScreen({super.key});

  @override
  State<EBooksScreen> createState() => _EBooksScreenState();
}

class _EBooksScreenState extends State<EBooksScreen> {
  List<Map<String, dynamic>> _books = [];
  bool _isLoading = true;
  Map<String, dynamic>? _selectedBook;
  bool _isReading = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    ScreenshotPrevention.enable();
    _loadBooks();
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    ScreenshotPrevention.disable();
    super.dispose();
  }

  Future<void> _loadBooks() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() {
      _books = [
        {
          'id': 1,
          'title': 'Misingi ya Ujasiriamali',
          'author': 'Kreative Karakana',
          'description':
              'Kitabu cha msingi cha kuelewa ujasiriamali wa kisasa Tanzania.',
          'pages': 124,
          'category': 'Ujasiriamali',
          'gradient': [const Color(0xFF3B1A08), const Color(0xFFC4620A)],
          'is_free': true,
        },
        {
          'id': 2,
          'title': 'Usimamizi wa Fedha za Biashara',
          'author': 'Kreative Karakana',
          'description':
              'Jinsi ya kusimamia fedha za biashara yako kwa ufanisi.',
          'pages': 89,
          'category': 'Fedha',
          'gradient': [const Color(0xFF1A2E5A), const Color(0xFF2D4A8A)],
          'is_free': false,
        },
        {
          'id': 3,
          'title': 'Masoko ya Kidijitali Tanzania',
          'author': 'Kreative Karakana',
          'description':
              'Strategies za masoko ya kidijitali kwa biashara ndogo Tanzania.',
          'pages': 67,
          'category': 'Masoko',
          'gradient': [const Color(0xFF2E5A1A), const Color(0xFF3A8A2D)],
          'is_free': true,
        },
        {
          'id': 4,
          'title': 'Uongozi na Timu',
          'author': 'Kreative Karakana',
          'description': 'Jinsi ya kuongoza timu yako na kukuza biashara.',
          'pages': 156,
          'category': 'Uongozi',
          'gradient': [const Color(0xFF5A1A1A), const Color(0xFF8A2D2D)],
          'is_free': false,
        },
      ];
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFFFF8F4),
        body: Center(
          child: KarakanaWaveLoader(color: Color(0xFF7B2D9E)),
        ),
      );
    }
    if (_isReading && _selectedBook != null) {
      return _buildReadingView();
    }
    return _buildLibraryView();
  }

  Widget _buildLibraryView() {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F4),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: const Color(0xFF4A1A6B),
            leading: const BackButton(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF4A1A6B), Color(0xFF7B2D9E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: -30,
                      right: -30,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                    ),
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.menu_book_outlined,
                                    color: Colors.white, size: 28),
                                const SizedBox(width: 10),
                                Text(
                                  'eBooks',
                                  style: GoogleFonts.poppins(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Maktaba ya Kidijitali ya Karakana',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.security_outlined,
                                      color: Colors.white, size: 12),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Haina Picha za Skrini',
                                    style: GoogleFonts.inter(
                                        fontSize: 10, color: Colors.white),
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
              ),
            ),
          ),

          // Screenshot warning banner
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFE65100).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.no_photography_outlined,
                      color: Color(0xFFE65100), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Maudhui haya yanalindwa. Picha za skrini haziruhusiwi.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFFE65100),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.72,
              ),
              delegate: SliverChildBuilderDelegate(
                (_, i) => _buildBookCard(_books[i]),
                childCount: _books.length,
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  Widget _buildBookCard(Map<String, dynamic> book) {
    return GestureDetector(
      onTap: () => setState(() {
        _selectedBook = book;
        _isReading = true;
      }),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            children: [
              // Book cover
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: (book['gradient'] as List).cast<Color>(),
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.menu_book,
                              color: Colors.white.withValues(alpha: 0.3),
                              size: 48,
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                book['title'] as String,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (book['is_free'] == true)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2E7D32),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'BURE',
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              // Book info
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book['author'] as String,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: const Color(0xFF9E8070),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.pages_outlined,
                            size: 11, color: Color(0xFFBDA99C)),
                        const SizedBox(width: 3),
                        Text(
                          '${book['pages']} kurasa',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: const Color(0xFFBDA99C),
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
      ),
    );
  }

  Widget _buildReadingView() {
    final book = _selectedBook!;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          setState(() {
            _isReading = false;
            _selectedBook = null;
          });
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: const Color(0xFF1A0A00),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => setState(() {
              _isReading = false;
              _selectedBook = null;
            }),
          ),
          title: Text(
            book['title'] as String,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lock_outline,
                        color: Colors.white.withValues(alpha: 0.7), size: 12),
                    const SizedBox(width: 4),
                    Text(
                      'Imelindwa',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        body: Container(
          color: Colors.white,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book['title'] as String,
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A0A00),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'na ${book['author']}',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF9E8070),
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(color: Color(0xFFF0E4DA)),
                const SizedBox(height: 20),
                Text(
                  book['description'] as String,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: const Color(0xFF3B1A08),
                    height: 1.7,
                  ),
                ),
                const SizedBox(height: 24),
                ...List.generate(3, (i) {
                  const titles = [
                    'Utangulizi',
                    'Misingi ya Msingi',
                    'Hatua za Vitendo',
                  ];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sura ${i + 1}: ${titles[i]}',
                        style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF3B1A08),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Lorem ipsum dolor sit amet, consectetur adipiscing elit. '
                        'Hii ni sehemu ya maudhui ya kozi ambayo itapatikana baadaye. '
                        'Karakana inaendelea kuandika vitabu bora vya ujasiriamali kwa Watanzania.',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: const Color(0xFF5C3D2E),
                          height: 1.7,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  );
                }),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.copyright_outlined,
                          color: Color(0xFFE65100), size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Maudhui haya ni mali ya Kreative Karakana. '
                          'Haki zote zimehifadhiwa.',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: const Color(0xFFE65100),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
