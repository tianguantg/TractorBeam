import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tbnet_app/models/tractor_beam_controller.dart';
import 'package:tbnet_app/startup/startup_warmup.dart';
import 'package:tbnet_app/widgets/paper_image.dart';

void main() {
  testWidgets('paper shader warm-up completes without throwing', (
    tester,
  ) async {
    final warmUp = TractorBeamShaderWarmUp();
    await tester.runAsync(warmUp.execute);
    await expectLater(warmUp.completed, completes);
  });

  testWidgets('startup gate precaches paper and removes dialog scene', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(960, 820));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    final controller = TractorBeamController.detached();
    addTearDown(controller.dispose);
    var released = false;

    await tester.pumpWidget(
      MaterialApp(
        home: StartupWarmupGate(
          controller: controller,
          timeout: const Duration(milliseconds: 750),
          onComplete: () => released = true,
          child: const ColoredBox(
            key: ValueKey('real-application'),
            color: Colors.black,
          ),
        ),
      ),
    );
    expect(find.byKey(const ValueKey('startup-splash')), findsOneWidget);
    expect(find.byKey(const ValueKey('startup-app-mark')), findsOneWidget);
    expect(find.byKey(const ValueKey('real-application')), findsNothing);
    expect(
      find.byKey(const ValueKey('create-lan-room-dialog')),
      findsOneWidget,
    );

    for (var index = 0; index < 20 && !released; index++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pumpAndSettle();

    expect(released, isTrue);
    expect(find.byKey(const ValueKey('real-application')), findsOneWidget);
    expect(find.byKey(const ValueKey('startup-splash')), findsNothing);
    expect(find.byKey(const ValueKey('create-lan-room-dialog')), findsNothing);

    final imageContext = tester.element(
      find.byKey(const ValueKey('real-application')),
    );
    for (final asset in const <String>[
      'assets/images/paper/connection_paper.webp',
      'assets/images/paper/connection_lan_torn.webp',
    ]) {
      final provider = TbPaperImageScope.providerFor(
        asset: asset,
        pixelRatio: MediaQuery.devicePixelRatioOf(imageContext),
        logicalWidth: 782,
      );
      final key = await provider.obtainKey(
        createLocalImageConfiguration(imageContext),
      );
      expect(PaintingBinding.instance.imageCache.containsKey(key), isTrue);
    }
  });
}
