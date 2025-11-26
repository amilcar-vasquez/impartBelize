import 'package:flutter/material.dart';

class DocumentUploadWidget extends StatefulWidget {
  final Function(Map<String, dynamic>) onAdd;
  final List<Map<String, dynamic>> documentList;
  final Function(int) onRemove;

  const DocumentUploadWidget({
    super.key,
    required this.onAdd,
    required this.documentList,
    required this.onRemove,
  });

  @override
  State<DocumentUploadWidget> createState() => _DocumentUploadWidgetState();
}

class _DocumentUploadWidgetState extends State<DocumentUploadWidget> {
  final _docTypeController = TextEditingController();
  final _remarksController = TextEditingController();
  String? _selectedDocType;
  String? _mockFilePath;
  bool _isUploading = false;

  final List<String> _documentTypes = [
    'Birth Certificate',
    'Police Record',
    'Passport Photo',
    'Diploma',
    'Transcript',
    'Teaching Certificate',
    'Resume/CV',
    'ID Card',
    'Social Security Card',
    'Other',
  ];

  void _clearForm() {
    _docTypeController.clear();
    _remarksController.clear();
    setState(() {
      _selectedDocType = null;
      _mockFilePath = null;
    });
  }

  // Mock file picker - simulates selecting a file
  Future<void> _mockPickFile() async {
    setState(() {
      _isUploading = true;
    });

    // Simulate file selection delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Generate a mock file path
    final fileName = 'document_${DateTime.now().millisecondsSinceEpoch}.pdf';
    setState(() {
      _mockFilePath = '/mock/path/to/$fileName';
      _isUploading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('File selected: $fileName'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _addDocument() {
    final docType = _selectedDocType == 'Other'
        ? _docTypeController.text.trim()
        : _selectedDocType;

    if (docType == null || docType.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Document type is required'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_mockFilePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a file'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final document = {
      'doc_type': docType,
      'file_path': _mockFilePath!, // This will be the Supabase URL after upload
      if (_remarksController.text.trim().isNotEmpty)
        'remarks': _remarksController.text.trim(),
    };

    widget.onAdd(document);
    _clearForm();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Document added'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 1),
      ),
    );
  }

  IconData _getDocumentIcon(String docType) {
    if (docType.toLowerCase().contains('certificate') ||
        docType.toLowerCase().contains('diploma')) {
      return Icons.workspace_premium;
    } else if (docType.toLowerCase().contains('photo') ||
        docType.toLowerCase().contains('id')) {
      return Icons.badge;
    } else if (docType.toLowerCase().contains('transcript') ||
        docType.toLowerCase().contains('resume')) {
      return Icons.description;
    } else {
      return Icons.insert_drive_file;
    }
  }

  @override
  void dispose() {
    _docTypeController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Display added documents
        if (widget.documentList.isNotEmpty) ...[
          ...widget.documentList.asMap().entries.map((entry) {
            final index = entry.key;
            final doc = entry.value;
            final fileName = doc['file_path']?.split('/').last ?? 'Unknown';

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.secondaryContainer,
                  child: Icon(
                    _getDocumentIcon(doc['doc_type'] ?? ''),
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
                title: Text(
                  doc['doc_type'] ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fileName,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (doc['remarks'] != null)
                      Text(
                        'Note: ${doc['remarks']}',
                        style: const TextStyle(fontSize: 12),
                      ),
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

        // Add new document form
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.upload_file),
                    const SizedBox(width: 8),
                    Text(
                      'Upload Documents',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedDocType,
                  decoration: const InputDecoration(
                    labelText: 'Document Type *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: _documentTypes.map((type) {
                    return DropdownMenuItem(value: type, child: Text(type));
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedDocType = value;
                    });
                  },
                ),
                if (_selectedDocType == 'Other') ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _docTypeController,
                    decoration: const InputDecoration(
                      labelText: 'Specify Document Type *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.edit),
                      hintText: 'Enter document type',
                    ),
                    maxLength: 100,
                  ),
                ],
                const SizedBox(height: 16),

                // File selection button
                OutlinedButton.icon(
                  onPressed: _isUploading ? null : _mockPickFile,
                  icon: _isUploading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.attach_file),
                  label: Text(
                    _mockFilePath == null
                        ? 'Select File'
                        : 'File Selected: ${_mockFilePath!.split('/').last}',
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _remarksController,
                  decoration: const InputDecoration(
                    labelText: 'Remarks (Optional)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.note),
                    hintText: 'Add any additional notes',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _clearForm,
                        icon: const Icon(Icons.clear),
                        label: const Text('Clear'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _addDocument,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Document'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
