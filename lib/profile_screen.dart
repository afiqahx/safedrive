import 'package:flutter/material.dart';

import 'services/api_service.dart';
import 'services/local_preferences_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.userID,
    required this.onLogout,
  });

  final int userID;
  final VoidCallback onLogout;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const _blue = Color(0xFF2862E9);
  static const _navy = Color(0xFF142B4A);
  static const _muted = Color(0xFF718096);

  bool _loading = true;
  bool _saving = false;
  bool _buzzerEnabled = true;
  bool _notificationsEnabled = true;
  bool _preferencesDirty = false;
  String? _error;
  Map<String, dynamic> _user = {};
  List<Map<String, dynamic>> _vehicles = [];
  int? _selectedVehicleID;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final preferences =
          await LocalPreferencesService.loadAlertPreferences(widget.userID);
      if (!mounted) return;
      setState(() {
        _buzzerEnabled = preferences.buzzerEnabled;
        _notificationsEnabled = preferences.mobileNotificationsEnabled;
        _preferencesDirty = false;
      });
    } catch (error) {
      debugPrint('LOAD LOCAL PREFERENCES ERROR: $error');
    }
  }

  Future<void> _loadProfile({bool showSpinner = true}) async {
    if (showSpinner && mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    final result = await ApiService.getProfile(widget.userID);
    if (!mounted) return;

    if (result['success'] != true) {
      setState(() {
        _loading = false;
        _error =
            result['message']?.toString() ?? 'Could not load your profile.';
      });
      return;
    }

    final user = Map<String, dynamic>.from(result['user'] as Map);
    final vehicles = ((result['vehicles'] as List?) ?? const [])
        .whereType<Map>()
        .map((vehicle) => Map<String, dynamic>.from(vehicle))
        .toList();
    final activeVehicle = vehicles.cast<Map<String, dynamic>?>().firstWhere(
          (vehicle) => vehicle?['status']?.toString().toLowerCase() == 'active',
          orElse: () => vehicles.isEmpty ? null : vehicles.first,
        );

    setState(() {
      _loading = false;
      _error = null;
      _user = user;
      _vehicles = vehicles;
      _selectedVehicleID = _toInt(activeVehicle?['vehicleID']);
    });
  }

  int? _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '');
  }

  Map<String, dynamic>? get _selectedVehicle {
    for (final vehicle in _vehicles) {
      if (_toInt(vehicle['vehicleID']) == _selectedVehicleID) return vehicle;
    }
    return _vehicles.isEmpty ? null : _vehicles.first;
  }

  String _text(dynamic value, {String fallback = 'Not provided'}) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  Future<void> _selectVehicle(int? vehicleID) async {
    if (vehicleID == null || vehicleID == _selectedVehicleID) return;
    setState(() => _saving = true);
    final result = await ApiService.activateVehicle(
      userID: widget.userID,
      vehicleID: vehicleID,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (result['success'] == true) {
      await _loadProfile(showSpinner: false);
    } else {
      _showMessage(
          result['message']?.toString() ?? 'Could not change vehicle.');
    }
  }

  Future<void> _editInformation() async {
    final nameController =
        TextEditingController(text: _text(_user['username'], fallback: ''));
    final emailController =
        TextEditingController(text: _text(_user['email'], fallback: ''));
    final phoneController =
        TextEditingController(text: _text(_user['phone'], fallback: ''));
    final vehicle = _selectedVehicle;
    final vehicleTypeController = TextEditingController(
      text: _text(vehicle?['vehicle_type'], fallback: ''),
    );
    final plateController = TextEditingController(
      text: _text(vehicle?['plate_number'], fallback: ''),
    );
    final formKey = GlobalKey<FormState>();

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Information'),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                _EditField(
                    controller: nameController,
                    label: 'Full name',
                    validator: _required),
                const SizedBox(height: 10),
                _EditField(
                    controller: emailController,
                    label: 'Email address',
                    keyboardType: TextInputType.emailAddress,
                    validator: _emailValidator),
                const SizedBox(height: 10),
                _EditField(
                    controller: phoneController,
                    label: 'Contact phone',
                    keyboardType: TextInputType.phone),
                if (vehicle != null) ...[
                  const SizedBox(height: 10),
                  _EditField(
                      controller: vehicleTypeController,
                      label: 'Vehicle type',
                      validator: _required),
                  const SizedBox(height: 10),
                  _EditField(
                      controller: plateController,
                      label: 'Plate number',
                      validator: _required),
                ],
              ]),
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() == true) {
                Navigator.pop(dialogContext, true);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (shouldSave == true && mounted) {
      setState(() => _saving = true);
      final result = await ApiService.updateProfile(
        userID: widget.userID,
        username: nameController.text.trim(),
        email: emailController.text.trim(),
        phone: phoneController.text.trim(),
        vehicleID: _toInt(vehicle?['vehicleID']),
        vehicleType: vehicle == null ? null : vehicleTypeController.text.trim(),
        plateNumber: vehicle == null ? null : plateController.text.trim(),
      );
      if (mounted) {
        setState(() => _saving = false);
        if (result['success'] == true) {
          await _loadProfile(showSpinner: false);
          if (mounted) _showMessage('Profile information saved.');
        } else {
          _showMessage(
              result['message']?.toString() ?? 'Could not save profile.');
        }
      }
    }

    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    vehicleTypeController.dispose();
    plateController.dispose();
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'This field is required.' : null;

  String? _emailValidator(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required.';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim())) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  Future<void> _savePreferences() async {
    setState(() => _saving = true);
    try {
      await LocalPreferencesService.saveAlertPreferences(
        userID: widget.userID,
        buzzerEnabled: _buzzerEnabled,
        mobileNotificationsEnabled: _notificationsEnabled,
      );
      if (!mounted) return;
      setState(() {
        _saving = false;
        _preferencesDirty = false;
      });
      _showMessage('Preferences saved on this device.');
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showMessage('Could not save preferences on this device.');
      debugPrint('SAVE LOCAL PREFERENCES ERROR: $error');
    }
  }

  Future<void> _deleteAccount() async {
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete account?'),
        content: SizedBox(
          width: 420,
          child: Form(
            key: formKey,
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                      'This permanently deletes your account, vehicles, trips, and related alert records.'),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                        labelText: 'Confirm your password',
                        border: OutlineInputBorder()),
                    validator: (value) => value == null || value.isEmpty
                        ? 'Enter your password to continue.'
                        : null,
                  ),
                ]),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFD84646)),
            onPressed: () {
              if (formKey.currentState?.validate() == true) {
                Navigator.pop(dialogContext, true);
              }
            },
            child: const Text('Delete permanently'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _saving = true);
      final result = await ApiService.deleteAccount(
        userID: widget.userID,
        password: passwordController.text,
      );
      if (!mounted) return;
      setState(() => _saving = false);
      if (result['success'] == true) {
        widget.onLogout();
      } else {
        _showMessage(
            result['message']?.toString() ?? 'Could not delete account.');
      }
    }
    passwordController.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(26),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: _loadProfile, child: const Text('Retry')),
          ]),
        ),
      );
    }

    final vehicle = _selectedVehicle;
    final username = _text(_user['username'], fallback: 'Driver');
    final email = _text(_user['email']);
    final initial =
        username.isEmpty ? 'D' : username.substring(0, 1).toUpperCase();

    return Stack(children: [
      ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: [
          _ProfileCard(
            username: username,
            email: email,
            initial: initial,
            phone: _text(_user['phone']),
            vehicle: vehicle,
            vehicles: _vehicles,
            selectedVehicleID: _selectedVehicleID,
            onVehicleChanged: _selectVehicle,
            onEdit: _editInformation,
            onDelete: _deleteAccount,
            onLogout: widget.onLogout,
          ),
          const SizedBox(height: 14),
          _PreferencesCard(
            buzzerEnabled: _buzzerEnabled,
            notificationsEnabled: _notificationsEnabled,
            dirty: _preferencesDirty,
            saving: _saving,
            onBuzzerChanged: (value) => setState(() {
              _buzzerEnabled = value;
              _preferencesDirty = true;
            }),
            onNotificationsChanged: (value) => setState(() {
              _notificationsEnabled = value;
              _preferencesDirty = true;
            }),
            onSave: _savePreferences,
          ),
        ],
      ),
      if (_saving)
        Positioned.fill(
          child: ColoredBox(
            color: Colors.black.withValues(alpha: .08),
            child: const Center(child: CircularProgressIndicator()),
          ),
        ),
    ]);
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.username,
    required this.email,
    required this.initial,
    required this.phone,
    required this.vehicle,
    required this.vehicles,
    required this.selectedVehicleID,
    required this.onVehicleChanged,
    required this.onEdit,
    required this.onDelete,
    required this.onLogout,
  });

  final String username;
  final String email;
  final String initial;
  final String phone;
  final Map<String, dynamic>? vehicle;
  final List<Map<String, dynamic>> vehicles;
  final int? selectedVehicleID;
  final ValueChanged<int?> onVehicleChanged;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onLogout;

  String _value(dynamic value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? 'Not provided' : text;
  }

  @override
  Widget build(BuildContext context) {
    final vehicleItems = vehicles.map((item) {
      final id = int.tryParse(item['vehicleID'].toString());
      return DropdownMenuItem<int>(
        value: id,
        child: Text(
          '${_value(item['plate_number'])} (${_value(item['vehicle_type'])})',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF142B4A),
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D142B4A),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'DRIVER PROFILE',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF142B4A),
                    fontWeight: FontWeight.w800,
                    letterSpacing: .3,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Edit information',
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined,
                    color: Color(0xFF2862E9), size: 19),
              ),
              IconButton(
                tooltip: 'Log out',
                onPressed: onLogout,
                icon: const Icon(Icons.logout_rounded,
                    color: Color(0xFF718096), size: 19),
              ),
            ],
          ),
          const Divider(height: 1),
          const SizedBox(height: 14),
          Row(
            children: [
              CircleAvatar(
                radius: 27,
                backgroundColor: const Color(0xFFEAF0FF),
                child: Text(
                  initial,
                  style: const TextStyle(
                    fontSize: 22,
                    color: Color(0xFF2862E9),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(username,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 15,
                            color: Color(0xFF142B4A),
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 3),
                    Text(email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF718096))),
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                          color: const Color(0xFFE9FAF4),
                          borderRadius: BorderRadius.circular(10)),
                      child: const Text('Driver',
                          style: TextStyle(
                              fontSize: 9,
                              color: Color(0xFF23886E),
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F7FF),
              border: Border.all(color: const Color(0xFFD7E5FF)),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.directions_car_outlined,
                    color: Color(0xFF2862E9), size: 17),
                const SizedBox(width: 7),
                const Text('Active Vehicle:',
                    style: TextStyle(fontSize: 11, color: Color(0xFF52647C))),
                const SizedBox(width: 6),
                Expanded(
                  child: vehicles.isEmpty
                      ? const Text('No vehicle registered',
                          textAlign: TextAlign.end,
                          style:
                              TextStyle(fontSize: 11, color: Color(0xFF718096)))
                      : DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: selectedVehicleID,
                            isExpanded: true,
                            isDense: true,
                            alignment: Alignment.centerRight,
                            items: vehicleItems,
                            onChanged: onVehicleChanged,
                          ),
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
                color: const Color(0xFFF4F8F8),
                borderRadius: BorderRadius.circular(14)),
            child: Column(
              children: [
                _InfoRow(
                    label: 'Vehicle Type',
                    value: _value(vehicle?['vehicle_type'])),
                _InfoRow(
                    label: 'Plate Number',
                    value: _value(vehicle?['plate_number'])),
                _InfoRow(label: 'Contact Phone', value: phone, last: true),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: FilledButton(
                    onPressed: onEdit,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2862E9),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Edit Information',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
              const SizedBox(width: 9),
              SizedBox(
                height: 42,
                child: OutlinedButton(
                  onPressed: onDelete,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFD84646),
                    side: const BorderSide(color: Color(0xFFF0C4C4)),
                    backgroundColor: const Color(0xFFFFF4F4),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Delete',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, this.last = false});
  final String label;
  final String value;
  final bool last;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(bottom: last ? 0 : 7),
        child: Row(children: [
          Expanded(
              child: Text(label,
                  style:
                      const TextStyle(fontSize: 10, color: Color(0xFF66788F)))),
          const SizedBox(width: 10),
          Flexible(
              child: Text(value,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF263B59),
                      fontWeight: FontWeight.w600))),
        ]),
      );
}

