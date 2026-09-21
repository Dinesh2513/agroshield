import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'crop_catalog.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.imagePicker});

  final ImagePicker? imagePicker;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AgroShield',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF25633C)),
        scaffoldBackgroundColor: const Color(0xFFF6F8F3),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      home: AgroShieldHome(imagePicker: imagePicker),
    );
  }
}

class AgroShieldHome extends StatefulWidget {
  const AgroShieldHome({super.key, this.imagePicker});

  final ImagePicker? imagePicker;

  @override
  State<AgroShieldHome> createState() => _AgroShieldHomeState();
}

class _AgroShieldHomeState extends State<AgroShieldHome> {
  static const _maxImageBytes = 5 * 1024 * 1024;
  static const _customId = '__custom__';
  final _customName = TextEditingController();
  late final ImagePicker _picker;
  Uint8List? _imageBytes;
  String? _categoryId;
  String? _plantId;
  String? _error;
  String? _notice;
  bool _busy = true;
  bool _scanOpen = false;

  PlantCategory? get _category {
    if (_categoryId == null) return null;
    return plantCategories.firstWhere((item) => item.id == _categoryId);
  }

  String get _plantName {
    if (_plantId == null) return '';
    if (_plantId == _customId) return _customName.text.trim();
    return _category!.plants.firstWhere((item) => item.id == _plantId).name;
  }

