import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> makePhoneCall(BuildContext context, String number) async {
  final uri = Uri(scheme: 'tel', path: number);
  try {
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      _showCannotDialDialog(context, number);
    }
  } catch (_) {
    if (context.mounted) {
      _showCannotDialDialog(context, number);
    }
  }
}

void _showCannotDialDialog(BuildContext context, String number) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.phone_disabled_rounded, color: Color(0xFFB71C1C)),
          const SizedBox(width: 10),
          Text('Cannot Dial', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        ],
      ),
      content: Text(
        'Could not open the dialer automatically.\n\nPlease dial $number manually.',
        style: GoogleFonts.inter(fontSize: 14, height: 1.5),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'OK',
            style: GoogleFonts.inter(
              color: const Color(0xFF1E8449),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}