const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

exports.onOrderCreated = functions.firestore
    .document("orders/{orderId}")
    .onCreate(async (snap, context) => {
      try {
        const orderData = snap.data();
        const orderId = context.params.orderId;
        const userId = orderData.userId;
        const totalAmount = orderData.totalAmount;

        // Lấy thông tin người dùng
        // eslint-disable-next-line max-len
        const userDoc = await admin.firestore().collection("users").doc(userId).get();
        if (!userDoc.exists) {
          console.error("User not found for userId:", userId);
          return null;
        }
        const userName = userDoc.data().name || "Unknown";

        // Định dạng số tiền theo định dạng tiền Việt Nam
        const formattedAmount = totalAmount.toLocaleString("vi-VN", {
          style: "currency",
          currency: "VND",
        });

        // Lấy danh sách admin
        const adminSnapshot = await admin.firestore()
            .collection("users")
            .where("role", "==", "admin")
            .get();

        if (adminSnapshot.empty) {
          console.warn("No admins found");
          return null;
        }

        // Thêm thông báo cho từng admin
        const promises = adminSnapshot.docs.map(async (adminDoc) => {
          const adminId = adminDoc.id;
          await admin.firestore()
              .collection("users")
              .doc(adminId)
              .collection("notifications")
              .add({
                title: "Đơn hàng mới",
                message: "Đơn hàng #" + orderId.substring(0, 8) +
                            " từ khách hàng " + userName +
                            " với tổng giá trị " + formattedAmount + ".",
                type: "Đơn hàng",
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
                isRead: false,
              });
        });

        await Promise.all(promises);
        console.log("Notifications sent to admins for order:", orderId);
        return null;
      } catch (error) {
        console.error("Error in onOrderCreated:", error);
        return null;
      }
    });
