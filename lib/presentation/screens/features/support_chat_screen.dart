import 'package:flutter/material.dart';

class SupportChatScreen extends StatefulWidget {
  const SupportChatScreen({super.key});

  @override
  State<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends State<SupportChatScreen> {
  final _ctl = TextEditingController();
  final _scroll = ScrollController();
  final List<_Msg> _msgs = <_Msg>[
    _Msg(text: 'Hi! This is Zoomigoo support 👋\nHow can we help?', me: false, ts: DateTime.now()),
  ];
  bool _sending = false;

  @override
  void dispose() {
    _ctl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send() async {
    final text = _ctl.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() {
      _sending = true;
      _msgs.add(_Msg(text: text, me: true, ts: DateTime.now()));
      _ctl.clear();
    });
    await Future.delayed(const Duration(milliseconds: 120));
    _scroll.animateTo(
      _scroll.position.maxScrollExtent + 120,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );

    // Fake agent reply (placeholder until backend/socket integrates)
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() {
      _msgs.add(_Msg(
        text: 'Thanks! We’ve received your message.\nA support agent will reply shortly.',
        me: false,
        ts: DateTime.now(),
      ));
      _sending = false;
    });
    await Future.delayed(const Duration(milliseconds: 120));
    if (mounted) {
      _scroll.animateTo(
        _scroll.position.maxScrollExtent + 120,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live chat'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                itemCount: _msgs.length,
                itemBuilder: (_, i) {
                  final m = _msgs[i];
                  return Align(
                    alignment: m.me ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.78,
                      ),
                      decoration: BoxDecoration(
                        color: m.me ? cs.primary : cs.surfaceVariant,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(14),
                          topRight: const Radius.circular(14),
                          bottomLeft: Radius.circular(m.me ? 14 : 4),
                          bottomRight: Radius.circular(m.me ? 4 : 14),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: .06),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Text(
                        m.text,
                        style: TextStyle(
                          color: m.me ? Colors.white : cs.onSurface,
                          height: 1.25,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Input bar (keyboard-safe)
            Padding(
              padding: EdgeInsets.fromLTRB(12, 4, 12, 12 + MediaQuery.of(context).viewPadding.bottom),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctl,
                      minLines: 1,
                      maxLines: 5,
                      textInputAction: TextInputAction.newline,
                      decoration: InputDecoration(
                        hintText: 'Type a message…',
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surfaceVariant,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _sending ? null : _send,
                    icon: const Icon(Icons.send_rounded),
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

class _Msg {
  final String text;
  final bool me;
  final DateTime ts;
  _Msg({required this.text, required this.me, required this.ts});
}
