import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lavanderia_partner/core/router/app_router.dart';
import 'package:lavanderia_partner/features/splash/presentation/view_model/cubit/splash_cubit.dart';
import 'package:video_player/video_player.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late final VideoPlayerController _videoController;
  bool _isVideoReady = false;

  @override
  void initState() {
    super.initState();

    _videoController = VideoPlayerController.asset(
      'assets/images/video_splash.mp4',
    );
    _videoController.initialize().then((_) {
      if (!mounted) return;
      _videoController.setVolume(0);
      _videoController.play();
      setState(() => _isVideoReady = true);
    });
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SplashCubit()..startSplashScreen(),
      child: BlocListener<SplashCubit, String>(
        listener: (context, state) {
          if (state == 'home') {
            GoRouter.of(context).pushReplacement(AppRouter.initialRoot);
          } else if (state == 'onboarding') {
            GoRouter.of(context).pushReplacement(AppRouter.onboarding);
          } else if (state == 'login') {
            GoRouter.of(context).pushReplacement(AppRouter.initialRoot);
          }
        },
        child: Scaffold(
          backgroundColor: Colors.black,
          body: _isVideoReady
              ? SizedBox.expand(
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _videoController.value.size.width,
                      height: _videoController.value.size.height,
                      child: VideoPlayer(_videoController),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ),
    );
  }
}
