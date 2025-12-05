import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/loading_widget.dart';

/// Pantalla de edición de perfil
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();
  final _locationController = TextEditingController();
  final _birthDateController = TextEditingController();

  File? _imageFile;
  bool _isLoading = false;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final user = ref.read(currentUserProvider);
    if (user != null) {
      _nameController.text = user.name;
      _emailController.text = user.email;
      _phoneController.text = user.phone ?? '';
      _bioController.text = user.bio ?? '';
      _locationController.text = user.location ?? '';
      if (user.birthDate != null) {
        _selectedDate = user.birthDate;
        _birthDateController.text = _formatDate(user.birthDate!);
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Usuario no encontrado'),
        ),
      );
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Editar Perfil',
        showBackButton: true,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: const Text(
              'Guardar',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingWidget()
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Foto de perfil
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: AppColors.primary,
                          backgroundImage: _imageFile != null
                              ? FileImage(_imageFile!)
                              : user.profileImage != null
                                  ? NetworkImage(user.profileImage!)
                                  : null as ImageProvider?,
                          child: _imageFile == null && user.profileImage == null
                              ? Text(
                                  user.name[0].toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 40,
                                    color: Colors.white,
                                  ),
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: CircleAvatar(
                            backgroundColor: AppColors.primary,
                            radius: 20,
                            child: IconButton(
                              icon: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                              onPressed: _pickImage,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Información básica
                  _buildSectionTitle('INFORMACIÓN BÁSICA'),
                  const SizedBox(height: 16),

                  CustomTextField(
                    controller: _nameController,
                    label: 'Nombre completo',
                    prefixIcon: Icons.person,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingresa tu nombre';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  CustomTextField(
                    controller: _emailController,
                    label: 'Correo electrónico',
                    prefixIcon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                    enabled: false, // Email no se puede cambiar
                  ),

                  const SizedBox(height: 16),

                  CustomTextField(
                    controller: _phoneController,
                    label: 'Teléfono',
                    prefixIcon: Icons.phone,
                    keyboardType: TextInputType.phone,
                  ),

                  const SizedBox(height: 32),

                  // Información adicional
                  _buildSectionTitle('INFORMACIÓN ADICIONAL'),
                  const SizedBox(height: 16),

                  CustomTextField(
                    controller: _bioController,
                    label: 'Biografía',
                    prefixIcon: Icons.info,
                    maxLines: 3,
                    maxLength: 200,
                    hintText: 'Cuéntanos un poco sobre ti...',
                  ),

                  const SizedBox(height: 16),

                  CustomTextField(
                    controller: _locationController,
                    label: 'Ubicación',
                    prefixIcon: Icons.location_on,
                    hintText: 'Ciudad, País',
                  ),

                  const SizedBox(height: 16),

                  GestureDetector(
                    onTap: _selectDate,
                    child: AbsorbPointer(
                      child: CustomTextField(
                        controller: _birthDateController,
                        label: 'Fecha de nacimiento',
                        prefixIcon: Icons.cake,
                        hintText: 'DD/MM/AAAA',
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Preferencias
                  _buildSectionTitle('PREFERENCIAS'),
                  const SizedBox(height: 16),

                  SwitchListTile(
                    title: const Text('Perfil público'),
                    subtitle: const Text(
                      'Permitir que otros usuarios vean tu perfil',
                    ),
                    value: user.isPublicProfile ?? true,
                    onChanged: (value) {
                      // Actualizar preferencia
                    },
                    activeColor: AppColors.primary,
                  ),

                  SwitchListTile(
                    title: const Text('Recibir mensajes'),
                    subtitle: const Text(
                      'Permitir que otros usuarios te envíen mensajes',
                    ),
                    value: user.allowMessages ?? true,
                    onChanged: (value) {
                      // Actualizar preferencia
                    },
                    activeColor: AppColors.primary,
                  ),

                  const SizedBox(height: 32),

                  // Botón de eliminar cuenta
                  TextButton.icon(
                    onPressed: _deleteAccount,
                    icon: const Icon(Icons.delete_forever, color: Colors.red),
                    label: const Text(
                      'Eliminar cuenta',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),

                  const SizedBox(height: 50),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Colors.grey[600],
      ),
    );
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Cámara'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galería'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            if (_imageFile != null || ref.read(currentUserProvider)?.profileImage != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Eliminar foto', style: TextStyle(color: Colors.red)),
                onTap: () {
                  setState(() {
                    _imageFile = null;
                  });
                  Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
    );

    if (source != null) {
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _imageFile = File(image.path);
        });
      }
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 13)), // Mínimo 13 años
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _birthDateController.text = _formatDate(picked);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Aquí iría la lógica para actualizar el perfil
      await ref.read(authProvider.notifier).updateProfile(
        name: _nameController.text,
        phone: _phoneController.text.isEmpty ? null : _phoneController.text,
        bio: _bioController.text.isEmpty ? null : _bioController.text,
        location: _locationController.text.isEmpty ? null : _locationController.text,
        birthDate: _selectedDate,
        profileImage: _imageFile,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil actualizado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar el perfil: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar cuenta'),
        content: const Text(
          'Esta acción no se puede deshacer. Se eliminarán todos tus datos, incluidos tus cursos, progreso y contenido guardado.\n\n¿Estás seguro de que quieres eliminar tu cuenta?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Eliminar cuenta'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Pedir confirmación adicional con contraseña
      final password = await showDialog<String>(
        context: context,
        builder: (context) {
          final passwordController = TextEditingController();
          return AlertDialog(
            title: const Text('Confirmar eliminación'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Por seguridad, ingresa tu contraseña para confirmar:'),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Contraseña',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, passwordController.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: const Text('Confirmar'),
              ),
            ],
          );
        },
      );

      if (password != null && password.isNotEmpty) {
        try {
          setState(() {
            _isLoading = true;
          });

          // await ref.read(authProvider.notifier).deleteAccount(password);

          if (mounted) {
            context.go('/login');
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error al eliminar la cuenta: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        } finally {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        }
      }
    }
  }
}