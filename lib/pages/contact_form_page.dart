import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/contact.dart';

class ContactFormPage extends StatefulWidget {
  final Contact? contact;

  const ContactFormPage({super.key, this.contact});

  @override
  State<ContactFormPage> createState() => _ContactFormPageState();
}

class _ContactFormPageState extends State<ContactFormPage> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref('contacts');

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late String _selectedCategory;
  bool _isLoading = false;

  final List<String> _categories = const [
    'Teman',
    'Keluarga',
    'Pekerjaan',
    'Umum',
  ];

  bool get _isEditMode => widget.contact != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.contact?.name ?? '');
    _phoneController = TextEditingController(text: widget.contact?.phone ?? '');
    _emailController = TextEditingController(text: widget.contact?.email ?? '');
    _addressController = TextEditingController(text: widget.contact?.address ?? '');
    _selectedCategory = widget.contact?.category ?? 'Teman';
    if (!_categories.contains(_selectedCategory)) {
      _selectedCategory = 'Umum';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _saveContact() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final contact = Contact(
      id: widget.contact?.id,
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      address: _addressController.text.trim(),
      category: _selectedCategory,
    );

    try {
      if (_isEditMode) {
        await _dbRef.child(widget.contact!.id!).update(contact.toMap());
      } else {
        await _dbRef.push().set(contact.toMap());
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan: $e'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditMode ? 'Edit Kontak' : 'Tambah Kontak Baru',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              // Header Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withAlpha(80),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.colorScheme.primary.withAlpha(40),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: theme.colorScheme.primary,
                      child: Icon(
                        _isEditMode ? Icons.edit : Icons.person_add_alt_1,
                        color: theme.colorScheme.onPrimary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isEditMode ? 'Perbarui Informasi' : 'Informasi Kontak',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _isEditMode
                                ? 'Ubah detail data kontak yang dipilih.'
                                : 'Lengkapi data kontak untuk disimpan ke database.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Category Selector
              Text(
                'Kategori Kontak',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _categories.map((category) {
                  final isSelected = _selectedCategory == category;
                  return ChoiceChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedCategory = category);
                      }
                    },
                    selectedColor: theme.colorScheme.primaryContainer,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    avatar: isSelected
                        ? Icon(Icons.check, size: 16, color: theme.colorScheme.primary)
                        : null,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Form Inputs
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Nama Lengkap',
                  hintText: 'Contoh: Ahmad Wildan',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  prefixIcon: const Icon(Icons.person_outline),
                ),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Nama wajib diisi' : null,
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Nomor Telepon',
                  hintText: 'Contoh: 08123456789',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  prefixIcon: const Icon(Icons.phone_outlined),
                ),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Nomor telepon wajib diisi' : null,
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  hintText: 'Contoh: user@domain.com',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  prefixIcon: const Icon(Icons.email_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Email wajib diisi';
                  if (!value.contains('@') || !value.contains('.')) {
                    return 'Format email tidak valid';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _addressController,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: 'Alamat',
                  hintText: 'Contoh: Jl. Merdeka No. 10, Jakarta',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  prefixIcon: const Icon(Icons.location_on_outlined),
                  alignLabelWithHint: true,
                ),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Alamat wajib diisi' : null,
              ),
              const SizedBox(height: 28),

              FilledButton.icon(
                onPressed: _isLoading ? null : _saveContact,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_rounded),
                label: Text(
                  _isLoading
                      ? 'Menyimpan...'
                      : (_isEditMode ? 'Simpan Perubahan' : 'Simpan Kontak'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
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
