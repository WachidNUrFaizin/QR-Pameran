import 'package:android_intent_plus/android_intent.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:lms_qr_generator/app/helper/customer_scan_coordinator.dart';
import 'package:lms_qr_generator/app/helper/scanned_helper.dart';
import 'package:lms_qr_generator/app/models/scanned_model.dart';
import 'package:lms_qr_generator/app/models/ticket_data.dart';
import 'package:lms_qr_generator/app/services/thermal_qr_image_service.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

class HomeController extends GetxController {
  final MobileScannerController cameraController = MobileScannerController();
  late final CustomerScanCoordinator _scanCoordinator = CustomerScanCoordinator(
    persist: insertScanned,
    stopCamera: cameraController.stop,
    startCamera: cameraController.start,
    canUseScanner: () => Get.isBottomSheetOpen == true,
    publish: (result) {
      scannedValue.value = result.payload;
      rawValue.value = result.canonicalPayload;
      scanError.value = '';
      debugPrint(result.canonicalPayload);
      debugPrint('${result.payload['pt']}');
    },
    closeScanner: () {
      if (Get.isBottomSheetOpen == true) {
        Get.back();
      }
    },
    reportError: (message) {
      scanError.value = message;
      Get.snackbar(
        'Error',
        message,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    },
    reportDiagnostic: (error, stackTrace) {
      debugPrint('Error processing QR: $error');
      debugPrintStack(stackTrace: stackTrace);
    },
  );

  var scannedValue = Rxn<Map<String, dynamic>>();
  var rawValue = ''.obs;
  var scanError = ''.obs;
  var scanResult = Rxn<List<BluetoothDevice>>();
  var selectedDevice = Rxn<BluetoothDevice>();
  BlueThermalPrinter printer = BlueThermalPrinter.instance;
  var isConnect = false.obs;
  var isSearching = false.obs;
  var loadingScanDevice = false.obs;

  final box = GetStorage();

  @override
  void onInit() {
    super.onInit();

    var device = box.read('bluetoothDevice');
    if (device != null) {
      printer.isConnected.then((result) {
        selectedDevice.value = BluetoothDevice(
          device['name'],
          device['address'],
        );
        if (result!) {
          isConnect.value = true;
        } else {
          connectDevice(selectedDevice.value!);
        }
      });
    }

    printer.getBondedDevices().then((list) => scanResult.value = list);
  }

  Future<void> scanDevices() async {
    isSearching.value = true;
    scanResult.value = await printer.getBondedDevices();
    isSearching.value = false;
  }

  Future<void> openBluetoothSettings() async {
    final intent = AndroidIntent(action: 'android.settings.BLUETOOTH_SETTINGS');
    await intent.launch();
  }

  Future<bool> connectDevice(BluetoothDevice device) async {
    try {
      selectedDevice.value = device;
      loadingScanDevice.value = true;
      await printer.connect(selectedDevice.value!);
      Get.snackbar(
        "Berhasil",
        "berhasil terhubung ke ${device.name}",
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      isConnect.value = true;
      loadingScanDevice.value = false;
      await box.write('bluetoothDevice', {
        'name': device.name,
        'address': device.address,
      });
      return true;
    } catch (e) {
      isConnect.value = false;
      loadingScanDevice.value = false;
      Get.snackbar(
        "Gagal",
        "Tidak bisa terhubung ke perangkat",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      forgetDevice(device);
      return false;
    }
  }

  void forgetDevice(BluetoothDevice device) {
    selectedDevice.value = null;
    printer.disconnect();
    isConnect.value = false;
    box.remove('bluetoothDevice');
  }

  void bottomSheetConnectDevice() {
    Get.bottomSheet(
      isScrollControlled: true,
      Container(
        width: Get.width,
        height: Get.height / 2 + 180,
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Get.theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            Text(
              'Pilih Perangkat',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: Get.height / 2,
              child: Obx(() {
                if (isSearching.value) {
                  return Center(child: CircularProgressIndicator());
                } else if (scanResult.value?.isEmpty ?? true) {
                  return Center(
                    child: Image.asset('assets/images/no_data.png'),
                  );
                } else {
                  return ListView(
                    children: scanResult.value!.map((device) {
                      if (selectedDevice.value != null) {
                        if (device.address == selectedDevice.value!.address) {
                          if (loadingScanDevice.value) {
                            return Shimmer(
                              duration: Duration(milliseconds: 500),
                              child: Card(
                                color: Colors.grey.shade100,
                                elevation: 0,
                                child: ListTile(
                                  title: Text(
                                    device.name ?? '-',
                                    style: Get.textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    device.address ?? '-',
                                    style: Get.textTheme.labelMedium,
                                  ),
                                ),
                              ),
                            );
                          }
                          return Card(
                            color: Get.theme.primaryColor,
                            elevation: 0,
                            child: ListTile(
                              onTap: () => forgetDevice(device),
                              title: Text(
                                device.name ?? '-',
                                style: Get.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              subtitle: Text(
                                device.address ?? '-',
                                style: Get.textTheme.labelMedium?.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          );
                        } else {
                          return Card(
                            color: Colors.white,
                            elevation: 0,
                            child: ListTile(
                              onTap: () async {
                                bool result = await connectDevice(device);
                                if (result) {
                                  Get.closeAllSnackbars();
                                  await Future.delayed(
                                    Duration(milliseconds: 100),
                                  );
                                  Get.back();
                                }
                              },
                              title: Text(
                                device.name ?? '-',
                                style: Get.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                device.address ?? '-',
                                style: Get.textTheme.labelMedium,
                              ),
                            ),
                          );
                        }
                      } else {
                        return Card(
                          color: Colors.white,
                          elevation: 0,
                          child: ListTile(
                            onTap: () async {
                              bool result = await connectDevice(device);
                              if (result) {
                                Get.closeAllSnackbars();
                                await Future.delayed(
                                  Duration(milliseconds: 100),
                                );
                                Get.back();
                              }
                            },
                            title: Text(
                              device.name ?? '-',
                              style: Get.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              device.address ?? '-',
                              style: Get.textTheme.labelMedium,
                            ),
                          ),
                        );
                      }
                    }).toList(),
                  );
                }
              }),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () => scanDevices(),
                    child: Text('Scan'),
                  ),
                ),
                const SizedBox(width: 20),
                OutlinedButton.icon(
                  onPressed: () => openBluetoothSettings(),
                  icon: Icon(Icons.settings),
                  label: Text('Pengaturan'),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void bottomSheetScan() {
    final scanSession = _scanCoordinator.beginSession();
    scanError.value = '';
    Get.bottomSheet(
      Container(
        width: Get.width,
        height: Get.height / 2,
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Get.theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            children: [
              // Kamera scanner
              MobileScanner(
                controller: cameraController,
                fit: BoxFit.cover,
                onDetect: (capture) async {
                  String? value;
                  for (final barcode in capture.barcodes) {
                    final candidate = barcode.rawValue;
                    if (candidate != null && candidate.trim().isNotEmpty) {
                      value = candidate;
                      break;
                    }
                  }
                  if (value == null) return;

                  await _scanCoordinator.process(scanSession, value);
                },
              ),

              Positioned(
                left: 20,
                right: 20,
                bottom: 20,
                child: Obx(() {
                  if (scanError.value.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withAlpha(225),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      scanError.value,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }),
              ),

              // Tombol switch kamera (pojok kanan atas)
              Positioned(
                top: 20,
                right: 20,
                child: CircleAvatar(
                  backgroundColor: Colors.black54,
                  child: IconButton(
                    icon: const Icon(Icons.cameraswitch, color: Colors.white),
                    onPressed: () {
                      cameraController.switchCamera();
                    },
                  ),
                ),
              ),

              // Tombol close (pojok kiri atas)
              Positioned(
                top: 20,
                left: 20,
                child: CircleAvatar(
                  backgroundColor: Colors.black54,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () async {
                      _scanCoordinator.endSession(scanSession);
                      if (Get.isBottomSheetOpen == true) {
                        Get.back();
                      }
                      await cameraController.stop();
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).whenComplete(() {
      _scanCoordinator.endSession(scanSession);
      scanError.value = '';
    });
  }

  Future<void> insertScanned(Map<String, dynamic> value) async {
    final scanned = ScannedItem(
      it: value["it"] ?? '',
      nt: value["nt"] ?? '',
      at: value["at"] ?? '',
      pt: value["pt"] ?? '',
      ws: value["ws"] ?? 'SA',
      telp: value["np"] ?? '',
      date: DateTime.timestamp().toIso8601String(),
    );
    final id = await DatabaseHelper.instance.insertScanned(scanned);
    debugPrint('ScannedItem inserted successfully with ID: $id');
  }

  Future<void> printTicket({ScannedItem? item}) async {
    printer.isConnected.then((isConnected) async {
      if (isConnected == true) {
        final scanData = scannedValue.value;
        final ticket = item != null
            ? TicketData.fromScannedItem(item)
            : scanData != null
            ? TicketData.fromScanMap(scanData)
            : null;

        if (ticket == null) {
          Get.snackbar(
            "Gagal",
            "Data scan tidak ditemukan",
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
          return;
        }

        printer.printCustom("ID CUSTOMER", 2, 1);
        printer.printNewLine();

        printer.printCustom("ID        : ${ticket.it}", 1, 0);
        printer.printCustom("Nama      : ${ticket.nt}", 1, 0);
        printer.printCustom("Area      : ${ticket.at}", 1, 0);
        printer.printCustom("Pelanggan : ${ticket.pt}", 1, 0);

        final noTlp = ticket.np.trim();
        if (noTlp.isNotEmpty) {
          printer.printCustom("No. Tlp   : $noTlp", 1, 0);
        }

        printer.printNewLine();

        final qrBytes = await ThermalQrImageService.build(ticket);
        printer.printImageBytes(qrBytes);

        printer.printNewLine();
        printer.printNewLine();
        printer.printNewLine();
      } else {
        bottomSheetConnectDevice();
      }
    });
  }
}
