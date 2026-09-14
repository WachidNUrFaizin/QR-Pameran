import 'package:flutter/material.dart';
import 'package:get/get.dart';
// Dinonaktifkan sementara bersama tombol Preview PDF di bawah.
// import 'package:lms_qr_generator/app/models/ticket_data.dart';
import 'package:lms_qr_generator/app/modules/home/views/riwayat_view.dart';
// Dinonaktifkan sementara bersama menu Customer di bawah.
// import 'package:lms_qr_generator/app/routes/app_pages.dart';
// Dinonaktifkan sementara bersama tombol Preview PDF di bawah.
// import 'package:lms_qr_generator/app/shared/ticket_pdf_preview_page.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../controllers/home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Header drawer
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.white),
              child: Center(
                child: Image.asset('assets/images/logo.png', width: 100),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Beranda'),
              onTap: () {
                Navigator.pop(context);
                Get.toNamed('/scan'); // contoh pakai GetX route
              },
            ),
            // Menu Customer disembunyikan sementara (CRUD Customer belum dipakai).
            // Untuk mengaktifkan lagi: uncomment blok ini, import app_pages.dart
            // di atas, dan route CUSTOMER di lib/app/routes/app_pages.dart.
            // ListTile(
            //   leading: const Icon(Icons.badge),
            //   title: const Text('Customer'),
            //   onTap: () {
            //     Navigator.pop(context);
            //     Get.toNamed(Routes.CUSTOMER);
            //   },
            // ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Riwayat'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RiwayatPage()),
                );
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: Text('LMS QR Generator', style: Get.textTheme.headlineSmall),
        actions: [
          Obx(() {
            if (controller.isConnect.value) {
              return Icon(Icons.bluetooth, color: Colors.green);
            } else {
              return Icon(Icons.bluetooth_disabled, color: Colors.red);
            }
          }),
          const SizedBox(width: 20),
          IconButton(
            onPressed: () => controller.bottomSheetConnectDevice(),
            style: IconButton.styleFrom(
              backgroundColor: Get.theme.primaryColor.withAlpha(50),
            ),
            icon: Icon(Icons.settings),
          ),
          const SizedBox(width: 20),
        ],
      ),
      floatingActionButton: FilledButton.icon(
        onPressed: () => controller.bottomSheetScan(),
        icon: Icon(Icons.camera),
        label: Text('Scan'),
      ),
      body: Obx(() {
        if (controller.scannedValue.value == null) {
          return Center(
            child: Image.asset('assets/images/no_data.png', scale: 2),
          );
        } else {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Card(
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Builder(
                          builder: (_) {
                            final hp =
                                controller.scannedValue.value?['np']
                                    ?.toString()
                                    .trim() ??
                                '';
                            final wsRaw =
                                controller.scannedValue.value?['ws']
                                    ?.toString() ??
                                '';
                            final grossir = wsRaw.trim().isEmpty
                                ? 'SA'
                                : wsRaw.trim();
                            return Table(
                              columnWidths: const {
                                0: IntrinsicColumnWidth(),
                                1: FixedColumnWidth(10),
                                2: FlexColumnWidth(),
                              },
                              children: [
                                _buildRow(
                                  "ID Toko",
                                  "${controller.scannedValue.value!["it"]}",
                                ),
                                _buildRow(
                                  "Nama Toko",
                                  "${controller.scannedValue.value!["nt"]}",
                                ),
                                _buildRow(
                                  "Area Toko",
                                  "${controller.scannedValue.value!["at"]}",
                                ),
                                _buildRow(
                                  "Pelanggan Toko",
                                  "${controller.scannedValue.value!["pt"]}",
                                ),
                                _buildRow("Grosir", grossir),
                                if (hp.isNotEmpty) _buildRow("No. Tlp", hp),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 12),
                        // Bagian QR Code
                        const Text(
                          "QR Code",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        QrImageView(
                          data: controller.rawValue.value,
                          version: QrVersions.auto,
                          size: 180,
                          gapless: false,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                if (controller.scannedValue.value != null)
                  // Layout Row (Hapus + Cetak) seperti sebelum commit ee7fc24.
                  // Kalau tombol Preview PDF diaktifkan lagi, kembalikan Row ini
                  // menjadi: Wrap(spacing: 12, runSpacing: 12,
                  // alignment: WrapAlignment.center) dan buang SizedBox
                  // beserta Expanded di bawah.
                  Row(
                    children: [
                      FilledButton.icon(
                        onPressed: () {
                          controller.scannedValue.value = null;
                          controller.rawValue.value = '';
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        icon: const Icon(Icons.delete),
                        label: const Text('Hapus'),
                      ),
                      const SizedBox(width: 20),
                      // Tombol Preview PDF disembunyikan sementara.
                      // Untuk mengaktifkan lagi: uncomment blok ini beserta
                      // import ticket_data.dart dan ticket_pdf_preview_page.dart
                      // di bagian atas file.
                      // OutlinedButton.icon(
                      //   onPressed: () {
                      //     final data = controller.scannedValue.value;
                      //     if (data == null) return;
                      //     Get.to(
                      //       () => TicketPdfPreviewPage(
                      //         ticketData: TicketData.fromScanMap(data),
                      //       ),
                      //     );
                      //   },
                      //   icon: const Icon(Icons.picture_as_pdf),
                      //   label: const Text('Preview PDF'),
                      // ),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => controller.printTicket(),
                          icon: const Icon(Icons.print),
                          label: const Text('Cetak'),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          );
        }
      }),
    );
  }

  TableRow _buildRow(String label, String value) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 6, 20, 6),
          child: Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 6),
          child: Text(":"),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(value, style: const TextStyle(fontSize: 16)),
        ),
      ],
    );
  }
}
