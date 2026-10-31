import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/config/theme.dart';
import '../../../data/models/create_delivery_dto.dart';

typedef CreateDeliveryCallback = Future<void> Function(CreateDeliveryDto dto);

class CreateDeliveryModalSheet extends StatefulWidget {
  final CreateDeliveryCallback onSubmit;

  const CreateDeliveryModalSheet({
    super.key,
    required this.onSubmit,
  });

  @override
  State<CreateDeliveryModalSheet> createState() => _CreateDeliveryModalSheetState();
}

class _ItemEntry {
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController codeCtrl = TextEditingController();
  final TextEditingController qtyCtrl = TextEditingController(text: '1');
  final TextEditingController weightCtrl = TextEditingController(text: '10');
  String unit = 'DUS';

  void dispose() {
    nameCtrl.dispose();
    codeCtrl.dispose();
    qtyCtrl.dispose();
    weightCtrl.dispose();
  }
}

class _StopEntry {
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController addressCtrl = TextEditingController();
  final TextEditingController latCtrl = TextEditingController(text: '-6.2088');
  final TextEditingController lngCtrl = TextEditingController(text: '106.8456');

  void dispose() {
    nameCtrl.dispose();
    addressCtrl.dispose();
    latCtrl.dispose();
    lngCtrl.dispose();
  }
}

