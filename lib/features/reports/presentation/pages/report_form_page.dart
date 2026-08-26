// lib/features/reports/presentation/pages/report_form_page.dart
//
// Formulario de captura basado EXACTAMENTE en MROAM-F-MR-04
// y FORMATO_SINIESTROS_2026.xlsx.
// Dividido en secciones con scroll para no abrumar al usuario.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../media/presentation/widgets/gps_location_widget.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/report_entity.dart';
import '../../domain/usecases/create_report_usecase.dart';
import '../providers/report_provider.dart';

class ReportFormPage extends ConsumerStatefulWidget {
  const ReportFormPage({super.key});

  @override
  ConsumerState<ReportFormPage> createState() => _ReportFormPageState();
}

class _ReportFormPageState extends ConsumerState<ReportFormPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  GeoLocation? _capturedLocation;

  // ─── CONTROLADORES DE CAMPOS ─────────────────────────
  final _highwayCtrl = TextEditingController();
  final _kmStartCtrl = TextEditingController();
  final _kmEndCtrl = TextEditingController();
  final _speedLimitCtrl = TextEditingController();
  final _observationsCtrl = TextEditingController();
  final _incidentDescCtrl = TextEditingController();
  final _probableCauseCtrl = TextEditingController();
  final _squadCtrl = TextEditingController();

  // ─── ESTADO DE SELECCIÓN ─────────────────────────────
  RoadBody _selectedBody = RoadBody.a;
  RoadSide _selectedSide = RoadSide.right;
  RoadType _selectedRoadType = RoadType.freeway;
  DateTime _accidentDate = DateTime.now();
  String? _weatherCondition;
  String? _surfaceCondition;
  String? _lightCondition;

  // Víctimas
  int _fatalities = 0;
  int _seriousInjuries = 0;
  int _minorInjuries = 0;
  int _uninjured = 0;

  // Vehículos (lista dinámica)
  final List<TextEditingController> _vehicleTypeCtrl = [];
  final List<TextEditingController> _vehiclePlateCtrl = [];

  @override
  void initState() {
    super.initState();
    // Pre-llenar número de cuadrilla con el del usuario logueado
    final user = ref.read(currentUserProvider);
    _squadCtrl.text = user?.employeeId ?? '';
    // Agregar un vehículo vacío por defecto
    _addVehicle();
  }

  @override
  void dispose() {
    _highwayCtrl.dispose();
    _kmStartCtrl.dispose();
    _kmEndCtrl.dispose();
    _speedLimitCtrl.dispose();
    _observationsCtrl.dispose();
    _incidentDescCtrl.dispose();
    _probableCauseCtrl.dispose();
    _squadCtrl.dispose();
    for (final c in _vehicleTypeCtrl){ c.dispose(); }
    for (final c in _vehiclePlateCtrl){ c.dispose(); }
    super.dispose();
  }

  void _addVehicle() {
    setState(() {
      _vehicleTypeCtrl.add(TextEditingController());
      _vehiclePlateCtrl.add(TextEditingController());
    });
  }

  void _removeVehicle(int index) {
    setState(() {
      _vehicleTypeCtrl[index].dispose();
      _vehiclePlateCtrl[index].dispose();
      _vehicleTypeCtrl.removeAt(index);
      _vehiclePlateCtrl.removeAt(index);
    });
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _accidentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('es', 'MX'),
    );
    if (picked != null) setState(() => _accidentDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    setState(() => _isSubmitting = true);

    final user = ref.read(currentUserProvider)!;

    // Construir lista de vehículos
    final vehicles = <VehicleInfo>[];
    for (int i = 0; i < _vehicleTypeCtrl.length; i++) {
      if (_vehicleTypeCtrl[i].text.trim().isNotEmpty) {
        vehicles.add(VehicleInfo(
          vehicleType: _vehicleTypeCtrl[i].text.trim(),
          licensePlate: _vehiclePlateCtrl[i].text.trim().isEmpty
              ? null
              : _vehiclePlateCtrl[i].text.trim(),
        ));
      }
    }

    final params = CreateReportParams(
      highway: _highwayCtrl.text.trim(),
      kmStart: DamageReportEntity.kmFromDisplay(_kmStartCtrl.text.trim()),
      kmEnd: DamageReportEntity.kmFromDisplay(_kmEndCtrl.text.trim()),
      body: _selectedBody,
      side: _selectedSide,
      roadType: _selectedRoadType,
      speedLimit: double.tryParse(_speedLimitCtrl.text),
      accidentDate: _accidentDate,
      observations: _observationsCtrl.text.trim(),
      incidentDescription: _incidentDescCtrl.text.trim().isEmpty
          ? null
          : _incidentDescCtrl.text.trim(),
      probableCause: _probableCauseCtrl.text.trim().isEmpty
          ? null
          : _probableCauseCtrl.text.trim(),
      squadNumber: _squadCtrl.text.trim(),
      createdBy: user.uid,
      createdByName: user.displayName,
      vehicles: vehicles,
      fatalitiesCount: _fatalities,
      seriousInjuriesCount: _seriousInjuries,
      minorInjuriesCount: _minorInjuries,
      location: _capturedLocation,
      uninjuredCount: _uninjured,
      weatherCondition: _weatherCondition,
      surfaceCondition: _surfaceCondition,
      lightCondition: _lightCondition,
    );

    final reportId = await ref.read(reportsProvider.notifier).createReport(params);

    setState(() => _isSubmitting = false);

    if (!mounted) return;

    if (reportId != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reporte creado exitosamente'),
          backgroundColor: AppColors.success,
        ),
      );
      // Navegar al detalle del reporte recién creado
      context.pushReplacement('/reports/$reportId');
    } else {
      final error = ref.read(reportsProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Error al crear reporte'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo Reporte'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── SECCIÓN 1: IDENTIFICACIÓN ──────────────
            _SectionHeader(
              icon: Icons.badge_outlined,
              title: 'Identificación',
            ),
            _buildIdentificationSection(),

            const SizedBox(height: 24),

            // ── SECCIÓN 2: UBICACIÓN ───────────────────
            _SectionHeader(
              icon: Icons.location_on_outlined,
              title: 'Ubicación',
              subtitle: 'Campos del formato MROAM-F-MR-04',
            ),
            _buildLocationSection(),
            const SizedBox(height: 12),
          GpsLocationWidget(
  currentLocation: _capturedLocation,
  onLocationCaptured: (loc) => setState(() => _capturedLocation = loc),
),
            

            const SizedBox(height: 24),

            // ── SECCIÓN 3: DATOS DEL ACCIDENTE ─────────
            _SectionHeader(
              icon: Icons.car_crash_outlined,
              title: 'Datos del Accidente',
            ),
            _buildAccidentSection(),

            const SizedBox(height: 24),

            // ── SECCIÓN 4: VEHÍCULOS ───────────────────
            _SectionHeader(
              icon: Icons.directions_car_outlined,
              title: 'Vehículos Involucrados',
            ),
            _buildVehiclesSection(),

            const SizedBox(height: 24),

            // ── SECCIÓN 5: VÍCTIMAS ────────────────────
            _SectionHeader(
              icon: Icons.personal_injury_outlined,
              title: 'Víctimas',
            ),
            _buildVictimsSection(),

            const SizedBox(height: 24),

            // ── SECCIÓN 6: CONDICIONES ─────────────────
            _SectionHeader(
              icon: Icons.wb_cloudy_outlined,
              title: 'Condiciones',
            ),
            _buildConditionsSection(),

            const SizedBox(height: 24),

            // ── ACTIVIDAD REALIZADA ────────────────────
            _SectionHeader(
              icon: Icons.construction_outlined,
              title: 'Actividad Realizada',
              subtitle: 'Del formato de cuadrilla',
            ),
            _buildObservationsSection(),

            const SizedBox(height: 32),

            // ── BOTÓN GUARDAR ──────────────────────────
            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _save,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(_isSubmitting ? 'Guardando...' : 'Guardar Reporte'),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ── SECCIONES DEL FORMULARIO ─────────────────────────

  Widget _buildIdentificationSection() {
    return Column(
      children: [
        // Número de cuadrilla
        TextFormField(
          controller: _squadCtrl,
          decoration: const InputDecoration(
            labelText: 'No. de Cuadrilla *',
            hintText: '#03',
            prefixIcon: Icon(Icons.group_outlined),
          ),
          validator: (v) =>
              v == null || v.trim().isEmpty ? 'Requerido' : null,
        ),
        const SizedBox(height: 12),
        // Fecha del accidente
        InkWell(
          onTap: _selectDate,
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Fecha del Accidente *',
              prefixIcon: Icon(Icons.calendar_today_outlined),
            ),
            child: Text(
              DateFormat('dd/MM/yyyy', 'es_MX').format(_accidentDate),
              style: AppTextStyles.bodyMedium,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationSection() {
    return Column(
      children: [
        // Carretera
        TextFormField(
          controller: _highwayCtrl,
          decoration: const InputDecoration(
            labelText: 'Carretera *',
            hintText: 'MEX-57, Libramiento Norte...',
            prefixIcon: Icon(Icons.route_outlined),
          ),
          validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
        ),
        const SizedBox(height: 12),

        // KM Inicial y Final en la misma fila
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _kmStartCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'KM Inicial *',
                  hintText: '21+525',
                  prefixIcon: Icon(Icons.first_page),
                ),
                // Acepta formato 21+525 o 21.525
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d+.]')),
                ],
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Requerido' : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _kmEndCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'KM Final *',
                  hintText: '21+530',
                  prefixIcon: Icon(Icons.last_page),
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d+.]')),
                ],
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Requerido' : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Cuerpo (A o B)
        _buildSegmentedField<RoadBody>(
          label: 'Cuerpo',
          value: _selectedBody,
          options: RoadBody.values,
          labelOf: (v) => v.displayName,
          onChanged: (v) => setState(() => _selectedBody = v),
        ),
        const SizedBox(height: 12),

        // Lado
        _buildSegmentedField<RoadSide>(
          label: 'Lado',
          value: _selectedSide,
          options: RoadSide.values,
          labelOf: (v) => v.displayName,
          onChanged: (v) => setState(() => _selectedSide = v),
        ),
        const SizedBox(height: 12),

        // Tipo de vía
        DropdownButtonFormField<RoadType>(
          initialValue: _selectedRoadType,
          decoration: const InputDecoration(
            labelText: 'Tipo de Vía *',
            prefixIcon: Icon(Icons.map_outlined),
          ),
          items: RoadType.values
              .map((t) => DropdownMenuItem(
                    value: t,
                    child: Text(t.displayName),
                  ))
              .toList(),
          onChanged: (v) => setState(() => _selectedRoadType = v!),
        ),
        const SizedBox(height: 12),

        // Velocidad límite
        TextFormField(
          controller: _speedLimitCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Velocidad Límite (km/h)',
            hintText: '110',
            prefixIcon: Icon(Icons.speed_outlined),
          ),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
      ],
    );
  }

  Widget _buildAccidentSection() {
    return Column(
      children: [
        // Narración del accidente
        TextFormField(
          controller: _incidentDescCtrl,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Narración del Accidente',
            hintText: 'Describe lo que ocurrió...',
            prefixIcon: Icon(Icons.description_outlined),
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 12),

        // Causa probable
        TextFormField(
          controller: _probableCauseCtrl,
          decoration: const InputDecoration(
            labelText: 'Causa Probable del Accidente',
            hintText: 'Exceso de velocidad, fatiga...',
            prefixIcon: Icon(Icons.help_outline),
          ),
        ),
      ],
    );
  }

  Widget _buildVehiclesSection() {
    return Column(
      children: [
        ...List.generate(_vehicleTypeCtrl.length, (i) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _vehicleTypeCtrl[i],
                    decoration: InputDecoration(
                      labelText: 'Tipo de Vehículo ${i + 1}',
                      hintText: 'Camioneta, Tráiler...',
                      prefixIcon: const Icon(Icons.directions_car_outlined),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _vehiclePlateCtrl[i],
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Placa',
                      hintText: 'ABC-123',
                    ),
                  ),
                ),
                if (i > 0)
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline,
                        color: AppColors.error),
                    onPressed: () => _removeVehicle(i),
                  ),
              ],
            ),
          );
        }),

        // Botón agregar vehículo
        TextButton.icon(
          onPressed: _addVehicle,
          icon: const Icon(Icons.add_circle_outline),
          label: const Text('Agregar otro vehículo'),
        ),
      ],
    );
  }

  Widget _buildVictimsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _VictimCounter(
            label: 'Muertos',
            value: _fatalities,
            color: AppColors.error,
            onChanged: (v) => setState(() => _fatalities = v),
          ),
          const Divider(height: 16),
          _VictimCounter(
            label: 'Heridos Graves',
            value: _seriousInjuries,
            color: AppColors.warning,
            onChanged: (v) => setState(() => _seriousInjuries = v),
          ),
          const Divider(height: 16),
          _VictimCounter(
            label: 'Heridos Leves',
            value: _minorInjuries,
            color: AppColors.statusReviewing,
            onChanged: (v) => setState(() => _minorInjuries = v),
          ),
          const Divider(height: 16),
          _VictimCounter(
            label: 'Ilesos',
            value: _uninjured,
            color: AppColors.success,
            onChanged: (v) => setState(() => _uninjured = v),
          ),
        ],
      ),
    );
  }

  Widget _buildConditionsSection() {
    return Column(
      children: [
        DropdownButtonFormField<String?>(
          initialValue: _weatherCondition,
          decoration: const InputDecoration(
            labelText: 'Condición Atmosférica',
            prefixIcon: Icon(Icons.wb_cloudy_outlined),
          ),
          items: const [
            DropdownMenuItem(value: null, child: Text('No especificada')),
            DropdownMenuItem(value: 'Despejado', child: Text('Despejado')),
            DropdownMenuItem(value: 'Nublado', child: Text('Nublado')),
            DropdownMenuItem(value: 'Lluvia', child: Text('Lluvia')),
            DropdownMenuItem(value: 'Niebla', child: Text('Niebla')),
            DropdownMenuItem(value: 'Granizo', child: Text('Granizo')),
          ],
          onChanged: (v) => setState(() => _weatherCondition = v),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String?>(
          initialValue: _surfaceCondition,
          decoration: const InputDecoration(
            labelText: 'Superficie',
            prefixIcon: Icon(Icons.texture_outlined),
          ),
          items: const [
            DropdownMenuItem(value: null, child: Text('No especificada')),
            DropdownMenuItem(value: 'Seca', child: Text('Seca')),
            DropdownMenuItem(value: 'Húmeda', child: Text('Húmeda')),
            DropdownMenuItem(value: 'Con hielo', child: Text('Con hielo')),
            DropdownMenuItem(value: 'Con aceite', child: Text('Con aceite')),
          ],
          onChanged: (v) => setState(() => _surfaceCondition = v),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String?>(
          initialValue: _lightCondition,
          decoration: const InputDecoration(
            labelText: 'Luminosidad',
            prefixIcon: Icon(Icons.light_mode_outlined),
          ),
          items: const [
            DropdownMenuItem(value: null, child: Text('No especificada')),
            DropdownMenuItem(value: 'Diurno', child: Text('Diurno')),
            DropdownMenuItem(value: 'Nocturno con luz', child: Text('Nocturno con luz')),
            DropdownMenuItem(value: 'Nocturno sin luz', child: Text('Nocturno sin luz')),
            DropdownMenuItem(value: 'Amanecer/Atardecer', child: Text('Amanecer/Atardecer')),
          ],
          onChanged: (v) => setState(() => _lightCondition = v),
        ),
      ],
    );
  }

  Widget _buildObservationsSection() {
    return TextFormField(
      controller: _observationsCtrl,
      maxLines: 4,
      decoration: const InputDecoration(
        labelText: 'Actividad Realizada / Observaciones *',
        hintText:
            'Suministro y colocación de defensa metálica (poste metálico IPR incluye)...',
        prefixIcon: Icon(Icons.edit_note_outlined),
        alignLabelWithHint: true,
      ),
      validator: (v) =>
          v == null || v.trim().isEmpty ? 'Describe la actividad realizada' : null,
    );
  }

  // Widget reutilizable para campos de selección segmentada
  Widget _buildSegmentedField<T>({
    required String label,
    required T value,
    required List<T> options,
    required String Function(T) labelOf,
    required ValueChanged<T> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8, left: 4),
          child: Text(label, style: AppTextStyles.label),
        ),
        Row(
          children: options.map((opt) {
            final isSelected = opt == value;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => onChanged(opt),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    height: 48,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.border,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        labelOf(opt),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ─── WIDGETS AUXILIARES ──────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;

  const _SectionHeader({
    required this.icon,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.h3),
                if (subtitle != null)
                  Text(subtitle!, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Contador de víctimas con botones +/-
class _VictimCounter extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final ValueChanged<int> onChanged;

  const _VictimCounter({
    required this.label,
    required this.value,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label, style: AppTextStyles.bodyMedium),
        ),
        // Botón restar
        IconButton(
          onPressed: value > 0 ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove_circle_outline),
          color: AppColors.textSecondary,
          iconSize: 28,
        ),
        // Contador
        SizedBox(
          width: 40,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: AppTextStyles.h3.copyWith(color: color),
          ),
        ),
        // Botón sumar
        IconButton(
          onPressed: () => onChanged(value + 1),
          icon: const Icon(Icons.add_circle_outline),
          color: AppColors.primary,
          iconSize: 28,
        ),
      ],
    );
  }
}