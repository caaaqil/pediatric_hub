import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme/app_dimens.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/state_views.dart';
import '../../../data/models/child.dart';
import '../../providers/providers.dart';

/// Add (`POST /children`) or edit (`PUT /children/:id`) a child.
///
/// `gender` is a free String column in Prisma; these are the values the web app
/// uses. `dateOfBirth` must be a full ISO-8601 datetime for the Zod schema.
class ChildFormScreen extends ConsumerStatefulWidget {
  const ChildFormScreen({super.key, this.childId});

  final String? childId;

  bool get isEdit => childId != null;

  @override
  ConsumerState<ChildFormScreen> createState() => _ChildFormScreenState();
}

class _ChildFormScreenState extends ConsumerState<ChildFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _firstName = TextEditingController();
  final TextEditingController _lastName = TextEditingController();

  static const List<String> _genders = <String>['Male', 'Female'];
  static const List<String> _bloodTypes = <String>[
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
  ];

  DateTime? _dateOfBirth;
  String _gender = _genders.first;
  String? _bloodType;

  bool _busy = false;
  bool _loaded = false;
  String? _error;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    super.dispose();
  }

  void _prefill(Child child) {
    if (_loaded) return;
    _loaded = true;
    _firstName.text = child.firstName;
    _lastName.text = child.lastName;
    _dateOfBirth = child.dateOfBirth;
    if (_genders.contains(child.gender)) {
      _gender = child.gender;
    }
    final String? blood = child.bloodType;
    if (blood != null && _bloodTypes.contains(blood)) _bloodType = blood;
  }

  Future<void> _pickDate() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(now.year - 1, now.month, now.day),
      firstDate: DateTime(now.year - 20),
      lastDate: now,
      helpText: 'Date of birth',
    );
    if (picked != null) setState(() => _dateOfBirth = picked);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final DateTime? dob = _dateOfBirth;
    if (dob == null) {
      setState(() => _error = 'Date of birth is required');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final String? id = widget.childId;
      if (id == null) {
        await ref
            .read(childRepositoryProvider)
            .create(
              firstName: _firstName.text.trim(),
              lastName: _lastName.text.trim(),
              dateOfBirth: dob,
              gender: _gender,
              bloodType: _bloodType,
            );
      } else {
        await ref
            .read(childRepositoryProvider)
            .update(
              id: id,
              firstName: _firstName.text.trim(),
              lastName: _lastName.text.trim(),
              dateOfBirth: dob,
              gender: _gender,
              bloodType: _bloodType,
            );
        ref.invalidate(childDetailProvider(id));
      }

      ref.invalidate(myChildrenProvider);
      ref.invalidate(allChildVaccinationsProvider);

      if (!mounted) return;
      Toast.success(
        context,
        widget.isEdit ? 'Child updated' : 'Child registered',
      );
      context.pop();
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.detailedMessage);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? id = widget.childId;

    if (id != null) {
      final AsyncValue<Child> child = ref.watch(childDetailProvider(id));
      return child.when(
        loading: () => Scaffold(
          appBar: AppBar(title: const Text('Edit child')),
          body: const LoadingView(),
        ),
        error: (Object error, StackTrace _) => Scaffold(
          appBar: AppBar(title: const Text('Edit child')),
          body: ErrorView(
            message: error is ApiException
                ? error.detailedMessage
                : error.toString(),
            onRetry: () => ref.invalidate(childDetailProvider(id)),
          ),
        ),
        data: (Child data) {
          _prefill(data);
          return _form(context);
        },
      );
    }

    return _form(context);
  }

  Widget _form(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.isEdit ? 'Edit child' : 'Add a child')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.pageBottom,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (_error != null) ...<Widget>[
                  ErrorBanner(message: _error ?? ''),
                  const SizedBox(height: AppSpacing.lg),
                ],
                TextFormField(
                  controller: _firstName,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'First name',
                    prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                  ),
                  validator: (String? v) =>
                      Validators.required(v, 'First name'),
                ),
                const SizedBox(height: AppSpacing.lg),
                TextFormField(
                  controller: _lastName,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Last name',
                    prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                  ),
                  validator: (String? v) => Validators.required(v, 'Last name'),
                ),
                const SizedBox(height: AppSpacing.lg),
                InkWell(
                  onTap: _pickDate,
                  borderRadius: AppRadius.smAll,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Date of birth',
                      prefixIcon: Icon(Icons.cake_outlined, size: 20),
                    ),
                    child: Text(
                      _dateOfBirth == null
                          ? 'Select a date'
                          : Fmt.date(_dateOfBirth),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                DropdownButtonFormField<String>(
                  initialValue: _gender,
                  decoration: const InputDecoration(
                    labelText: 'Gender',
                    prefixIcon: Icon(Icons.wc_rounded, size: 20),
                  ),
                  items: _genders
                      .map(
                        (String g) =>
                            DropdownMenuItem<String>(value: g, child: Text(g)),
                      )
                      .toList(),
                  onChanged: (String? value) {
                    if (value != null) setState(() => _gender = value);
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                DropdownButtonFormField<String>(
                  initialValue: _bloodType,
                  decoration: const InputDecoration(
                    labelText: 'Blood type (optional)',
                    prefixIcon: Icon(Icons.bloodtype_outlined, size: 20),
                  ),
                  items: <DropdownMenuItem<String>>[
                    const DropdownMenuItem<String>(child: Text('Not recorded')),
                    ..._bloodTypes.map(
                      (String b) =>
                          DropdownMenuItem<String>(value: b, child: Text(b)),
                    ),
                  ],
                  onChanged: (String? value) =>
                      setState(() => _bloodType = value),
                ),
                const SizedBox(height: AppSpacing.xl),
                PrimaryButton(
                  label: widget.isEdit ? 'Save changes' : 'Register child',
                  icon: Icons.check_rounded,
                  isLoading: _busy,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
