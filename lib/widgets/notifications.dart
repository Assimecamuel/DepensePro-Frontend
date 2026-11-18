import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api_service.dart';
import '../core/app_settings.dart';
import '../core/app_theme.dart';
import 'app_widgets.dart';

/// Modèle représentant une notification individuelle de l'utilisateur.
class AppNotification {
  final int id;
  final String title;
  final String message;
  final String kind;
  final bool isRead;
  final DateTime? createdAt;

  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.kind,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      title: json['title']?.toString() ?? 'Notification',
      message: json['message']?.toString() ?? '',
      kind: json['kind']?.toString() ?? 'general',
      isRead: json['is_read'] == true,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'message': message,
        'kind': kind,
        'is_read': isRead,
        'created_at': createdAt?.toIso8601String(),
      };

  AppNotification copyWith({bool? isRead}) => AppNotification(
        id: id,
        title: title,
        message: message,
        kind: kind,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt,
      );
}

/// Conteneur pour la réponse de l'API listant les notifications et le nombre d'éléments non lus.
class AppNotificationList {
  final List<AppNotification> notifications;
  final int unreadCount;

  const AppNotificationList({
    required this.notifications,
    required this.unreadCount,
  });

  factory AppNotificationList.fromJson(Map<String, dynamic> json) {
    final rawList = json['notifications'];
    final items = (rawList is List)
        ? rawList
            .whereType<Map>()
            .map((item) =>
                AppNotification.fromJson(Map<String, dynamic>.from(item)))
            .toList()
        : <AppNotification>[];

    final count = int.tryParse(json['unread_count']?.toString() ?? '') ??
        items.where((n) => !n.isRead).length;

    return AppNotificationList(
      notifications: items,
      unreadCount: count,
    );
  }
}

/// Modèle de réponse pour la confirmation de marquage de toutes les notifications comme lues.
class MarkAllReadResponse {
  final bool ok;
  final int updated;

  const MarkAllReadResponse({
    required this.ok,
    required this.updated,
  });

  factory MarkAllReadResponse.fromJson(Map<String, dynamic> json) {
    return MarkAllReadResponse(
      ok: json['ok'] == true,
      updated: int.tryParse(json['updated']?.toString() ?? '') ?? 0,
    );
  }
}

/// Service de gestion des notifications connecté à l'API REST backend et synchronisé localement.
class NotificationManager {
  NotificationManager._();
  static final NotificationManager instance = NotificationManager._();

  static const String _localPrefsKey = 'local_app_notifications';

  /// Ajoute une notification locale (ex: fin de tâche planifiée).
  Future<void> addLocalNotification({
    required String title,
    required String message,
    String kind = 'task',
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_localPrefsKey);
      final List localList =
          raw != null && raw.isNotEmpty ? jsonDecode(raw) : [];

      final newNotif = AppNotification(
        id: DateTime.now().millisecondsSinceEpoch,
        title: title,
        message: message,
        kind: kind,
        isRead: false,
        createdAt: DateTime.now(),
      );

      localList.insert(0, newNotif.toJson());
      await prefs.setString(_localPrefsKey, jsonEncode(localList));
    } catch (_) {}
  }

  /// Récupère les notifications locales stockées.
  Future<List<AppNotification>> _getLocalNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_localPrefsKey);
      if (raw == null || raw.isEmpty) return [];
      final List localList = jsonDecode(raw);
      return localList
          .whereType<Map>()
          .map((e) => AppNotification.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Récupère la liste des notifications (API backend + notifications locales) et le compteur total de non lues.
  Future<AppNotificationList> fetchNotifications() async {
    List<AppNotification> remote = [];
    int remoteUnread = 0;

    try {
      final response = await ApiService.instance.get('notifications/');
      if (response is Map) {
        final parsed =
            AppNotificationList.fromJson(Map<String, dynamic>.from(response));
        remote = parsed.notifications;
        remoteUnread = parsed.unreadCount;
      }
    } catch (_) {
      // Si le backend est temporairement indisponible, les notifications locales restent affichées.
    }

    final local = await _getLocalNotifications();
    final combined = [...local, ...remote];
    combined.sort((a, b) {
      final da = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final db = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return db.compareTo(da);
    });

    final totalUnread = remoteUnread + local.where((n) => !n.isRead).length;

    return AppNotificationList(
      notifications: combined,
      unreadCount: totalUnread,
    );
  }

  /// Alias de rétrocompatibilité renvoyant uniquement la liste des notifications.
  Future<List<AppNotification>> getNotifications() async {
    final data = await fetchNotifications();
    return data.notifications;
  }

  /// Marque toutes les notifications non lues de l'utilisateur comme lues.
  Future<MarkAllReadResponse> markAllAsRead() async {
    int updatedCount = 0;
    try {
      final res =
          await ApiService.instance.post('notifications/mark-all-read/', {});
      if (res is Map) {
        updatedCount = int.tryParse(res['updated']?.toString() ?? '') ?? 0;
      }
    } catch (_) {}

    try {
      final prefs = await SharedPreferences.getInstance();
      final local = await _getLocalNotifications();
      final updatedLocal = local
          .map((n) {
            if (!n.isRead) updatedCount++;
            return n.copyWith(isRead: true);
          })
          .map((n) => n.toJson())
          .toList();
      await prefs.setString(_localPrefsKey, jsonEncode(updatedLocal));
    } catch (_) {}

    return MarkAllReadResponse(ok: true, updated: updatedCount);
  }

  /// Envoie la requête PATCH /notifications/{id}/ ou met à jour la notification locale.
  Future<AppNotification?> markAsRead(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final local = await _getLocalNotifications();
      final idx = local.indexWhere((n) => n.id == id);
      if (idx != -1) {
        local[idx] = local[idx].copyWith(isRead: true);
        await prefs.setString(
            _localPrefsKey, jsonEncode(local.map((n) => n.toJson()).toList()));
        return local[idx];
      }
    } catch (_) {}

    try {
      final response = await ApiService.instance
          .patch('notifications/$id/', {'is_read': true});
      if (response is Map) {
        return AppNotification.fromJson(Map<String, dynamic>.from(response));
      }
    } catch (_) {}
    return null;
  }

  /// Supprime une notification spécifique (API backend ou locale).
  Future<void> delete(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final local = await _getLocalNotifications();
      final idx = local.indexWhere((n) => n.id == id);
      if (idx != -1) {
        local.removeAt(idx);
        await prefs.setString(
            _localPrefsKey, jsonEncode(local.map((n) => n.toJson()).toList()));
        return;
      }
    } catch (_) {}

    try {
      await ApiService.instance.delete('notifications/$id/');
    } catch (_) {}
  }
}

