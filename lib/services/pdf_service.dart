import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/parade_day.dart';
import '../models/corps_data.dart';
import '../models/military_order.dart';
import '../models/lsa_item.dart';

class PdfService {
  static Future<void> generateRoutineOrders(ParadeDay day, CorpsData corps) async {
    final pdf = await _buildPdf(day, corps);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'RO_${day.date}.pdf',
    );
  }

  static Future<void> exportRoutineOrders(ParadeDay day, CorpsData corps) async {
    final pdf = await _buildPdf(day, corps);
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'RO_${day.date}.pdf',
    );
  }

  static Future<void> generateWarningOrder(WarningOrder order, CorpsData corps) async {
    final pdf = await _buildWarningOrderPdf(order, corps);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'WNG_O_${order.date.replaceAll(' ', '_')}.pdf',
    );
  }

  static Future<void> exportWarningOrder(WarningOrder order, CorpsData corps) async {
    final pdf = await _buildWarningOrderPdf(order, corps);
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'WNG_O_${order.date.replaceAll(' ', '_')}.pdf',
    );
  }

  static Future<void> generateOperationOrder(OperationOrder order, CorpsData corps) async {
    final pdf = await _buildOperationOrderPdf(order, corps);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'OPORD_${order.date.replaceAll(' ', '_')}.pdf',
    );
  }

  static Future<void> generateLSASponsorMemo(CorpsData corps, List<LsaItem> items) async {
    final pdf = await _buildLsaSponsorMemoPdf(corps, items);
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'LSA_Sponsor_Memo.pdf',
    );
  }

  static Future<void> exportOperationOrder(OperationOrder order, CorpsData corps) async {
    final pdf = await _buildOperationOrderPdf(order, corps);
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'OPORD_${order.date.replaceAll(' ', '_')}.pdf',
    );
  }

  static Future<pw.Document> _buildPdf(ParadeDay day, CorpsData corps) async {
    final roboto = await PdfGoogleFonts.robotoRegular();
    final robotoBold = await PdfGoogleFonts.robotoBold();

    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: roboto,
        bold: robotoBold,
      ),
    );

    pw.ImageProvider? logoImage;
    if (corps.logoUrl != null) {
      try {
        logoImage = await networkImage(corps.logoUrl!);
      } catch (e) {
        // Fallback if image fails to load
      }
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.letter,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(40),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Center(
                  child: pw.Column(
                    children: [
                      if (logoImage != null)
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(bottom: 10),
                          child: pw.Image(logoImage, height: 60),
                        ),
                      pw.Text(
                        'ROUTINE ORDERS',
                        style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(
                        'Issued by ${corps.coRank} ${corps.coName}',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                      pw.Text(
                        corps.unitDesignation.toUpperCase(),
                        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(height: 10),
                      pw.Container(height: 1, width: 300, color: PdfColors.black),
                      pw.SizedBox(height: 10),
                      pw.Text(
                        'FOR THE PERIOD OF ${day.date.toUpperCase()}',
                        style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 40),

                // PART 1 - TRAINING
                _buildSectionTitle('PART 1 - TRAINING'),
                ...day.periods.entries.map((p) {
                  return pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 10),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'PERIOD ${p.key.toUpperCase()}',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
                        ),
                        ...(p.value as Map).entries.map((lvl) {
                          final lesson = lvl.value['lessonId'] ?? 'TBD';
                          final inst = lvl.value['instructor'] ?? 'TBD';
                          final loc = lvl.value['location'] ?? 'Main Deck';
                          return pw.Bullet(
                            text: '${lvl.key}: $lesson ($inst) at $loc',
                            style: const pw.TextStyle(fontSize: 10),
                          );
                        }).toList(),
                      ],
                    ),
                  );
                }).toList(),

                pw.SizedBox(height: 20),

                // PART 2 - PERSONNEL & DUTIES
                _buildSectionTitle('PART 2 - PERSONNEL & DUTIES'),
                _buildDutyRow('DUTY OFFICER', day.dutyRoster['dutyOfficer'] ?? 'TBD'),
                _buildDutyRow('DUTY PETTY OFFICER', day.dutyRoster['dutyPO'] ?? 'TBD'),
                _buildDutyRow('DUTY COXSWAIN', day.dutyRoster['dutyCoxn'] ?? 'TBD'),
                _buildDutyRow('DUTY DIVISION', day.dutyRoster['dutyDivision'] ?? 'TBD'),

                if (day.announcements.isNotEmpty) ...[
                  pw.SizedBox(height: 20),
                  _buildSectionTitle('PART 3 - ANNOUNCEMENTS'),
                  ...day.announcements.map((a) => pw.Bullet(text: a, style: const pw.TextStyle(fontSize: 10))),
                ],
              ],
            ),
          );
        },
      ),
    );

    return pdf;
  }

  static pw.Widget _buildSectionTitle(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 15),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13)),
          pw.Container(height: 0.5, width: double.infinity, color: PdfColors.grey),
        ],
      ),
    );
  }

  static pw.Widget _buildDutyRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 5),
      child: pw.Row(
        children: [
          pw.SizedBox(width: 150, child: pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
          pw.Text(value, style: const pw.TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  static Future<pw.Document> _buildWarningOrderPdf(WarningOrder order, CorpsData corps) async {
    final roboto = await PdfGoogleFonts.robotoRegular();
    final robotoBold = await PdfGoogleFonts.robotoBold();

    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: roboto,
        bold: robotoBold,
      ),
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(40),
        header: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.center,
            margin: const pw.EdgeInsets.only(bottom: 20),
            child: pw.Text(
              'CAN UNCLASSIFIED',
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
            ),
          );
        },
        footer: (pw.Context context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(top: 20),
            child: pw.Column(
              children: [
                pw.Divider(thickness: 0.5),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('CAN UNCLASSIFIED', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    pw.Text('Page ${context.pageNumber} of ${context.pagesCount}', style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
              ],
            ),
          );
        },
        build: (pw.Context context) {
          return [
            // Bilingual Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: corps.ordersHeaderEn.split('\n').asMap().entries.map((e) {
                      return pw.Text(
                        e.value,
                        style: pw.TextStyle(fontSize: 9, fontWeight: e.key == 0 ? pw.FontWeight.bold : pw.FontWeight.normal),
                      );
                    }).toList(),
                  ),
                ),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: corps.ordersHeaderFr.split('\n').asMap().entries.map((e) {
                      return pw.Text(
                        e.value,
                        style: pw.TextStyle(fontSize: 9, fontWeight: e.key == 0 ? pw.FontWeight.bold : pw.FontWeight.normal),
                        textAlign: pw.TextAlign.right,
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 15),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(order.fileNumber, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                pw.Text(order.date, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
              ],
            ),
            pw.Text('Distribution List', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
            pw.SizedBox(height: 15),
            pw.Center(
              child: pw.Text(
                order.subject.toUpperCase(),
                style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, decoration: pw.TextDecoration.underline),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.SizedBox(height: 15),
            
            // References
            pw.Text('References: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
            ...order.references.map((ref) => pw.Padding(
              padding: const pw.EdgeInsets.only(left: 20, bottom: 2),
              child: pw.Text(ref, style: const pw.TextStyle(fontSize: 10)),
            )),
            pw.SizedBox(height: 15),

            // SITUATION
            _buildMilitarySection('SITUATION', [
              pw.Text('1. ${order.situation}', style: const pw.TextStyle(fontSize: 10)),
            ]),

            // MISSION
            _buildMilitarySection('MISSION', [
              pw.Text('2. ${order.mission}', style: const pw.TextStyle(fontSize: 10)),
            ]),

            // EXECUTION
            _buildMilitarySection('EXECUTION', [
              pw.Text('3. Administration Instructions:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
              _buildSubParagraph('a. Orders:', order.adminOrders),
              _buildSubParagraph('b. Joining Instructions (JIs):', order.adminJIs),
              _buildSubParagraph('c. Participant Eligibility:', order.participantEligibility),
              _buildSubParagraph('d. Registration of Participants:', order.registrationOfParticipants),
              _buildSubParagraph('e. Support Cadet Opportunities:', order.supportCadetOpportunities),
              _buildSubParagraph('f. Adult Staffing Opportunities:', order.adultStaffingOpportunities),
              _buildSubParagraph('g. Request for Accommodation:', order.requestForAccommodation),
              _buildSubParagraph('h. Contingency Plans:', order.contingencyPlans),
              _buildSubParagraph('i. Lessons Learned:', order.lessonsLearned),
              _buildSubParagraph('j. Gender Based Analysis Plus (GBA+):', order.gbaPlus),
            ]),

            // SERVICE SUPPORT
            _buildMilitarySection('SERVICE SUPPORT', [
              _buildSubParagraph('4. Pay:', order.pay),
              _buildSubParagraph('5. Travel:', order.travel),
              _buildSubParagraph('6. Rations:', order.rations),
              _buildSubParagraph('7. Lodgings:', order.lodgings),
              _buildSubParagraph('8. Transportation:', order.transportation),
              _buildSubParagraph('9. Equipment / Training Facilities:', order.equipment),
              _buildSubParagraph('10. Public Affairs:', order.publicAffairs),
              _buildSubParagraph('11. Financial Authorization:', order.financialAuthorization),
            ]),

            // COMMAND AND SIGNALS
            _buildMilitarySection('COMMAND AND SIGNALS', [
              pw.Text('12. Contact Information:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
              ...order.contacts.map((c) {
                final role = c['role'] ?? '';
                final name = c['name'] ?? '';
                final phone = c['phone'] ?? '';
                final email = c['email'] ?? '';
                return pw.Padding(
                  padding: const pw.EdgeInsets.only(left: 20, top: 4),
                  child: pw.Text('• $role – $name – $phone / $email', style: const pw.TextStyle(fontSize: 10)),
                );
              }),
              pw.SizedBox(height: 25),
              // Signature
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(corps.coName, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                    pw.Text(corps.coRank, style: const pw.TextStyle(fontSize: 10)),
                    pw.Text('Commanding Officer', style: const pw.TextStyle(fontSize: 10)),
                    pw.Text(corps.unitDesignation, style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
              ),
            ]),

            // Annex A: Serials
            pw.NewPage(),
            pw.Center(
              child: pw.Text(
                'Annex A\n${order.fileNumber}\n${order.date}',
                style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Center(
              child: pw.Text(
                'SERIALS AND CORPS / SQUADRON ASSIGNMENTS',
                style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, decoration: pw.TextDecoration.underline),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.SizedBox(height: 15),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('SERIAL / CODE', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('DATES / LOCATION', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('ELEMENT', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('CORPS / SQUADRONS', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                    ),
                  ],
                ),
                ...order.serials.map((s) => pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('${s['serial'] ?? ''}\n${s['code'] ?? ''}', style: const pw.TextStyle(fontSize: 8)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('${s['dates'] ?? ''}\n${s['location'] ?? ''}', style: const pw.TextStyle(fontSize: 8)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(s['element'] ?? '', style: const pw.TextStyle(fontSize: 8)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(s['units'] ?? '', style: const pw.TextStyle(fontSize: 8)),
                    ),
                  ],
                )).toList(),
              ],
            ),
            pw.SizedBox(height: 25),
            // Distribution List
            pw.Text('Distribution List', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
            pw.SizedBox(height: 5),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Action:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                      ...order.distributionAction.map((d) => pw.Padding(
                        padding: const pw.EdgeInsets.only(left: 10),
                        child: pw.Text('• $d', style: const pw.TextStyle(fontSize: 9)),
                      )),
                    ],
                  ),
                ),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Information:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                      ...order.distributionInfo.map((d) => pw.Padding(
                        padding: const pw.EdgeInsets.only(left: 10),
                        child: pw.Text('• $d', style: const pw.TextStyle(fontSize: 9)),
                      )),
                    ],
                  ),
                ),
              ],
            ),
          ];
        },
      ),
    );

    return pdf;
  }

  static Future<pw.Document> _buildOperationOrderPdf(OperationOrder order, CorpsData corps) async {
    final roboto = await PdfGoogleFonts.robotoRegular();
    final robotoBold = await PdfGoogleFonts.robotoBold();

    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: roboto,
        bold: robotoBold,
      ),
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(40),
        header: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.center,
            margin: const pw.EdgeInsets.only(bottom: 20),
            child: pw.Text(
              'CAN UNCLASSIFIED',
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
            ),
          );
        },
        footer: (pw.Context context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(top: 20),
            child: pw.Column(
              children: [
                pw.Divider(thickness: 0.5),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('CAN UNCLASSIFIED', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    pw.Text('Page ${context.pageNumber} of ${context.pagesCount}', style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
              ],
            ),
          );
        },
        build: (pw.Context context) {
          return [
            // Bilingual Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: corps.ordersHeaderEn.split('\n').asMap().entries.map((e) {
                      return pw.Text(
                        e.value,
                        style: pw.TextStyle(fontSize: 9, fontWeight: e.key == 0 ? pw.FontWeight.bold : pw.FontWeight.normal),
                      );
                    }).toList(),
                  ),
                ),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: corps.ordersHeaderFr.split('\n').asMap().entries.map((e) {
                      return pw.Text(
                        e.value,
                        style: pw.TextStyle(fontSize: 9, fontWeight: e.key == 0 ? pw.FontWeight.bold : pw.FontWeight.normal),
                        textAlign: pw.TextAlign.right,
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 15),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(order.fileNumber, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                pw.Text(order.date, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
              ],
            ),
            pw.Text('Distribution List', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
            pw.SizedBox(height: 15),
            pw.Center(
              child: pw.Text(
                order.subject.toUpperCase(),
                style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, decoration: pw.TextDecoration.underline),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.SizedBox(height: 15),

            // References
            pw.Text('References: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
            ...order.references.map((ref) => pw.Padding(
              padding: const pw.EdgeInsets.only(left: 20, bottom: 2),
              child: pw.Text(ref, style: const pw.TextStyle(fontSize: 10)),
            )),
            pw.SizedBox(height: 15),

            // SITUATION
            _buildMilitarySection('SITUATION', [
              pw.Text('1. ${order.situation}', style: const pw.TextStyle(fontSize: 10)),
            ]),

            // MISSION
            _buildMilitarySection('MISSION', [
              pw.Text('2. ${order.mission}', style: const pw.TextStyle(fontSize: 10)),
            ]),

            // EXECUTION
            _buildMilitarySection('EXECUTION', [
              pw.Text('3. Concept of Operations:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
              _buildSubParagraph('a. Command Intent:', order.conceptCommandIntent),
              _buildSubParagraph('b. Scheme of Maneuver:', order.conceptSchemeOfManeuver),
              _buildSubParagraph('c. General Outline:', order.conceptGeneralOutline),
              _buildSubParagraph('d. End State:', order.conceptEndState),
              _buildSubParagraph('4. Contingency Plan:', order.contingencyPlan),
              _buildSubParagraph('5. Groupings:', order.groupings),
              _buildSubParagraph('6. Taskings:', order.taskings),
              pw.Text('7. Coordinating Instructions:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
              _buildSubParagraph('a. Orders:', order.adminOrders),
              _buildSubParagraph('b. Participant Eligibility / Selection:', order.participantEligibility),
              _buildSubParagraph('c. Registration of Participants:', order.registrationOfParticipants),
              _buildSubParagraph('d. Support Cadet Eligibility:', order.supportCadetEligibility),
              _buildSubParagraph('e. Adult Staffing Opportunities:', order.adultStaffingOpportunities),
              _buildSubParagraph('f. Lessons Learned:', order.lessonsLearned),
              _buildSubParagraph('g. Dress:', order.dress),
              _buildSubParagraph('h. Medical / Emergency:', order.medicalEmergency),
              _buildSubParagraph('i. Conduct / Discipline:', order.conductDiscipline),
              _buildSubParagraph('8. Gender Based Analysis Plus (GBA+):', order.gbaPlus),
            ]),

            // SERVICE SUPPORT
            _buildMilitarySection('SERVICE SUPPORT', [
              _buildSubParagraph('9. Pay:', order.pay),
              _buildSubParagraph('10. Lodgings:', order.lodgings),
              _buildSubParagraph('11. Transportation:', order.transportation),
              _buildSubParagraph('12. Rations:', order.rations),
              _buildSubParagraph('13. Request for Accommodation:', order.requestForAccommodation),
              _buildSubParagraph('14. Equipment / Training Facilities:', order.equipment),
              _buildSubParagraph('15. Information Technology:', order.informationTechnology),
              _buildSubParagraph('16. Travel and Claims:', order.travelClaims),
              _buildSubParagraph('17. Public Affairs:', order.publicAffairs),
            ]),

            // COMMAND AND SIGNALS
            _buildMilitarySection('COMMAND AND SIGNALS', [
              pw.Text('18. Contact Information:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
              ...order.contacts.map((c) {
                final role = c['role'] ?? '';
                final name = c['name'] ?? '';
                final phone = c['phone'] ?? '';
                final email = c['email'] ?? '';
                return pw.Padding(
                  padding: const pw.EdgeInsets.only(left: 20, top: 4),
                  child: pw.Text('• $role – $name – $phone / $email', style: const pw.TextStyle(fontSize: 10)),
                );
              }),
              _buildSubParagraph('19. Emergency Communications:', order.emergencyCommunications),
              pw.SizedBox(height: 25),
              // Signature
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(corps.coName, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                    pw.Text(corps.coRank, style: const pw.TextStyle(fontSize: 10)),
                    pw.Text('Commanding Officer', style: const pw.TextStyle(fontSize: 10)),
                    pw.Text(corps.unitDesignation, style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
              ),
            ]),

            // Annexes List Page
            pw.NewPage(),
            pw.Center(
              child: pw.Text(
                'Annexes\n${order.fileNumber}\n${order.date}',
                style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Text('List of Annexes:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
            pw.SizedBox(height: 10),
            ...order.annexes.map((annex) => pw.Padding(
              padding: const pw.EdgeInsets.only(left: 20, bottom: 4),
              child: pw.Text(annex, style: const pw.TextStyle(fontSize: 10)),
            )),

            // Annex C: Serials and assignments table
            pw.NewPage(),
            pw.Center(
              child: pw.Text(
                'Annex C\n${order.fileNumber}\n${order.date}',
                style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Center(
              child: pw.Text(
                'SERIALS AND CORPS / SQUADRON ASSIGNMENTS',
                style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, decoration: pw.TextDecoration.underline),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.SizedBox(height: 15),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('SERIAL / CODE', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('DATES / LOCATION', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('ELEMENT', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('CORPS / SQUADRONS', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                    ),
                  ],
                ),
                ...order.serials.map((s) => pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('${s['serial'] ?? ''}\n${s['code'] ?? ''}', style: const pw.TextStyle(fontSize: 8)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('${s['dates'] ?? ''}\n${s['location'] ?? ''}', style: const pw.TextStyle(fontSize: 8)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(s['element'] ?? '', style: const pw.TextStyle(fontSize: 8)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(s['units'] ?? '', style: const pw.TextStyle(fontSize: 8)),
                    ),
                  ],
                )).toList(),
              ],
            ),
            pw.SizedBox(height: 25),
            // Distribution List
            pw.Text('Distribution List', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
            pw.SizedBox(height: 5),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Action:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                      ...order.distributionAction.map((d) => pw.Padding(
                        padding: const pw.EdgeInsets.only(left: 10),
                        child: pw.Text('• $d', style: const pw.TextStyle(fontSize: 9)),
                      )),
                    ],
                  ),
                ),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Information:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                      ...order.distributionInfo.map((d) => pw.Padding(
                        padding: const pw.EdgeInsets.only(left: 10),
                        child: pw.Text('• $d', style: const pw.TextStyle(fontSize: 9)),
                      )),
                    ],
                  ),
                ),
              ],
            ),
          ];
        },
      ),
    );

    return pdf;
  }

  static pw.Widget _buildMilitarySection(String title, List<pw.Widget> children) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 15),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, decoration: pw.TextDecoration.underline)),
          pw.SizedBox(height: 5),
          ...children,
        ],
      ),
    );
  }

  static pw.Widget _buildSubParagraph(String label, String body) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(left: 15, top: 4),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
          if (body.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(left: 15, top: 2),
              child: pw.Text(body, style: const pw.TextStyle(fontSize: 10)),
            ),
        ],
      ),
    );
  }

  static Future<pw.Document> _buildLsaSponsorMemoPdf(CorpsData corps, List<LsaItem> items) async {
    final roboto = await PdfGoogleFonts.robotoRegular();
    final robotoBold = await PdfGoogleFonts.robotoBold();

    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: roboto,
        bold: robotoBold,
      ),
    );

    double grandTotal = 0;
    for (var item in items) {
      grandTotal += (item.quantity * item.unitPrice);
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(50),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(
                  'CERTIFICATION OF SPONSORING COMMITTEE AGREEMENT',
                  style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Center(
                child: pw.Text(
                  'LOCAL SUPPORT ALLOCATION (LSA) FUNDS EXPENDITURE',
                  style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.SizedBox(height: 40),
              pw.Text(
                '1. This is written certification that the Sponsoring Committee of ${corps.unitDesignation} agrees to the use of LSA funds as outlined & authorized in CATO 17-34, para 11.',
                style: const pw.TextStyle(fontSize: 11),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                '2. LSA funds will be used for the following purpose(s):',
                style: const pw.TextStyle(fontSize: 11),
              ),
              pw.SizedBox(height: 10),
              ...items.map((item) => pw.Padding(
                padding: const pw.EdgeInsets.only(left: 20, bottom: 4),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('• ', style: const pw.TextStyle(fontSize: 11)),
                    pw.Expanded(child: pw.Text('${item.quantity} x ${item.name}', style: const pw.TextStyle(fontSize: 11))),
                  ]
                ),
              )),
              pw.SizedBox(height: 10),
              pw.Padding(
                padding: const pw.EdgeInsets.only(left: 20),
                child: pw.Text(
                  'Total Estimated Cost: \$${grandTotal.toStringAsFixed(2)}',
                  style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                '3. This agreement, once completed, must be attached with the LSA expenditure of funds and then sent to the NL Area Office.',
                style: const pw.TextStyle(fontSize: 11),
              ),
              pw.SizedBox(height: 80),
              pw.Container(height: 1, width: 300, color: PdfColors.black),
              pw.SizedBox(height: 5),
              pw.Text('Signature of Sponsoring Committee Authorized Member', style: const pw.TextStyle(fontSize: 11)),
              pw.SizedBox(height: 40),
              pw.Container(height: 1, width: 300, color: PdfColors.black),
              pw.SizedBox(height: 5),
              pw.Text('Printed Name of Sponsoring Committee Authorized Member', style: const pw.TextStyle(fontSize: 11)),
            ],
          );
        }
      )
    );
    return pdf;
  }
}
