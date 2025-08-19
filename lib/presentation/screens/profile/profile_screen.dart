import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

// ✅ Use app routes constant for Navigator.pushNamed(..., Routes.wallet)
import '../../../app/routes.dart';

/// ---------- Color Palette (unique + high contrast) ----------
class AppColors {
  // Background gradient
  static const bg1 = Color(0xFF12002B);   // deep plum
  static const bg2 = Color(0xFF3A0CA3);   // indigo violet
  static const bg3 = Color(0xFF7B2FF7);   // electric violet

  // Accents
  static const mint        = Color(0xFF00E5B0); // primary action
  static const periwinkle  = Color(0xFF8AB4FF); // secondary action
  static const tangerine   = Color(0xFFFF9E4A); // camera CTA
  static const cyanGlow    = Color(0xFF54FFE3); // subtle highlights

  // Cards & sheets
  static const cardGlass   = Color(0x1AFFFFFF); // 10% white
  static const cardBorder  = Color(0x33FFFFFF); // 20% white
  static const sheetTint   = Color(0xF00C0720); // 94% opaque deep tint
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  // ---- Mock profile state (replace with your repository/provider) ----
  String _name = 'Muhammad Ali';
  String _phone = '+92 300 0000000';
  String _email = 'ali@example.com';

  // Avatar state: either _avatarFile (gallery/camera) or _avatarUrl (network).
  File? _avatarFile;
  String _avatarUrl = '';