/// Cloche de notification synchronisée avec le compte utilisateur connecté.
class NotificationBell extends StatefulWidget {
  const NotificationBell({super.key});

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  int _unreadCount = 0;
  bool _loading = false;
  Timer? _poller;

  @override
  void initState() {
    super.initState();
    _refreshUnread();
    _poller =
        Timer.periodic(const Duration(seconds: 15), (_) => _refreshUnread());
  }

  @override
  void dispose() {
    _poller?.cancel();
    super.dispose();
  }

  Future<void> _refreshUnread() async {
    if (_loading) return;
    _loading = true;
    try {
      final res = await NotificationManager.instance.fetchNotifications();
      if (mounted) {
        setState(() => _unreadCount = res.unreadCount);
      }
    } catch (_) {
      // La cloche reste utilisable en cas de déconnexion réseau temporaire.
    } finally {
      _loading = false;
    }
  }

  Future<void> _openNotifications() async {
    try {
      final data = await NotificationManager.instance.fetchNotifications();
      if (!mounted) return;
      await _showNotifications(context, data);
      await _refreshUnread();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Impossible de charger les notifications : $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Stack(
      children: [
        IconButton(
          tooltip: context.t('notif_tooltip'),
          icon: Icon(Icons.notifications_outlined, color: p.title),
          onPressed: _openNotifications,
        ),
        if (_unreadCount > 0)
          Positioned(
            right: 12,
            top: 12,
            child: IgnorePointer(
              child: Container(
                constraints: const BoxConstraints(minWidth: 9, minHeight: 9),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: p.expense,
                  shape: BoxShape.circle,
                  border: Border.all(color: p.surface, width: 1.5),
                ),
                child: _unreadCount > 9
                    ? Text(
                        _unreadCount > 99 ? '99+' : '$_unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                        ),
                      )
                    : null,
              ),
            ),
          ),
      ],
    );
  }
}