class _PreferencesCard extends StatelessWidget {
  const _PreferencesCard({
    required this.buzzerEnabled,
    required this.notificationsEnabled,
    required this.dirty,
    required this.saving,
    required this.onBuzzerChanged,
    required this.onNotificationsChanged,
    required this.onSave,
  });

  final bool buzzerEnabled;
  final bool notificationsEnabled;
  final bool dirty;
  final bool saving;
  final ValueChanged<bool> onBuzzerChanged;
  final ValueChanged<bool> onNotificationsChanged;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(21),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x0D142B4A), blurRadius: 8, offset: Offset(0, 2))
            ]),
        child: Column(children: [
          Row(children: [
            const Expanded(
                child: Text('SOUND & ALERT PREFERENCES',
                    style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF142B4A),
                        fontWeight: FontWeight.w800,
                        letterSpacing: .2))),
            Icon(Icons.tune_rounded, size: 17, color: Colors.blueGrey.shade300),
          ]),
          const Divider(height: 18),
          _PreferenceSwitch(
            title: 'Buzzer Sound Alert',
            subtitle: 'Save your sound alert preference on this device',
            value: buzzerEnabled,
            onChanged: onBuzzerChanged,
          ),
          const Divider(height: 13),
          _PreferenceSwitch(
            title: 'Mobile Notification',
            subtitle: 'Save your notification preference on this device',
            value: notificationsEnabled,
            onChanged: onNotificationsChanged,
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: FilledButton(
              onPressed: saving || !dirty ? null : onSave,
              style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF2862E9),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13))),
              child: Text(
                  saving
                      ? 'Saving...'
                      : dirty
                          ? 'Save Preferences'
                          : 'Preferences Saved',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 7),
          const Text(
              'These preferences stay on this device. Alerts are not yet connected to camera detection.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 9, color: Color(0xFF8A98AA))),
        ]),
      );
}

class _PreferenceSwitch extends StatelessWidget {
  const _PreferenceSwitch(
      {required this.title,
      required this.subtitle,
      required this.value,
      required this.onChanged});
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF263B59),
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 3),
          Text(subtitle,
              style: const TextStyle(fontSize: 9, color: Color(0xFF8A98AA))),
        ])),
        Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF2862E9)),
      ]);
}

class _EditField extends StatelessWidget {
  const _EditField(
      {required this.controller,
      required this.label,
      this.validator,
      this.keyboardType});
  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) => TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            isDense: true),
      );
}
