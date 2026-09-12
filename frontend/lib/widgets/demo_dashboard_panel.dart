import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../screens/chatbot_screen.dart';

class DemoDashboardPanel extends StatefulWidget {
  const DemoDashboardPanel({super.key});
  @override
  State<DemoDashboardPanel> createState() => _DemoDashboardPanelState();
}

class _DemoDashboardPanelState extends State<DemoDashboardPanel> {
  final api = ApiService();
  Timer? timer;
  bool polling = false;
  String? error;
  Map<String, dynamic>? contextData;
  List<Map<String, dynamic>> items = [];
  @override
  void initState() {
    super.initState();
    refresh();
    timer = Timer.periodic(const Duration(seconds: 2), (_) => refresh());
  }
  @override
  void dispose() { timer?.cancel(); super.dispose(); }

  Future<void> refresh() async {
    if (polling) return;
    polling = true;
    try {
      contextData ??= await api.demoContext();
      final next = await api.notifications();
      if (mounted) setState(() { items = next; error = null; });
    } catch (_) {
      if (mounted) setState(() => error = 'Mất kết nối — đang tự kết nối lại.');
    } finally { polling = false; }
  }

  Future<void> inbox() async {
    await refresh();
    if (!mounted) return;
    await showModalBottomSheet(context: context, builder: (ctx) => SafeArea(child: ListView(
      shrinkWrap: true, padding: const EdgeInsets.all(20), children: [
        const Text('Thông báo 💌', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        if (items.isEmpty) const ListTile(title: Text('Chưa có thông báo mới.')),
        ...items.map((n) => ListTile(
          leading: Icon(n['isRead'] == true ? Icons.drafts_outlined : Icons.mark_email_unread_outlined),
          title: Text(n['message']), subtitle: Text(n['isRead'] == true ? 'Đã đọc' : 'Chạm để đánh dấu đã đọc'),
          onTap: () async {
            try { await api.readNotification(n['id']); if (ctx.mounted) Navigator.pop(ctx); await refresh(); }
            catch (_) { if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Chưa cập nhật được, hãy thử lại.'))); }
          },
        )),
      ],
    )));
  }

  @override
  Widget build(BuildContext context) {
    final unread = items.where((n) => n['isRead'] != true).length;
    return Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(
      crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Expanded(child: Text('Khoảnh khắc sắp tới ❤️', style: TextStyle(fontWeight: FontWeight.bold))),
          TextButton.icon(onPressed: inbox, icon: const Icon(Icons.notifications_outlined), label: Text('$unread mới')),
        ]),
        Text('Anniversary còn ${contextData?['daysUntil'] ?? 3} ngày ❤️', style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
        Text('Vẫn còn thời gian để chuẩn bị một điều thật riêng cho ${contextData?['partner'] ?? 'người ấy'}.'),
        if (api.currentUser?.uid == 'demo-alex') FilledButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatbotScreen(
            initialPrompt: 'Anniversary còn 3 ngày. Mình muốn chuẩn bị một moment cho Emma, budget 500K.',
          ))), child: const Text('Chuẩn bị một moment ❤️')),
        if (unread > 0) ...items.where((n) => n['isRead'] != true).map((n) => ListTile(
          leading: const Text('💌'), title: Text(n['message']), onTap: inbox)),
        if (error != null) Text(error!, style: const TextStyle(color: Colors.red)),
        if (api.currentUser?.uid == 'demo-alex') TextButton(onPressed: () async {
          final reset = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
            title: const Text('Bắt đầu lại demo?'), content: const Text('Xóa chat, plan và thông báo demo của Alex–Emma.'),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
              TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Reset'))],
          ));
          if (reset != true) return;
          try { await api.resetDemo(); contextData = null; await refresh(); }
          catch (_) { if (mounted) setState(() => error = 'Reset chưa thành công. Hãy thử lại.'); }
        }, child: const Text('Reset demo')),
      ],
    )));
  }
}
