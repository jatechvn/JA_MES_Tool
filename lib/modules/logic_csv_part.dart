part of 'logic.dart';

extension AppLogicCsvExt on AppLogic {
  Future<String?> pickFile({bool isSave = false}) async {
    final picker = filePicker;
    if (picker != null) return picker(isSave);
    final script = isSave
        ? '''
Add-Type -AssemblyName System.Windows.Forms
\$f = New-Object System.Windows.Forms.SaveFileDialog
\$f.Filter = "CSV Files (*.csv)|*.csv|All Files (*.*)|*.*"
\$f.InitialDirectory = [Environment]::GetFolderPath("Desktop")
if(\$f.ShowDialog() -eq "OK") { Write-Output \$f.FileName }
'''
        : '''
Add-Type -AssemblyName System.Windows.Forms
\$f = New-Object System.Windows.Forms.OpenFileDialog
\$f.Filter = "CSV Files (*.csv)|*.csv|All Files (*.*)|*.*"
\$f.InitialDirectory = [Environment]::GetFolderPath("Desktop")
if(\$f.ShowDialog() -eq "OK") { Write-Output \$f.FileName }
''';

    try {
      final result = await Process.run('powershell', [
        '-NoProfile',
        '-STA',
        '-Command',
        script,
      ]);
      final path = result.stdout.toString().trim();
      if (path.isNotEmpty) {
        return path;
      }
    } catch (e) {
      _logger.severe('Failed to pick file: $e');
    }
    return null;
  }

  Future<void> downloadTemplateCsv() async {
    _setGlobalMessage('');
    _notify();
    try {
      final script = '''
Add-Type -AssemblyName System.Windows.Forms
\$f = New-Object System.Windows.Forms.SaveFileDialog
\$f.Filter = "CSV Files (*.csv)|*.csv"
\$f.FileName = "Template_SN.csv"
\$f.InitialDirectory = [Environment]::GetFolderPath("Desktop")
if(\$f.ShowDialog() -eq "OK") { Write-Output \$f.FileName }
''';
      final path = await _pickTemplatePath(script);
      if (path.isEmpty) return; // User canceled

      final file = File(path.replaceAll('"', '').trim());
      await file.writeAsString('SN\nSN123456\nSN789012\n');
      _setGlobalMessage(
        'csv_template_success',
        isError: false,
        values: {'path': path},
      );
    } catch (e) {
      _setGlobalMessage('csv_template_error', values: {'error': '$e'});
    }
    _notify();
  }

  Future<String> _pickTemplatePath(String script) async {
    final picker = filePicker;
    if (picker != null) return await picker(true) ?? '';
    final result = await Process.run('powershell', [
      '-NoProfile',
      '-STA',
      '-Command',
      script,
    ]);
    return result.stdout.toString().trim();
  }

  Future<void> importCsv() async {
    _setGlobalMessage('');
    _notify();
    try {
      final path = await pickFile(isSave: false);
      if (path == null || path.isEmpty) return; // User canceled

      final file = File(path.replaceAll('"', '').trim());
      if (!await file.exists()) {
        _setGlobalMessage('csv_file_not_found');
        _notify();
        return;
      }
      final content = await file.readAsString();
      await addSns(content, allowTestRecordFallback: false);
      _setGlobalMessage(
        'csv_import_success',
        isError: false,
        values: {'path': path},
      );
      _notify();
    } catch (e) {
      _setGlobalMessage('csv_import_error', values: {'error': '$e'});
      _notify();
    }
  }