  PaymentMethod _defaultPayment = PaymentMethod.card;
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.bg2,
      ),
    );
  }

  Future<void> _pickAvatarFromGallery() async {
    try {
      final picker = ImagePicker();
      final XFile? x = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        imageQuality: 85,
      );
      if (x != null) {
        setState(() {
          _avatarFile = File(x.path);
          _avatarUrl = '';
        });
        _snack('Photo updated from gallery');
      }
    } catch (e) {
      _snack('Failed to pick image');
    }
  }

  Future<void> _captureAvatarFromCamera() async {
    try {
      final picker = ImagePicker();
      final XFile? x = await picker.pickImage(
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
    } catch (e) {
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
              left: 16, right: 16,
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
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.12),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.cardBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.periwinkle, width: 1.4),
                      ),
                    ),
                    cursorColor: AppColors.periwinkle,
                    style: const TextStyle(color: Colors.white),
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
                        backgroundColor: AppColors.mint,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                      ),
                      child: Text(okLabel, style: const TextStyle(fontWeight: FontWeight.w800)),
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

  Future<void> _editPayment() async {
    PaymentMethod temp = _defaultPayment;
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return _GlassSheet(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _SheetHandle(title: 'Default payment'),
                RadioListTile<PaymentMethod>(
                  value: PaymentMethod.card,
                  groupValue: temp,
                  onChanged: (v) => setState(() => temp = v!),
                  title: const Text('Card', style: TextStyle(color: Colors.white)),
                  secondary: const Icon(Icons.credit_card, color: AppColors.periwinkle),
                  activeColor: AppColors.mint,
                ),
                RadioListTile<PaymentMethod>(
                  value: PaymentMethod.wallet,
                  groupValue: temp,
                  onChanged: (v) => setState(() => temp = v!),
                  title: const Text('Wallet', style: TextStyle(color: Colors.white)),
                  secondary: const Icon(Icons.account_balance_wallet, color: AppColors.mint),
                  activeColor: AppColors.mint,
                ),
                RadioListTile<PaymentMethod>(
                  value: PaymentMethod.cash,
                  groupValue: temp,
                  onChanged: (v) => setState(() => temp = v!),
                  title: const Text('Cash', style: TextStyle(color: Colors.white)),
                  secondary: const Icon(Icons.payments, color: AppColors.tangerine),
                  activeColor: AppColors.mint,
                ),

                // Wallet & Payments shortcut (opens new screen by route)
                ListTile(
                  leading: const Icon(Icons.account_balance_wallet),
                  title: const Text('Wallet & Payments'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(sheetCtx); // close sheet first
                    // then open wallet screen
                    Future.microtask(() => Navigator.pushNamed(context, Routes.wallet));
                  },
                ),

                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() => _defaultPayment = temp);
                      Navigator.pop(sheetCtx);
                      _snack('Default payment updated');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.mint,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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

  // ------------------------------- BUILD (scrollable main) ------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true, // keyboard/small screens friendly
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Gradient backdrop
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.bg1, AppColors.bg2, AppColors.bg3],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          // Soft blobs (now tinted for pop)
          Positioned(top: -70, left: -30, child: _blurBlob(200, AppColors.cyanGlow.withOpacity(0.10))),
          Positioned(bottom: -60, right: -20, child: _blurBlob(220, AppColors.periwinkle.withOpacity(0.12))),

          // Content (ListView → scroll enabled)
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
                            : const AssetImage('assets/images/driver_avatar.png') as ImageProvider),
                    onEditName: () => _editTextField(
                      title: 'Edit name',
                      initial: _name,
                      hint: 'Full name',
                      okLabel: 'Save',
                      fieldKey: 'name',
                      validator: (v) => v.isEmpty ? 'Required' : (v.length < 3 ? 'Too short' : null),
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
                        if (!RegExp(r'^\+?\d{10,15}$').hasMatch(cleaned)) return 'Invalid phone';
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
                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(v)) return 'Invalid email';
                        return null;
                      },
                      onSaved: (v) => setState(() => _email = v),
                    ),
                    onTapAvatar: () {
                      // Quick sheet with camera + gallery + reset
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        builder: (_) => _GlassSheet(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
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
                                      backgroundColor: AppColors.tangerine,
                                      foregroundColor: Colors.black,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                                      backgroundColor: AppColors.periwinkle,
                                      foregroundColor: Colors.black,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                                      foregroundColor: Colors.white,
                                      side: const BorderSide(color: AppColors.periwinkle, width: 1),
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    onLongPressAvatar: () {}, // not needed now (sheet opens on tap)
                  ),
                  const SizedBox(height: 14),

                  // Payment (compact)
                  _GlassCard(
                    child: Column(
                      children: [
                        const _SectionTitle('Default payment'),
                        ListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                          leading: const Icon(Icons.account_balance_wallet, color: AppColors.mint),
                          title: const Text(
                            'Wallet / Card / Cash (select below)',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            _defaultPayment.label,
                            style: TextStyle(color: Colors.white.withOpacity(0.9)),
                          ),
                          trailing: const Icon(Icons.chevron_right, color: Colors.white),
                          onTap: _editPayment,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Saved places (show only first 2 to keep height short)
                  _GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _SectionTitle('Saved places'),
                        ..._places.take(2).map((p) => ListTile(
                              dense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                              leading: const Icon(Icons.location_on, color: AppColors.periwinkle),
                              title: Text(p.label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                              subtitle: Text(p.address, style: TextStyle(color: Colors.white.withOpacity(0.92))),
                            )),
                        const Divider(height: 1, color: AppColors.cardBorder),
                        ListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                          leading: const Icon(Icons.edit_location_alt, color: AppColors.mint),
                          title: const Text('Manage places', style: TextStyle(color: Colors.white)),
                          trailing: const Icon(Icons.chevron_right, color: Colors.white),
                          onTap: _managePlaces,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Account
                  _GlassCard(
                    child: Column(
                      children: [
                        const _SectionTitle('Account'),
                        ListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                          leading: const Icon(Icons.account_balance_wallet, color: AppColors.mint),
                          title: const Text('Wallet & Payments', style: TextStyle(color: Colors.white)),
                          trailing: const Icon(Icons.chevron_right, color: Colors.white),
                          onTap: () => Navigator.pushNamed(context, Routes.wallet),
                        ),
                        ListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                          leading: const Icon(Icons.logout, color: AppColors.tangerine),
                          title: const Text('Log out', style: TextStyle(color: Colors.white)),
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
  });

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Row(
        children: [
          Stack(
            children: [
              GestureDetector(
                onTap: onTapAvatar,
                onLongPress: onLongPressAvatar,
                child: CircleAvatar(
                  radius: 34,
                  backgroundColor: Colors.white.withOpacity(0.14),
                  backgroundImage: avatarProvider,
                ),
              ),
              Positioned(
                bottom: 0, right: 0,
                child: InkWell(
                  onTap: onTapAvatar,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.periwinkle,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 8, offset: const Offset(0, 3)),
                      ],
                    ),
                    child: const Icon(Icons.edit, size: 16, color: Colors.black),
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
                _EditRow(label: 'Name',  value: name,  onTap: onEditName),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Text(label, style: TextStyle(color: Colors.white.withOpacity(0.75))),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
              ),
            ),
            const Icon(Icons.edit, size: 16, color: Colors.white),
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.cardGlass,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.cardBorder, width: 1.2),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 18, offset: const Offset(0, 8)),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 6),
      child: Row(
        children: [
          Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.mint, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.3,
              fontSize: 16,
            ),
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
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.sheetTint,
            border: const Border(top: BorderSide(color: AppColors.cardBorder)),
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
    return Column(
      children: [
        Container(
          width: 44, height: 5,
          decoration: BoxDecoration(
            color: AppColors.periwinkle.withOpacity(0.9),
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        const SizedBox(height: 10),
        Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
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
            left: 16, right: 16,
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
                  style: const TextStyle(color: Colors.white),
                  decoration: _fld('Label (e.g., Home, Gym)'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: addrCtl,
                  style: const TextStyle(color: Colors.white),
                  decoration: _fld('Address / landmark'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (!formKey.currentState!.validate()) return;
                      final item = SavedPlace(label: labelCtl.text.trim(), address: addrCtl.text.trim());
                      setState(() {
                        if (existing == null) {
                          _items.add(item);
                        } else {
                          _items[index!] = item;
                        }
                      });
                      Navigator.pop(context); // close inner sheet
                      Navigator.pop(context); // close places list
                      widget.onChanged(_items);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.mint,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text(existing == null ? 'Add' : 'Save', style: const TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static InputDecoration _fld(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.periwinkle, width: 1.4),
        ),
      );

  @override
  Widget build(BuildContext context) {
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
                leading: const Icon(Icons.location_on, color: AppColors.periwinkle),
                title: Text(p.label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                subtitle: Text(p.address, style: TextStyle(color: Colors.white.withOpacity(0.92))),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Edit',
                      onPressed: () => _addOrEdit(existing: p, index: i),
                      icon: const Icon(Icons.edit, color: Colors.white),
                    ),
                    IconButton(
                      tooltip: 'Delete',
                      onPressed: () => setState(() => _items.removeAt(i)),
                      icon: const Icon(Icons.delete_outline, color: Colors.white),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.add_location_alt, color: AppColors.mint),
                label: const Text('Add place', style: TextStyle(color: Colors.white)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.mint, width: 1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

enum PaymentMethod { card, wallet, cash }
extension on PaymentMethod {
  String get label => switch (this) {
        PaymentMethod.card => 'Easypaisa',
        PaymentMethod.wallet => 'JazzCash',
        PaymentMethod.cash => 'Cash',
      };
}

class SavedPlace {
  final String label;
  final String address;
  SavedPlace({required this.label, required this.address});
}
