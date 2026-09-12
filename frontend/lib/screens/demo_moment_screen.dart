import 'package:flutter/material.dart';
import '../services/api_service.dart';

class DemoMomentScreen extends StatefulWidget {
  final String? recommendationId;
  const DemoMomentScreen({super.key, this.recommendationId});
  @override
  State<DemoMomentScreen> createState() => _DemoMomentScreenState();
}

class _DemoMomentScreenState extends State<DemoMomentScreen> {
  final api = ApiService();
  List<Map<String, dynamic>> ideas = [];
  Map<String, dynamic>? plan;
  bool busy = false;
  String? error;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> run(Future<void> Function() work) async {
    if (busy) return;
    setState(() { busy = true; error = null; });
    try { await work(); }
    catch (_) { if (mounted) error = 'Chưa kết nối được. Hãy thử lại.'; }
    finally { if (mounted) setState(() => busy = false); }
  }

  Future<void> load() => run(() async {
    if (widget.recommendationId != null) {
      plan = await api.createDemoPlan(widget.recommendationId!);
    } else {
      ideas = await api.recommendations();
    }
  });

  Future<void> confirm() async {
    await run(() async { plan = await api.updateDemoPlan(plan!['id'], {'status': 'planned'}); });
    if (!mounted || error != null) return;
    final send = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Muốn mình thả một hint nhỏ cho Emma không? 👀'),
      content: const Text('Hint không tiết lộ địa điểm hay chi tiết kế hoạch.'),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Để sau')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Bật Mystery Hint'))],
    ));
    if (send == true && mounted) await hint();
  }

  Future<void> hint() => run(() async { plan = await api.sendDemoHint(plan!['id']); });

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(plan == null ? 'Idea dành cho Emma · 500K' : 'Perfect Moment')),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      if (busy) const LinearProgressIndicator(),
      if (error != null) ...[Text(error!, style: const TextStyle(color: Colors.red)),
        TextButton(onPressed: busy ? null : (plan == null ? load : () => setState(() => error = null)), child: const Text('Thử lại'))],
      if (plan == null) ...ideas.map((idea) {
        final place = idea['place'] as Map;
        final icon = idea['id'] == 'pottery' ? '🎨' : idea['id'] == 'sunset' ? '🌅' : '☕';
        return Card(margin: const EdgeInsets.only(bottom: 18), child: Padding(
          padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Stack(alignment: Alignment.center, children: [
              Image.asset(place['imageUrl'], height: 100, errorBuilder: (_, __, ___) => const SizedBox(height: 100)),
              Text(icon, style: const TextStyle(fontSize: 48)),
            ])),
            Text(place['name'], style: Theme.of(context).textTheme.titleLarge),
            Text('${(idea['estimatedCost']['amount'] as num) ~/ 1000}K VND · ${place['area']}'),
            Wrap(spacing: 6, children: (idea['matchTags'] as List).map((t) => Chip(label: Text('$t'))).toList()),
            const Text('Why this one?', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(idea['personalReason']), const SizedBox(height: 12),
            FilledButton(onPressed: busy ? null : () => run(() async { plan = await api.createDemoPlan(idea['id']); }), child: const Text('Chọn idea này ❤️')),
          ]),
        ));
      }),
      if (plan != null) ...[
        Text(plan!['title'], style: Theme.of(context).textTheme.headlineSmall),
        Text(plan!['status'] == 'planned' ? 'Planned ❤️' : 'Suggested'),
        const SizedBox(height: 20),
        ...(plan!['timeline'] as List).map((s) => ListTile(leading: const Icon(Icons.favorite_outline), title: Text('$s'))),
        const Divider(),
        ...(plan!['breakdown'] as List).map((s) => Text('$s')),
        if (plan!['tulipAdded'] == true) const Text('Tulip: 50K'),
        Text('Tổng: ${(plan!['totalCost'] as num) ~/ 1000}K / 500K', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 20),
        Text(plan!['secretSuggestion']),
        SwitchListTile(title: const Text('Thêm Tulip vào plan · 50K'), value: plan!['tulipAdded'] == true,
          onChanged: busy ? null : (value) => run(() async { plan = await api.updateDemoPlan(plan!['id'], {'tulipAdded': value}); })),
        if (plan!['status'] == 'suggested') FilledButton(onPressed: busy ? null : confirm, child: const Text('I’m doing this ❤️')),
        if (plan!['status'] == 'planned') ...[
          const Text('Kế hoạch đã được xác nhận ❤️'),
          if (plan!['mysteryHintEnabled'] == true) const Text('Đã gửi Mystery Hint cho Emma 👀❤️')
          else OutlinedButton(onPressed: busy ? null : hint, child: const Text('Bật Mystery Hint cho Emma 👀')),
        ],
      ],
    ]),
  );
}
