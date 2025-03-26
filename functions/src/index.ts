/**
 * Import function triggers from their respective submodules:
 *
 * import {onCall} from "firebase-functions/v2/https";
 * import {onDocumentWritten} from "firebase-functions/v2/firestore";
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

import {onDocumentCreated} from "firebase-functions/v2/firestore";
import {setGlobalOptions} from "firebase-functions/v2";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

// Khởi tạo Firebase Admin
admin.initializeApp();

// Cấu hình global cho functions
setGlobalOptions({
  maxInstances: 10,
  timeoutSeconds: 30,
  memory: "256MiB",
});

// Function xử lý khi có thông báo mới trong hàng đợi
export const processNotificationQueueItem = onDocumentCreated(
  "notifications_queue/{notificationId}",
  async (event) => {
    const notificationData = event.data?.data();
    
    if (!notificationData) {
      logger.warn("Invalid notification data in queue");
      return;
    }

    const token = notificationData.token;
    const notification = notificationData.notification;
    const data = notificationData.data;

    if (!token || !notification) {
      logger.warn("Missing token or notification data");
      return;
    }

    try {
      // Gửi thông báo đẩy
      await admin.messaging().send({
        token: token,
        notification: {
          title: notification.title,
          body: notification.body,
        },
        data: data || {},
        android: {
          priority: "high",
          notification: {
            channelId: "social_app_channel",
            sound: "default",
            priority: "high",
            defaultSound: true,
            defaultVibrateTimings: true,
          },
        },
        apns: {
          payload: {
            aps: {
              sound: "default",
              badge: 1,
              contentAvailable: true,
            },
          },
        },
      });

      // Cập nhật trạng thái đã gửi
      await event.data?.ref.update({
        sent: true,
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      logger.info(`Push notification sent successfully to token: ${token.substring(0, 10)}...`);
    } catch (error: any) {
      logger.error("Error sending push notification:", error);
      
      // Cập nhật trạng thái lỗi
      await event.data?.ref.update({
        error: error.message || "Unknown error",
        errorAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
  }
);
