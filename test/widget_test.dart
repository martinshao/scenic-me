import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scenic_me/app/app.dart';
import 'package:scenic_me/app/theme/app_theme.dart';
import 'package:scenic_me/features/create/presentation/create_flow_screen.dart';

void main() {
  testWidgets('首页展示三个创作入口和四项底部导航', (tester) async {
    await tester.pumpWidget(const App());

    expect(find.text('你好，旅行者'), findsOneWidget);
    expect(find.text('把旅途里没拍好的，重新拍好'), findsOneWidget);
    expect(find.text('发现附近打卡点'), findsOneWidget);
    expect(find.text('虚拟去一个地方'), findsOneWidget);
    expect(find.text('首页'), findsOneWidget);
    expect(find.text('灵感'), findsOneWidget);
    expect(find.text('作品'), findsOneWidget);
    expect(find.text('我的'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('底部导航可以切换一级页面', (tester) async {
    await tester.pumpWidget(const App());

    await tester.tap(find.text('灵感'));
    await tester.pumpAndSettle();

    expect(find.text('目的地与风格'), findsOneWidget);
    expect(find.text('用这个灵感创作'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('附近地图支持手动选城并保留场景选择', (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(const App());

    await tester.tap(find.byKey(const Key('start-nearby')));
    await tester.pumpAndSettle();

    expect(find.text('为你推荐 4'), findsOneWidget);
    expect(find.text('首页'), findsNothing);
    await tester.tap(find.byKey(const Key('city-selector')));
    await tester.pumpAndSettle();
    expect(find.text('想去哪里找场景？'), findsOneWidget);

    await tester.tap(find.byKey(const Key('city-上海')));
    await tester.pumpAndSettle();
    expect(find.text('精选场景 4'), findsOneWidget);
    expect(find.text('城市浏览 · 距离需开启定位'), findsOneWidget);

    await tester.tap(find.byKey(const Key('nearby-scene-0')));
    await tester.pumpAndSettle();
    expect(find.text('外滩 · 蓝调时刻'), findsOneWidget);
    await tester.tap(find.byKey(const Key('nearby-continue')));
    await tester.pumpAndSettle();
    expect(find.text('选一张像你的照片'), findsOneWidget);

    await tester.tap(find.byTooltip('返回上一步'));
    await tester.pumpAndSettle();
    expect(find.text('上海'), findsOneWidget);
    expect(find.text('外滩 · 蓝调时刻'), findsOneWidget);
    expect(find.text('城市浏览 · 距离需开启定位'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('附近地图仅在主动操作后展示定位用途并模拟定位', (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(const App());
    await tester.tap(find.byKey(const Key('start-nearby')));
    await tester.pumpAndSettle();

    expect(find.text('用位置找附近机位'), findsNothing);
    await tester.tap(find.byKey(const Key('nearby-locate')));
    await tester.pumpAndSettle();
    expect(find.text('用位置找附近机位'), findsOneWidget);
    expect(find.textContaining('当前仅模拟定位'), findsOneWidget);

    await tester.tap(find.byKey(const Key('continue-location-demo')));
    await tester.pump();
    expect(find.text('正在定位'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pumpAndSettle();
    expect(find.text('当前位置附近 · 已按光线排序'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('附近地图横屏保持主操作可见', (tester) async {
    tester.view.physicalSize = const Size(844, 390);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const CreateFlowScreen(mode: CreationMode.nearby),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('nearby-continue')), findsOneWidget);
    expect(find.text('雷峰塔 · 夕照'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('旅行回忆入口完成本地演示生成流程', (tester) async {
    await tester.pumpWidget(const App());

    await tester.tap(find.byKey(const Key('start-memory')));
    await tester.pumpAndSettle();

    expect(find.text('先选一个场景'), findsOneWidget);
    expect(find.text('首页'), findsNothing);
    FilledButton sceneNext = tester.widget(find.byKey(const Key('scene-next')));
    expect(sceneNext.onPressed, isNull);

    await tester.tap(find.byKey(const Key('pick-memory-scene')));
    await tester.pump();
    sceneNext = tester.widget(find.byKey(const Key('scene-next')));
    expect(sceneNext.onPressed, isNotNull);
    await tester.tap(find.byKey(const Key('scene-next')));
    await tester.pumpAndSettle();

    FilledButton portraitNext = tester.widget(
      find.byKey(const Key('portrait-next')),
    );
    expect(portraitNext.onPressed, isNull);
    await tester.tap(find.byKey(const Key('pick-portrait')));
    await tester.ensureVisible(find.byType(Checkbox));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    portraitNext = tester.widget(find.byKey(const Key('portrait-next')));
    expect(portraitNext.onPressed, isNotNull);
    await tester.tap(find.byKey(const Key('portrait-next')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('style-next')));
    await tester.pumpAndSettle();
    expect(find.text('本地演示'), findsOneWidget);

    await tester.tap(find.byKey(const Key('generate')));
    await tester.pump();
    expect(find.text('正在演示生成流程'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pumpAndSettle();

    expect(find.text('这一张，像你记得的旅途吗？'), findsOneWidget);
    expect(find.text('演示生成 · 尚未连接 AI 服务'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
