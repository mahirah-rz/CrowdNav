import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/emergency_dialer.dart';

const _allGroups = [
  'All', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'
];

const _canReceiveFrom = {
  'A+':  ['A+', 'A-', 'O+', 'O-'],
  'A-':  ['A-', 'O-'],
  'B+':  ['B+', 'B-', 'O+', 'O-'],
  'B-':  ['B-', 'O-'],
  'AB+': ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'],
  'AB-': ['A-', 'B-', 'AB-', 'O-'],
  'O+':  ['O+', 'O-'],
  'O-':  ['O-'],
};

const _canDonateTo = {
  'A+':  ['A+', 'AB+'],
  'A-':  ['A+', 'A-', 'AB+', 'AB-'],
  'B+':  ['B+', 'AB+'],
  'B-':  ['B+', 'B-', 'AB+', 'AB-'],
  'AB+': ['AB+'],
  'AB-': ['AB+', 'AB-'],
  'O+':  ['A+', 'B+', 'O+', 'AB+'],
  'O-':  ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'],
};

const _groupColor = {
  'A+':  Color(0xFFB71C1C),
  'A-':  Color(0xFFC62828),
  'B+':  Color(0xFF1565C0),
  'B-':  Color(0xFF0D47A1),
  'AB+': Color(0xFF6A1B9A),
  'AB-': Color(0xFF4A148C),
  'O+':  Color(0xFF2E7D32),
  'O-':  Color(0xFF1B5E20),
};

Color _colorOf(String? bg) => _groupColor[bg] ?? const Color(0xFFB71C1C);

class BloodBankPage extends StatefulWidget {
  const BloodBankPage({super.key});

  @override
  State<BloodBankPage> createState() => _BloodBankPageState();
}

