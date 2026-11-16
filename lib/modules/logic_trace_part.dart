part of 'logic.dart';

extension AppLogicTraceExt on AppLogic {
  /// 1-click navigation from Tab 3 (Component List) -> Tab 4 (Component Trace).
  Future<void> traceComponentFromWip(String csn) async {
    final target = csn.trim().toUpperCase();
    if (target.isEmpty) return;
    setViewMode(ViewMode.componentTrace);
    if (_traceResults.containsKey(target) && _traceErrors[target] == null) {
      if (!_traceHistory.contains(target)) {
        _traceHistory.insert(0, target);
        _saveConfig(_exportConfigMap());
      }
      selectTraceCsn(target);
      return;
    }
    await searchComponentTrace(target);
  }

  /// 1-click navigation from Tab 4 (Component Trace) -> SN Queue (Test Record).
  Future<void> inspectProductSnFromTrace(String productSn) async {
    final target = productSn.trim();
    if (target.isEmpty) return;
    setViewMode(ViewMode.testRecord);
    await addSns(target);
  }

  /// Reverse component lookup: given a scanned/typed component CSN, finds
  /// which product SN it is currently installed into. Adds the CSN to the
  /// trace history (if new) and selects it, so the sidebar and detail view
  /// both reflect the just-searched CSN.
  Future<void> searchComponentTrace(String csn) async {
    final trimmed = csn.trim().toUpperCase();
    if (trimmed.isEmpty) return;
    if (!_traceHistory.contains(trimmed)) {
      _traceHistory.insert(0, trimmed);
      _saveConfig(_exportConfigMap());
    }
    _selectedTraceCsn = trimmed;
    _invalidate('csn:$trimmed');
    await _fetchTrace(trimmed);
  }

  Future<void> _fetchTrace(String csn) {
    final revision = _revision('csn:$csn');
    bool current() =>
        !_disposed &&
        _traceHistory.contains(csn) &&
        _revision('csn:$csn') == revision;
    _traceLoadingStatus[csn] = true;
    _traceErrors.remove(csn);
    _notify();
    return _queue.run(('trace', csn, revision), () async {
      try {
        final records = await ApiClient.queryComponentInfo(
          csn: csn,
          token: _token,
          lang: _lang,
          operationId: _operationId,
          uuid: _uuid,
          cookie: _cookie,
        );
        if (!current()) return;
        _traceResults[csn] = records;
        if (records.isEmpty) _traceErrors[csn] = 'No records found';
      } catch (e) {
        if (current()) {
          _traceErrors[csn] = e.toString().replaceFirst('Exception: ', '');
        }
      } finally {
        if (current()) {
          _traceLoadingStatus[csn] = false;
          _notify();
        }
      }
    }, isCurrent: current);
  }

  /// Selects a previously searched CSN from the trace history without
  /// re-fetching (its result is already cached).
  void selectTraceCsn(String csn) {
    _selectedTraceCsn = csn;
    _notify();
  }

  /// Re-runs the lookup for a CSN already in the trace history.
  Future<void> refreshTraceCsn(String csn) async {
    _traceResults.remove(csn);
    _traceErrors.remove(csn);
    _notify();
    await searchComponentTrace(csn);
  }

  void removeTraceCsn(String csn) {
    _invalidate('csn:$csn');
    _traceHistory.remove(csn);
    _traceResults.remove(csn);
    _traceErrors.remove(csn);
    _traceLoadingStatus.remove(csn);
    if (_selectedTraceCsn == csn) {
      _selectedTraceCsn = _traceHistory.isNotEmpty ? _traceHistory.first : '';
    }
    _saveConfig(_exportConfigMap());
    _notify();
  }

  void clearTraceHistory() {
    for (final csn in _traceHistory) {
      _invalidate('csn:$csn');
    }
    _traceHistory.clear();
    _traceResults.clear();
    _traceErrors.clear();
    _traceLoadingStatus.clear();
    _selectedTraceCsn = '';
    _saveConfig(_exportConfigMap());
    _notify();
  }

  /// Explicitly refreshes trace history without changing the user's selection.
  Future<void> refetchAllTraceSearches() async {
    for (final csn in _traceHistory) {
      _invalidate('csn:$csn');
    }
    await Future.wait(List<String>.of(_traceHistory).map(_fetchTrace));
  }

  /// Parses a multi-line/comma-separated blob of component CSNs (manual
  /// paste or CSV file content) and queues the searches concurrently — the
  /// Component Trace equivalent of [addSns], reusing the same delimiter and
  /// header-row-skip conventions.
  Future<void> addTraceCsns(String input) async {
    final lines = input.split(RegExp(r'[\n\r,;\s]+'));
    final toSearch = <String>[];
    for (var line in lines) {
      final csn = line.trim().toUpperCase();
      if (csn == 'SN' || csn == 'CSN') continue;
      if (csn.isNotEmpty &&
          RegExp(r'^[A-Z0-9_-]+$').hasMatch(csn) &&
          !toSearch.contains(csn)) {
        toSearch.add(csn);
      }
    }

    await Future.wait(toSearch.map(searchComponentTrace));
  }

  Future<void> downloadTraceTemplateCsv() async {
    _setGlobalMessage('');
    _notify();
    try {
      final script = '''
Add-Type -AssemblyName System.Windows.Forms
\$f = New-Object System.Windows.Forms.SaveFileDialog
\$f.Filter = "CSV Files (*.csv)|*.csv"
\$f.FileName = "Template_Component_SN.csv"
\$f.InitialDirectory = [Environment]::GetFolderPath("Desktop")
if(\$f.ShowDialog() -eq "OK") { Write-Output \$f.FileName }
''';
      final path = await _pickTemplatePath(script);
      if (path.isEmpty) return; // User canceled

      final file = File(path.replaceAll('"', '').trim());
      await file.writeAsString('CSN\nOPM1106349G1CCX\nQB940AE002627V05171\n');
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

  Future<void> importTraceCsv() async {
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
      await addTraceCsns(content);
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

  Future<void> exportTraceCsv() async {
    _setGlobalMessage('');
    _notify();
    try {
      final path = await pickFile(isSave: true);
      if (path == null || path.isEmpty) return; // User canceled

      final file = File(path.replaceAll('"', '').trim());
      final buffer = StringBuffer();
      buffer.writeln(
        'Component SN,Parsed CSN,MAC,Scan Type,Product SN,Material No,Material Name,Material Version,Customer Material No,Category,Manufacturer,Mfg Part No,Product No,Line Code,Process Code,WO,Qty,Process Time,Assembled Status',
      );

      for (final csn in _traceHistory) {
        final records = _traceResults[csn];
        if (records != null && records.isNotEmpty) {
          for (final r in records) {
            buffer.writeln(
              [
                csn,
                r.parsedCsn,
                r.mac,
                r.scanType,
                r.productSn,
                r.materialNo,
                r.materialName,
                r.materialVersion,
                r.customerMaterialNo,
                r.materialCategory,
                r.mfgName,
                r.mfgPn,
                r.productNo,
                r.lineCode,
                r.processCode,
                r.woNo,
                r.installedQty,
                r.createdDt,
                r.checkAssembled,
              ].map(csvField).join(','),
            );
          }
        } else {
          final err = _traceErrors[csn] ?? 'No records / Pending';
          buffer.writeln(
            [csn, ...List<String>.filled(17, ''), err].map(csvField).join(','),
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

  Future<void> refetchTraceHistory() => refetchAllTraceSearches();
  Future<void> refetchTraceCsn(String csn) => searchComponentTrace(csn);
}
