import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

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
  File? _selectedFile;
  String? _selectedFileName;
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
      _selectedFile = null;
      _selectedFileName = null;
    });
  }

  // Real file picker
  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final fileName = result.files.single.name;

        // Check file size (limit to 10MB)
        final fileSize = await file.length();
        if (fileSize > 10 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('File size must be less than 10MB'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        setState(() {
          _selectedFile = file;
          _selectedFileName = fileName;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('File selected: $fileName'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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

    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a file'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Store the file object and metadata for upload later
    final document = {
      'doc_type': docType,
      'file': _selectedFile!, // Actual File object for upload
      'file_name': _selectedFileName!,
      if (_remarksController.text.trim().isNotEmpty)
        'remarks': _remarksController.text.trim(),
    };

    widget.onAdd(document);
    _clearForm();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Document added to queue'),
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
            final fileName =
                doc['file_name'] ??
                doc['file_path']?.split('/').last ??
                'Unknown';

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
                  onPressed: _pickFile,
                  icon: const Icon(Icons.attach_file),
                  label: Text(
                    _selectedFile == null
                        ? 'Select File (PDF, Image, DOC)'
                        : 'File Selected: $_selectedFileName',
                    overflow: TextOverflow.ellipsis,
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
