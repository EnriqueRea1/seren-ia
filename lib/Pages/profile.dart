import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

// Paleta de colores consistente
const Color bgColor = Color(0xFF3B82F6);
const Color cardBgColor = Color(0xFF60A5FA);
const Color primaryTextColor = Colors.white;
const Color secondaryTextColor = Color(0xFFDDEAFF);
const Color accentColor = Color(0xFF93C5FD);
const Color accentColorLight = Color(0xFFBFDBFE);

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _groupController;
  late TextEditingController _classController;
  
  String? _selectedGender;
  bool _isEditing = false;
  bool _isLoading = true;
  String? _email;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _ageController = TextEditingController();
    _groupController = TextEditingController();
    _classController = TextEditingController();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    if (user == null) return;

    setState(() {
      _email = user.email;
    });

    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        _nameController.text = data['name'] ?? '';
        _ageController.text = data['age']?.toString() ?? '';
        _groupController.text = data['group'] ?? '';
        _classController.text = data['class'] ?? '';
        _selectedGender = data['gender'];
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      await _firestore.collection('users').doc(user.uid).update({
        'name': _nameController.text.trim(),
        'age': _ageController.text.trim().isNotEmpty ? int.tryParse(_ageController.text.trim()) : null,
        'group': _groupController.text.trim(),
        'class': _classController.text.trim(),
        'gender': _selectedGender,
      });

      // Actualizar nombre en Auth si es diferente
      if (user.displayName != _nameController.text.trim()) {
        await user.updateDisplayName(_nameController.text.trim());
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Perfil actualizado correctamente'),
          backgroundColor: cardBgColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar: $e'),
          backgroundColor: Colors.red[400],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
        _isEditing = false;
      });
    }
  }

  Future<void> _signOut() async {
    try {
      await _auth.signOut();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, 'login', (route) => false);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cerrar sesión: $e'),
          backgroundColor: Colors.red[400],
        ),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _groupController.dispose();
    _classController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [bgColor, cardBgColor.withOpacity(0.8)],
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () {
                          Navigator.pop(context); // Esto regresará a la página anterior
                        },
                        icon: Icon(
                          Icons.arrow_back_rounded,
                          color: primaryTextColor,
                          size: 24,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      Text(
                        'Mi Perfil',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: primaryTextColor,
                        ),
                      ),
                      IconButton(
                        onPressed: _signOut,
                        icon: Icon(
                          Icons.logout_rounded,
                          color: primaryTextColor,
                          size: 24,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Avatar y nombre
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: accentColorLight.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            Icons.person_outline,
                            size: 28,
                            color: primaryTextColor,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isLoading ? 'Cargando...' : _nameController.text,
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: primaryTextColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                _email ?? 'correo@ejemplo.com',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: secondaryTextColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Contenido
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
                ),
                padding: const EdgeInsets.all(24),
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: accentColor,
                        ),
                      )
                    : SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Botón de edición
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                onPressed: () {
                                  setState(() => _isEditing = !_isEditing);
                                },
                                icon: Icon(
                                  _isEditing ? Icons.close_rounded : Icons.edit_rounded,
                                  size: 18,
                                  color: _isEditing ? Colors.red : accentColor,
                                ),
                                label: Text(
                                  _isEditing ? 'Cancelar' : 'Editar perfil',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: _isEditing ? Colors.red : accentColor,
                                  ),
                                ),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    side: BorderSide(
                                      color: _isEditing ? Colors.red : accentColor,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Campos del perfil
                            _buildProfileField(
                              icon: Icons.person_outline,
                              label: 'Nombre completo',
                              controller: _nameController,
                              isEditable: _isEditing,
                            ),
                            
                            _buildProfileField(
                              icon: Icons.email_outlined,
                              label: 'Correo electrónico',
                              value: _email ?? 'No disponible',
                              isEditable: false,
                            ),
                            
                            _buildProfileField(
                              icon: Icons.calendar_today_outlined,
                              label: 'Edad',
                              controller: _ageController,
                              isEditable: _isEditing,
                              keyboardType: TextInputType.number,
                            ),
                            
                            // Selector de género
                            Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.wc,
                                    color: accentColor,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _isEditing
                                        ? DropdownButton<String>(
                                            value: _selectedGender,
                                            isExpanded: true,
                                            underline: const SizedBox(),
                                            style: GoogleFonts.poppins(
                                              color: bgColor,
                                              fontSize: 15,
                                            ),
                                            dropdownColor: Colors.white,
                                            items: [
                                              'Masculino',
                                              'Femenino',
                                              'Otro',
                                            ].map((String value) {
                                              return DropdownMenuItem<String>(
                                                value: value,
                                                child: Text(value),
                                              );
                                            }).toList(),
                                            onChanged: (newValue) {
                                              setState(() {
                                                _selectedGender = newValue;
                                              });
                                            },
                                          )
                                        : Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 16),
                                            child: Text(
                                              _selectedGender ?? 'No especificado',
                                              style: GoogleFonts.poppins(
                                                color: const Color(0xFF1E293B),
                                                fontSize: 15,
                                              ),
                                            ),
                                          ),
                                  ),
                                ],
                              ),
                            ),
                            
                            _buildProfileField(
                              icon: Icons.school_outlined,
                              label: 'Grupo/Clase',
                              controller: _groupController,
                              isEditable: _isEditing,
                            ),
                            
                            _buildProfileField(
                              icon: Icons.class_outlined,
                              label: 'Carrera',
                              controller: _classController,
                              isEditable: _isEditing,
                            ),
                            
                            const SizedBox(height: 32),
                            
                            if (_isEditing)
                              ElevatedButton(
                                onPressed: _isLoading ? null : _updateProfile,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: cardBgColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        'Guardar cambios',
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                          ],
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileField({
    required IconData icon,
    required String label,
    TextEditingController? controller,
    String? value,
    required bool isEditable,
    TextInputType? keyboardType,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: accentColor,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: isEditable && controller != null
                ? TextField(
                    controller: controller,
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF1E293B),
                      fontSize: 15,
                    ),
                    decoration: InputDecoration(
                      labelText: label,
                      labelStyle: GoogleFonts.poppins(
                        color: const Color(0xFF64748B),
                        fontSize: 12,
                      ),
                      border: InputBorder.none,
                    ),
                    keyboardType: keyboardType,
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF64748B),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          controller?.text ?? value ?? 'No especificado',
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF1E293B),
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
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
}