import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/api_client.dart';
import 'package:mana/l10n/app_localizations.dart';

// PRD F3 — 동반 가족/참석자 (부부·가족). 인원수·픽업에 각각 반영.
class CompanionStep extends ConsumerStatefulWidget {
  final String programId;
  const CompanionStep({super.key, required this.programId});

  @override
  ConsumerState<CompanionStep> createState() => _CompanionStepState();
}

class _CompanionStepState extends ConsumerState<CompanionStep> {
  List<Map<String, dynamic>> _companions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final rows = await ApiClient.getMyCompanions(widget.programId);
      if (!mounted) return;
      setState(() {
        _companions = rows.map((r) => _fromServer(r as Map<String, dynamic>)).toList();
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Map<String, dynamic> _fromServer(Map<String, dynamic> r) => {
        'realName': r['real_name'] ?? '',
        'bibleName': r['bible_name'] ?? '',
        'gender': r['gender'],
        'age': r['age'],
        'language': r['language'] ?? '',
        'branch': r['branch'] ?? '',
        'sameFlightAsPrimary': r['same_flight_as_primary'] ?? true,
        'arrivalFlightNo': (r['arrival_flight'] as Map?)?['flight_no'] ?? '',
        'departureFlightNo': (r['departure_flight'] as Map?)?['flight_no'] ?? '',
        'needsPickup': r['needs_pickup'] ?? true,
      };

  // 로컬 → 서버 payload
  List<Map<String, dynamic>> _toPayload() => _companions.map((c) {
        final same = c['sameFlightAsPrimary'] == true;
        return {
          'realName': c['realName'],
          'bibleName': c['bibleName'],
          'gender': c['gender'],
          'age': c['age'],
          'language': c['language'],
          'branch': c['branch'],
          'sameFlightAsPrimary': same,
          'arrivalFlight': (!same && '${c['arrivalFlightNo']}'.isNotEmpty)
              ? {'flight_no': c['arrivalFlightNo']}
              : null,
          'departureFlight': (!same && '${c['departureFlightNo']}'.isNotEmpty)
              ? {'flight_no': c['departureFlightNo']}
              : null,
          'needsPickup': c['needsPickup'] ?? true,
        };
      }).toList();

  Future<void> _persist() async {
    try {
      await ApiClient.saveMyCompanions(widget.programId, _toPayload());
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _addOrEdit({int? index}) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CompanionSheet(existing: index != null ? _companions[index] : null),
    );
    if (result == null) return;
    setState(() {
      if (index != null) {
        _companions[index] = result;
      } else {
        _companions.add(result);
      }
    });
    await _persist();
  }

  Future<void> _remove(int index) async {
    setState(() => _companions.removeAt(index));
    await _persist();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 90),
          children: [
            const Icon(Icons.family_restroom, size: 48, color: Color(0xFF7A6BB5)),
            const SizedBox(height: 12),
            Text(l10n.companionTitle,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(l10n.companionDesc,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            if (_companions.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(child: Text(l10n.companionEmpty,
                    style: TextStyle(color: Colors.grey[500]))),
              )
            else ...[
              Text(l10n.companionCount(_companions.length),
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              ..._companions.asMap().entries.map((e) {
                final c = e.value;
                final sub = [
                  if (c['gender'] == 'M') l10n.genderMale else if (c['gender'] == 'F') l10n.genderFemale,
                  if (c['age'] != null) '${c['age']}',
                  if ('${c['branch']}'.isNotEmpty) c['branch'],
                ].where((x) => x != null && '$x'.isNotEmpty).join(' · ');
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFF7A6BB5),
                      child: Icon(Icons.person, color: Colors.white, size: 20),
                    ),
                    title: Text(c['realName'] as String? ?? '',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(sub),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          onPressed: () => _addOrEdit(index: e.key),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                          onPressed: () => _remove(e.key),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ],
        ),
        Positioned(
          left: 20, right: 20, bottom: 16,
          child: FilledButton.icon(
            onPressed: () => _addOrEdit(),
            icon: const Icon(Icons.person_add_alt),
            label: Text(l10n.companionAdd),
          ),
        ),
      ],
    );
  }
}

// ── 동반자 입력 바텀시트 ──────────────────────────────────────
class _CompanionSheet extends StatefulWidget {
  final Map<String, dynamic>? existing;
  const _CompanionSheet({this.existing});
  @override
  State<_CompanionSheet> createState() => _CompanionSheetState();
}

class _CompanionSheetState extends State<_CompanionSheet> {
  late final TextEditingController _name;
  late final TextEditingController _bible;
  late final TextEditingController _age;
  late final TextEditingController _language;
  late final TextEditingController _branch;
  late final TextEditingController _arrFlight;
  late final TextEditingController _depFlight;
  String? _gender;
  bool _sameFlight = true;
  bool _needsPickup = true;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?['realName'] ?? '');
    _bible = TextEditingController(text: e?['bibleName'] ?? '');
    _age = TextEditingController(text: e?['age']?.toString() ?? '');
    _language = TextEditingController(text: e?['language'] ?? '');
    _branch = TextEditingController(text: e?['branch'] ?? '');
    _arrFlight = TextEditingController(text: e?['arrivalFlightNo'] ?? '');
    _depFlight = TextEditingController(text: e?['departureFlightNo'] ?? '');
    _gender = e?['gender'] as String?;
    _sameFlight = e?['sameFlightAsPrimary'] ?? true;
    _needsPickup = e?['needsPickup'] ?? true;
  }

  @override
  void dispose() {
    _name.dispose(); _bible.dispose(); _age.dispose();
    _language.dispose(); _branch.dispose();
    _arrFlight.dispose(); _depFlight.dispose();
    super.dispose();
  }

  void _submit() {
    if (_name.text.trim().isEmpty) return;
    Navigator.pop(context, {
      'realName': _name.text.trim(),
      'bibleName': _bible.text.trim(),
      'gender': _gender,
      'age': int.tryParse(_age.text.trim()),
      'language': _language.text.trim(),
      'branch': _branch.text.trim(),
      'sameFlightAsPrimary': _sameFlight,
      'arrivalFlightNo': _arrFlight.text.trim(),
      'departureFlightNo': _depFlight.text.trim(),
      'needsPickup': _needsPickup,
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.existing == null ? l10n.companionAddTitle : l10n.companionEditTitle,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(controller: _name,
                decoration: InputDecoration(labelText: l10n.profileNameLabel)),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: TextField(controller: _bible,
                  decoration: InputDecoration(labelText: l10n.regBibleName))),
              const SizedBox(width: 10),
              SizedBox(width: 90, child: TextField(controller: _age,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(labelText: l10n.summaryAge))),
            ]),
            const SizedBox(height: 12),
            Text(l10n.regGender, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 4),
            SegmentedButton<String>(
              segments: [
                ButtonSegment(value: 'M', label: Text(l10n.genderMale)),
                ButtonSegment(value: 'F', label: Text(l10n.genderFemale)),
              ],
              selected: _gender != null ? {_gender!} : {},
              emptySelectionAllowed: true,
              onSelectionChanged: (s) => setState(() => _gender = s.isEmpty ? null : s.first),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: TextField(controller: _language,
                  decoration: InputDecoration(labelText: l10n.companionLanguage))),
              const SizedBox(width: 10),
              Expanded(child: TextField(controller: _branch,
                  decoration: InputDecoration(labelText: l10n.summaryBranch))),
            ]),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.companionSameFlight),
              value: _sameFlight,
              onChanged: (v) => setState(() => _sameFlight = v),
            ),
            if (!_sameFlight) ...[
              TextField(controller: _arrFlight,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(labelText: l10n.companionArrivalFlightNo, hintText: 'KE123')),
              const SizedBox(height: 8),
              TextField(controller: _depFlight,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(labelText: l10n.companionDepartureFlightNo, hintText: 'KE124')),
              const SizedBox(height: 8),
            ],
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.companionNeedsPickup),
              value: _needsPickup,
              onChanged: (v) => setState(() => _needsPickup = v),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(onPressed: _submit, child: Text(l10n.actionSave)),
            ),
          ],
        ),
      ),
    );
  }
}
