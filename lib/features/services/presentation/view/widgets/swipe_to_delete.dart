import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:lavanderia_partner/core/common_widget/label.dart';
import 'package:lavanderia_partner/core/style/app_colors.dart';
import 'package:lavanderia_partner/core/theme/text_styles.dart';

/// سحب الكارت يمين أو شمال بيكشف زرار حذف أحمر جنبه
/// السحب لوحده مش بيحذف، لازم اليوزر يضغط على الزرار وبعدها يأكّد
/// الكروت كلها بتشارك [openId] عشان كارت واحد بس يفضل مفتوح
class SwipeToDelete extends StatefulWidget {
  final Object id;
  final ValueNotifier<Object?> openId;

  /// بيتقفل في وضع التحديد
  final bool enabled;

  /// بيتنده لما يضغط على زرار الحذف، والكارت بيتقفل بعد ما يخلص
  final Future<void> Function() onDelete;
  final Widget child;

  const SwipeToDelete({
    super.key,
    required this.id,
    required this.openId,
    required this.enabled,
    required this.onDelete,
    required this.child,
  });

  @override
  State<SwipeToDelete> createState() => _SwipeToDeleteState();
}

class _SwipeToDeleteState extends State<SwipeToDelete>
    with SingleTickerProviderStateMixin {
  /// قيمته هي إزاحة الكارت بالـ pixels، موجبة يعني الكارت اتسحب يمين
  late final AnimationController _controller = AnimationController.unbounded(
    vsync: this,
  );

  double get _actionWidth => 76.w;

  /// المسافة اللي الكارت بيتسحبها لما يتفتح: الزرار والمسافة اللي بينهم
  double get _extent => _actionWidth + 8.w;

  @override
  void initState() {
    super.initState();
    widget.openId.addListener(_onOpenIdChanged);
  }

  @override
  void dispose() {
    widget.openId.removeListener(_onOpenIdChanged);
    _controller.dispose();
    super.dispose();
  }

  /// كارت تاني اتفتح أو الكل اتقفل
  void _onOpenIdChanged() {
    if (widget.openId.value != widget.id && _controller.value != 0) {
      _animateTo(0);
    }
  }

  void _animateTo(double offset) {
    _controller.animateTo(
      offset,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  void _open(double direction) {
    widget.openId.value = widget.id;
    _animateTo(direction * _extent);
  }

  void _close() {
    if (widget.openId.value == widget.id) widget.openId.value = null;
    _animateTo(0);
  }

  void _onDragUpdate(DragUpdateDetails details) {
    _controller.value = (_controller.value + details.primaryDelta!).clamp(
      -_extent,
      _extent,
    );
  }

  /// السحب السريع بيفتح في اتجاهه، وغير كده بيتفتح لو اتسحب أكتر من نص المسافة
  void _onDragEnd(DragEndDetails details) {
    final offset = _controller.value;
    final velocity = details.primaryVelocity ?? 0;
    if (velocity.abs() > 400) {
      offset == 0 || velocity.sign == offset.sign
          ? _open(velocity.sign)
          : _close();
      return;
    }
    offset.abs() > _extent / 2 ? _open(offset.sign) : _close();
  }

  Future<void> _delete() async {
    await widget.onDelete();
    if (mounted) _close();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      // قارئ الشاشة مش بيعرف يسحب، فالحذف بيبقى action على الكارت
      customSemanticsActions: widget.enabled
          ? {CustomSemanticsAction(label: 'delete'.tr()): _delete}
          : null,
      child: GestureDetector(
        // أول ما يبدأ يسحب أي كارت تاني مفتوح بيتقفل
        onHorizontalDragStart: widget.enabled
            ? (_) => widget.openId.value = widget.id
            : null,
        onHorizontalDragUpdate: widget.enabled ? _onDragUpdate : null,
        onHorizontalDragEnd: widget.enabled ? _onDragEnd : null,
        child: AnimatedBuilder(
          animation: _controller,
          child: widget.child,
          builder: (context, child) {
            final offset = _controller.value;
            final progress = (offset.abs() / _extent).clamp(0.0, 1.0);
            return Stack(
              // من غير ده ظل الكارت بيتقص
              clipBehavior: Clip.none,
              children: [
                // الزرار بيظهر في الناحية اللي الكارت اتسحب بعيد عنها
                Positioned(
                  top: 0,
                  bottom: 0,
                  left: offset >= 0 ? 0 : null,
                  right: offset < 0 ? 0 : null,
                  width: _actionWidth,
                  child: Visibility(
                    visible: offset != 0,
                    child: Opacity(
                      opacity: progress,
                      child: Transform.scale(
                        scale: 0.6 + 0.4 * progress,
                        child: _DeleteAction(onTap: _delete),
                      ),
                    ),
                  ),
                ),
                Transform.translate(
                  offset: Offset(offset, 0),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      child!,
                      // وهو مفتوح الضغط على الكارت بيقفله بدل ما يفتح التعديل
                      Positioned.fill(
                        child: IgnorePointer(
                          ignoring: offset == 0,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: _close,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// زرار الحذف الأحمر اللي بيظهر جنب الكارت
class _DeleteAction extends StatelessWidget {
  final VoidCallback onTap;

  const _DeleteAction({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.redColor2,
      borderRadius: BorderRadius.circular(16.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        // بيصغر لو الكارت أقصر من الأيقونة والكلمة
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.delete_outline_rounded,
                  size: 24.sp,
                  color: AppColors.whiteColor,
                ),
                Gap(2.h),
                LocalizedLabel(
                  text: 'delete',
                  maxLines: 1,
                  style: TextStyles.whiteText(12, weight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
