import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(const MyApp());
}

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
  static const int _maxImageBytes = 5 * 1024 * 1024;

  late final ImagePicker _picker;
  Uint8List? _imageBytes;
  String? _error;
  bool _busy = true;
  bool _scanOpen = false;

  @override
  void initState() {
    super.initState();
    _picker = widget.imagePicker ?? ImagePicker();
    _restoreImage();
  }

  // Android can restart the app while the photo picker is open.
  Future<void> _restoreImage() async {
    try {
      final response = await _picker.retrieveLostData();

      if (response.exception != null) {
        throw response.exception!;
      }

      final files = response.files;
      if (files != null && files.isNotEmpty) {
        await _acceptImage(files.first);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error =
              'The previous photo could not be restored. '
              'Please select it again.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  bool _isJpegOrPng(Uint8List bytes) {
    final isJpeg =
        bytes.length >= 3 &&
        bytes[0] == 0xFF &&
        bytes[1] == 0xD8 &&
        bytes[2] == 0xFF;

    const pngSignature = <int>[0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];

    var isPng = bytes.length >= pngSignature.length;
    if (isPng) {
      for (var i = 0; i < pngSignature.length; i++) {
        if (bytes[i] != pngSignature[i]) {
          isPng = false;
          break;
        }
      }
    }

    return isJpeg || isPng;
  }

  Future<void> _acceptImage(XFile file) async {
    if (await file.length() > _maxImageBytes) {
      throw const FormatException(
        'This photo is too large. Choose an image of 5 MiB or less.',
      );
    }

    final bytes = await file.readAsBytes();

    if (bytes.length > _maxImageBytes) {
      throw const FormatException(
        'This photo is too large. Choose an image of 5 MiB or less.',
      );
    }

    if (!_isJpegOrPng(bytes)) {
      throw const FormatException('Please choose a JPEG or PNG image.');
    }

    // Check that the file can actually be decoded as an image.
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
    });
  }

  Future<void> _chooseImage(ImageSource source) async {
    if (_busy) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final file = await _picker.pickImage(source: source);

      // Closing the picker without choosing a photo is not an error.
      if (file != null) {
        await _acceptImage(file);
      }
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _error = error is FormatException
            ? error.message
            : 'Could not open the photo. Try another image, '
                  'or check camera access if you used the camera.';
      });
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Widget _buildHome() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.eco_outlined, size: 76, color: Color(0xFF25633C)),
        const SizedBox(height: 20),
        Text(
          'Get to know your crop.',
          style: Theme.of(context).textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        const Text(
          'Start with a clear photo of a tomato leaf.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'A good leaf photo',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 12),
                Text(
                  '• Use bright, natural light.\n'
                  '• Keep the whole leaf in focus.\n'
                  '• Avoid shadows and cluttered backgrounds.',
                  style: TextStyle(height: 1.7),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: _busy
              ? null
              : () {
                  setState(() => _scanOpen = true);
                },
          icon: const Icon(Icons.document_scanner_outlined),
          label: const Text('Start leaf scan'),
        ),
        const SizedBox(height: 16),
        const Text(
          'Current version: photo selection and preview. '
          'Disease analysis is not available yet.',
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildScan() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.eco, color: Color(0xFF25633C)),
          title: Text('Tomato'),
          subtitle: Text('The first crop supported by our project'),
        ),
        const SizedBox(height: 16),
        Container(
          height: 260,
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
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Text('Unable to display this photo.'),
                    );
                  },
                ),
        ),
        const SizedBox(height: 12),
        const Text('JPEG or PNG • Maximum 5 MiB', textAlign: TextAlign.center),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: _busy ? null : () => _chooseImage(ImageSource.gallery),
          icon: const Icon(Icons.photo_library_outlined),
          label: const Text('Choose from gallery'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _busy ? null : () => _chooseImage(ImageSource.camera),
          icon: const Icon(Icons.camera_alt_outlined),
          label: const Text('Take a photo'),
        ),
        if (_imageBytes != null)
          TextButton(
            onPressed: _busy
                ? null
                : () {
                    setState(() {
                      _imageBytes = null;
                      _error = null;
                    });
                  },
            child: const Text('Remove photo'),
          ),
        const SizedBox(height: 20),
        const FilledButton(
          key: Key('analyseButton'),
          onPressed: null,
          child: Text('Analyse leaf'),
        ),
        const SizedBox(height: 12),
        const Text(
          'Preview only. Your photo has not been uploaded or analysed. '
          'Photos are not saved permanently in this version.',
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
        if (!didPop && _scanOpen) {
          setState(() => _scanOpen = false);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_scanOpen ? 'Tomato leaf scan' : 'AgroShield'),
          leading: _scanOpen
              ? BackButton(
                  onPressed: () {
                    setState(() => _scanOpen = false);
                  },
                )
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
              if (_scanOpen) _buildScan() else _buildHome(),
            ],
          ),
        ),
      ),
    );
  }
}
