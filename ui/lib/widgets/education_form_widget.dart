import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EducationFormWidget extends StatefulWidget {
  final Function(Map<String, dynamic>) onAdd;
  final List<Map<String, dynamic>> educationList;
  final Function(int) onRemove;

  const EducationFormWidget({
    super.key,
    required this.onAdd,
    required this.educationList,
    required this.onRemove,
  });

  @override
  State<EducationFormWidget> createState() => _EducationFormWidgetState();
}

class _EducationFormWidgetState extends State<EducationFormWidget> {
  final _institutionController = TextEditingController();
  final _levelController = TextEditingController();
  final _programController = TextEditingController();
  final _degreeController = TextEditingController();
  final _yearController = TextEditingController();

  bool _isExpanded = false;

  void _clearForm() {
    _institutionController.clear();
    _levelController.clear();
    _programController.clear();
    _degreeController.clear();
    _yearController.clear();
  }

  void _addEducation() {
    if (_institutionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Institution name is required'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final education = {
      'institution': _institutionController.text.trim(),
      if (_levelController.text.trim().isNotEmpty)
        'level': _levelController.text.trim(),
      if (_programController.text.trim().isNotEmpty)
        'program': _programController.text.trim(),
      if (_degreeController.text.trim().isNotEmpty)
        'degree': _degreeController.text.trim(),
      if (_yearController.text.trim().isNotEmpty)
        'year_obtained': int.tryParse(_yearController.text.trim()),
    };

    widget.onAdd(education);
    _clearForm();
    setState(() {
      _isExpanded = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Education added'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  void dispose() {
    _institutionController.dispose();
    _levelController.dispose();
    _programController.dispose();
    _degreeController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Display added education records
        if (widget.educationList.isNotEmpty) ...[
          ...widget.educationList.asMap().entries.map((entry) {
            final index = entry.key;
            final edu = entry.value;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primaryContainer,
                  child: Icon(
                    Icons.school,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                title: Text(
                  edu['institution'] ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (edu['degree'] != null) Text('Degree: ${edu['degree']}'),
                    if (edu['program'] != null)
                      Text('Program: ${edu['program']}'),
                    if (edu['level'] != null) Text('Level: ${edu['level']}'),
                    if (edu['year_obtained'] != null)
                      Text('Year: ${edu['year_obtained']}'),
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

        // Add new education form
        Card(
          child: ExpansionTile(
            title: const Text('Add Education Record'),
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
                    TextFormField(
                      controller: _institutionController,
                      decoration: const InputDecoration(
                        labelText: 'Institution Name *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.business),
                        hintText: 'University of Belize',
                      ),
                      maxLength: 150,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _levelController,
                      decoration: const InputDecoration(
                        labelText: 'Level',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.stairs),
                        hintText: 'Bachelor, Master, PhD',
                      ),
                      maxLength: 50,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _programController,
                      decoration: const InputDecoration(
                        labelText: 'Program',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.menu_book),
                        hintText: 'Computer Science',
                      ),
                      maxLength: 100,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _degreeController,
                      decoration: const InputDecoration(
                        labelText: 'Degree',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.workspace_premium),
                        hintText: 'BSc in Computer Science',
                      ),
                      maxLength: 100,
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
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              _clearForm();
                              setState(() {
                                _isExpanded = false;
                              });
                            },
                            icon: const Icon(Icons.cancel),
                            label: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _addEducation,
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