class _CreateDeliveryModalSheetState extends State<CreateDeliveryModalSheet> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _doNumberCtrl = TextEditingController();
  final TextEditingController _clientNameCtrl = TextEditingController();
  final TextEditingController _notesCtrl = TextEditingController();

  final List<_ItemEntry> _items = [];
  final List<_StopEntry> _stops = [];

  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Default initial item & stop for convenience
    _addItem();
    _addStop();
  }

  @override
  void dispose() {
    _doNumberCtrl.dispose();
    _clientNameCtrl.dispose();
    _notesCtrl.dispose();
    for (final item in _items) {
      item.dispose();
    }
    for (final stop in _stops) {
      stop.dispose();
    }
    super.dispose();
  }

  void _addItem() {
    setState(() {
      final entry = _ItemEntry();
      entry.codeCtrl.text = 'ITM-0${_items.length + 1}';
      _items.add(entry);
    });
  }

  void _removeItem(int index) {
    if (_items.length <= 1) return;
    setState(() {
      _items[index].dispose();
      _items.removeAt(index);
    });
  }

  void _addStop() {
    setState(() {
      _stops.add(_StopEntry());
    });
  }

  void _removeStop(int index) {
    if (_stops.length <= 1) return;
    setState(() {
      _stops[index].dispose();
      _stops.removeAt(index);
    });
  }

  int get _totalKoli {
    return _items.fold(0, (sum, i) => sum + (int.tryParse(i.qtyCtrl.text) ?? 0));
  }

  double get _totalWeightKg {
    return _items.fold(0.0, (sum, i) {
      final qty = int.tryParse(i.qtyCtrl.text) ?? 0;
      final w = double.tryParse(i.weightCtrl.text) ?? 0.0;
      return sum + (qty * w);
    });
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_items.isEmpty) {
      setState(() => _errorMessage = 'Minimal 1 item barang harus diinputkan.');
      return;
    }

    if (_stops.isEmpty) {
      setState(() => _errorMessage = 'Minimal 1 titik singgah toko harus diinputkan.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final deliveryItems = _items.map((i) {
        return CreateDeliveryItemDto(
          itemCode: i.codeCtrl.text.trim().isNotEmpty ? i.codeCtrl.text.trim() : 'SKU-DEFAULT',
          itemName: i.nameCtrl.text.trim().isNotEmpty ? i.nameCtrl.text.trim() : 'Muatan Barang',
          quantity: int.tryParse(i.qtyCtrl.text) ?? 1,
          unit: i.unit,
          weightKg: double.tryParse(i.weightCtrl.text) ?? 0.0,
        );
      }).toList();

      final deliveryStops = _stops.asMap().entries.map((e) {
        final idx = e.key + 1;
        final s = e.value;
        return CreateDeliveryStopDto(
          sequence: idx,
          destinationName: s.nameCtrl.text.trim().isNotEmpty ? s.nameCtrl.text.trim() : 'Toko $idx',
          address: s.addressCtrl.text.trim().isNotEmpty ? s.addressCtrl.text.trim() : 'Alamat Pengiriman',
          latitude: double.tryParse(s.latCtrl.text) ?? -6.2088,
          longitude: double.tryParse(s.lngCtrl.text) ?? 106.8456,
        );
      }).toList();

      final dto = CreateDeliveryDto(
        deliveryCode: _doNumberCtrl.text.trim(),
        customerName: _clientNameCtrl.text.trim().isNotEmpty ? _clientNameCtrl.text.trim() : null,
        notes: _notesCtrl.text.trim().isNotEmpty ? _notesCtrl.text.trim() : null,
        items: deliveryItems,
        stops: deliveryStops,
      );

      await widget.onSubmit(dto);

      if (mounted) {
        Navigator.of(context).maybePop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Gagal menerbitkan DO: $e';
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Grab handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Buat Perintah Kirim (DO) Baru',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          'Formulir multi-stop pengiriman distribusi armada',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ],
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.statusDanger.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.statusDanger.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: AppTheme.statusDanger, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: AppTheme.statusDanger,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // SECTION 1: DO Header Info
              Text(
                '1. Informasi Dokumen Pengiriman',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _doNumberCtrl,
                decoration: InputDecoration(
                  labelText: 'Nomor Surat Jalan / DO *',
                  hintText: 'Contoh: DO-2026-1025',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Nomor DO wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _clientNameCtrl,
                decoration: InputDecoration(
                  labelText: 'Nama Klien / Distributor',
                  hintText: 'Contoh: PT Sinar Makmur Retail',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _notesCtrl,
                decoration: InputDecoration(
                  labelText: 'Catatan Pengiriman (Opsional)',
                  hintText: 'Instruksi khusus penanganan kargo',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),

              const SizedBox(height: 20),

              // SECTION 2: Cargo Items Builder
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '2. Muatan Barang (${_items.length} Item)',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _addItem,
                    icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
                    label: const Text('Tambah Barang'),
                    style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              ..._items.asMap().entries.map((entry) {
                final idx = entry.key;
                final item = entry.value;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: item.nameCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Nama Barang',
                                isDense: true,
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: item.qtyCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Koli/Qty',
                                isDense: true,
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          if (_items.length > 1)
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.statusDanger, size: 20),
                              onPressed: () => _removeItem(idx),
                              visualDensity: VisualDensity.compact,
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: item.weightCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Berat per unit (kg)',
                                isDense: true,
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: item.unit,
                              isDense: true,
                              decoration: const InputDecoration(labelText: 'Satuan'),
                              items: const [
                                DropdownMenuItem(value: 'DUS', child: Text('DUS')),
                                DropdownMenuItem(value: 'KOLI', child: Text('KOLI')),
                                DropdownMenuItem(value: 'KARTON', child: Text('KARTON')),
                                DropdownMenuItem(value: 'PAIL', child: Text('PAIL')),
                                DropdownMenuItem(value: 'KG', child: Text('KG')),
                              ],
                              onChanged: (val) {
                                if (val != null) setState(() => item.unit = val);
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),

              // Total Cargo Metrics
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total: $_totalKoli Koli',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                    Text(
                      'Total Berat: ${_totalWeightKg.toStringAsFixed(1)} kg',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // SECTION 3: Multi-Stop Destinations
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '3. Titik Tujuan / Stop (${_stops.length})',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _addStop,
                    icon: const Icon(Icons.add_location_alt_outlined, size: 16),
                    label: const Text('Tambah Titik Tujuan (Stop)'),
                    style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              ..._stops.asMap().entries.map((entry) {
                final idx = entry.key + 1;
                final stopIndex = entry.key;
                final stop = entry.value;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 11,
                            backgroundColor: AppTheme.primaryBlue,
                            child: Text(
                              '$idx',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: stop.nameCtrl,
                              decoration: InputDecoration(
                                labelText: 'Nama Toko / Outlet $idx *',
                                isDense: true,
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Nama toko wajib diisi';
                                }
                                return null;
                              },
                            ),
                          ),
                          if (_stops.length > 1)
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.statusDanger, size: 20),
                              onPressed: () => _removeStop(stopIndex),
                              visualDensity: VisualDensity.compact,
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: stop.addressCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Alamat Pengiriman',
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: stop.latCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                              decoration: const InputDecoration(labelText: 'Latitude', isDense: true),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: stop.lngCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                              decoration: const InputDecoration(labelText: 'Longitude', isDense: true),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 24),

              // SUBMIT BUTTON
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.post_add_rounded, color: Colors.white),
                  label: Text(
                    _isSubmitting ? 'Menerbitkan DO...' : 'Simpan & Terbitkan DO',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
