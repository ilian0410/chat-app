// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:chat_app/models/chat_model.dart';

void main() {
  test('chat model resolves the other participant and unread count', () {
    final chat = ChatModel(
      id: 'chat-id',
      participants: ['current-user', 'other-user'],
      unreadCount: {'current-user': 2},
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

    expect(chat.getOtherParticipant('current-user'), 'other-user');
    expect(chat.getUnreadCount('current-user'), 2);
  });
}
