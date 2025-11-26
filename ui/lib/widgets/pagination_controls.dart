import 'package:flutter/material.dart';
import '../models/pagination_metadata.dart';

class PaginationControls extends StatelessWidget {
  final PaginationMetadata metadata;
  final Function(int) onPageChanged;

  const PaginationControls({
    super.key,
    required this.metadata,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Records info
          Text(
            '${_getStartRecord()}-${_getEndRecord()} of ${metadata.totalRecords}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),

          // Page controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // First page
              IconButton(
                icon: const Icon(Icons.first_page, size: 20),
                onPressed: metadata.hasPreviousPage
                    ? () => onPageChanged(metadata.firstPage)
                    : null,
                tooltip: 'First',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),

              // Previous page
              IconButton(
                icon: const Icon(Icons.chevron_left, size: 20),
                onPressed: metadata.hasPreviousPage
                    ? () => onPageChanged(metadata.currentPage - 1)
                    : null,
                tooltip: 'Previous',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),

              // Current page indicator
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${metadata.currentPage}/${metadata.lastPage}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),

              // Next page
              IconButton(
                icon: const Icon(Icons.chevron_right, size: 20),
                onPressed: metadata.hasNextPage
                    ? () => onPageChanged(metadata.currentPage + 1)
                    : null,
                tooltip: 'Next',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),

              // Last page
              IconButton(
                icon: const Icon(Icons.last_page, size: 20),
                onPressed: metadata.hasNextPage
                    ? () => onPageChanged(metadata.lastPage)
                    : null,
                tooltip: 'Last',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
        ],
      ),
    );
  }

  int _getStartRecord() {
    if (metadata.totalRecords == 0) return 0;
    return ((metadata.currentPage - 1) * metadata.pageSize) + 1;
  }

  int _getEndRecord() {
    final end = metadata.currentPage * metadata.pageSize;
    return end > metadata.totalRecords ? metadata.totalRecords : end;
  }
}
