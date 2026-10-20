import 'package:flutter/material.dart';

import 'package:ELEODES/core/theme/app_theme.dart';
import 'package:ELEODES/core/settings/app_settings.dart';
import 'package:ELEODES/features/notifications/services/notification_service.dart';
import 'package:ELEODES/features/notifications/widgets/notification_card.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final NotificationService _service = NotificationService();
  late final _notifications = _service.notificationStream;

  bool _clearing = false;
  bool _selecting = false;
  final Set<String> _selectedIds = {};

  void _toggleSelection(String id) {
    setState(() {
      if (!_selectedIds.add(id)) _selectedIds.remove(id);
    });
  }

  String _severityOf(Map<String, dynamic> item) {
    final title = (item['title'] ?? '').toString().toLowerCase();
    if (title == 'water tank full') return 'info';
    final type = (item['type'] ?? 'info').toString().toLowerCase();
    if (type == 'danger' || type == 'error' || type == 'critical') {
      return 'critical';
    }
    if (type == 'warning') return 'warning';
    return 'info';
  }

  String _filterLabel(String filter) => switch (filter) {
    'critical' => 'Critical',
    'warning' => 'Warnings',
    'info' => 'Info',
    _ => 'All',
  };

  Future<void> _deleteSelectedNotifications() async {
    if (_clearing || _selectedIds.isEmpty) return;
    final ids = Set<String>.of(_selectedIds);
    setState(() => _clearing = true);
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Delete selected notifications?'),
          content: Text(
            '${ids.length} selected notification(s) will be permanently deleted. This cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(dialogContext).colorScheme.error,
              ),
              child: const Text('Delete'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
      await _service.deleteNotifications(ids);
      if (!mounted) return;
      setState(() {
        _selectedIds.clear();
        _selecting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${ids.length} notification(s) deleted.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not delete notifications. Please try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _clearing = false);
    }
  }

  Future<void> _markAsRead(Map<String, dynamic> item) async {
    final id = item['id']?.toString();
    if (id == null || item['read'] == true) return;
    try {
      await _service.markAsRead(id);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not mark notification as read.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background(context, const Color(0xFFD2FFEE)),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        actions: [
          ListenableBuilder(
            listenable: AppSettings.instance,
            builder: (context, _) => PopupMenuButton<String>(
              tooltip: 'Filter notifications',
              initialValue: AppSettings.instance.alertFilter,
              onSelected: (value) async {
                await AppSettings.instance.setAlertFilter(value);
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'all', child: Text('All')),
                PopupMenuItem(value: 'critical', child: Text('Critical')),
                PopupMenuItem(value: 'warning', child: Text('Warnings')),
                PopupMenuItem(value: 'info', child: Text('Info')),
              ],
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_filterLabel(AppSettings.instance.alertFilter)),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: _selecting ? 'Cancel selection' : 'Select notifications to delete',
            onPressed: _clearing ? null : () => setState(() {
              _selecting = !_selecting;
              _selectedIds.clear();
            }),
            icon: Icon(_selecting ? Icons.close : Icons.delete_sweep_outlined),
            color: Theme.of(context).colorScheme.error,
          ),
        ],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (widget.onBack != null) {
              widget.onBack!();
            } else {
              Navigator.maybePop(context);
            }
          },
        ),
        title: const Text(
          'Notification',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListenableBuilder(
        listenable: AppSettings.instance,
        builder: (context, _) => SafeArea(
          child: Column(
            children: [
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _notifications,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Center(
                        child: Text('Unable to load notifications.'),
                      );
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final allNotifications = snapshot.data ?? [];
                    final filter = AppSettings.instance.alertFilter;
                    final notifications = allNotifications
                        .where(
                          (item) =>
                              filter == 'all' || _severityOf(item) == filter,
                        )
                        .toList();
                    if (notifications.isEmpty) {
                      return Center(
                        child: Text(
                          allNotifications.isEmpty
                              ? 'No notifications yet.'
                              : 'No alerts match this filter.',
                        ),
                      );
                    }
                    return Column(
                      children: [
                        if (_selecting)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextButton(
                                    style: TextButton.styleFrom(
                                      alignment: Alignment.centerLeft,
                                    ),
                                    onPressed: _clearing ? null : () => setState(() {
                                      final visibleIds = notifications.map((item) => item['id'].toString()).toSet();
                                      if (visibleIds.every(_selectedIds.contains)) {
                                        _selectedIds.removeAll(visibleIds);
                                      } else {
                                        _selectedIds.addAll(visibleIds);
                                      }
                                    }),
                                    child: const Text('Select all'),
                                  ),
                                ),
                                TextButton.icon(
                                  style: TextButton.styleFrom(
                                    foregroundColor: Theme.of(context).colorScheme.error,
                                  ),
                                  onPressed: _clearing || _selectedIds.isEmpty ? null : _deleteSelectedNotifications,
                                  icon: const Icon(Icons.delete_outline),
                                  label: Text('Delete (${_selectedIds.length})'),
                                ),
                              ],
                            ),
                          ),
                        Expanded(child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
                      itemCount: notifications.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = notifications[index];
                        return GestureDetector(
                          key: ValueKey(item['id']),
                          onTap: _clearing ? null : () => _selecting
                              ? _toggleSelection(item['id'].toString())
                              : _markAsRead(item),
                          child: Row(children: [
                            if (_selecting)
                              Semantics(
                                label: 'Select notification: ${item['title'] ?? ''}',
                                checked: _selectedIds.contains(item['id'].toString()),
                                enabled: !_clearing,
                                child: InkResponse(
                                  onTap: _clearing ? null : () => _toggleSelection(item['id'].toString()),
                                  radius: 24,
                                  child: SizedBox(
                                    width: 48,
                                    height: 48,
                                    child: Center(
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 150),
                                        width: 22,
                                        height: 22,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: _selectedIds.contains(item['id'].toString())
                                              ? Theme.of(context).colorScheme.primary
                                              : Colors.transparent,
                                          border: Border.all(
                                            color: _selectedIds.contains(item['id'].toString())
                                                ? Theme.of(context).colorScheme.primary
                                                : Theme.of(context).colorScheme.outline,
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            Expanded(child: NotificationCard(
                            title: (item['title'] ?? '').toString(),
                            message: (item['message'] ?? '').toString(),
                            time: (item['time'] ?? '').toString(),
                            type: (item['type'] ?? 'info').toString(),
                            read: item['read'] == true,
                          )),
                          ]),
                        );
                      },
                    )),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
