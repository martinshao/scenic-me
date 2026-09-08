import 'package:flutter/material.dart';

import '../features/create/data/nearby_services.dart';
import '../features/home/presentation/home_shell.dart';
import 'theme/app_theme.dart';

class App extends StatelessWidget {
  const App({this.nearbyMapDependencies, super.key});

  final NearbyMapDependencies? nearbyMapDependencies;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Scenic Me',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: HomeShell(nearbyMapDependencies: nearbyMapDependencies),
    );
  }
}
