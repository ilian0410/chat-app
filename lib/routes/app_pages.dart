import 'package:chat_app/controllers/auth_controller.dart';
import 'package:chat_app/routes/app_routes.dart';
import 'package:chat_app/view/auth/login_view.dart';
import 'package:chat_app/view/auth/register_view.dart';
import 'package:chat_app/view/auth/splash_view.dart';
import 'package:get/get.dart';

class AppPages {
  AppPages._();

  static const initial = AppRoutes.splash;

  static final routes = [
    GetPage(name: AppRoutes.splash, page: () => SplashView()),
    GetPage(name: AppRoutes.login, page: () => LoginView()),
    GetPage(name: AppRoutes.register, page: () => RegisterView()),

    /*GetPage(
      name: AppRoutes.home,
      page: () => HomeView(),
      binding: BindingsBuilder((){
        Get.put(HomeController());
      })
    ),
    GetPage(
      name: AppRoutes.main,
      page: () => MainView(),
      binding: BindingsBuilder((){
        Get.put(MainController());
      })
    ),
   
    
    GetPage(
      name: AppRoutes.forgotPassword,
      page: () => ForgotPasswordView(),
      binding: BindingsBuilder((){
        Get.put(ForgotPasswordController());
      })
    ),
    GetPage(
      name: AppRoutes.changePassword,
      page: () => ChangePasswordView(),
      binding: BindingsBuilder((){
        Get.put(ChangePasswordController());
      })
    ),    GetPage(
      name: AppRoutes.profile,
      page: () => ProfileView(),
    ),    GetPage(
      name: AppRoutes.chat,
      page: () => ChatView(),
    ),    GetPage(
      name: AppRoutes.usersList,
      page: () => UsersListView(),
      binding: BindingsBuilder((){
        Get.put(UsersListController());
      })
    ),    GetPage(
      name: AppRoutes.friends,
      page: () => FriendsView(),
      binding: BindingsBuilder((){
        Get.put(FriendsController());
      })
    ),    GetPage(
      name: AppRoutes.friendRequests,
      page: () => FriendRequestsView(),
      binding: BindingsBuilder((){
        Get.put(NotificationsController());
      })
    ),    GetPage(
      name: AppRoutes.notifications,
      page: () => NotificationsView(),
      binding: BindingsBuilder((){
        Get.put(NotificationsController());
      })
    ),*/
  ];
}