  bool get _canPick => !_busy && _plantName.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _picker = widget.imagePicker ?? ImagePicker();
    _restoreImage();
  }

  @override
  void dispose() {
    _customName.dispose();
    super.dispose();
  }

  void _clearPhotoForPlantChange() {
    if (_imageBytes != null) {
      _notice = 'Plant changed. Please choose a photo for this plant.';
    }
    _imageBytes = null;
    _error = null;
  }

  void _changeCategory(String? value) {
    if (value == null || value == _categoryId) return;
    setState(() {
      if (_categoryId != null) _clearPhotoForPlantChange();
      _categoryId = value;
      _plantId = null;
      _customName.clear();
      _error = null;
    });
  }

  void _changePlant(String? value) {
    if (value == null || value == _plantId) return;
    setState(() {
      if (_plantId != null) _clearPhotoForPlantChange();
      _plantId = value;
      _customName.clear();
      _error = null;
    });
  }

  Future<void> _restoreImage() async {
    try {
      final response = await _picker.retrieveLostData();
      if (response.exception != null) throw response.exception!;
      final files = response.files;
      if (files != null && files.isNotEmpty) {
        await _acceptImage(files.first);
        if (mounted) {
          setState(() {
            _notice = 'Photo recovered. Select its category and plant again.';
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'The previous photo could not be restored. Select it again.';
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  bool _isJpegOrPng(Uint8List bytes) {
    if (bytes.length >= 3 &&
        bytes[0] == 0xFF &&
        bytes[1] == 0xD8 &&
        bytes[2] == 0xFF) {
      return true;
    }
    const signature = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];
    if (bytes.length < signature.length) return false;
    for (var i = 0; i < signature.length; i++) {
      if (bytes[i] != signature[i]) return false;
    }
    return true;
  }

  Future<void> _acceptImage(XFile file) async {
    if (await file.length() > _maxImageBytes) {
      throw const FormatException('Choose an image of 5 MiB or less.');
    }
    final bytes = await file.readAsBytes();
    if (bytes.length > _maxImageBytes) {
      throw const FormatException('Choose an image of 5 MiB or less.');
    }
    if (!_isJpegOrPng(bytes)) {
      throw const FormatException('Please choose a JPEG or PNG image.');
    }
    final codec = await ui.instantiateImageCodec(bytes, targetWidth: 1200);
    try {
      final frame = await codec.getNextFrame();
      frame.image.dispose();
    } finally {
      codec.dispose();
    }
    if (!mounted) return;
    setState(() {
      _imageBytes = bytes;
      _scanOpen = true;
      _error = null;
      _notice = null;
    });
  }

  Future<void> _chooseImage(ImageSource source) async {
    if (!_canPick) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final file = await _picker.pickImage(source: source);
      if (file != null) await _acceptImage(file);
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error is FormatException
              ? error.message
              : 'Could not open the photo. Try another image or check camera access.';
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _buildHome() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.eco_outlined, size: 76, color: Color(0xFF25633C)),
        const SizedBox(height: 20),
        Text(
          'Get to know your plants.',
          style: Theme.of(context).textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        const Text(
          'Crops, vegetables, fruit plants, flowers and more.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'Choose a category and plant, then select a leaf photo. '
              'If your plant is not listed, enter its name.\n\n'
              'For a clear photo, use natural light and keep the whole leaf in focus.',
              style: TextStyle(height: 1.6),
            ),
          ),
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: _busy ? null : () => setState(() => _scanOpen = true),
          icon: const Icon(Icons.document_scanner_outlined),
          label: const Text('Start leaf scan'),
        ),
        const SizedBox(height: 16),
        const Text(
          'Photo preview is available. Disease analysis is not available yet.',
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildScan() {
    final category = _category;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          key: const Key('categoryField'),
          initialValue: _categoryId,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Plant category'),
          items: plantCategories
              .map(
                (item) =>
                    DropdownMenuItem(value: item.id, child: Text(item.name)),
              )
              .toList(),
          onChanged: _busy ? null : _changeCategory,
        ),
        const SizedBox(height: 16),
        if (category != null) ...[
          DropdownButtonFormField<String>(
            key: ValueKey('plantField-${category.id}'),
            initialValue: _plantId,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Plant'),
            items: [
              ...category.plants.map(
                (item) =>
                    DropdownMenuItem(value: item.id, child: Text(item.name)),
              ),
              const DropdownMenuItem(
                value: _customId,
                child: Text('Other / enter name'),
              ),
            ],
            onChanged: _busy ? null : _changePlant,
          ),
          const SizedBox(height: 16),
        ],
        if (_plantId == _customId) ...[
          TextField(
            key: const Key('customNameField'),
            controller: _customName,
            enabled: !_busy,
            maxLength: 60,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Your plant name'),
            onChanged: (_) => setState(_clearPhotoForPlantChange),
          ),
          const SizedBox(height: 12),
        ],
        Text(
          _plantName.isEmpty
              ? 'Select your plant to enable photo selection.'
              : 'Selected plant: $_plantName',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        Container(
          height: 230,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFD5DECF)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: _imageBytes == null
              ? const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_photo_alternate_outlined, size: 56),
                    SizedBox(height: 12),
                    Text('No photo selected'),
                  ],
                )
              : Image.memory(
                  _imageBytes!,
                  fit: BoxFit.contain,
                  cacheWidth: 1200,
                  semanticLabel: 'Selected leaf photo',
                  errorBuilder: (context, error, stackTrace) => const Center(
                    child: Text('Unable to display this photo.'),
                  ),
                ),
        ),
        const SizedBox(height: 12),
        const Text('JPEG or PNG • Maximum 5 MiB', textAlign: TextAlign.center),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          key: const Key('galleryButton'),
          onPressed: _canPick ? () => _chooseImage(ImageSource.gallery) : null,
          icon: const Icon(Icons.photo_library_outlined),
          label: const Text('Choose from gallery'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _canPick ? () => _chooseImage(ImageSource.camera) : null,
          icon: const Icon(Icons.camera_alt_outlined),
          label: const Text('Take a photo'),
        ),
        if (_imageBytes != null)
          TextButton(
            onPressed: _busy
                ? null
                : () => setState(() {
                    _imageBytes = null;
                    _error = null;
                    _notice = null;
                  }),
            child: const Text('Remove photo'),
          ),
        const SizedBox(height: 20),
        const FilledButton(
          key: Key('analyseButton'),
          onPressed: null,
          child: Text('Analyse leaf'),
        ),
        const SizedBox(height: 12),
        Text(
          _plantName.isEmpty
              ? 'Disease analysis is not available yet.'
              : 'Disease analysis is not available for $_plantName yet.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Text(
          'Preview only. Nothing is uploaded or analysed. '
          'Selections and photos are not saved permanently in this version.',
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_scanOpen,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _scanOpen) setState(() => _scanOpen = false);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_scanOpen ? 'Leaf photo preview' : 'AgroShield'),
          leading: _scanOpen
              ? BackButton(onPressed: () => setState(() => _scanOpen = false))
              : null,
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              if (_busy) ...[
                const LinearProgressIndicator(),
                const SizedBox(height: 16),
              ],
              if (_error != null) ...[
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                const SizedBox(height: 16),
              ],
              if (_notice != null) ...[
                Text(_notice!),
                const SizedBox(height: 16),
              ],
              if (_scanOpen) _buildScan() else _buildHome(),
            ],
          ),
        ),
      ),
    );
  }
}
