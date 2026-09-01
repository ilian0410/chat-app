import 'package:chat_app/controllers/auth_controller.dart';
import 'package:chat_app/routes/app_routes.dart';
import 'package:chat_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    _animationController.forward();

    _checkAuthAndNavigate();
    // will implement check if logged in auth controller in upcoming videos
  }

  void _checkAuthAndNavigate() async {
    await Future.delayed(const Duration(seconds: 3));
    final authController = Get.put(AuthController(), permanent: true);
    await Future.delayed(const Duration(milliseconds: 500));
    if(authController.isAuthenticated){
      Get.offAllNamed(AppRoutes.main);
    } else {
      Get.offAllNamed(AppRoutes.login);
    }
  }

void dispose() {
    _animationController.dispose();
    super.dispose();
  } 

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: Center(
        child: AnimatedBuilder(animation: _animationController, 
        builder:(context,child){
          return FadeTransition(opacity: _fadeAnimation,
          child: ScaleTransition(scale: _scaleAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration:  BoxDecoration(
                  color: Colors.white,
borderRadius:  BorderRadius.circular(30)   ,
boxShadow: [
  BoxShadow(
    color: Colors.black26,
    blurRadius: 10,
    offset: Offset(0, 4),
  )
]
            ),
            child: Icon(
              Icons.chat_bubble_rounded,
              size:60,  
              ) ,
              ),
             SizedBox(height: 32,),
             Text(
              "Chat App",
              style: Theme.of(  context).textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold
              ),
              
             ),
             SizedBox(height: 32,),
             Text("connect with your friends and family",
             style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withOpacity( 0.8),
              fontWeight: FontWeight.normal
             ),
              ),
              SizedBox(height: 64,),
              CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
              )
            ],
          )
          )
            );
        }
        )
      )
    );
  }
}
