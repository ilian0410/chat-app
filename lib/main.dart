import 'package:chat_app/firebase_options.dart';
import 'package:chat_app/routes/app_pages.dart';
import 'package:chat_app/theme/app_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Chat App',
      theme: AppTheme.lightTheme,
      themeMode: ThemeMode.light,
initialRoute: AppPages.initial,
getPages: AppPages.routes,

      debugShowMaterialGrid: false, 
    );
    
  }
}