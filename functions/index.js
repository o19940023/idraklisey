const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

/**
 * ✅ Yeni bildiriş Firestore-a əlavə edildikdə avtomatik push göndərir
 * 
 * Tətbiq kapalı olsa belə bildiriş gəlir! 🎉
 */
exports.sendNotificationOnCreate = functions.firestore
  .document('notifications/{notificationId}')
  .onCreate(async (snap, context) => {
    const notification = snap.data();
    const notificationId = context.params.notificationId;
    
    console.log(`📬 Yeni bildiriş: ${notificationId} - "${notification.title}"`);
    
    // Topic-ləri müəyyənləşdir
    const topics = [];
    
    // 1. Sinif topic-ləri (class_9A, class_10B və s.)
    if (notification.targetClasses && notification.targetClasses.length > 0) {
      notification.targetClasses.forEach(className => {
        const sanitized = className.replace(/[^a-zA-Z0-9\-_.~%]/g, '_');
        topics.push(`class_${sanitized}`);
      });
    }
    
    // 2. Rol topic-ləri (role_teacher, role_parent və s.)
    if (notification.targetRoles && notification.targetRoles.length > 0) {
      notification.targetRoles.forEach(role => {
        topics.push(`role_${role}`);
      });
    }
    
    // 3. Konkret istifadəçi (user_usr-teacher-3 və s.)
    if (notification.targetUserId) {
      topics.push(`user_${notification.targetUserId}`);
    }
    
    // 4. Konkret valideyn (şagird ID-dən tapırıq)
    if (notification.targetStudentId) {
      // Şagirdin valideynini tap
      try {
        const usersSnapshot = await admin.firestore()
          .collection('users')
          .where('role', '==', 'parent')
          .where('linkedStudentIds', 'array-contains', notification.targetStudentId)
          .get();
        
        usersSnapshot.forEach(doc => {
          topics.push(`user_${doc.id}`);
        });
      } catch (error) {
        console.warn('Valideyn tapılmadı:', error);
      }
    }
    
    // 5. Heç bir target yoxdursa hamıya göndər
    if (topics.length === 0) {
      topics.push('all');
    }
    
    console.log(`📤 Topic-lər: ${topics.join(', ')}`);
    
    // Priority müəyyənləşdir
    const priority = notification.priority === 'urgent' ? 'high' : 'normal';
    const androidPriority = notification.priority === 'urgent' ? 'high' : 'default';
    
    // Hər topic üçün mesaj göndər
    const promises = topics.map(topic => {
      const message = {
        notification: {
          title: notification.title || 'İdrak Liseyi',
          body: notification.message || '',
        },
        data: {
          notificationId: notificationId,
          category: notification.category || 'general',
          senderName: notification.senderName || 'İdrak Liseyi',
          senderRole: notification.senderRole || '',
          priority: notification.priority || 'normal',
          clickAction: 'FLUTTER_NOTIFICATION_CLICK',
        },
        android: {
          priority: priority,
          notification: {
            channelId: 'idrak_general',
            sound: 'default',
            priority: androidPriority,
            defaultSound: true,
            defaultVibrateTimings: true,
            // Təcili bildirişlər üçün heads-up notification
            visibility: notification.priority === 'urgent' ? 'public' : 'private',
            tag: notificationId,
          },
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
              badge: 1,
              alert: {
                title: notification.title || 'İdrak Liseyi',
                body: notification.message || '',
              },
            },
          },
        },
        topic: topic,
      };
      
      return admin.messaging().send(message).catch(err => {
        console.error(`❌ Topic ${topic} göndərmə xətası:`, err);
        // Xəta olsa belə digər topic-lərə göndərməyə davam et
        return null;
      });
    });
    
    const results = await Promise.all(promises);
    const successCount = results.filter(r => r !== null).length;
    
    console.log(`✅ ${successCount}/${topics.length} topic-ə bildiriş göndərildi`);
    
    return null;
  });

/**
 * ✅ Ticket cavablandırıldıqda avtomatik bildiriş göndər
 */