class _BloodBankPageState extends State<BloodBankPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  List<Map<String, dynamic>> _allDonors = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _loading = true;
  String? _error;
  String _selectedGroup = 'All';
  String? _myBloodGroup;
  String? _myId;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final uid = Supabase.instance.client.auth.currentUser?.id;

      if (uid != null) {
        final me = await Supabase.instance.client
            .from('profiles')
            .select('id, blood_group')
            .eq('id', uid)
            .maybeSingle();
        _myBloodGroup = (me?['blood_group'] as String?)?.trim();
        _myId = uid;
      }

      final raw = await Supabase.instance.client
          .from('profiles')
          .select('id, name, blood_group, phone, department, program')
          .order('name');

      final donors = (raw as List)
          .map((e) => Map<String, dynamic>.from(e))
          .where((e) {
            final id = e['id'] as String?;
            final phone = (e['phone'] as String?)?.trim() ?? '';
            final bg = (e['blood_group'] as String?)?.trim() ?? '';
            return id != _myId && phone.isNotEmpty && bg.isNotEmpty;
          })
          .toList();

      if (mounted) {
        setState(() {
          _allDonors = donors;
          _loading = false;
        });
        _applyFilter();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Could not load donors.\nPlease check your connection and try again.';
        });
      }
    }
  }

  void _applyFilter() {
    setState(() {
      _filtered = _selectedGroup == 'All'
          ? List.from(_allDonors)
          : _allDonors
              .where((d) =>
                  (d['blood_group'] as String?)?.trim() == _selectedGroup)
              .toList();
    });
  }

  List<Map<String, dynamic>> get _compatibleDonors {
    if (_myBloodGroup == null) return [];
    final compatible = _canReceiveFrom[_myBloodGroup] ?? [];
    return _allDonors
        .where((d) =>
            compatible.contains((d['blood_group'] as String?)?.trim()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5F5),
      appBar: AppBar(
        title: Text('Blood Bank',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFFB71C1C),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _load,
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle:
              GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: const [
            Tab(text: 'All Donors'),
            Tab(text: 'Compatible for Me'),
          ],
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFB71C1C)))
          : _error != null
              ? _buildError()
              : Column(
                  children: [
                    if (_myBloodGroup != null) _buildMyBloodCard(),
                    Expanded(
                      child: TabBarView(
                        controller: _tabs,
                        children: [
                          _buildAllDonorsTab(),
                          _buildCompatibleTab(),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildMyBloodCard() {
    final color = _colorOf(_myBloodGroup);
    final receive = (_canReceiveFrom[_myBloodGroup] ?? []).join(', ');
    final donate = (_canDonateTo[_myBloodGroup] ?? []).join(', ');
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha:0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha:0.2),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Center(
              child: Text(
                _myBloodGroup!,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Blood Group',
                  style: GoogleFonts.inter(
                      color: Colors.white70, fontSize: 11),
                ),
                const SizedBox(height: 3),
                Text(
                  'Can receive from: $receive',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 12, height: 1.4),
                ),
                Text(
                  'Can donate to: $donate',
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 11, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllDonorsTab() {
    return Column(
      children: [
        const SizedBox(height: 10),
        _buildGroupFilterBar(),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
          child: Row(
            children: [
              const Icon(Icons.people_outline_rounded,
                  size: 14, color: Colors.grey),
              const SizedBox(width: 5),
              Text(
                '${_filtered.length} donor${_filtered.length == 1 ? '' : 's'} found',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        Expanded(
          child: _filtered.isEmpty
              ? _buildEmpty(
                  'No donors for "$_selectedGroup"',
                  'Donors appear once students complete\ntheir profile with blood group and phone number.',
                )
              : _buildList(_filtered),
        ),
      ],
    );
  }

  Widget _buildCompatibleTab() {
    if (_myBloodGroup == null || _myBloodGroup!.isEmpty) {
      return _buildEmpty(
        'Blood group not set',
        'Go to your Profile and add your\nblood group to see compatible donors.',
      );
    }
    final list = _compatibleDonors;
    return Column(
      children: [
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: Row(
            children: [
              const Icon(Icons.favorite_rounded,
                  size: 14, color: Color(0xFFB71C1C)),
              const SizedBox(width: 5),
              Text(
                '${list.length} compatible donor${list.length == 1 ? '' : 's'} for blood group $_myBloodGroup',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        Expanded(
          child: list.isEmpty
              ? _buildEmpty(
                  'No compatible donors yet',
                  'As more students register on CrowdNav\nand fill their profiles, donors will appear here.',
                )
              : _buildList(list),
        ),
      ],
    );
  }

  Widget _buildGroupFilterBar() {
    return SizedBox(
      height: 42,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _allGroups.length,
        itemBuilder: (_, i) {
          final bg = _allGroups[i];
          final selected = bg == _selectedGroup;
          final color =
              bg == 'All' ? const Color(0xFFB71C1C) : _colorOf(bg);
          return GestureDetector(
            onTap: () {
              setState(() => _selectedGroup = bg);
              _applyFilter();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: selected ? color : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color, width: 1.5),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha:0.28),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        )
                      ]
                    : [],
              ),
              alignment: Alignment.center,
              child: Text(
                bg,
                style: TextStyle(
                  color: selected ? Colors.white : color,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> list) {
    return RefreshIndicator(
      color: const Color(0xFFB71C1C),
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 24),
        itemCount: list.length,
        itemBuilder: (ctx, i) => _buildDonorCard(ctx, list[i]),
      ),
    );
  }

  Widget _buildDonorCard(BuildContext context, Map<String, dynamic> d) {
    final bg = (d['blood_group'] as String?)?.trim() ?? '';
    final name = (d['name'] as String?)?.trim() ?? 'Anonymous';
    final phone = (d['phone'] as String?)?.trim() ?? '';
    final dept = (d['department'] as String?)?.trim() ?? '';
    final program = (d['program'] as String?)?.trim() ?? '';
    final color = _colorOf(bg);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: color.withValues(alpha:0.2), width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => makePhoneCall(context, phone),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Center(
                  child: Text(
                    bg,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    if (dept.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        '$dept${program.isNotEmpty ? ' · $program' : ''}',
                        style: const TextStyle(
                            fontSize: 11, color: Colors.grey),
                      ),
                    ],
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(Icons.phone_rounded,
                            size: 12, color: color),
                        const SizedBox(width: 4),
                        Text(
                          phone,
                          style: TextStyle(
                            fontSize: 12,
                            color: color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => makePhoneCall(context, phone),
                icon: const Icon(Icons.call_rounded, size: 14),
                label: const Text('Call'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
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

  Widget _buildEmpty(String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bloodtype_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.grey, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 64, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB71C1C),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}