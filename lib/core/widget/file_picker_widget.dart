import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lavanderia_partner/core/helpers/image_picker_helper.dart';
import 'package:lavanderia_partner/core/style/app_text_theme.dart';
import 'package:lavanderia_partner/core/style/assets.dart';

class FilePickerWidget extends StatefulWidget {
  final String headerText;
  final String footerText;
  final ValueChanged<File?> onFilePicked;
  final File? selectedFile;

  const FilePickerWidget({
    super.key,
    required this.headerText,
    required this.footerText,
    required this.onFilePicked,
    this.selectedFile,
  });

  @override
  State<FilePickerWidget> createState() => _FilePickerWidgetState();
}

class _FilePickerWidgetState extends State<FilePickerWidget> {
  File? _localFile;

  @override
  void didUpdateWidget(covariant FilePickerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.selectedFile != oldWidget.selectedFile) {
      _localFile = widget.selectedFile;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        ImagePickerHelper.showImagePicker(context, (image) {
          setState(() {
            _localFile = image;
          });
          widget.onFilePicked(image);
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.headerText,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextTheme.bodyLarge.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color.fromRGBO(156, 163, 175, 1),
              ),
            ),
            const SizedBox(height: 8),
            (_localFile != null)
                ? Center(
                    child: Image.file(
                      _localFile!,
                      height: 120,
                      fit: BoxFit.contain,
                    ),
                  )
                : Column(
                    children: [
                      Center(
                        child: SvgPicture.asset(
                          Assets.assetsImagesLogo,
                          height: 48,
                          width: 48,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.footerText,
                        maxLines: 2,
                        style: AppTextTheme.bodyMedium.copyWith(
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}
