import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class QualificationFormWidget extends StatefulWidget {
  final Function(Map<String, dynamic>) onAdd;
  final List<Map<String, dynamic>> qualificationList;
  final Function(int) onRemove;

  const QualificationFormWidget({
    super.key,
    required this.onAdd,
    required this.qualificationList,
    required this.onRemove,
  });

  @override
  State<QualificationFormWidget> createState() =>
      _QualificationFormWidgetState();
}

class _QualificationFormWidgetState extends State<QualificationFormWidget> {
  final _institutionController = TextEditingController();
  final _specializationController = TextEditingController();
  final _certificationController = TextEditingController();
  final _yearController = TextEditingController();

  bool _isExpanded = false;

  void _clearForm() {
    _institutionController.clear();
    _specializationController.clear();
    _certificationController.clear();
    _yearController.clear();
  }

  void _addQualification() {
    // All fields are optional, but we should have at least one field filled
    if (_institutionController.text.trim().isEmpty &&
        _specializationController.text.trim().isEmpty &&
        _certificationController.text.trim().isEmpty &&
        _yearController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in at least one field'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final qualification = <String, dynamic>{};

    if (_institutionController.text.trim().isNotEmpty) {
      qualification['institution'] = _institutionController.text.trim();
    }
    if (_specializationController.text.trim().isNotEmpty) {
      qualification['specialization'] = _specializationController.text.trim();
    }
    if (_certificationController.text.trim().isNotEmpty) {
      qualification['certification'] = _certificationController.text.trim();
    }
    if (_yearController.text.trim().isNotEmpty) {
      final year = int.tryParse(_yearController.text.trim());
      if (year != null) {
        qualification['year_obtained'] = year;
      }
    }

    widget.onAdd(qualification);
    _clearForm();
    setState(() {
      _isExpanded = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Qualification added'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  void dispose() {
    _institutionController.dispose();
    _specializationController.dispose();
    _certificationController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Display added qualification records
        if (widget.qualificationList.isNotEmpty) ...[
          ...widget.qualificationList.asMap().entries.map((entry) {
            final index = entry.key;
            final qual = entry.value;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.secondaryContainer,
                  child: Icon(
                    Icons.workspace_premium,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
                title: Text(
                  qual['certification'] ??
                      qual['specialization'] ??
                      'Qualification',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (qual['institution'] != null)
                      Text('Institution: ${qual['institution']}'),
                    if (qual['specialization'] != null)
                      Text('Specialization: ${qual['specialization']}'),
                    if (qual['certification'] != null)
                      Text('Certification: ${qual['certification']}'),
                    if (qual['year_obtained'] != null)
                      Text('Year: ${qual['year_obtained']}'),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => widget.onRemove(index),
                ),
              ),
            );
          }).toList(),
          const SizedBox(height: 16),
        ],

        // Add new qualification form
        Card(
          child: ExpansionTile(
            title: const Text('Add Qualification (Optional)'),
            leading: const Icon(Icons.add_circle_outline),
            initiallyExpanded: _isExpanded,
            onExpansionChanged: (expanded) {
              setState(() {
                _isExpanded = expanded;
              });
            },
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'All fields are optional. Add any certifications, licenses, or qualifications.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _institutionController,
                      decoration: const InputDecoration(
                        labelText: 'Institution',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.business),
                        hintText: 'Certifying organization',
                      ),
                      maxLength: 150,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _specializationController,
                      decoration: const InputDecoration(
                        labelText: 'Specialization',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.star),
                        hintText: 'Area of specialization',
                      ),
                      maxLength: 100,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _certificationController,
                      decoration: const InputDecoration(
                        labelText: 'Certification',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.verified),
                        hintText: 'Certification name',
                      ),
                      maxLength: 150,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _yearController,
                      decoration: const InputDecoration(
                        labelText: 'Year Obtained',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                        hintText: '2020',
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _clearForm,
                            child: const Text('Clear'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _addQualification,
                            icon: const Icon(Icons.add),
                            label: const Text('Add'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
