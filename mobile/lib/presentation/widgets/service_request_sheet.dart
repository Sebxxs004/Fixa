import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'photo_picker_grid.dart';

class ServiceCategory {
  final int id;
  final String name;
  final IconData icon;

  const ServiceCategory({
    required this.id,
    required this.name,
    required this.icon,
  });
}

class ServiceRequestSheet extends StatefulWidget {
  final Function({
    required int categoriaId,
    required String categoriaNombre,
    required String descripcion,
    required List<String> fotos,
  }) onSubmit;

  const ServiceRequestSheet({
    super.key,
    required this.onSubmit,
  });

  @override
  State<ServiceRequestSheet> createState() => _ServiceRequestSheetState();
}

class _ServiceRequestSheetState extends State<ServiceRequestSheet> {
  final _formKey = GlobalKey<FormState>();
  final _descripcionController = TextEditingController();
  List<String> _fotos = [];

  static const List<ServiceCategory> _categories = [
    ServiceCategory(id: 1, name: 'Plomería', icon: Icons.plumbing_rounded),
    ServiceCategory(id: 2, name: 'Electricidad', icon: Icons.electrical_services_rounded),
    ServiceCategory(id: 3, name: 'Cerrajería', icon: Icons.lock_clock_rounded),
    ServiceCategory(id: 4, name: 'Pintura', icon: Icons.format_paint_rounded),
    ServiceCategory(id: 5, name: 'Carpintería', icon: Icons.carpenter_rounded),
    ServiceCategory(id: 6, name: 'Climatización', icon: Icons.ac_unit_rounded),
    ServiceCategory(id: 7, name: 'General', icon: Icons.handyman_rounded),
  ];

  late ServiceCategory _selectedCategory;

  @override
  void initState() {
    super.initState();
    _selectedCategory = _categories.first;
  }

  @override
  void dispose() {
    _descripcionController.dispose();
    super.dispose();
  }

  void _onPostulatePressed() {
    if (_formKey.currentState?.validate() ?? false) {
      widget.onSubmit(
        categoriaId: _selectedCategory.id,
        categoriaNombre: _selectedCategory.name,
        descripcion: _descripcionController.text.trim(),
        fotos: _fotos,
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      padding: EdgeInsets.fromLTRB(24, 16, 24, bottomInset + 24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Indicador de arrastre del Modal
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Encabezado
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Solicitar Servicio',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.4,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, size: 20),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Selecciona la categoría, describe el problema y adjunta fotos para recibir ofertas.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),

              // 1. Selector de Categorías de Servicio
              const Text(
                '1. Selecciona la Categoría',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.1,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 80,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    final isSelected = cat.id == _selectedCategory.id;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCategory = cat;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 82,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.border,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              cat.icon,
                              size: 24,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textPrimary,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              cat.name,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

              // 2. Descripción del Problema
              const Text(
                '2. Describe el Problema',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.1,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _descripcionController,
                maxLines: 3,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
                decoration: const InputDecoration(
                  hintText: 'Ej. Se requiere reparación de fuga en tubería de agua bajo el lavamanos...',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa una breve descripción del problema';
                  }
                  if (value.trim().length < 5) {
                    return 'La descripción debe tener al menos 5 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // 3. Carga de Fotografías del Problema (Hasta 5)
              PhotoPickerGrid(
                photos: _fotos,
                onPhotosChanged: (photos) {
                  setState(() {
                    _fotos = photos;
                  });
                },
                maxPhotos: 5,
              ),
              const SizedBox(height: 28),

              // Botón de Postulación
              ElevatedButton(
                onPressed: _onPostulatePressed,
                child: const Text('Postular Servicio para Cotizaciones'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
