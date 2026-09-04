import 'dart:typed_data';
import 'package:printing/printing.dart';
import '../../core/models/print_layout.dart';

abstract class PrinterService {
  Future<List<Printer>> getPrinters();
  Future<Printer?> getDefaultPrinter();
  Future<bool> printLayout(PrintLayout layout, {Printer? printer, String? jobName});
  Future<bool> directPrintPdf(Uint8List pdfBytes, {Printer? printer, String? jobName});
  Future<bool> showPrintDialog(PrintLayout layout);
  Future<bool> exportPdf(PrintLayout layout, String suggestedFileName);
  Future<bool> printMultiLayout(List<PrintLayout> layouts, {Printer? printer, String? jobName});
  Future<bool> exportMultiLayoutPdf(List<PrintLayout> layouts, String suggestedFileName);
}
