/*
 * Copyright (C) 2017, David PHAM-VAN <dev.nfet.net@gmail.com>
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'catalog.dart';
import 'data_types.dart';
import 'document.dart';
import 'encryption.dart';
import 'info.dart';
import 'object.dart';
import 'signature.dart';
import 'stream.dart';
import 'xref.dart';

/// PDF document writer
class PdfOutput {
  /// This creates a Pdf [PdfStream]
  PdfOutput(this.os, this.version) {
    String v;
    switch (version) {
      case PdfVersion.pdf_1_4:
        v = '1.4';
        break;
      case PdfVersion.pdf_1_5:
        v = '1.5';
        break;
    }

    os.putString('%PDF-$v\n');
    os.putBytes(const <int>[0x25, 0xC2, 0xA5, 0xC2, 0xB1, 0xC3, 0xAB, 0x0A]);
  }

  /// Pdf version to output
  final PdfVersion version;

  /// This is the actual [PdfStream] used to write to.
  final PdfStream os;

  /// Cross reference table
  final xref = PdfXrefTable();

  /// This is used to track the /Root object (catalog)
  PdfCatalog? rootID;

  /// This is used to track the /Info object (info)
  PdfInfo? infoID;

  /// This is used to track the /Encrypt object (encryption)
  PdfEncryption? encryptID;

  /// This is used to track the /Sign object (signature)
  PdfSignature? signatureID;

  /// Generate a compressed cross reference table
  bool get isCompressed => version.index > PdfVersion.pdf_1_4.index;

  /// This method writes a [PdfObject] to the stream.
  void write(PdfObject ob) {
    // Check the object to see if it's one that is needed later
    if (ob is PdfCatalog) {
      rootID = ob;
    } else if (ob is PdfInfo) {
      infoID = ob;
    } else if (ob is PdfEncryption) {
      encryptID = ob;
    } else if (ob is PdfSignature) {
      assert(signatureID == null, 'Only one document signature is allowed');
      signatureID = ob;
    }

    xref.add(PdfXref(ob.objser, os.offset));
    ob.write(os);
  }

  /// This closes the Stream, writing the xref table
  Future<void> close() async {
    if (rootID == null) {
      throw Exception('Root object is not present in document');
    }

    final params = PdfDict();

    // the number of entries (REQUIRED)
    params['/Size'] = PdfNum(rootID!.pdfDocument.objser);

    // the /Root catalog indirect reference (REQUIRED)
    params['/Root'] = rootID!.ref();
    final id =
        PdfString(rootID!.pdfDocument.documentID, PdfStringFormat.binary);
    params['/ID'] = PdfArray([id, id]);

    // the /Info reference (OPTIONAL)
    if (infoID != null) {
      params['/Info'] = infoID!.ref();
    }

    // the /Encrypt reference (OPTIONAL)
    if (encryptID != null) {
      params['/Encrypt'] = encryptID!.ref();
    }

    if (rootID!.pdfDocument.prev != null) {
      params['/Prev'] = PdfNum(rootID!.pdfDocument.prev!.xrefOffset);
    }

    final _xref = os.offset;
    if (isCompressed) {
      xref.outputCompressed(rootID!, os, params);
    } else {
      xref.output(os);
    }

    if (!isCompressed) {
      // the trailer object
      os.putString('trailer\n');
      params.output(os);
      os.putByte(0x0a);
    }

    // the reference to the xref object
    os.putString('startxref\n$_xref\n%%EOF\n');

    if (signatureID != null) {
      await signatureID!.writeSignature(os);
    }
  }
}
