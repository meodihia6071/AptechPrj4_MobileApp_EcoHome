import 'package:ecohome_app/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Hiển thị trang đăng nhập khi mở ứng dụng', (tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Đăng nhập'), findsWidgets);
    expect(find.text('Số căn cước'), findsOneWidget);
    expect(find.text('Mật khẩu'), findsOneWidget);
    expect(find.text('Đặt lại mật khẩu'), findsOneWidget);
  });

  testWidgets('Kiểm tra dữ liệu bắt buộc trước khi đăng nhập', (tester) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.text('Đăng nhập').last);
    await tester.pump();

    expect(find.text('Vui lòng nhập số căn cước'), findsOneWidget);
    expect(find.text('Vui lòng nhập mật khẩu'), findsOneWidget);
  });
}
