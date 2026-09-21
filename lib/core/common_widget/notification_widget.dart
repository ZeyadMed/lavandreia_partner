import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:lavanderia_partner/core/theme/text_styles.dart';

class NotificationWidget extends StatelessWidget {
  final String title;
  final String body;
  final String date;
  final int? income;
  final IconData? icon;
  const NotificationWidget({
    super.key,
    required this.title,
    required this.body,
    required this.date,
    this.icon,
    this.income,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    title,
                    style: TextStyles.blackBold16,
                    textAlign: TextAlign.start,
                  ),
                ),
                Gap(5.h),
                Container(
                  padding: EdgeInsets.all(8.h),
                  decoration: BoxDecoration(
                    color: Color(0xffefe2e4),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Icon(
                    icon ?? Icons.notifications,
                    color: Color(0xff7D151E),
                    size: 20,
                  ),
                ),
              ],
            ),
            Gap(10.h),
            Text(
              body,
              textAlign: TextAlign.start,
              style: TextStyles.greyRegular15,
            ),
            Gap(5.h),
            Align(
              alignment: AlignmentDirectional.bottomEnd,
              child: Text(
                date,
                textAlign: TextAlign.end,
                style: TextStyles.grey3Bold12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
