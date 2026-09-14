import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:lms_qr_generator/app/helper/scanned_helper.dart';
import 'package:lms_qr_generator/app/models/customer_model.dart';
import 'package:lms_qr_generator/app/models/ticket_data.dart';
import 'package:lms_qr_generator/app/services/thermal_qr_image_service.dart';

class CustomerController extends GetxController {
  final customers = <CustomerItem>[].obs;
  final isLoading = false.obs;

  final box = GetStorage();
  final BlueThermalPrinter printer = BlueThermalPrinter.instance;
  var selectedDevice = Rxn<BluetoothDevice>();
  var isConnect = false.obs;
  var loadingScanDevice = false.obs;

  @override
  void onInit() {
    super.onInit();
    _initPrinter();
    loadCustomers();
  }

  Future<void> _initPrinter() async {
    var device = box.read('bluetoothDevice');
    if (device != null) {
      printer.isConnected.then((result) {
        selectedDevice.value = BluetoothDevice(
          device['name'],
          device['address'],
        );
        if (result == true) {
          isConnect.value = true;
        } else {
          connectDevice(selectedDevice.value!);
        }
      });
    }
  }

  Future<void> loadCustomers() async {
    isLoading.value = true;
    try {
      final result = await DatabaseHelper.instance.getCustomers();
      customers.value = result
          .map((data) => CustomerItem.fromMap(data))
          .toList();
    } catch (e) {
      Get.snackbar(
        "Gagal",
        "Tidak bisa memuat data customer",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> saveCustomer(CustomerItem item) async {
    final isNew = item.id == null;
    try {
      if (isNew) {
        await DatabaseHelper.instance.insertCustomer(item.toMap());
      } else {
        await DatabaseHelper.instance.updateCustomer(item.toMap());
      }
      await loadCustomers();
      Get.snackbar(
        "Berhasil",
        isNew ? "Customer berhasil disimpan" : "Customer berhasil diperbarui",
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 2),
      );
      return true;
    } catch (e) {
      Get.snackbar(
        "Gagal",
        "Tidak bisa menyimpan customer",
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
      return false;
    }
  }

  Future<void> deleteCustomer(CustomerItem item) async {
    if (item.id == null) return;
    try {
      await DatabaseHelper.instance.deleteCustomer(item.id!);
      await loadCustomers();
      Get.snackbar(
        "Berhasil",
        "Customer berhasil dihapus",
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar(
        "Gagal",
        "Tidak bisa menghapus customer",
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    }
  }

  Future<bool> connectDevice(BluetoothDevice device) async {
    try {
      selectedDevice.value = device;
      loadingScanDevice.value = true;
      await printer.connect(selectedDevice.value!);
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
      return false;
    }
  }

  String buildQrPayload(CustomerItem item) {
    return TicketData.fromCustomerItem(item).qrPayload;
  }

  Future<void> printCustomerCard(CustomerItem item) async {
    printer.isConnected.then((isConnected) async {
      if (isConnected == true) {
        final ticket = TicketData.fromCustomerItem(item);

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
        Get.snackbar(
          "Printer",
          "Bluetooth belum terhubung",
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
      }
    });
  }
}
