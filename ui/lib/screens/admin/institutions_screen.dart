import 'package:flutter/material.dart';
import '../../models/institution.dart';
import '../../models/district.dart';
import '../../services/institution_service.dart';
import '../../services/district_service.dart';

class AdminInstitutionsScreen extends StatefulWidget {
  const AdminInstitutionsScreen({super.key});

  @override
  State<AdminInstitutionsScreen> createState() =>
      _AdminInstitutionsScreenState();
}

class _AdminInstitutionsScreenState extends State<AdminInstitutionsScreen> {
  final InstitutionService _institutionService = InstitutionService();
  final DistrictService _districtService = DistrictService();

  List<Institution> _institutions = [];
  List<District> _districts = [];
  bool _isLoading = true;
  String? _error;

  // Filters
  int? _filterDistrictId;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final institutionsResult = await _institutionService.fetchInstitutions();
      final districtsResult = await _districtService.fetchDistricts();

      setState(() {
        _institutions = institutionsResult['institutions'] as List<Institution>;
        _districts = districtsResult['districts'] as List<District>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Institution> get _filteredInstitutions {
    var filtered = _institutions;

    // Apply district filter
    if (_filterDistrictId != null) {
      filtered = filtered
          .where((inst) => inst.districtId == _filterDistrictId)
          .toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((inst) =>
              inst.name.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    return filtered;
  }

  Future<void> _showAddInstitutionDialog() async {
    final nameController = TextEditingController();
    final typeController = TextEditingController();
    int? selectedDistrictId;
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add New Institution'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Institution Name *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter an institution name';
                      }
                      if (value.length > 200) {
                        return 'Name must not exceed 200 characters';
                      }
                      return null;
                    },
                    autofocus: true,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: selectedDistrictId,
                    decoration: const InputDecoration(
                      labelText: 'District (Optional)',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<int>(
                        value: null,
                        child: Text('-- None --'),
                      ),
                      ..._districts.map((district) {
                        return DropdownMenuItem<int>(
                          value: district.id,
                          child: Text(district.name),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setDialogState(() => selectedDistrictId = value);
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: typeController,
                    decoration: const InputDecoration(
                      labelText: 'Institution Type (Optional)',
                      border: OutlineInputBorder(),
                      hintText: 'e.g., Primary, Secondary, University',
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  Navigator.of(context).pop(true);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );

    if (result == true && mounted) {
      try {
        await _institutionService.createInstitution(
          name: nameController.text.trim(),
          districtId: selectedDistrictId,
          institutionType: typeController.text.trim().isNotEmpty
              ? typeController.text.trim()
              : null,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Institution added successfully'),
              backgroundColor: Colors.green,
            ),
          );
          _loadData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error adding institution: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _confirmDelete(Institution institution) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text(
          'Are you sure you want to delete "${institution.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await _institutionService.deleteInstitution(institution.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Institution deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          _loadData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting institution: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  String _getDistrictName(int? districtId) {
    if (districtId == null) return 'No district assigned';
    final district =
        _districts.where((d) => d.id == districtId).firstOrNull;
    return district?.name ?? 'Unknown District';
  }

  @override
  Widget build(BuildContext context) {
    final filteredInstitutions = _filteredInstitutions;

    return Scaffold(
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.school,
                      size: 32,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Institutions Management',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Manage educational institutions',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                              color:
                                  Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: _showAddInstitutionDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Institution'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Search and Filter Bar
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search institutions...',
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
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (value) {
                          setState(() => _searchQuery = value);
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<int?>(
                        value: _filterDistrictId,
                        decoration: const InputDecoration(
                          labelText: 'Filter by District',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('All Districts'),
                          ),
                          ..._districts.map((district) {
                            return DropdownMenuItem<int?>(
                              value: district.id,
                              child: Text(district.name),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          setState(() => _filterDistrictId = value);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Error loading institutions',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _error!,
                              style: Theme.of(context).textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              onPressed: _loadData,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : filteredInstitutions.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.school_outlined,
                                  size: 64,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _institutions.isEmpty
                                      ? 'No institutions found'
                                      : 'No matching institutions',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _institutions.isEmpty
                                      ? 'Add your first institution to get started'
                                      : 'Try adjusting your filters',
                                  style:
                                      Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 16),
                                if (_institutions.isEmpty)
                                  FilledButton.icon(
                                    onPressed: _showAddInstitutionDialog,
                                    icon: const Icon(Icons.add),
                                    label: const Text('Add Institution'),
                                  ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadData,
                            child: ListView(
                              padding: const EdgeInsets.all(24),
                              children: [
                                // Stats Cards
                                Row(
                                  children: [
                                    Expanded(
                                      child: Card(
                                        child: Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.analytics_outlined,
                                                size: 32,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary,
                                              ),
                                              const SizedBox(width: 16),
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Total',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodyMedium,
                                                  ),
                                                  Text(
                                                    '${_institutions.length}',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .headlineMedium
                                                        ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Card(
                                        child: Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.filter_list,
                                                size: 32,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .secondary,
                                              ),
                                              const SizedBox(width: 16),
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Filtered',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodyMedium,
                                                  ),
                                                  Text(
                                                    '${filteredInstitutions.length}',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .headlineMedium
                                                        ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),

                                // Institutions List
                                ...filteredInstitutions.map((institution) {
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: Theme.of(context)
                                            .colorScheme
                                            .primaryContainer,
                                        child: Icon(
                                          Icons.school,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onPrimaryContainer,
                                        ),
                                      ),
                                      title: Text(
                                        institution.name,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.location_city,
                                                size: 14,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                _getDistrictName(
                                                    institution.districtId),
                                              ),
                                            ],
                                          ),
                                          if (institution.institutionType !=
                                              null) ...[
                                            const SizedBox(height: 2),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.category,
                                                  size: 14,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(institution.institutionType!),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.delete_outline),
                                        color:
                                            Theme.of(context).colorScheme.error,
                                        onPressed: () =>
                                            _confirmDelete(institution),
                                        tooltip: 'Delete institution',
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
