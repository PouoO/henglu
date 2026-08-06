import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';
import '../../../icons/lucide_adapter.dart';
import '../../ble/ble_config_store.dart';
import 'ble_config_page.dart';

/// BLE 扫描页。
///
/// 扫描附近设备，连接后自动发现服务和特征，
/// 让用户点选要写/订阅的特征，然后生成配置。
class BleScanPage extends StatefulWidget {
  const BleScanPage({super.key});

  @override
  State<BleScanPage> createState() => _BleScanPageState();
}

class _BleScanPageState extends State<BleScanPage> {
  final List<ScanResult> _results = [];
  bool _scanning = false;
  String? _error;
  StreamSubscription<List<ScanResult>>? _scanSub;

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  @override
  void dispose() {
    _stopScan();
    super.dispose();
  }

  void _startScan() {
    setState(() {
      _scanning = true;
      _error = null;
      _results.clear();
    });
    _scanSub = FlutterBluePlus.scanResults.listen((results) {
      setState(() {
        for (final r in results) {
          if (!_results.any((x) => x.device.remoteId == r.device.remoteId)) {
            _results.add(r);
          }
        }
      });
    });
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 15)).catchError((e) {
      setState(() => _error = '扫描失败: $e');
      return;
    });
  }

  void _stopScan() {
    _scanSub?.cancel();
    _scanSub = null;
    try {
      FlutterBluePlus.stopScan();
    } catch (_) {}
  }

  Future<void> _onDeviceSelected(ScanResult result) async {
    _stopScan();
    if (!mounted) return;
    final picked = await showDialog<_PickedUuids>(
      context: context,
      builder: (_) => _CharacteristicPicker(device: result.device),
    );
    if (picked == null) return;
    final store = context.read<BleConfigStore>();
    final config = await store.add(
      name: result.device.platformName.isNotEmpty
          ? result.device.platformName
          : result.device.remoteId.str,
      serviceUuid: picked.serviceUuid,
      writeUuid: picked.writeUuid,
      notifyUuid: picked.notifyUuid,
    );
    await store.setActive(config.id);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => BleConfigEditPage(config: config)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('扫描 BLE 设备'),
        actions: [
          if (_scanning)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))),
            )
          else
            IconButton(
              icon: const Icon(Lucide.RefreshCw),
              onPressed: _startScan,
            ),
        ],
      ),
      body: _buildBody(cs),
    );
  }

  Widget _buildBody(ColorScheme cs) {
    if (_error != null) {
      return Center(child: Text(_error!, style: TextStyle(color: cs.error)));
    }
    if (_results.isEmpty) {
      return const Center(child: Text('扫描中...'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final r = _results[i];
        final name = r.device.platformName.isNotEmpty ? r.device.platformName : '未知设备';
        return Card(
          child: ListTile(
            leading: Icon(Lucide.Bluetooth, color: cs.primary),
            title: Text(name),
            subtitle: Text(r.device.remoteId.str, style: const TextStyle(fontSize: 12)),
            trailing: Text('${r.rssi} dBm', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.6))),
            onTap: () => _onDeviceSelected(r),
          ),
        );
      },
    );
  }
}

class _PickedUuids {
  final String serviceUuid;
  final String writeUuid;
  final String? notifyUuid;

  _PickedUuids({
    required this.serviceUuid,
    required this.writeUuid,
    this.notifyUuid,
  });
}

class _CharacteristicPicker extends StatefulWidget {
  final BluetoothDevice device;
  const _CharacteristicPicker({required this.device});

  @override
  State<_CharacteristicPicker> createState() => _CharacteristicPickerState();
}

class _CharacteristicPickerState extends State<_CharacteristicPicker> {
  bool _connecting = true;
  String? _error;
  List<BluetoothService> _services = [];
  BluetoothCharacteristic? _selectedWrite;
  BluetoothCharacteristic? _selectedNotify;

  @override
  void initState() {
    super.initState();
    _connectAndDiscover();
  }

  Future<void> _connectAndDiscover() async {
    try {
      await widget.device.connect(timeout: const Duration(seconds: 10), license: License.free);
      final services = await widget.device.discoverServices();
      if (!mounted) return;
      setState(() {
        _services = services;
        _connecting = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _connecting = false;
      });
    }
  }

  void _submit() {
    if (_selectedWrite == null) return;
    final service = _services.firstWhere((s) => s.characteristics.contains(_selectedWrite!));
    final notify = _selectedNotify;
    Navigator.of(context).pop(_PickedUuids(
      serviceUuid: service.uuid.str.toUpperCase(),
      writeUuid: _selectedWrite!.uuid.str.toUpperCase(),
      notifyUuid: notify?.uuid.str.toUpperCase(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (_connecting) {
      return const AlertDialog(content: Center(child: CircularProgressIndicator()));
    }
    if (_error != null) {
      return AlertDialog(title: const Text('连接失败'), content: Text(_error!));
    }
    return AlertDialog(
      title: const Text('选择特征'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final service in _services) ...[
              Text('服务: ${service.uuid.str.toUpperCase()}',
                  style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.6))),
              for (final c in service.characteristics)
                ListTile(
                  dense: true,
                  title: Text(c.uuid.str.toUpperCase(), style: const TextStyle(fontSize: 13)),
                  subtitle: Text(
                    '写: ${_canWrite(c)}  通知: ${_canNotify(c)}',
                    style: const TextStyle(fontSize: 11),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_canWrite(c))
                        TextButton(
                          onPressed: () => setState(() => _selectedWrite = c),
                          child: Text(_selectedWrite == c ? '已选写' : '选为写'),
                        ),
                      if (_canNotify(c))
                        TextButton(
                          onPressed: () => setState(() => _selectedNotify = c),
                          child: Text(_selectedNotify == c ? '已选通知' : '选为通知'),
                        ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('取消')),
        TextButton(
          onPressed: _selectedWrite == null ? null : _submit,
          child: const Text('确定'),
        ),
      ],
    );
  }

  bool _canWrite(BluetoothCharacteristic c) =>
      c.properties.write || c.properties.writeWithoutResponse;

  bool _canNotify(BluetoothCharacteristic c) => c.properties.notify || c.properties.indicate;
}
