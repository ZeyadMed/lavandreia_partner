import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:lavanderia_partner/core/extensions/context_extension.dart';
import 'package:lavanderia_partner/core/http/failure.dart';
import 'package:lavanderia_partner/core/router/app_router.dart';
import 'package:lavanderia_partner/core/service_locator/service_locator.dart';
import 'package:lavanderia_partner/core/style/app_colors.dart';
import 'package:lavanderia_partner/features/auth/register/data/models/register_data.dart';
import 'package:lavanderia_partner/features/auth/register/data/register_data_source.dart';
import 'package:lavanderia_partner/features/auth/register/presentation/view/steps/laundry_info_step.dart';
import 'package:lavanderia_partner/features/auth/register/presentation/view/steps/location_step.dart';
import 'package:lavanderia_partner/features/auth/register/presentation/view/steps/review_step.dart';
import 'package:lavanderia_partner/features/auth/register/presentation/view/steps/working_hours_step.dart';
import 'package:lavanderia_partner/features/auth/register/presentation/view/widgets/register_step_header.dart';

/// شاشة إنشاء حساب المغسلة، أربع خطوات على نفس الشاشة
/// الداتا كلها في [RegisterData] واحدة بتتمرر للخطوات وبتتعبى تدريجياً
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  /// أسماء الخطوات في الشريط العلوي، ترتيبها هو ترتيب الخطوات
  static const List<String> _stepKeys = [
    'step_laundry_info',
    'step_location',
    'step_working_hours',
    'step_review',
  ];

  final RegisterData _data = RegisterData();
  final ScrollController _scrollController = ScrollController();

  /// الخطوة الحالية بادئة من 1
  int _currentStep = 1;

  bool _isSubmitting = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    // بنحصر الرقم في المدى الصحيح عشان شريط الخطوات مايخرجش عن اللستة
    setState(() => _currentStep = step.clamp(1, _stepKeys.length));
    // كل خطوة بتبدأ من فوق، من غير كده اليوزر بيلاقي نفسه في نص الشاشة
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
  }

  void _next() => _goToStep(_currentStep + 1);

  /// زرار الرجوع: بيرجع خطوة، ومن أول خطوة بيخرج لشاشة الدخول
  void _back() {
    // مانرجعش وسط الريكوست عشان النتيجة ماترجعش على شاشة مقفولة
    if (_isSubmitting) return;
    if (_currentStep > 1) {
      _goToStep(_currentStep - 1);
      return;
    }
    context.go(AppRouter.login);
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    final result = await getIt<RegisterDataSource>().register(_data);
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    result.fold(
      (failure) {
        // الـ ApiConsumer بيعرض بنفسه أخطاء الاتصال والـ validation،
        // فبنعرض هنا بس رسالة السيرفر العادية عشان ماتظهرش مرتين
        if (failure is ServerFailure || failure is UnknownFailure) {
          context.showErrorMessage(failure.message);
        }
      },
      // push مش go عشان زرار الرجوع في شاشة الكود يرجّع للمراجعة
      (_) => context.push(AppRouter.verifyOtp, extra: _data.laundryPhone),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // بنمسك زرار الرجوع بتاع النظام عشان يرجع خطوة بدل ما يقفل الشاشة كلها
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        backgroundColor: AppColors.secondaryColor,
        body: Column(
          children: [
            RegisterStepHeader(
              currentStep: _currentStep,
              stepKeys: _stepKeys,
              onBack: _back,
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 0),
                child: Column(
                  children: [
                    _buildCurrentStep(),
                    Gap(30.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    // الـ key بيخلي كل خطوة تبني الـ state بتاعها من أول وجديد
    // لما اليوزر يرجعلها، فالكنترولرز بتتملّي من الداتا المحفوظة
    switch (_currentStep) {
      case 1:
        return LaundryInfoStep(
          key: const ValueKey('step_1'),
          data: _data,
          onNext: _next,
        );
      case 2:
        return LocationStep(
          key: const ValueKey('step_2'),
          data: _data,
          onNext: _next,
        );
      case 3:
        return WorkingHoursStep(
          key: const ValueKey('step_3'),
          data: _data,
          onNext: _next,
        );
      default:
        return ReviewStep(
          key: const ValueKey('step_4'),
          data: _data,
          onSubmit: _submit,
          onEditStep: _goToStep,
          isSubmitting: _isSubmitting,
        );
    }
  }
}