Future<void> _showNotifications(
  BuildContext context,
  AppNotificationList initialData,
) async {
  final items = List<AppNotification>.from(initialData.notifications);
  int unreadCount = initialData.unreadCount;
  if (!context.mounted) return;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      final p = dialogContext.pal;
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        clipBehavior: Clip.antiAlias,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: StatefulBuilder(
          builder: (context, setSheetState) {
            final currentUnread = items.where((item) => !item.isRead).length;
            final displayedUnread =
                unreadCount > 0 ? unreadCount : currentUnread;

            return ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 480,
                maxHeight: MediaQuery.sizeOf(context).height * 0.75,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
                    child: Row(
                      children: [
                        IconBadge(
                          icon: Icons.notifications_active_rounded,
                          color: p.primary,
                          background: p.primarySoft,
                          size: 38,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                dialogContext.t('notif_title'),
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: p.title,
                                ),
                              ),
                              Text(
                                displayedUnread == 0
                                    ? 'Aucune notification non lue'
                                    : '$displayedUnread notification(s) non lue(s)',
                                style:
                                    TextStyle(color: p.muted, fontSize: 11.5),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Fermer',
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(dialogContext),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: p.border),
                  items.isEmpty
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 40, horizontal: 24),
                          alignment: Alignment.center,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 320),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 68,
                                  height: 68,
                                  decoration: BoxDecoration(
                                    color: p.primarySoft,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: p.primary.withValues(alpha: 0.2),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.notifications_none_rounded,
                                    size: 32,
                                    color: p.primary,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                Text(
                                  'Vous êtes à jour !',
                                  style: TextStyle(
                                    fontSize: 16.5,
                                    fontWeight: FontWeight.w800,
                                    color: p.title,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Aucune notification pour le moment. Vos alertes budgétaires et activités apparaîtront ici.',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: p.muted,
                                    height: 1.4,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                      : Flexible(
                          child: ListView.separated(
                            shrinkWrap: true,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 12),
                            itemCount: items.length,
                            separatorBuilder: (_, __) =>
                                Divider(height: 1, color: p.border),
                            itemBuilder: (context, index) {
                              final item = items[index];
                              return Dismissible(
                                key: ValueKey(item.id),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20),
                                  decoration: BoxDecoration(
                                    color: p.expense.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(Icons.delete_outline_rounded,
                                      color: p.expense),
                                ),
                                onDismissed: (_) async {
                                  final removedItem = items.removeAt(index);
                                  setSheetState(() {
                                    if (!removedItem.isRead &&
                                        unreadCount > 0) {
                                      unreadCount--;
                                    }
                                  });
                                  try {
                                    await NotificationManager.instance
                                        .delete(removedItem.id);
                                  } catch (error) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              'Erreur lors de la suppression : $error'),
                                        ),
                                      );
                                    }
                                  }
                                },
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: item.isRead
                                      ? null
                                      : () async {
                                          try {
                                            await NotificationManager.instance
                                                .markAsRead(item.id);
                                            setSheetState(() {
                                              items[index] =
                                                  item.copyWith(isRead: true);
                                              if (unreadCount > 0)
                                                unreadCount--;
                                            });
                                          } catch (_) {
                                            setSheetState(() {
                                              items[index] =
                                                  item.copyWith(isRead: true);
                                              if (unreadCount > 0)
                                                unreadCount--;
                                            });
                                          }
                                        },
                                  child: _NotificationItem(
                                    item: item,
                                    onDelete: () async {
                                      setSheetState(() {
                                        items.removeWhere(
                                            (n) => n.id == item.id);
                                        if (!item.isRead && unreadCount > 0) {
                                          unreadCount--;
                                        }
                                      });
                                      try {
                                        await NotificationManager.instance
                                            .delete(item.id);
                                      } catch (error) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                  'Erreur lors de la suppression : $error'),
                                            ),
                                          );
                                        }
                                      }
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                  if (displayedUnread > 0)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            try {
                              final res = await NotificationManager.instance
                                  .markAllAsRead();
                              setSheetState(() {
                                for (var i = 0; i < items.length; i++) {
                                  items[i] = items[i].copyWith(isRead: true);
                                }
                                unreadCount = 0;
                              });
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      res.updated > 0
                                          ? '${res.updated} notification(s) marquée(s) comme lue(s).'
                                          : dialogContext.t('notif_marked'),
                                    ),
                                  ),
                                );
                              }
                            } catch (error) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Action impossible : $error'),
                                  ),
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.done_all_rounded),
                          label: Text(dialogContext.t('notif_mark_all')),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      );
    },
  );
}

class _NotificationItem extends StatelessWidget {
  final AppNotification item;
  final VoidCallback onDelete;

  const _NotificationItem({
    required this.item,
    required this.onDelete,
  });

  String _relativeTime(DateTime? date) {
    if (date == null) return '';
    final difference = DateTime.now().difference(date.toLocal());
    if (difference.inSeconds < 60) return 'À l’instant';
    if (difference.inMinutes < 60) return 'Il y a ${difference.inMinutes} min';
    if (difference.inHours < 24) return 'Il y a ${difference.inHours} h';
    if (difference.inDays < 7) return 'Il y a ${difference.inDays} j';
    final local = date.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
  }

  IconData _iconForKind() {
    switch (item.kind) {
      case 'budget_warning':
      case 'budget_critical':
        return Icons.account_balance_wallet_outlined;
      case 'transaction':
      case 'transaction_updated':
      case 'transaction_deleted':
        return Icons.receipt_long_outlined;
      case 'security_login':
      case 'security_recovery':
      case 'security_password':
      case 'security_profile':
        return Icons.security_outlined;
      case 'announcement':
        return Icons.campaign_outlined;
      case 'task':
        return Icons.task_alt_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconBadge(
            icon: _iconForKind(),
            color: item.isRead ? p.muted : p.primary,
            background: item.isRead ? p.surfaceAlt : p.primarySoft,
            size: 36,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: TextStyle(
                          fontWeight:
                              item.isRead ? FontWeight.w600 : FontWeight.w800,
                          fontSize: 13.5,
                          color: p.title,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _relativeTime(item.createdAt),
                      style: TextStyle(color: p.muted, fontSize: 10.5),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item.message,
                  style: TextStyle(
                    color: p.muted,
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
                if (!item.isRead)
                  Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Text(
                      'NON LUE',
                      style: TextStyle(
                        color: p.primary,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close_rounded, size: 18, color: p.muted),
            tooltip: 'Supprimer',
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
