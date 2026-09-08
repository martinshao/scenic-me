import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../../create/presentation/create_flow_screen.dart';

const _travelImage =
    'docs/changes/001-ai-travel-photo/prototype/assets/'
    'west-lake-travel-portrait.png';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;

  Future<void> _startCreation(CreationMode mode) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => CreateFlowScreen(mode: mode)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      HomePage(onStart: _startCreation),
      InspirationPage(onStart: _startCreation),
      const WorksPage(),
      const ProfilePage(),
    ];

    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border),
            boxShadow: const [
              BoxShadow(
                color: Color(0x24326973),
                blurRadius: 34,
                offset: Offset(0, 16),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: NavigationBar(
              height: 72,
              selectedIndex: _currentIndex,
              onDestinationSelected: (index) {
                setState(() => _currentIndex = index);
              },
              backgroundColor: Colors.transparent,
              elevation: 0,
              indicatorColor: const Color(0xFFB4EBE1),
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home_rounded),
                  label: '首页',
                ),
                NavigationDestination(
                  icon: Icon(Icons.explore_outlined),
                  selectedIcon: Icon(Icons.explore_rounded),
                  label: '灵感',
                ),
                NavigationDestination(
                  icon: Icon(Icons.photo_library_outlined),
                  selectedIcon: Icon(Icons.photo_library_rounded),
                  label: '作品',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline_rounded),
                  selectedIcon: Icon(Icons.person_rounded),
                  label: '我的',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({required this.onStart, super.key});

  final ValueChanged<CreationMode> onStart;

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 118),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '你好，旅行者',
                        style: TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '今天想留下哪一段旅程？',
                        style: TextStyle(color: AppColors.muted, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const _Avatar(),
              ],
            ),
            const SizedBox(height: 22),
            _HeroCard(onTap: () => onStart(CreationMode.memory)),
            const SizedBox(height: 18),
            const Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    '选择一种创作方式',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
                  ),
                ),
                Text(
                  '无需写 Prompt',
                  style: TextStyle(color: AppColors.clearSky, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (textScale > 1.25)
              Column(
                children: [
                  _TaskCard(
                    key: const Key('start-nearby'),
                    icon: Icons.location_on_outlined,
                    title: '发现附近打卡点',
                    description: '根据定位推荐景点与合适机位',
                    onTap: () => onStart(CreationMode.nearby),
                  ),
                  const SizedBox(height: 10),
                  _TaskCard(
                    key: const Key('start-virtual'),
                    icon: Icons.explore_outlined,
                    title: '虚拟去一个地方',
                    description: '搜索目的地，生成新的旅行视角',
                    onTap: () => onStart(CreationMode.virtual),
                  ),
                ],
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _TaskCard(
                      key: const Key('start-nearby'),
                      icon: Icons.location_on_outlined,
                      title: '发现附近打卡点',
                      description: '根据定位推荐景点与合适机位',
                      onTap: () => onStart(CreationMode.nearby),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _TaskCard(
                      key: const Key('start-virtual'),
                      icon: Icons.explore_outlined,
                      title: '虚拟去一个地方',
                      description: '搜索目的地，生成新的旅行视角',
                      onTap: () => onStart(CreationMode.virtual),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: '旅行者头像',
      child: Container(
        width: 44,
        height: 44,
        padding: const EdgeInsets.all(2),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.white,
          boxShadow: [BoxShadow(color: Color(0x20377881), blurRadius: 16)],
        ),
        child: const ClipOval(
          child: Image(image: AssetImage(_travelImage), fit: BoxFit.cover),
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFBFE6E1)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x263D7E89),
            blurRadius: 38,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: Color(0xFFE6FAF5)),
            Align(
              alignment: Alignment.centerRight,
              child: FractionallySizedBox(
                widthFactor: 0.64,
                child: Image.asset(
                  _travelImage,
                  fit: BoxFit.cover,
                  alignment: const Alignment(0.1, -0.1),
                  color: Colors.white.withValues(alpha: 0.14),
                  colorBlendMode: BlendMode.screen,
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFF1FDFA),
                    const Color(0xFFECFAF7).withValues(alpha: 0.94),
                    const Color(0xFFE8F8F7).withValues(alpha: 0.10),
                  ],
                  stops: const [0, 0.48, 0.82],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 18, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.78),
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: const Color(0xFFA7D8D2)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: Color(0xFF286C67),
                        ),
                        SizedBox(width: 4),
                        Text(
                          '杭州 · 西湖',
                          style: TextStyle(
                            color: Color(0xFF286C67),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  const SizedBox(
                    width: 225,
                    child: Text(
                      '把旅途里没拍好的，重新拍好',
                      style: TextStyle(
                        fontSize: 27,
                        height: 1.14,
                        letterSpacing: -0.8,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  FilledButton(
                    key: const Key('start-memory'),
                    onPressed: onTap,
                    child: const Text('从风景照开始'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$title，$description',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          height: 160,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.white, Color(0xFFF1FAF8)],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.border),
            boxShadow: const [
              BoxShadow(
                color: Color(0x173E7880),
                blurRadius: 24,
                offset: Offset(0, 9),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFDCF5EF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: const Color(0xFF318F82)),
              ),
              const Spacer(),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class InspirationPage extends StatelessWidget {
  const InspirationPage({required this.onStart, super.key});

  final ValueChanged<CreationMode> onStart;

  @override
  Widget build(BuildContext context) {
    return _TopLevelPage(
      title: '灵感',
      subtitle: '目的地与风格',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: AspectRatio(
              aspectRatio: 0.88,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(_travelImage, fit: BoxFit.cover),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Color(0xCC17343D)],
                        stops: [0.35, 1],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 18,
                    right: 18,
                    bottom: 18,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '西湖，把黄昏留得更久',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: () => onStart(CreationMode.virtual),
                          child: const Text('用这个灵感创作'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class WorksPage extends StatelessWidget {
  const WorksPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _TopLevelPage(
      title: '我的作品',
      subtitle: '旅行回忆与草稿',
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.7,
        children: const [
          _WorkTile(label: '西湖 · 自然写真'),
          _WorkTile(label: '未完成 · 电影胶片', sepia: true),
        ],
      ),
    );
  }
}

class _WorkTile extends StatelessWidget {
  const _WorkTile({required this.label, this.sepia = false});

  final String label;
  final bool sepia;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: ColorFiltered(
              colorFilter: sepia
                  ? const ColorFilter.mode(Color(0x44966F45), BlendMode.color)
                  : const ColorFilter.mode(Colors.transparent, BlendMode.dst),
              child: Image.asset(_travelImage, fit: BoxFit.cover),
            ),
          ),
        ),
        const SizedBox(height: 7),
        Text(label, style: const TextStyle(color: AppColors.muted)),
      ],
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    const items = [
      ('肖像照片', '1 张'),
      ('创作草稿', '1 个'),
      ('隐私与数据删除', ''),
      ('生成内容标识', '已开启'),
    ];
    return _TopLevelPage(
      title: '我的',
      subtitle: '偏好与数据',
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            for (var i = 0; i < items.length; i++)
              ListTile(
                minTileHeight: 60,
                title: Text(items[i].$1),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (items[i].$2.isNotEmpty)
                      Text(
                        items[i].$2,
                        style: const TextStyle(color: AppColors.muted),
                      ),
                    const Icon(Icons.chevron_right_rounded),
                  ],
                ),
                shape: i == items.length - 1
                    ? null
                    : const Border(bottom: BorderSide(color: AppColors.border)),
              ),
          ],
        ),
      ),
    );
  }
}

class _TopLevelPage extends StatelessWidget {
  const _TopLevelPage({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 118),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(color: AppColors.muted)),
            const SizedBox(height: 22),
            child,
          ],
        ),
      ),
    );
  }
}
