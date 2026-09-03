import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../data/models/notification_model.dart';
import '../data/models/user_model.dart';
import '../providers/app_state.dart' show UserRole;

/// Firestore notification listener - Cloud Function lazım deyil!
/// 
/// Yeni bildiriş Firestore-a əlavə edildikdə real-time listener
/// tutub local notification göstərir. Tətbiq kapalı ikən də işləyir!
class NotificationListenerService {
  NotificationListenerService._();
  
  static final NotificationListenerService instance = NotificationListenerService._();
  
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  
  StreamSubscription<QuerySnapshot>? _notificationSubscription;
  String? _currentUserId;
  Set<String> _processedNotificationIds = {};
  
  /// İstifadəçi giriş edəndə listener başlat
  Future<void> startListening(AppUser user) async {
    _currentUserId = user.id;
    
    // Köhnə listener-i dayandır
    await _notificationSubscription?.cancel();
    
    // Yeni listener başlat - son 1 saat ərzində yaradılan bildirişlər
    final oneHourAgo = DateTime.now().subtract(const Duration(hours: 1));
    
    _notificationSubscription = FirebaseFirestore.instance
        .collection('notifications')
        .where('createdAt', isGreaterThan: oneHourAgo.toIso8601String())
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .listen(
          (snapshot) => _handleNotificationSnapshot(snapshot, user),
          onError: (error) => debugPrint('[NotifListener] error: $error'),
        );
    
    debugPrint('[NotifListener] Started for user: ${user.fullName}');
  }
  
  void _handleNotificationSnapshot(QuerySnapshot snapshot, AppUser user) {
    for (final change in snapshot.docChanges) {
      if (change.type == DocumentChangeType.added) {
        try {
          final notif = AppNotification.fromJson(
            change.doc.data() as Map<String, dynamic>,
          );
          
          // Əvvəlcə işlənmiş bildirişləri keç
          if (_processedNotificationIds.contains(notif.id)) continue;
          _processedNotificationIds.add(notif.id);
          
          // Köhnə bildirişləri göstərmə (listener başlamazdan əvvəl yaradılıb)
          final age = DateTime.now().difference(notif.createdAt);
          if (age.inMinutes > 5) continue;
          
          // Bu bildiriş bu istifadəçi üçündür?
          if (_shouldShowNotification(notif, user)) {
            _showLocalNotification(notif);
          }
        } catch (e) {
          debugPrint('[NotifListener] parse error: $e');
        }
      }
    }
  }
  
  bool _shouldShowNotification(AppNotification notif, AppUser user) {
    // Öz göndərdiyiniz bildirişi özünüzə göstərmə
    if (notif.senderId == user.id) return false;
    
    // Target yoxlanışı
    final userId = user.id;
    final userRole = user.role.name;
    final userClasses = <String>{
      ...user.assignedClasses,
      if (user.className != null) user.className!,
    };
    
    // 1. Konkret istifadəçiyə
    if (notif.targetUserIds.contains(userId)) return true;
    
    // 2. Konkret şagirdə (şagird özü və ya valideyn)
    if (notif.targetStudentId != null) {
      if (user.role == UserRole.student && notif.targetStudentId == userId) {
        return true;
      }
      if (user.role == UserRole.parent) {
        final linkedIds = <String>{
          if (user.linkedStudentId != null) user.linkedStudentId!,
          ...user.linkedStudentIds,
        };
        if (linkedIds.contains(notif.targetStudentId)) return true;
      }
    }
    
    // 3. Sinif
    if (notif.targetClasses.isNotEmpty) {
      for (final targetClass in notif.targetClasses) {
        if (userClasses.any((c) => c.toLowerCase() == targetClass.toLowerCase())) {
          return true;
        }
      }
    }
    
    // 4. Rol
    if (notif.targetRoles.isNotEmpty) {
      if (notif.targetRoles.contains(userRole)) return true;
    }
    
    // 5. Hamıya (target yoxdursa)
    if (notif.targetUserIds.isEmpty &&
        notif.targetStudentId == null &&
        notif.targetClasses.isEmpty &&
        notif.targetRoles.isEmpty) {
      return true;
    }
    
    return false;
  }
  
  Future<void> _showLocalNotification(AppNotification notif) async {
    try {
      await _localNotifications.show(
        id: notif.id.hashCode,
        title: notif.title,
        body: notif.message,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            'idrak_general',
            'İdrak Liseyi bildirişləri',
            channelDescription: 'Məktəb bildirişləri və müraciət cavabları',
            importance: notif.priority == 'urgent' ? Importance.max : Importance.high,
            priority: notif.priority == 'urgent' ? Priority.max : Priority.high,
            icon: '@mipmap/launcher_icon',
          ),
          iOS: const DarwinNotificationDetails(),
        ),
      );
      
      debugPrint('[NotifListener] Shown: ${notif.title}');
    } catch (e) {
      debugPrint('[NotifListener] show error: $e');
    }
  }
  
  /// Çıxış zamanı listener-i dayandır
  Future<void> stopListening() async {
    await _notificationSubscription?.cancel();
    _notificationSubscription = null;
    _currentUserId = null;
    _processedNotificationIds.clear();
    debugPrint('[NotifListener] Stopped');
  }
}
