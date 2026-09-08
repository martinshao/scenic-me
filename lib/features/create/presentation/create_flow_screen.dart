import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../data/nearby_services.dart';
import 'nearby_map_screen.dart';

const _travelImage =
    'docs/changes/001-ai-travel-photo/prototype/assets/'
    'west-lake-travel-portrait.png';

enum CreationMode {
  memory('修复旅行回忆'),
  nearby('发现附近打卡点'),
  virtual('虚拟去一个地方');

  const CreationMode(this.label);
  final String label;
}

enum CreationStep { scene, portrait, style, review, generating, result }

class CreateFlowScreen extends StatefulWidget {
  const CreateFlowScreen({
    required this.mode,
    this.nearbyMapDependencies,
    super.key,
  });

  final CreationMode mode;
  final NearbyMapDependencies? nearbyMapDependencies;

  @override
  State<CreateFlowScreen> createState() => _CreateFlowScreenState();
}

class _CreateFlowScreenState extends State<CreateFlowScreen> {
  CreationStep _step = CreationStep.scene;
  String? _scene;
  bool _portraitSelected = false;
  bool _authorized = false;
  String _style = '自然写真';
  int _selectedResult = 0;
  String _nearbyCity = '杭州';
  bool _nearbyLocationMode = true;
  NearbyFilter _nearbyFilter = NearbyFilter.recommended;
  Timer? _generationTimer;

  @override
  void initState() {
    super.initState();
    if (widget.mode == CreationMode.nearby) {
      _scene = '雷峰塔 · 夕照';
    }
  }

  @override
  void dispose() {
    _generationTimer?.cancel();
    super.dispose();
  }

  void _goBack() {
    final previous = switch (_step) {
      CreationStep.scene => null,
      CreationStep.portrait => CreationStep.scene,
      CreationStep.style => CreationStep.portrait,
      CreationStep.review => CreationStep.style,
      CreationStep.generating => CreationStep.review,
      CreationStep.result => CreationStep.review,
    };
    if (previous == null) {
      Navigator.of(context).pop();
    } else {
      _generationTimer?.cancel();
      setState(() => _step = previous);
    }
  }

