import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/emergency_dialer.dart';
import 'blood_bank_page.dart';

class _Contact {
  final String name;
  final String number;
  final String subtitle;
  final IconData icon;
  final Color color;
  const _Contact({
    required this.name,
    required this.number,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}

const _nationalContacts = [
  _Contact(
    name: 'National Emergency',
    number: '999',
    subtitle: 'Police · Fire · Ambulance',
    icon: Icons.emergency_rounded,
    color: Color(0xFFB71C1C),
  ),
  _Contact(
    name: 'Fire Service & Civil Defence',
    number: '199',
    subtitle: 'Fire emergency response',
    icon: Icons.local_fire_department_rounded,
    color: Color(0xFFBF360C),
  ),
  _Contact(
    name: 'Ambulance (DGHS)',
    number: '16000',
    subtitle: 'Government ambulance service',
    icon: Icons.local_hospital_rounded,
    color: Color(0xFF1565C0),
  ),
];

const _luContacts = [
  _Contact(
    name: 'LU Main Line (PABX)',
    number: '01313084499',
    subtitle: 'Central switchboard – all extensions',
    icon: Icons.business_rounded,
    color: Color(0xFF1B5E20),
  ),
  _Contact(
    name: 'Proctor\'s Office',
    number: '01717019305',
    subtitle: 'Mr. Md. Mahbubur Rahaman – Proctor',
    icon: Icons.shield_rounded,
    color: Color(0xFF1A237E),
  ),
  _Contact(
    name: 'Vice Chancellor\'s Office',
    number: '01313084499',
    subtitle: 'Ext. 110 – Prof. Dr. Mohammed Taj Uddin',
    icon: Icons.account_balance_rounded,
    color: Color(0xFF4A148C),
  ),
  _Contact(
    name: 'Transport & Estate Section',
    number: '01313084499',
    subtitle: 'Ext. 174 – Bus & transport office',
    icon: Icons.directions_bus_rounded,
    color: Color(0xFF006064),
  ),
  _Contact(
    name: 'Dept. of CSE',
    number: '01313084499',
    subtitle: 'Ext. 221 – Kazi Md. Jahid Hasan',
    icon: Icons.computer_rounded,
    color: Color(0xFF2E7D32),
  ),
  _Contact(
    name: 'Registrar\'s Office',
    number: '01313084499',
    subtitle: 'Ext. 130 – Registration & academic records',
    icon: Icons.assignment_ind_rounded,
    color: Color(0xFF37474F),
  ),
];

class SafetyPage extends StatelessWidget {
  const SafetyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5F5),
      appBar: AppBar(
        title: Text(
          'Emergency & Safety',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFFB71C1C),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _buildSosBanner(),
          const SizedBox(height: 22),
          _buildSectionHeader(
            icon: Icons.warning_amber_rounded,
            label: 'National Emergency',
            color: const Color(0xFFB71C1C),
          ),
          const SizedBox(height: 10),
          ..._nationalContacts.map((c) => _ContactCard(contact: c)),
          const SizedBox(height: 22),
          _buildSectionHeader(
            icon: Icons.school_rounded,
            label: 'Leading University Contacts',
            color: const Color(0xFF1B5E20),
          ),
          const SizedBox(height: 10),
          ..._luContacts.map((c) => _ContactCard(contact: c)),
          const SizedBox(height: 22),
          _buildSectionHeader(
            icon: Icons.bloodtype_rounded,
            label: 'Blood Bank',
            color: const Color(0xFFB71C1C),
          ),
          const SizedBox(height: 10),
          _buildBloodBankCard(context),
          const SizedBox(height: 22),
          _buildInfoBanner(),
        ],
      ),
    );
  }

  Widget _buildSosBanner() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFB71C1C), Color(0xFFE53935)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFB71C1C).withOpacity(0.3),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.health_and_safety_rounded,
                color: Colors.white, size: 34),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Stay Safe on Campus',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Tap any contact to dial instantly.\nFor life-threatening emergencies, always call 999 first.',
                  style: TextStyle(
                      color: Color(0xCCFFFFFF), fontSize: 12, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1A1A),
          ),
        ),
      ],
    );
  }

  Widget _buildBloodBankCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFB71C1C), width: 1.5),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BloodBankPage()),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFB71C1C),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.bloodtype_rounded,
                    color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Find Blood Donors',
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Search registered LU student donors by blood group and call them directly.',
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_ios_rounded,
                  size: 15, color: Color(0xFFB71C1C)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: const Color(0xFF2E7D32).withOpacity(0.4), width: 1),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded,
              color: Color(0xFF2E7D32), size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'LU main line is 01313084499. Use the extensions shown to reach specific offices. Your blood group is saved in your profile and is visible to first responders on campus.',
              style: TextStyle(
                  fontSize: 12, height: 1.5, color: Color(0xFF1B5E20)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final _Contact contact;
  const _ContactCard({required this.contact});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: contact.color.withOpacity(0.25), width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => makePhoneCall(context, contact.number),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: contact.color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(contact.icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contact.name,
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      contact.subtitle,
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      contact.number,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: contact.color,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => makePhoneCall(context, contact.number),
                icon: const Icon(Icons.call_rounded, size: 14),
                label: const Text('Call'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: contact.color,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  textStyle: GoogleFonts.inter(
                      fontSize: 12, fontWeight: FontWeight.w600),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}