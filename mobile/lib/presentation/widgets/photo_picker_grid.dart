import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';

class PhotoPickerGrid extends StatelessWidget {
  final List<String> photos;
  final ValueChanged<List<String>> onPhotosChanged;
  final int maxPhotos;

  const PhotoPickerGrid({
    super.key,
    required this.photos,
    required this.onPhotosChanged,
    this.maxPhotos = 5,
  });

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    if (photos.length >= maxPhotos) return;

    try {
      final ImagePicker picker = ImagePicker();

      if (source == ImageSource.gallery) {
        // Permite selección múltiple de fotos al tiempo desde la galería
        final List<XFile> images = await picker.pickMultiImage(
          imageQuality: 80,
          maxWidth: 1024,
        );

        if (images.isNotEmpty) {
          final int remainingCapacity = maxPhotos - photos.length;
          final List<String> newPaths =
              images.take(remainingCapacity).map((img) => img.path).toList();
          final updated = List<String>.from(photos)..addAll(newPaths);
          onPhotosChanged(updated);
        }
      } else {
        // Tomar 1 foto directa desde la cámara
        final XFile? image = await picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 80,
          maxWidth: 1024,
        );

        if (image != null) {
          final updated = List<String>.from(photos)..add(image.path);
          onPhotosChanged(updated);
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No fue posible acceder a la cámara o galería: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _removePhoto(int index) {
    final updated = List<String>.from(photos)..removeAt(index);
    onPhotosChanged(updated);
  }

  void _showImageSourcePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Agregar Evidencia Fotográfica',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 18),

            // Opción 1: Tomar foto con Cámara (Recomendado)
            InkWell(
              onTap: () {
                Navigator.of(ctx).pop();
                _pickImage(context, ImageSource.camera);
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt_rounded,
                          color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Tomar Foto',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.all(Radius.circular(4)),
                                ),
                                child: const Text(
                                  'Recomendado',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Abre la cámara de tu teléfono para captura directa',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded,
                        color: AppColors.textMuted),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Opción 2: Escoger MÚLTIPLES fotos de Galería
            InkWell(
              onTap: () {
                Navigator.of(ctx).pop();
                _pickImage(context, ImageSource.gallery);
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(20),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.photo_library_rounded,
                          color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Seleccionar varias fotos de Galería',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Selecciona varias imágenes al tiempo de tu galería',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded,
                        color: AppColors.textMuted),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Evidencia Fotográfica del Problema',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              '${photos.length} / $maxPhotos fotos',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: photos.length >= maxPhotos
                    ? AppColors.primary
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Grilla de fotos seleccionadas + Botón de agregar
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.0,
          ),
          itemCount: photos.length < maxPhotos ? photos.length + 1 : photos.length,
          itemBuilder: (context, index) {
            if (index == photos.length) {
              return InkWell(
                onTap: () => _showImageSourcePicker(context),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.border,
                      width: 1.5,
                    ),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo_rounded,
                          size: 26, color: AppColors.textPrimary),
                      SizedBox(height: 6),
                      Text(
                        'Agregar Fotos',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final photoPath = photos[index];
            return Stack(
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: kIsWeb
                      ? Image.network(
                          photoPath,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        )
                      : Image.file(
                          File(photoPath),
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () => _removePhoto(index),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