exports.notifyOnTicketReply = functions.firestore
  .document('tickets/{ticketId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    const ticketId = context.params.ticketId;
    
    // Status dəyişdisə və ya yeni comment əlavə olundusa
    const statusChanged = before.status !== after.status;
    const newCommentAdded = (after.comments?.length || 0) > (before.comments?.length || 0);
    
    if (!statusChanged && !newCommentAdded) {
      return null;
    }
    
    const creatorId = after.createdBy;
    const ticketTitle = after.title;
    
    console.log(`🎫 Ticket yeniləndi: ${ticketId} - Status: ${after.status}`);
    
    // Ticket yaradanın topic-inə göndər
    try {
      const message = {
        notification: {
          title: '🎫 Müraciətinizə Cavab',
          body: `"${ticketTitle}" başlıqlı müraciətinizə cavab verildi`,
        },
        data: {
          type: 'ticket_reply',
          ticketId: ticketId,
          ticketTitle: ticketTitle,
          status: after.status,
          clickAction: 'FLUTTER_NOTIFICATION_CLICK',
        },
        android: {
          notification: {
            channelId: 'idrak_general',
            sound: 'default',
            priority: 'high',
          },
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
              badge: 1,
            },
          },
        },
        topic: `user_${creatorId}`,
      };
      
      await admin.messaging().send(message);
      console.log(`✅ Ticket cavabı bildirildi: ${creatorId}`);
    } catch (error) {
      console.error('❌ Ticket bildirişi göndərmə xətası:', error);
    }
    
    return null;
  });

/**
 * ✅ Yeni ev tapşırığı əlavə edildikdə sinifə bildiriş göndər
 */
exports.notifyOnNewAssignment = functions.firestore
  .document('assignments/{assignmentId}')
  .onCreate(async (snap, context) => {
    const assignment = snap.data();
    const assignmentId = context.params.assignmentId;
    
    console.log(`📚 Yeni ev tapşırığı: ${assignmentId} - "${assignment.title}"`);
    
    if (!assignment.targetClass) {
      console.log('⚠️ Target class yoxdur, bildiriş göndərilmədi');
      return null;
    }
    
    const sanitizedClass = assignment.targetClass.replace(/[^a-zA-Z0-9\-_.~%]/g, '_');
    
    try {
      const message = {
        notification: {
          title: `📚 Yeni Ev Tapşırığı - ${assignment.subject || 'Fənn'}`,
          body: `${assignment.title} - Son tarix: ${assignment.dueDate || 'Bildirilməyib'}`,
        },
        data: {
          type: 'new_assignment',
          assignmentId: assignmentId,
          subject: assignment.subject || '',
          targetClass: assignment.targetClass,
          clickAction: 'FLUTTER_NOTIFICATION_CLICK',
        },
        android: {
          notification: {
            channelId: 'idrak_general',
            sound: 'default',
            priority: 'default',
          },
        },
        topic: `class_${sanitizedClass}`,
      };
      
      await admin.messaging().send(message);
      console.log(`✅ Ev tapşırığı bildirişi göndərildi: class_${sanitizedClass}`);
    } catch (error) {
      console.error('❌ Ev tapşırığı bildirişi xətası:', error);
    }
    
    return null;
  });

/**
 * ✅ Qiymət dəyişdikdə valideynə və şagirdə bildiriş göndər
 */
exports.notifyOnGradeChange = functions.firestore
  .document('grades/{gradeId}')
  .onCreate(async (snap, context) => {
    const grade = snap.data();
    const gradeId = context.params.gradeId;
    
    console.log(`📊 Yeni qiymət: ${gradeId} - ${grade.subject}: ${grade.grade}`);
    
    if (!grade.studentId) {
      return null;
    }
    
    try {
      // Şagirdi tap
      const studentDoc = await admin.firestore()
        .collection('students')
        .doc(grade.studentId)
        .get();
      
      if (!studentDoc.exists) {
        console.log('⚠️ Şagird tapılmadı');
        return null;
      }
      
      const student = studentDoc.data();
      
      const message = {
        notification: {
          title: `📊 Yeni Qiymət - ${grade.subject || 'Fənn'}`,
          body: `${student.fullName}: ${grade.grade} (${grade.examType || 'İmtahan'})`,
        },
        data: {
          type: 'new_grade',
          gradeId: gradeId,
          studentId: grade.studentId,
          subject: grade.subject || '',
          grade: String(grade.grade),
          clickAction: 'FLUTTER_NOTIFICATION_CLICK',
        },
        android: {
          notification: {
            channelId: 'idrak_general',
            sound: 'default',
          },
        },
      };
      
      // Şagirdə göndər
      await admin.messaging().send({
        ...message,
        topic: `user_${grade.studentId}`,
      });
      
      // Valideynə göndər
      const parentsSnapshot = await admin.firestore()
        .collection('users')
        .where('role', '==', 'parent')
        .where('linkedStudentIds', 'array-contains', grade.studentId)
        .get();
      
      const parentPromises = [];
      parentsSnapshot.forEach(doc => {
        parentPromises.push(
          admin.messaging().send({
            ...message,
            topic: `user_${doc.id}`,
          })
        );
      });
      
      await Promise.all(parentPromises);
      
      console.log(`✅ Qiymət bildirişi göndərildi: şagird + ${parentPromises.length} valideyn`);
    } catch (error) {
      console.error('❌ Qiymət bildirişi xətası:', error);
    }
    
    return null;
  });
