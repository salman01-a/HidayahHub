import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Import Image Picker
import '../../controllers/auth_controller.dart';
import '../../models/user.dart';
import '../../services/session_service.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileView extends StatefulWidget {
  final String userName;
  final VoidCallback onUpdate;
  const ProfileView({
    super.key,
    required this.userName,
    required this.onUpdate,
  });

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final email = await SessionService.instance.getLastEmail();
    if (email != null) {
      final user = await AuthController.instance.getUserByEmail(email);
      if (mounted) setState(() => _currentUser = user);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        _buildUserHeader(),
        const SizedBox(height: 24),
        _MenuItem(
          icon: Icons.manage_accounts_rounded,
          title: 'Pengaturan Akun',
          subtitle: 'Ubah foto, username, email, dan password',
          onTap: () => _navigateToEdit(context),
        ),
        const SizedBox(height: 12),
        _MenuItem(
          icon: Icons.support_agent_rounded,
          title: 'Pusat Bantuan',
          subtitle: 'Hubungi tim pengembang via WhatsApp',
          onTap: () => _showHelpCenter(context),
        ),
      ],
    );
  }

  Widget _buildUserHeader() {
    final path = _currentUser?.profilePath ?? 'assets/profile/default.png';
    final imageProvider = path.startsWith('assets/')
        ? AssetImage(path) as ImageProvider
        : FileImage(File(path));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.grey.shade200,
            backgroundImage: imageProvider,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Username',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                Text(
                  widget.userName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToEdit(BuildContext context) async {
    if (_currentUser != null && context.mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => EditProfilePage(user: _currentUser!)),
      );
      await _loadUser();
      widget.onUpdate();
    }
  }

  void _showHelpCenter(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => HelpCenterSheet(userName: widget.userName),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      tileColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: const Color(0xFF0F5A4E)),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.chevron_right_rounded),
    );
  }
}

class EditProfilePage extends StatefulWidget {
  final UserModel user;
  const EditProfilePage({super.key, required this.user});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _passController;
  bool _loading = false;
  bool _obscurePassword = true;

  File? _selectedImage; // State untuk gambar dari galeri

  static const Color _deepTeal = Color(0xFF0F5A4E);
  static const Color _primaryTeal = Color(0xFF1A7F6D);
  static const Color _accentGold = Color(0xFFCBA052);
  static const Color _bgSoft = Color(0xFFF8FAFB);

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _emailController = TextEditingController(text: widget.user.email);
    _passController = TextEditingController();
  }

  // Fungsi ambil gambar dari galeri
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  void _showSnackBar(String msg, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.redAccent : _primaryTeal,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _save() async {
    String name = _nameController.text.trim();
    String email = _emailController.text.trim();
    String password = _passController.text.trim();

    if (name.isEmpty || email.isEmpty) {
      _showSnackBar("Nama dan Email tidak boleh kosong");
      return;
    }

    setState(() => _loading = true);

    // Sisipkan _selectedImage?.path ke parameter profilePath
    final res = await AuthController.instance.updateProfile(
      id: widget.user.id!,
      name: name,
      email: email,
      password: password,
      profilePath: _selectedImage?.path ?? widget.user.profilePath,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (res['success']) {
      await SessionService.instance.saveLoginSession(userName: name);
      if (mounted) {
        _showSnackBar(res['message'], isError: false);
        Navigator.pop(context);
      }
    } else {
      _showSnackBar(res['message']);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgSoft,
      appBar: AppBar(
        title: const Text(
          'Edit Profil',
          style: TextStyle(fontWeight: FontWeight.w900, color: _deepTeal),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: _deepTeal,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Center(
              child: GestureDetector(
                onTap: _pickImage, // Trigger ganti gambar saat diketuk
                child: Stack(
                  children: [
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(
                          color: _primaryTeal.withOpacity(0.2),
                          width: 4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _primaryTeal.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                        image: DecorationImage(
                          image: _selectedImage != null
                              ? FileImage(_selectedImage!) as ImageProvider
                              : (widget.user.profilePath.startsWith('assets/')
                                    ? AssetImage(widget.user.profilePath)
                                    : FileImage(File(widget.user.profilePath))),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: _accentGold,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            _customField(
              controller: _nameController,
              label: "Username",
              icon: Icons.person_outline_rounded,
            ),
            const SizedBox(height: 18),
            _customField(
              controller: _emailController,
              label: "Email",
              icon: Icons.email_outlined,
              readOnly: true,
            ),
            const SizedBox(height: 18),
            _customField(
              controller: _passController,
              label: "Password Baru",
              icon: Icons.lock_outline_rounded,
              isPassword: true,
              hint: "Kosongkan jika tidak ingin diubah",
            ),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 58,
              child: ElevatedButton(
                onPressed: _loading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryTeal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        "SIMPAN PERUBAHAN",
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _customField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool readOnly = false,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: _deepTeal,
              fontSize: 14,
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          obscureText: isPassword ? _obscurePassword : false,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: readOnly ? Colors.grey : _deepTeal,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 13,
              fontWeight: FontWeight.normal,
            ),
            prefixIcon: Icon(icon, color: _primaryTeal, size: 22),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: _accentGold,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  )
                : null,
            filled: true,
            fillColor: readOnly ? Colors.grey.shade100 : Colors.white,
            contentPadding: const EdgeInsets.all(20),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: _primaryTeal, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

// Biarkan kelas HelpCenterSheet sesuai bawaan
class HelpCenterSheet extends StatelessWidget {
  final String userName;
  const HelpCenterSheet({super.key, required this.userName});

  Future<void> _launchWhatsApp(String phone) async {
    String formattedPhone = phone.startsWith('0')
        ? '62${phone.substring(1)}'
        : phone;
    final String message =
        "Halo, saya pengguna Hidayah Hub dengan username=$userName hendak meminta bantuan dari tim pengembang terkait...";
    final Uri url = Uri.parse(
      "https://wa.me/$formattedPhone?text=${Uri.encodeComponent(message)}",
    );
    if (!await launchUrl(url, mode: LaunchMode.externalApplication))
      throw Exception('Tidak bisa membuka WhatsApp $url');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'Silakan hubungi kontak berikut:',
            style: TextStyle(color: Color(0xFF5E6D7E)),
          ),
          const SizedBox(height: 16),
          _whatsappItem('Salman Faris', '085339167818'),
          const SizedBox(height: 14),
          _whatsappItem('Reza Rasendriya Adi Putra', '081227213841'),
        ],
      ),
    );
  }

  Widget _whatsappItem(String name, String phone) {
    return InkWell(
      onTap: () => _launchWhatsApp(phone),
      child: ListTile(
        leading: const FaIcon(
          FontAwesomeIcons.whatsapp,
          color: Color(0xFF25D366),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(phone),
      ),
    );
  }
}
