import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/contact.dart';
import 'contact_form_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref('contacts');
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategoryFilter = 'Semua';

  final List<String> _categoryFilters = const [
    'Semua',
    'Teman',
    'Keluarga',
    'Pekerjaan',
    'Umum',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openForm({Contact? contact}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ContactFormPage(contact: contact),
      ),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                contact == null
                    ? 'Kontak berhasil ditambahkan'
                    : 'Kontak berhasil diperbarui',
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _deleteContact(String id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.delete_outline, color: Colors.red.shade700, size: 24),
            ),
            const SizedBox(width: 12),
            const Text('Hapus Kontak'),
          ],
        ),
        content: Text('Yakin ingin menghapus "$name" dari buku alamat?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade600,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _dbRef.child(id).remove();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('"$name" berhasil dihapus'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal menghapus: $e'),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Color _getAvatarColor(String name) {
    const colors = [
      Color(0xFF2563EB), // Blue
      Color(0xFF7C3AED), // Purple
      Color(0xFF059669), // Emerald
      Color(0xFFD97706), // Amber
      Color(0xFFDC2626), // Red
      Color(0xFF0891B2), // Cyan
      Color(0xFFDB2777), // Pink
      Color(0xFF4F46E5), // Indigo
    ];
    if (name.isEmpty) return colors[0];
    final hash = name.codeUnits.reduce((a, b) => a + b);
    return colors[hash % colors.length];
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Keluarga':
        return Colors.purple;
      case 'Teman':
        return Colors.teal;
      case 'Pekerjaan':
        return Colors.indigo;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.contacts_rounded),
            SizedBox(width: 10),
            Text('Buku Alamat', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(116),
          child: Column(
            children: [
              // Search input
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari nama, nomor, atau email...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest.withAlpha(120),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value.toLowerCase().trim());
                  },
                ),
              ),
              const SizedBox(height: 8),

              // Horizontal Category Chips
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _categoryFilters.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final cat = _categoryFilters[index];
                    final isSelected = _selectedCategoryFilter == cat;
                    return FilterChip(
                      label: Text(cat),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() => _selectedCategoryFilter = cat);
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      showCheckmark: false,
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: _dbRef.onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 12),
                    Text(
                      'Terjadi kesalahan saat memuat data:\n${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withAlpha(60),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.contacts_outlined,
                        size: 72,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Buku Alamat Masih Kosong',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Belum ada data kontak tersimpan.\nTekan tombol di bawah untuk menambahkan.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: () => _openForm(),
                      icon: const Icon(Icons.person_add_alt_1),
                      label: const Text('Tambah Kontak Pertama'),
                    ),
                  ],
                ),
              ),
            );
          }

          final data = snapshot.data!.snapshot.value;
          final List<Contact> contacts = [];

          if (data is Map) {
            data.forEach((key, value) {
              if (value is Map) {
                contacts.add(Contact.fromMap(key.toString(), value));
              }
            });
          }

          // Filter by category
          final categoryFiltered = contacts.where((c) {
            if (_selectedCategoryFilter == 'Semua') return true;
            return c.category == _selectedCategoryFilter;
          }).toList();

          // Filter by search query
          final filteredContacts = categoryFiltered.where((c) {
            if (_searchQuery.isEmpty) return true;
            return c.name.toLowerCase().contains(_searchQuery) ||
                c.phone.toLowerCase().contains(_searchQuery) ||
                c.email.toLowerCase().contains(_searchQuery) ||
                c.address.toLowerCase().contains(_searchQuery);
          }).toList();

          // Sort A-Z by name
          filteredContacts.sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );

          if (filteredContacts.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.search_off_rounded,
                      size: 64,
                      color: theme.colorScheme.outline,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Tidak ada kontak ditemukan',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Coba kata kunci pencarian atau kategori lain.',
                      style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            itemCount: filteredContacts.length,
            itemBuilder: (context, index) {
              final contact = filteredContacts[index];
              final avatarColor = _getAvatarColor(contact.name);
              final categoryColor = _getCategoryColor(contact.category);

              return Card(
                elevation: 1,
                margin: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: theme.colorScheme.outlineVariant.withAlpha(80),
                  ),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _openForm(contact: contact),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header: Avatar, Name, Category chip, Menu
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: avatarColor.withAlpha(40),
                              child: Text(
                                contact.name.isNotEmpty
                                    ? contact.name[0].toUpperCase()
                                    : '?',
                                style: TextStyle(
                                  color: avatarColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          contact.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: categoryColor.withAlpha(25),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: categoryColor.withAlpha(80),
                                          ),
                                        ),
                                        child: Text(
                                          contact.category,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: categoryColor,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  GestureDetector(
                                    onTap: () {
                                      Clipboard.setData(ClipboardData(text: contact.phone));
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Nomor ${contact.phone} disalin'),
                                          duration: const Duration(seconds: 1),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    },
                                    child: Row(
                                      children: [
                                        Icon(Icons.phone_rounded,
                                            size: 14, color: theme.colorScheme.primary),
                                        const SizedBox(width: 4),
                                        Text(
                                          contact.phone,
                                          style: TextStyle(
                                            color: theme.colorScheme.primary,
                                            fontWeight: FontWeight.w500,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Icon(Icons.copy_rounded,
                                            size: 12,
                                            color: theme.colorScheme.primary.withAlpha(120)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              onSelected: (value) {
                                if (value == 'edit') {
                                  _openForm(contact: contact);
                                } else if (value == 'delete') {
                                  _deleteContact(contact.id!, contact.name);
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit_outlined,
                                          color: Colors.blue, size: 20),
                                      SizedBox(width: 10),
                                      Text('Edit Kontak'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete_outline,
                                          color: Colors.red, size: 20),
                                      SizedBox(width: 10),
                                      Text('Hapus',
                                          style: TextStyle(color: Colors.red)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const Divider(height: 16),
                        // Email & Address
                        Row(
                          children: [
                            Icon(Icons.email_outlined,
                                size: 14, color: theme.colorScheme.onSurfaceVariant),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                contact.email,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.location_on_outlined,
                                size: 14, color: theme.colorScheme.onSurfaceVariant),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                contact.address,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Tambah Kontak'),
      ),
    );
  }
}
