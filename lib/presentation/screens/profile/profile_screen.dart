import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  // ---- Mock profile state ----
  String _name = 'Muhammad Ali';
  String _phone = '+92 300 0000000';
  String _email = 'ali@example.com';

  File? _avatarFile;
  String _avatarUrl = '';

  // Only CASH is supported/visible
//  PaymentMethod _defaultPayment = PaymentMethod.cash;

  final List<SavedPlace> _places = [
    SavedPlace(label: 'Home', address: 'DHA Phase 6, Karachi'),
    SavedPlace(label: 'Work', address: 'Tech Park, Shahrah-e-Faisal'),
  ];

  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  // --------------------------- Helpers ----------------------------
  void _snack(String msg) {
    final cs = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: cs.secondary,
      ),
    );
  }

  Future<void> _pickAvatarFromGallery() async {
    try {
      final x = await ImagePicker()
          .pickImage(source: ImageSource.gallery, maxWidth: 1024, imageQuality: 85);
      if (x != null) {
        setState(() {
          _avatarFile = File(x.path);
          _avatarUrl = '';
        });
        _snack('Photo updated from gallery');
      }
    } catch (_) {
      _snack('Failed to pick image');
    }
  }

  Future<void> _captureAvatarFromCamera() async {
    try {
      final x = await ImagePicker().pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.front,
      );
      if (x != null) {
        setState(() {
          _avatarFile = File(x.path);
          _avatarUrl = '';
        });
        _snack('Photo captured');
      }
    } catch (_) {
      _snack('Failed to open camera');
    }
  }

  void _resetAvatar() {
    setState(() {
      _avatarFile = null;
      _avatarUrl = '';
    });
    _snack('Photo reset to default');
  }

  Future<void> _editTextField({
    required String title,
    required String initial,
    required String hint,
    required String okLabel,
    required String fieldKey,
    required String? Function(String) validator,
    required void Function(String) onSaved,
    TextInputType inputType = TextInputType.text,
  }) async {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final controller = TextEditingController(text: initial);
    final formKey = GlobalKey<FormState>();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _GlassSheet(
          child: Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              top: 16,
            ),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _SheetHandle(title: title),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: ValueKey(fieldKey),
                    controller: controller,
                    keyboardType: inputType,
                    decoration: InputDecoration(
                      hintText: hint,
                      hintStyle: theme.textTheme.bodyMedium
                          ?.copyWith(color: cs.onSurface.withOpacity(0.6)),
                      filled: true,
                      fillColor: theme.cardColor.withOpacity(0.12),
                    ),
                    cursorColor: cs.primary,
                    style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurface),
                    validator: (v) => validator(v?.trim() ?? ''),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          onSaved(controller.text.trim());
                          Navigator.pop(context);
                          _snack('Saved');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cs.primary,
                        foregroundColor: cs.onPrimary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                      ),
                      child: Text(okLabel,
                          style: const TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ------------------------------- BUILD ------------------------------
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final bg = theme.scaffoldBackgroundColor;

    final hasCustomAvatar = _avatarFile != null || _avatarUrl.isNotEmpty;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: cs.surface.withOpacity(0.92), // visible in light/dark
        foregroundColor: cs.onSurface,
        elevation: 1,
      ),
      body: Stack(
        children: [
          // Theme-aware Background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [bg, cs.secondaryContainer.withOpacity(0.25), bg],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Positioned(
              top: -70,
              left: -30,
              child: _blurBlob(200, cs.secondary.withOpacity(0.10))),
          Positioned(
              bottom: -60,
              right: -20,
              child: _blurBlob(220, cs.primary.withOpacity(0.12))),

          // Content
          SafeArea(
            child: FadeTransition(
              opacity: CurvedAnimation(parent: _anim, curve: Curves.easeOut),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                physics: const BouncingScrollPhysics(),
                children: [
                  // Header
                  _HeaderCard(
                    name: _name,
                    phone: _phone,
                    email: _email,
                    avatarProvider: _avatarFile != null
                        ? FileImage(_avatarFile!)
                        : (_avatarUrl.isNotEmpty
                            ? NetworkImage(_avatarUrl)
                            : const AssetImage('assets/images/profile.JPEG')
                                as ImageProvider),
                    onEditName: () => _editTextField(
                      title: 'Edit name',
                      initial: _name,
                      hint: 'Full name',
                      okLabel: 'Save',
                      fieldKey: 'name',
                      validator: (v) =>
                          v.isEmpty ? 'Required' : (v.length < 3 ? 'Too short' : null),
                      onSaved: (v) => setState(() => _name = v),
                    ),
                    onEditPhone: () => _editTextField(
                      title: 'Edit phone',
                      initial: _phone,
                      hint: '+92 3xx xxxxxxx',
                      okLabel: 'Save',
                      fieldKey: 'phone',
                      inputType: TextInputType.phone,
                      validator: (v) {
                        if (v.isEmpty) return 'Required';
                        final cleaned = v.replaceAll(RegExp(r'[\s-]'), '');
                        if (!RegExp(r'^\+?\d{10,15}$').hasMatch(cleaned)) {
                          return 'Invalid phone';
                        }
                        return null;
                      },
                      onSaved: (v) => setState(() => _phone = v),
                    ),
                    onEditEmail: () => _editTextField(
                      title: 'Edit email',
                      initial: _email,
                      hint: 'name@example.com',
                      okLabel: 'Save',
                      fieldKey: 'email',
                      inputType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v.isEmpty) return 'Required';
                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(v)) {
                          return 'Invalid email';
                        }
                        return null;
                      },
                      onSaved: (v) => setState(() => _email = v),
                    ),
                    onTapAvatar: () {
                      // Quick sheet: camera / gallery / reset
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        builder: (_) => _GlassSheet(
                          child: Padding(
                            padding:
                                const EdgeInsets.fromLTRB(16, 16, 16, 16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const _SheetHandle(title: 'Profile photo'),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      _captureAvatarFromCamera();
                                    },
                                    icon: const Icon(Icons.photo_camera),
                                    label: const Text('Take a photo'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: cs.tertiary,
                                      foregroundColor: cs.onTertiary,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 14),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                      elevation: 0,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      _pickAvatarFromGallery();
                                    },
                                    icon: const Icon(Icons.photo_library),
                                    label: const Text('Choose from gallery'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: cs.secondary,
                                      foregroundColor: cs.onSecondary,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 14),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                      elevation: 0,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      _resetAvatar();
                                    },
                                    icon: const Icon(Icons.refresh),
                                    label: const Text('Reset to default'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: cs.onSurface,
                                      side: BorderSide(color: cs.secondary, width: 1),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 14),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    onLongPressAvatar: () {},
                    hasCustomAvatar: hasCustomAvatar, // NEW
                  ),
                  const SizedBox(height: 14),

                  // ------ Default payment (CASH only) ------
                  _GlassCard(
                    child: Column(
                      children: [
                        const _SectionTitle('Default payment'),
                        ListTile(
                          dense: true,
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 8),
                          leading:
                              Icon(Icons.payments, color: cs.primary),
                          title: Text(
                            'Cash (only)',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          subtitle: const Text(
                              'Cash is the active payment method'),
                          // no trailing chevron; no onTap
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Saved places
                  _GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _SectionTitle('Saved places'),
                        ..._places.take(2).map(
                          (p) => ListTile(
                            dense: true,
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 8),
                            leading:
                                Icon(Icons.location_on, color: cs.secondary),
                            title: Text(
                              p.label,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            subtitle: Text(p.address),
                          ),
                        ),
                        Divider(height: 1, color: Theme.of(context).dividerColor),
                        ListTile(
                          dense: true,
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 8),
                          leading: Icon(Icons.edit_location_alt, color: cs.primary),
                          title: const Text('Manage places'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: _managePlaces,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Account (Wallet & Payments removed)
                  _GlassCard(
                    child: Column(
                      children: [
                        const _SectionTitle('Account'),
                        ListTile(
                          dense: true,
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 8),
                          leading: Icon(Icons.logout, color: cs.tertiary),
                          title: const Text('Log out'),
                          onTap: () => _snack('Implement logout here'),
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
    );
  }

  Future<void> _managePlaces() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PlacesSheet(
        places: List.of(_places),
        onChanged: (updated) => setState(() => _places
          ..clear()
          ..addAll(updated)),
      ),
    );
  }

  Widget _blurBlob(double size, Color color) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ),
    );
  }
}

// ============================ Widgets =============================

class _HeaderCard extends StatelessWidget {
  final String name, phone, email;
  final ImageProvider avatarProvider;
  final VoidCallback onEditName, onEditPhone, onEditEmail;
  final VoidCallback onTapAvatar;
  final VoidCallback onLongPressAvatar;
  final bool hasCustomAvatar; // NEW

  const _HeaderCard({
    required this.name,
    required this.phone,
    required this.email,
    required this.avatarProvider,
    required this.onEditName,
    required this.onEditPhone,
    required this.onEditEmail,
    required this.onTapAvatar,
    required this.onLongPressAvatar,
    required this.hasCustomAvatar,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return _GlassCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Row(
        children: [
          // Avatar + visible controls
          Stack(
            clipBehavior: Clip.none,
            children: [
              // tappable avatar
              Semantics(
                button: true,
                label: 'Profile photo. Tap to change.',
                child: GestureDetector(
                  onTap: onTapAvatar,
                  onLongPress: onLongPressAvatar,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: cs.outline.withOpacity(0.35)),
                    ),
                    child: CircleAvatar(
                      radius: 34,
                      backgroundColor: theme.cardColor.withOpacity(0.08),
                      backgroundImage: avatarProvider,
                    ),
                  ),
                ),
              ),

              // Hint pill (when no custom image yet)
              if (!hasCustomAvatar)
                Positioned(
                  left: -8,
                  top: -6,
                  child: _Pulse(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: cs.primary.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: cs.primary.withOpacity(0.35)),
                      ),
           
                    ),
                  ),
                ),

              // Camera FAB
              Positioned(
                right: -6,
                bottom: -6,
                child: Tooltip(
                  message: 'Change photo',
                  child: Material(
                    elevation: 4,
                    shape: const CircleBorder(),
                    color: cs.primary,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: onTapAvatar,
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(Icons.camera_alt_rounded,
                            size: 18, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _EditRow(label: 'Name', value: name, onTap: onEditName),
                _EditRow(label: 'Phone', value: phone, onTap: onEditPhone),
                _EditRow(label: 'Email', value: email, onTap: onEditEmail),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EditRow extends StatelessWidget {
  final String label, value;
  final VoidCallback onTap;

  const _EditRow({required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Text(label,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: cs.onSurface.withOpacity(0.7))),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            Icon(Icons.edit, size: 16, color: cs.onSurface.withOpacity(0.8)),
          ],
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  const _GlassCard({required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final divider = theme.dividerColor;
    final isDark = theme.brightness == Brightness.dark;

    // lighter in light theme; translucent in dark
    final Color bg =
        isDark ? theme.colorScheme.surface.withOpacity(0.20) : Colors.white.withOpacity(0.85);

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(22),
            border:
                Border.all(color: divider.withOpacity(isDark ? 0.25 : 0.35), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.18 : 0.08),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: padding ?? const EdgeInsets.all(12),
          child: child,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 6),
      child: Row(
        children: [
          Container(
              width: 6,
              height: 6,
              decoration:
                  BoxDecoration(color: cs.primary, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(
            text,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 0.3),
          ),
        ],
      ),
    );
  }
}

class _GlassSheet extends StatelessWidget {
  final Widget child;
  const _GlassSheet({required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final divider = theme.dividerColor;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withOpacity(0.95),
            border: Border(top: BorderSide(color: divider)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  final String title;
  const _SheetHandle({required this.title});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Container(
          width: 44,
          height: 5,
          decoration:
              BoxDecoration(color: cs.secondary, borderRadius: BorderRadius.circular(99)),
        ),
        const SizedBox(height: 10),
        Text(
          title,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

// ---------------------------- Saved Places ----------------------------

class _PlacesSheet extends StatefulWidget {
  final List<SavedPlace> places;
  final ValueChanged<List<SavedPlace>> onChanged;
  const _PlacesSheet({required this.places, required this.onChanged});

  @override
  State<_PlacesSheet> createState() => _PlacesSheetState();
}

class _PlacesSheetState extends State<_PlacesSheet> {
  late List<SavedPlace> _items = widget.places;

  void _addOrEdit({SavedPlace? existing, int? index}) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final labelCtl = TextEditingController(text: existing?.label ?? '');
    final addrCtl = TextEditingController(text: existing?.address ?? '');
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _GlassSheet(
        child: Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            top: 16,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _SheetHandle(title: existing == null ? 'Add place' : 'Edit place'),
                const SizedBox(height: 12),
                TextFormField(
                  controller: labelCtl,
                  decoration: InputDecoration(
                    hintText: 'Label (e.g., Home, Gym)',
                    filled: true,
                    fillColor: theme.cardColor.withOpacity(0.12),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: addrCtl,
                  decoration: InputDecoration(
                    hintText: 'Address / landmark',
                    filled: true,
                    fillColor: theme.cardColor.withOpacity(0.12),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (!formKey.currentState!.validate()) return;
                      final item = SavedPlace(
                          label: labelCtl.text.trim(), address: addrCtl.text.trim());
                      setState(() {
                        if (existing == null) {
                          _items.add(item);
                        } else {
                          _items[index!] = item;
                        }
                      });
                      Navigator.pop(context); // inner
                      Navigator.pop(context); // list
                      widget.onChanged(_items);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cs.primary,
                      foregroundColor: cs.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text(existing == null ? 'Add' : 'Save',
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return _GlassSheet(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _SheetHandle(title: 'Manage places'),
            const SizedBox(height: 8),
            ..._items.asMap().entries.map((e) {
              final i = e.key;
              final p = e.value;
              return ListTile(
                leading: Icon(Icons.location_on, color: cs.secondary),
                title: Text(p.label,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800)),
                subtitle: Text(p.address),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Edit',
                      onPressed: () => _addOrEdit(existing: p, index: i),
                      icon: const Icon(Icons.edit),
                    ),
                    IconButton(
                      tooltip: 'Delete',
                      onPressed: () => setState(() => _items.removeAt(i)),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: Icon(Icons.add_location_alt, color: cs.primary),
                label: const Text('Add place'),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: cs.primary, width: 1),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () => _addOrEdit(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------- Models ----------------------------

enum PaymentMethod { cash }

extension on PaymentMethod {
  //String get label => 'Cash';
}

class SavedPlace {
  final String label;
  final String address;
  SavedPlace({required this.label, required this.address});
}

// ---------------------------- Small helper (pulse) ----------------------------

class _Pulse extends StatefulWidget {
  final Widget child;
  const _Pulse({required this.child});
  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
        ..repeat(reverse: true);
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.96, end: 1.06)
          .animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut)),
      child: widget.child,
    );
  }
}