  Future<void> exportCsv() async {
    _setGlobalMessage('');
    _notify();
    try {
      final path = await pickFile(isSave: true);
      if (path == null || path.isEmpty) return; // User canceled

      final file = File(path.replaceAll('"', '').trim());
      final buffer = StringBuffer();
      // Write Header
      buffer.writeln(
        'SN,Internal SN,Customer SN,Product No,Process Code,Line Station Code,Station ID,Error Code,Test Time,Test Start Time,Test End Time,Duration,Test No,Result,Failure Reason,Fail Desc,Fail Step,Fail Cycle,Major Item,Host Loc,Product Series,WO,EmpNo,MB SN,MAC Group,Collecting Data,Components,GIT/ASN Data,Eqp Params,Zip File,Test Log Path,Qty,Pass Qty,Fail Qty,Repass Qty,FPY,LPY',
      );

      for (final sn in _snList) {
        final records = _results[sn];
        if (records != null && records.isNotEmpty) {
          for (final r in records) {
            buffer.writeln(
              [
                r.sn,
                r.internalSn,
                r.customerSn,
                r.productNo,
                r.processCode,
                r.lineStationCode,
                r.stationId,
                r.errCode,
                r.testDate,
                r.testStartDate,
                r.testEndDate,
                r.timeDifferenceValue,
                r.testNo,
                r.testResult,
                r.failureReason,
                r.failDesc,
                r.testItemFailStep,
                r.testItemFailCycle,
                r.testMajorItem,
                r.loc,
                r.productSeries,
                r.woNo,
                r.empNo,
                r.mbSn,
                r.macGroup,
                r.collectingData,
                r.components,
                r.gitAsnData,
                r.eqpParams,
                r.zipFileName,
                r.testLogPath,
                r.qty,
                r.passQty,
                r.failQty,
                r.repassQty,
                r.fpy,
                r.lpy,
              ].map(csvField).join(','),
            );
          }
        } else {
          final err = _errors[sn] ?? 'No records / Pending';
          buffer.writeln(
            [sn, ...List<String>.filled(35, ''), err].map(csvField).join(','),
          );
        }
      }

      await file.writeAsString(buffer.toString());
      _setGlobalMessage(
        'csv_export_success',
        isError: false,
        values: {'path': path},
      );
    } catch (e) {
      _setGlobalMessage('csv_export_error', values: {'error': '$e'});
    }
    _notify();
  }

  Future<void> exportBarcodeHistoryCsv() async {
    _setGlobalMessage('');
    _notify();
    try {
      final path = await pickFile(isSave: true);
      if (path == null || path.isEmpty) return;

      final file = File(path.replaceAll('"', '').trim());
      final buffer = StringBuffer();
      buffer.writeln(
        'Product SN,Internal SN,Customer SN,Current Process Code,Current Process Name,Line,Line Station,Equipment No,Result,Operate Date,WO,Plan No,Product No,Product Version,Operator,Landmark Codes,Remark',
      );

      for (final sn in _snList) {
        final records = _processResults[sn];
        if (records != null && records.isNotEmpty) {
          for (final r in records) {
            final lineVal = r.lineName.isNotEmpty ? r.lineName : r.lineCode;
            buffer.writeln(
              [
                r.productSn,
                r.internalSn,
                r.customerSn,
                r.currentProcessCode,
                r.currentProcessName,
                lineVal,
                r.lineStation,
                r.eqpId,
                r.result,
                r.operateDt,
                r.woNo,
                r.planNo,
                r.productNo,
                r.productVersion,
                r.operatorName,
                r.landMarkCodes,
                r.remark,
              ].map(csvField).join(','),
            );
          }
        }
      }

      await file.writeAsString(buffer.toString());
      _setGlobalMessage(
        'csv_export_success',
        isError: false,
        values: {'path': path},
      );
    } catch (e) {
      _setGlobalMessage('csv_export_error', values: {'error': '$e'});
    }
    _notify();
  }

  Future<void> exportWipComponentsCsv() async {
    _setGlobalMessage('');
    _notify();
    try {
      final path = await pickFile(isSave: true);
      if (path == null || path.isEmpty) return;

      final file = File(path.replaceAll('"', '').trim());
      final buffer = StringBuffer();
      buffer.writeln(
        'Product SN,Internal SN,Customer SN,Material No,Material Name,Category,Component SN,Parsed CSN,Scan Type,Location,Manufacturer,Mfg PN,Date Code,Package ID,Installed Qty,Station Code,Process Code,Created Date,Unlink Time,Check Assembled Code',
      );

      for (final sn in _snList) {
        final records = _wipResults[sn];
        if (records != null && records.isNotEmpty) {
          for (final r in records) {
            buffer.writeln(
              [
                r.productSn,
                r.internalSn,
                r.customerSn,
                r.materialNo,
                r.materialName,
                r.materialCategory,
                r.scannedCsn,
                r.parsedCsn,
                r.scanType,
                r.location,
                r.mfgName,
                r.mfgPn,
                r.dateCode,
                r.pkgId,
                r.installedQty,
                r.stationCode,
                r.processCode,
                r.createdDt,
                r.unlinkTime,
                r.checkAssembledCode,
              ].map(csvField).join(','),
            );
          }
        }
      }

      await file.writeAsString(buffer.toString());
      _setGlobalMessage(
        'csv_export_success',
        isError: false,
        values: {'path': path},
      );
    } catch (e) {
      _setGlobalMessage('csv_export_error', values: {'error': '$e'});
    }
    _notify();
  }
}
