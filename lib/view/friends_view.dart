import 'package:chat_app/controllers/friends_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get_state_manager/src/simple/get_view.dart';

class FriendsView extends GetView<FriendsController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Friends'),
      ),
      body: Center(
        child: Text('Friends View'),
      ),
    );
  }
}