  void _startGeneration() {
    setState(() => _step = CreationStep.generating);
    _generationTimer = Timer(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _step = CreationStep.result);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_step == CreationStep.scene && widget.mode == CreationMode.nearby) {
      return NearbyMapScreen(
        dependencies: widget.nearbyMapDependencies,
        city: _nearbyCity,
        locationMode: _nearbyLocationMode,
        filter: _nearbyFilter,
        selectedScene: _scene,
        onBack: _goBack,
        onCityChanged: (city, locationMode) {
          setState(() {
            _nearbyCity = city;
            _nearbyLocationMode = locationMode;
          });
        },
        onFilterChanged: (filter) {
          setState(() => _nearbyFilter = filter);
        },
        onSceneChanged: (scene) {
          setState(() => _scene = scene);
        },
        onContinue: (scene) {
          setState(() {
            _scene = scene;
            _step = CreationStep.portrait;
          });
        },
      );
    }
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: '返回上一步',
          onPressed: _goBack,
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        title: Text(_titleForStep()),
        actions: [
          IconButton(
            tooltip: '退出创作',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: KeyedSubtree(key: ValueKey(_step), child: _buildStep()),
        ),
      ),
    );
  }

  String _titleForStep() {
    return switch (_step) {
      CreationStep.scene => widget.mode.label,
      CreationStep.portrait => '添加肖像',
      CreationStep.style => '选择风格',
      CreationStep.review => '确认生成',
      CreationStep.generating => '生成中',
      CreationStep.result => '生成结果',
    };
  }

  Widget _buildStep() {
    return switch (_step) {
      CreationStep.scene => _sceneStep(),
      CreationStep.portrait => _portraitStep(),
      CreationStep.style => _styleStep(),
      CreationStep.review => _reviewStep(),
      CreationStep.generating => _generatingStep(),
      CreationStep.result => _resultStep(),
    };
  }

  Widget _page({
    required int progress,
    required String title,
    required String description,
    required Widget content,
    Widget? footer,
  }) {
    return Column(
      children: [
        if (progress > 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            child: Row(
              children: [
                for (var i = 1; i <= 4; i++) ...[
                  Expanded(
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: i <= progress
                            ? AppColors.freshMint
                            : AppColors.border,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  if (i < 4) const SizedBox(width: 6),
                ],
              ],
            ),
          ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 28,
                    height: 1.15,
                    letterSpacing: -0.7,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  description,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                content,
              ],
            ),
          ),
        ),
        if (footer != null)
          SafeArea(
            top: false,
            minimum: const EdgeInsets.fromLTRB(20, 10, 20, 16),
            child: SizedBox(width: double.infinity, child: footer),
          ),
      ],
    );
  }

  Widget _sceneStep() {
    final content = switch (widget.mode) {
      CreationMode.memory => _memoryScene(),
      CreationMode.nearby => const SizedBox.shrink(),
      CreationMode.virtual => _virtualScene(),
    };
    return _page(
      progress: 1,
      title: '先选一个场景',
      description: '我们会根据它匹配人物位置、光线与构图。',
      content: content,
      footer: FilledButton(
        key: const Key('scene-next'),
        onPressed: _scene == null
            ? null
            : () => setState(() => _step = CreationStep.portrait),
        child: const Text('下一步 · 添加肖像'),
      ),
    );
  }

  Widget _memoryScene() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ImageStage(selected: _scene != null, label: _scene ?? '上传你当时拍摄的风景照'),
        const SizedBox(height: 14),
        OutlinedButton(
          key: const Key('pick-memory-scene'),
          onPressed: () => setState(() => _scene = '西湖暮色.jpg'),
          child: Text(_scene == null ? '选择照片（演示）' : '重新选择'),
        ),
      ],
    );
  }

  Widget _virtualScene() {
    return Column(
      children: [
        const TextField(
          decoration: InputDecoration(
            labelText: '搜索目的地',
            hintText: '例如：富士山、巴黎铁塔',
            prefixIcon: Icon(Icons.search_rounded),
          ),
        ),
        const SizedBox(height: 12),
        _ChoiceTile(
          title: '富士山 · 湖畔新视角',
          subtitle: '演示场景 · AI 重构尚未接入',
          selected: _scene == '富士山 · 湖畔新视角',
          onTap: () => setState(() => _scene = '富士山 · 湖畔新视角'),
        ),
        const SizedBox(height: 10),
        _ChoiceTile(
          title: '巴黎 · 雨夜电影感',
          subtitle: '演示场景 · AI 重构尚未接入',
          selected: _scene == '巴黎 · 雨夜电影感',
          onTap: () => setState(() => _scene = '巴黎 · 雨夜电影感'),
        ),
      ],
    );
  }

  Widget _portraitStep() {
    return _page(
      progress: 2,
      title: '选一张像你的照片',
      description: '正面、无遮挡、光线均匀，生成效果会更自然。',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ImageStage(
            selected: _portraitSelected,
            label: _portraitSelected ? '肖像已通过演示检查' : '尚未选择肖像',
          ),
          const SizedBox(height: 14),
          OutlinedButton(
            key: const Key('pick-portrait'),
            onPressed: () => setState(() => _portraitSelected = true),
            child: Text(_portraitSelected ? '重新选择肖像' : '从相册选择（演示）'),
          ),
          const SizedBox(height: 14),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: _authorized,
            onChanged: (value) => setState(() => _authorized = value ?? false),
            title: const Text(
              '我确认照片中的成年人是本人，或已同意用于本次 AI 创作。',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
      footer: FilledButton(
        key: const Key('portrait-next'),
        onPressed: _portraitSelected && _authorized
            ? () => setState(() => _step = CreationStep.style)
            : null,
        child: const Text('下一步 · 选择风格'),
      ),
    );
  }

  Widget _styleStep() {
    const styles = ['自然写真', '电影胶片', '动漫旅行', '奇幻大片'];
    return _page(
      progress: 3,
      title: '让这张照片有情绪',
      description: '默认保留真实感，也可以改变画面语言。',
      content: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: styles.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.82,
        ),
        itemBuilder: (context, index) {
          final style = styles[index];
          final selected = style == _style;
          return Semantics(
            button: true,
            selected: selected,
            label: style,
            child: InkWell(
              onTap: () => setState(() => _style = style),
              borderRadius: BorderRadius.circular(20),
              child: Ink(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected ? AppColors.freshMint : AppColors.border,
                    width: selected ? 3 : 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(17),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(_travelImage, fit: BoxFit.cover),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Color(0xB317343D)],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 12,
                        right: 12,
                        bottom: 12,
                        child: Text(
                          style,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
      footer: FilledButton(
        key: const Key('style-next'),
        onPressed: () => setState(() => _step = CreationStep.review),
        child: const Text('下一步 · 确认生成'),
      ),
    );
  }

  Widget _reviewStep() {
    return _page(
      progress: 4,
      title: '准备重新遇见这一刻',
      description: '原始照片不会被修改。',
      content: Column(
        children: [
          _SummaryRow(label: '方式', value: widget.mode.label),
          _SummaryRow(label: '场景', value: _scene ?? ''),
          const _SummaryRow(label: '肖像', value: '已确认'),
          _SummaryRow(label: '风格', value: _style),
          const SizedBox(height: 16),
          const _Notice(
            icon: Icons.science_outlined,
            title: '本地演示',
            message: '会模拟生成 4 张候选，不会上传照片或调用 AI 服务。',
          ),
        ],
      ),
      footer: FilledButton(
        key: const Key('generate'),
        onPressed: _startGeneration,
        child: const Text('开始演示生成'),
      ),
    );
  }

  Widget _generatingStep() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.asset(
                    _travelImage,
                    width: double.infinity,
                    height: 410,
                    fit: BoxFit.cover,
                    color: Colors.white.withValues(alpha: 0.30),
                    colorBlendMode: BlendMode.screen,
                  ),
                  const SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              '正在演示生成流程',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            const Text(
              '当前不会上传素材或调用 AI 服务。',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _resultStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '这一张，像你记得的旅途吗？',
            style: TextStyle(
              fontSize: 27,
              height: 1.15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: AspectRatio(
              aspectRatio: 0.72,
              child: Image.asset(_travelImage, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (var i = 0; i < 4; i++) ...[
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _selectedResult = i),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: i == _selectedResult
                              ? AppColors.freshMint
                              : Colors.transparent,
                          width: 3,
                        ),
                        image: const DecorationImage(
                          image: AssetImage(_travelImage),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
                if (i < 3) const SizedBox(width: 7),
              ],
            ],
          ),
          const SizedBox(height: 12),
          const Center(
            child: Text(
              '演示生成 · 尚未连接 AI 服务',
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _step = CreationStep.review),
                  child: const Text('再生成一组'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('演示：保存与系统分享尚未接入')),
                    );
                  },
                  child: const Text('保存并分享'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ImageStage extends StatelessWidget {
  const _ImageStage({required this.selected, required this.label});

  final bool selected;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 255,
      decoration: BoxDecoration(
        color: AppColors.mintWash,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: selected ? AppColors.freshMint : AppColors.clearSky,
          width: selected ? 2 : 1,
        ),
        image: selected
            ? const DecorationImage(
                image: AssetImage(_travelImage),
                fit: BoxFit.cover,
              )
            : null,
      ),
      alignment: selected ? Alignment.bottomLeft : Alignment.center,
      padding: const EdgeInsets.all(16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: selected
              ? AppColors.deepOcean.withValues(alpha: 0.72)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : AppColors.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: selected ? AppColors.mintWash : AppColors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? AppColors.freshMint : AppColors.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.asset(
                  _travelImage,
                  width: 54,
                  height: 54,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.freshMint,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5F8),
        borderRadius: BorderRadius.circular(16),
        border: const Border(
          left: BorderSide(color: AppColors.clearSky, width: 3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.clearSky),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: const TextStyle(color: AppColors.muted, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(width: 18),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(color: AppColors.muted),
            ),
          ),
        ],
      ),
    );
  }
}
