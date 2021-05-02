# Pdf Printing Example

This example project combines https://github.com/DavBfr/dart_pdf and Another Brother https://github.com/CodeMinion/another_brother.

Steps ussed (23 min):

1. Clone https://github.com/DavBfr/dart_pdf
2. Open the `demo` project.
3. Add the missing fonts. 
4. Add the misisng profile picture (I picked Pikachu)
5. Run in the terminal `flutter pub get`
6. Run the project to make sure everything works.
7. Add Another Brother to your `pubspec.yaml`

```
     another_brother:
       git:
         url: git://github.com/CodeMinion/another_brother.git
```
8. Run in the terminal `flutter pub get`
9. Open the Android app `build.grade` and increase the `minSdkVersion` to `19`. Another Brother supportss 19+. 
10. Run the project to make sure everything works.
11. Now you want to add the code to integrate. If you try to compile you will get an error because you will have 2 libraries that define a `Printer` object. You have to do this:
```
import 'package:another_brother/printer_info.dart' as brother;
```
12. Add the example below Here is a modified example from the Another Brother Demo app.

```
void brotherPrint(BuildContext context, String filePath) async {

    var printer = new brother.Printer();
    var printInfo = brother.PrinterInfo();
    printInfo.printerModel = brother.Model.PJ_763MFi;
    printInfo.printMode = brother.PrintMode.FIT_TO_PAPER;
    printInfo.isAutoCut = false;
    printInfo.port = brother.Port.BLUETOOTH;
    // Set the label type.
    //printInfo.labelNameIndex = QL1100.ordinalFromID(QL1100.W103.getId());

    // Set the printer info so we can use the SDK to get the printers.
    await printer.setPrinterInfo(printInfo);

    // Get a list of printers with my model available in the network.
    List<brother.BluetoothPrinter> printers = await printer.getBluetoothPrinters([brother.Model.PJ_763MFi.getName()]);

    if (printers.isEmpty) {
      // Show a message if no printers are found.
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text("No paired printers found on your device."),
        ),
      ));

      return;
    }
    // Get the IP Address from the first printer found.
    printInfo.macAddress = printers.single.macAddress;

    await printer.setPrinterInfo(printInfo);
    printer.printPdfFile(filePath, 1);
  }
```
This example uses Bluetooth to print on a `PJ_763MFi`.

13. The `PdfPreview` class handles displaying the PDF and printing it for you. Unfortunately, I could not see a way to attach a print action. So I had to modify that file. Go to line `437` and comment this out:
```
/*if (widget.allowPrinting && info.canPrint) {
      actions.add(
        IconButton(
          icon: const Icon(Icons.print),
          onPressed: _print,
        ),
      );
    }*/
```
What you are doing is removing the automatic print so that we can replace it with our own in the `app.dart`. This was the easiest way I found to add the printing functionality without modifying the library too much.

14. Now we can add an `action` in the `Widget build(BuildContext context)`
```
  @override
  Widget build(BuildContext context) {
    pw.RichText.debug = true;

    if (_tabController == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final actions = <PdfPreviewAction>[
      PdfPreviewAction(
        icon: const Icon(Icons.print),
        onPressed: _printFile,
      ),
```
What we are doing is adding a printer button to replace the one we removed from the `PdfPreview` class earlier. 

15. Take the `_saveAsFile`, copy it, and modify it to print by adding: 

```
  brotherPrint(context, file.path);
```
  



