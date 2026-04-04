import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class PaymentScreen extends StatefulWidget {
  final int courseId;
  final String courseTitle;
  final double coursePrice;
  final String? courseThumbnail;

  const PaymentScreen({
    super.key,
    required this.courseId,
    required this.courseTitle,
    required this.coursePrice,
    this.courseThumbnail,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String? _selectedProvider;
  final TextEditingController _phoneController = TextEditingController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  String _formatPrice(double price) {
    final formatter = NumberFormat('#,###', 'en_US');
    return 'TZS ${formatter.format(price)}';
  }

  Future<void> _processPayment() async {
    setState(() => _isProcessing = true);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              color: Color(0xFFC4620A),
            ),
            const SizedBox(height: 18),
            Text(
              'Inashughulikia Malipo...',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF3B1A08),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Utapata ujumbe kwenye simu yako. Thibitisha ili kukamilisha.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF5C3D2E),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );

    await Future.delayed(const Duration(seconds: 3));
    if (mounted) Navigator.pop(context);
    if (mounted) context.go('/payment/success');
    if (mounted) setState(() => _isProcessing = false);
  }

  @override
  Widget build(BuildContext context) {
    const providers = [
      {'id': 'mpesa', 'name': 'M-Pesa', 'color': Color(0xFF00A651)},
      {'id': 'tigo', 'name': 'Tigo Pesa', 'color': Color(0xFF009FE3)},
      {'id': 'airtel', 'name': 'Airtel Money', 'color': Color(0xFFEF3B24)},
      {'id': 'halopesa', 'name': 'Halopesa', 'color': Color(0xFF702082)},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F4),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3B1A08),
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: Text(
          'Lipia Kozi',
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14C4620A),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  if (widget.courseThumbnail != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: CachedNetworkImage(
                        imageUrl: widget.courseThumbnail!,
                        width: 72,
                        height: 64,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => _thumbFallback(),
                      ),
                    )
                  else
                    _thumbFallback(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.courseTitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF3B1A08),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _formatPrice(widget.coursePrice),
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFC4620A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Chagua Njia ya Malipo',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF3B1A08),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tumia nambari yako ya simu kulipa',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF9E8070),
              ),
            ),
            const SizedBox(height: 16),
            ...providers.map((provider) {
              final isSelected = _selectedProvider == provider['id'];
              final color = provider['color']! as Color;
              return GestureDetector(
                onTap: () => setState(
                  () => _selectedProvider = provider['id']! as String,
                ),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? color : const Color(0xFFE8D5C8),
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected
                            ? color.withValues(alpha: 0.2)
                            : Colors.black.withValues(alpha: 0.04),
                        blurRadius: isSelected ? 12 : 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.phone_android,
                          color: color,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              provider['name']! as String,
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF3B1A08),
                              ),
                            ),
                            Text(
                              'Lipa kwa ${provider['name']}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: const Color(0xFF9E8070),
                              ),
                            ),
                          ],
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? color : const Color(0xFFE8D5C8),
                            width: 2,
                          ),
                          color: isSelected
                              ? color.withValues(alpha: 0.12)
                              : Colors.transparent,
                        ),
                        child: isSelected
                            ? Icon(Icons.check, color: color, size: 14)
                            : null,
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 24),
            Text(
              'Nambari ya Simu',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF3B1A08),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  width: 80,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5E6D8),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE8D5C8)),
                  ),
                  child: Center(
                    child: Text(
                      '+255',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF3B1A08),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    onChanged: (_) => setState(() {}),
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: const Color(0xFF3B1A08),
                    ),
                    decoration: InputDecoration(
                      hintText: '7XX XXX XXX',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFFBDA99C),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFFFF8F4),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: Color(0xFFE8D5C8),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: Color(0xFFC4620A),
                          width: 1.5,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Mfano: 0712345678 au 712345678',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: const Color(0xFFBDA99C),
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE8D5C8)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Jumla',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: const Color(0xFF9E8070),
                        ),
                      ),
                      Text(
                        _formatPrice(widget.coursePrice),
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF3B1A08),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Ada ya Malipo',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: const Color(0xFF9E8070),
                        ),
                      ),
                      Text(
                        'Bure',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: const Color(0xFF2E7D32),
                        ),
                      ),
                    ],
                  ),
                  const Divider(
                    color: Color(0xFFF0E4DA),
                    height: 20,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Jumla ya Kulipa',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF3B1A08),
                        ),
                      ),
                      Text(
                        _formatPrice(widget.coursePrice),
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFC4620A),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC4620A),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  elevation: 0,
                ),
                onPressed: (_selectedProvider != null &&
                        _phoneController.text.isNotEmpty &&
                        !_isProcessing)
                    ? _processPayment
                    : null,
                child: _isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Lipa ${_formatPrice(widget.coursePrice)}',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.lock_outline,
                  size: 14,
                  color: Color(0xFF9E8070),
                ),
                const SizedBox(width: 6),
                Text(
                  'Malipo Salama na AzamPay',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF9E8070),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _thumbFallback() {
    return Container(
      width: 72,
      height: 64,
      decoration: BoxDecoration(
        color: const Color(0xFFF5E6D8),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(
        Icons.school_outlined,
        color: Color(0xFFC4620A),
      ),
    );
  }
}
