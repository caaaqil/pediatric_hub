import 'enums.dart';
import 'json_utils.dart';

/// `model Notification` — rows are produced by the vaccine cron and by
/// appointment/system events. `type` is APPOINTMENT | VACCINE | SYSTEM.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.isRead,
    required this.type,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String title;
  final String body;
  final bool isRead;
  final String type;
  final DateTime createdAt;

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: Json.str(json['id']),
      userId: Json.str(json['userId']),
      title: Json.str(json['title']),
      body: Json.str(json['body']),
      isRead: Json.boolean(json['isRead']),
      type: Json.str(json['type'], fallback: 'SYSTEM'),
      createdAt: Json.date(json['createdAt']),
    );
  }
}

/// `model EducationalContent` — only published rows are returned.
class EducationalContent {
  const EducationalContent({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.isPublished,
    this.createdAt,
  });

  final String id;
  final String title;
  final String content;
  final String category;
  final bool isPublished;
  final DateTime? createdAt;

  factory EducationalContent.fromJson(Map<String, dynamic> json) {
    return EducationalContent(
      id: Json.str(json['id']),
      title: Json.str(json['title']),
      content: Json.str(json['content']),
      category: Json.str(json['category']),
      isPublished: Json.boolean(json['isPublished']),
      createdAt: Json.dateOrNull(json['createdAt']),
    );
  }
}

/// `model EmergencyContact` — type is HOSPITAL | AMBULANCE | POISON_CONTROL.
class EmergencyContact {
  const EmergencyContact({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.type,
    this.region,
  });

  final String id;
  final String name;
  final String phoneNumber;
  final String type;
  final String? region;

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      id: Json.str(json['id']),
      name: Json.str(json['name']),
      phoneNumber: Json.str(json['phoneNumber']),
      type: Json.str(json['type']),
      region: Json.strOrNull(json['region']),
    );
  }
}

/// `model Payment` — note the payment endpoints bypass the response wrapper.
class Payment {
  const Payment({
    required this.id,
    required this.userId,
    required this.amount,
    required this.currency,
    required this.status,
    required this.accountNo,
    required this.referenceId,
    required this.invoiceId,
    required this.createdAt,
    this.appointmentId,
    this.transactionId,
    this.description,
    this.payerEmail,
    this.payerName,
  });

  final String id;
  final String userId;
  final double amount;
  final String currency;
  final PaymentStatus status;
  final String accountNo;
  final String referenceId;
  final String invoiceId;
  final DateTime createdAt;
  final String? appointmentId;
  final String? transactionId;
  final String? description;
  final String? payerEmail;

  /// From the `user.parentProfile` include on `GET /payments`.
  final String? payerName;

  factory Payment.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic>? user = Json.mapOrNull(json['user']);
    final Map<String, dynamic>? profile = user == null
        ? null
        : Json.mapOrNull(user['parentProfile']);
    final String name = profile == null
        ? ''
        : '${Json.str(profile['firstName'])} ${Json.str(profile['lastName'])}'
              .trim();
    return Payment(
      id: Json.str(json['id']),
      userId: Json.str(json['userId']),
      amount: Json.decimal(json['amount']),
      currency: Json.str(json['currency'], fallback: 'USD'),
      status: PaymentStatus.fromJson(json['status']),
      accountNo: Json.str(json['accountNo']),
      referenceId: Json.str(json['referenceId']),
      invoiceId: Json.str(json['invoiceId']),
      createdAt: Json.date(json['createdAt']),
      appointmentId: Json.strOrNull(json['appointmentId']),
      transactionId: Json.strOrNull(json['transactionId']),
      description: Json.strOrNull(json['description']),
      payerEmail: user == null ? null : Json.strOrNull(user['email']),
      payerName: name.isEmpty ? null : name,
    );
  }
}

/// `POST /payments` answers `{ success, data, message? }` with HTTP 402 when
/// the WaafiPay charge is declined, so the result carries both halves.
class PaymentResult {
  const PaymentResult({required this.success, this.payment, this.message});

  final bool success;
  final Payment? payment;
  final String? message;
}

