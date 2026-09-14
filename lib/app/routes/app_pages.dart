import 'package:get/get.dart';

// Dinonaktifkan sementara bersama route CUSTOMER di bawah.
// import '../modules/customer/bindings/customer_binding.dart';
// import '../modules/customer/views/customer_view.dart';
import '../modules/home/bindings/home_binding.dart';
import '../modules/home/views/home_view.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const INITIAL = Routes.HOME;

  static final routes = [
    GetPage(
      name: _Paths.HOME,
      page: () => const HomeView(),
      binding: HomeBinding(),
    ),
    // Route Customer disembunyikan sementara (CRUD Customer belum dipakai).
    // File modul customer/ tetap ada, tinggal uncomment blok ini dan
    // import-nya di atas untuk mengaktifkan kembali.
    // GetPage(
    //   name: _Paths.CUSTOMER,
    //   page: () => const CustomerView(),
    //   binding: CustomerBinding(),
    // ),
  ];
}