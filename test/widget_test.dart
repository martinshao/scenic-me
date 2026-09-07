import 'package:flutter_test/flutter_test.dart';
import 'package:scenic_me/app/app.dart';

void main() {
  testWidgets('renders bootstrap screen', (tester) async {
    await tester.pumpWidget(const App());
    expect(find.text('项目已初始化，下一步定义核心用户任务。'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