/// `model ChatbotSession`
class ChatbotSession {
  const ChatbotSession({
    required this.id,
    required this.language,
    required this.isActive,
    required this.createdAt,
    this.title,
    this.endedAt,
    this.firstMessage,
  });

  final String id;
  final String language;
  final bool isActive;
  final DateTime createdAt;
  final String? title;
  final DateTime? endedAt;
  final String? firstMessage;

  factory ChatbotSession.fromJson(Map<String, dynamic> json) {
    final List<Map<String, dynamic>> messages = Json.mapList(json['messages']);
    return ChatbotSession(
      id: Json.str(json['id']),
      language: Json.str(json['language'], fallback: 'so'),
      isActive: Json.boolean(json['isActive'], fallback: true),
      createdAt: Json.date(json['createdAt']),
      title: Json.strOrNull(json['title']),
      endedAt: Json.dateOrNull(json['endedAt']),
      firstMessage: messages.isEmpty
          ? null
          : Json.strOrNull(messages.first['message']),
    );
  }

  String get displayTitle {
    final String? t = title;
    if (t != null && t.isNotEmpty) return t;
    final String? first = firstMessage;
    if (first != null && first.isNotEmpty) {
      return first.length > 45 ? '${first.substring(0, 45)}…' : first;
    }
    return 'Untitled chat';
  }
}

/// `model ChatbotMessage` — `sender` is 'USER' or 'AI'.
class ChatbotMessage {
  const ChatbotMessage({
    required this.id,
    required this.sessionId,
    required this.sender,
    required this.message,
    required this.timestamp,
  });

  final String id;
  final String sessionId;
  final String sender;
  final String message;
  final DateTime timestamp;

  factory ChatbotMessage.fromJson(Map<String, dynamic> json) {
    return ChatbotMessage(
      id: Json.str(json['id']),
      sessionId: Json.str(json['sessionId']),
      sender: Json.str(json['sender'], fallback: 'AI'),
      message: Json.str(json['message']),
      timestamp: Json.date(json['timestamp']),
    );
  }

  bool get isFromUser => sender.toUpperCase() == 'USER';

  /// Local echo so a sent message paints before the AI reply lands.
  factory ChatbotMessage.local({
    required String sessionId,
    required String message,
  }) {
    return ChatbotMessage(
      id: 'local-${DateTime.now().microsecondsSinceEpoch}',
      sessionId: sessionId,
      sender: 'USER',
      message: message,
      timestamp: DateTime.now(),
    );
  }
}

/// `model ChatbotTemplate` — admin keyword overrides.
class ChatbotTemplate {
  const ChatbotTemplate({
    required this.id,
    required this.triggerKeyword,
    required this.response,
    this.createdAt,
  });

  final String id;
  final String triggerKeyword;
  final String response;
  final DateTime? createdAt;

  factory ChatbotTemplate.fromJson(Map<String, dynamic> json) {
    return ChatbotTemplate(
      id: Json.str(json['id']),
      triggerKeyword: Json.str(json['triggerKeyword']),
      response: Json.str(json['response']),
      createdAt: Json.dateOrNull(json['createdAt']),
    );
  }
}

/// `GET /chat/contacts` — `{ id, name, role }` where `id` is a **User** id.
class ChatContact {
  const ChatContact({required this.id, required this.name, required this.role});

  final String id;
  final String name;
  final String role;

  factory ChatContact.fromJson(Map<String, dynamic> json) {
    return ChatContact(
      id: Json.str(json['id']),
      name: Json.str(json['name'], fallback: 'Contact'),
      role: Json.str(json['role']),
    );
  }
}

/// `model DirectMessage`
class DirectMessage {
  const DirectMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.isRead,
    required this.createdAt,
  });

  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final bool isRead;
  final DateTime createdAt;

  factory DirectMessage.fromJson(Map<String, dynamic> json) {
    return DirectMessage(
      id: Json.str(json['id']),
      senderId: Json.str(json['senderId']),
      receiverId: Json.str(json['receiverId']),
      content: Json.str(json['content']),
      isRead: Json.boolean(json['isRead']),
      createdAt: Json.date(json['createdAt']),
    );
  }
}
