import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/network/api_client.dart';

class StudentProgressScreen extends StatefulWidget {
  final int? courseId;

  const StudentProgressScreen({super.key, this.courseId});

  @override
  State<StudentProgressScreen> createState() => _StudentProgressScreenState();
}

class _StudentProgressScreenState extends State<StudentProgressScreen> {
  List<Map<String, dynamic>> _students = [];
  bool _isLoading = true;
  String? _error;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final endpoint = widget.courseId != null
          ? '/api/v1/courses/${widget.courseId}/students/'
          : '/api/v1/trainer/students/';
      final res = await ApiClient().dio.get(endpoint);
      final data = res.data;
      final rawList = data is Map
          ? (data['results'] as List? ?? data['students'] as List? ?? const [])
          : (data as List? ?? const []);
      if (!mounted) return;
      setState(() {
        _students = rawList
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = ApiClient().parseError(e);
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_search.isEmpty) return _students;
    final q = _search.toLowerCase();
    return _students.where((s) {
      final name = (s['full_name'] as String? ??
              s['username'] as String? ??
              '')
          .toLowerCase();
      return name.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF3D1800),
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: Text(
          'Maendeleo ya Wanafunzi',
          style: GoogleFonts.montserrat(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_students.length} wanafunzi',
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: 'Tafuta mwanafunzi...',
                hintStyle: GoogleFonts.montserrat(
                  fontSize: 14,
                  color: const Color(0xFFBDA99C),
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  color: Color(0xFF9E8070),
                  size: 20,
                ),
                filled: true,
                fillColor: const Color(0xFFFFF8F4),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE8D5C8)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: Color(0xFFE87722),
                    width: 1.5,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF0E4DA)),

          // Summary bar
          if (!_isLoading && _error == null && _students.isNotEmpty)
            _SummaryBar(students: _students),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFE87722)),
                  )
                : _error != null
                    ? _ErrorState(
                        message: _error!,
                        onRetry: () {
                          setState(() {
                            _isLoading = true;
                            _error = null;
                          });
                          _load();
                        },
                      )
                    : _filtered.isEmpty
                        ? _EmptyState(hasSearch: _search.isNotEmpty)
                        : RefreshIndicator(
                            color: const Color(0xFFE87722),
                            onRefresh: () async {
                              setState(() => _isLoading = true);
                              await _load();
                            },
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filtered.length,
                              itemBuilder: (_, i) =>
                                  _StudentCard(student: _filtered[i]),
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

// ── Summary Bar ──────────────────────────────────────────────────────────────

class _SummaryBar extends StatelessWidget {
  final List<Map<String, dynamic>> students;
  const _SummaryBar({required this.students});

  @override
  Widget build(BuildContext context) {
    final completed = students.where((s) {
      final pct = (s['progress_percentage'] as num?)?.toDouble() ?? 0;
      return pct >= 100;
    }).length;
    final avgProgress = students.isEmpty
        ? 0.0
        : students.fold<double>(
                0,
                (sum, s) =>
                    sum +
                    ((s['progress_percentage'] as num?)?.toDouble() ?? 0),
              ) /
            students.length;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      child: Row(
        children: [
          _stat('$completed', 'Wamekamilisha', const Color(0xFFE87722)),
          _divider(),
          _stat('${students.length - completed}', 'Wanaendelea',
              const Color(0xFFE87722)),
          _divider(),
          _stat('${avgProgress.toStringAsFixed(0)}%', 'Wastani',
              const Color(0xFF3D1800)),
        ],
      ),
    );
  }

  Widget _stat(String value, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.montserrat(
              fontSize: 11,
              color: const Color(0xFF9E8070),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(
        height: 32,
        width: 1,
        color: const Color(0xFFE8D5C8),
      );
}

// ── Student Card ─────────────────────────────────────────────────────────────

class _StudentCard extends StatelessWidget {
  final Map<String, dynamic> student;
  const _StudentCard({required this.student});

  @override
  Widget build(BuildContext context) {
    final name = student['full_name'] as String? ??
        student['username'] as String? ??
        'Mwanafunzi';
    final email = student['email'] as String? ?? '';
    final progress =
        (student['progress_percentage'] as num?)?.toDouble() ?? 0.0;
    final completedLessons = student['completed_lessons'] as int? ?? 0;
    final totalLessons = student['total_lessons'] as int? ?? 0;
    final isCompleted = progress >= 100;

    final avatar = student['avatar'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0FC4620A),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xFFF5E6D8),
                backgroundImage:
                    avatar != null ? NetworkImage(avatar) : null,
                child: avatar == null
                    ? Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'M',
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFE87722),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF3D1800),
                      ),
                    ),
                    if (email.isNotEmpty)
                      Text(
                        email,
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          color: const Color(0xFF9E8070),
                        ),
                      ),
                  ],
                ),
              ),
              // Status badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? const Color(0xFFF5E6D8)
                      : const Color(0xFFFFF8F4),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isCompleted
                        ? const Color(0xFFE87722)
                        : const Color(0xFFE87722),
                  ),
                ),
                child: Text(
                  isCompleted ? 'Amekamilisha' : '${progress.toInt()}%',
                  style: GoogleFonts.montserrat(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isCompleted
                        ? const Color(0xFFE87722)
                        : const Color(0xFFE87722),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    totalLessons > 0
                        ? '$completedLessons / $totalLessons masomo'
                        : 'Maendeleo',
                    style: GoogleFonts.montserrat(
                      fontSize: 11,
                      color: const Color(0xFF9E8070),
                    ),
                  ),
                  Text(
                    '${progress.toInt()}%',
                    style: GoogleFonts.montserrat(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isCompleted
                          ? const Color(0xFFE87722)
                          : const Color(0xFFE87722),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (progress / 100).clamp(0.0, 1.0),
                  minHeight: 6,
                  backgroundColor: const Color(0xFFF0E4DA),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isCompleted
                        ? const Color(0xFFE87722)
                        : const Color(0xFFE87722),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Empty & Error states ──────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool hasSearch;
  const _EmptyState({required this.hasSearch});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasSearch ? Icons.search_off : Icons.people_outline,
            size: 64,
            color: const Color(0xFFE8D5C8),
          ),
          const SizedBox(height: 16),
          Text(
            hasSearch ? 'Hakuna matokeo' : 'Hakuna Wanafunzi Bado',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A0A00),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasSearch
                ? 'Jaribu kutafuta jina tofauti.'
                : 'Wanafunzi wataonekana hapa wanaposajiliwa.',
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: const Color(0xFF9E8070),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Color(0xFFE8D5C8)),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: const Color(0xFF9E8070),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE87722),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: Text(
                'Jaribu Tena',
                style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
