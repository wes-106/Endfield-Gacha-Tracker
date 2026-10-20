import 'package:flutter/material.dart';

class ExportDialog extends StatefulWidget {
  final String poolTitle;
  final List<String> bannerNames;
  final bool initialShowTime;
  final bool initialShowAccount;
  final String initialAccountName;
  // 導出時將玩家選好的設定回傳給主畫面
  final Function(List<String> toExport, bool showTime, bool showAccount, String accountName) onExport;

  const ExportDialog({
    super.key,
    required this.poolTitle,
    required this.bannerNames,
    required this.initialShowTime,
    required this.initialShowAccount,
    required this.initialAccountName,
    required this.onExport,
  });

  @override
  State<ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<ExportDialog> {
  late Map<String, bool> selectedBanners;
  late bool showTime;
  late bool showAccount;
  late TextEditingController nameController;

  @override
  void initState() {
    super.initState();
    // 根據傳入的卡池清單，預設全部打勾
    selectedBanners = {for (var name in widget.bannerNames) name: true};
    showTime = widget.initialShowTime;
    showAccount = widget.initialShowAccount;
    nameController = TextEditingController(text: widget.initialAccountName);
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool allSelected = selectedBanners.values.every((v) => v);

    return AlertDialog(
      backgroundColor: const Color(0xFF181920),
      title: Row(
        children: [
          const Icon(Icons.image, color: Color(0xFF60A5FA), size: 20),
          const SizedBox(width: 8),
          Text('導出 ${widget.poolTitle} 紀錄', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('戳記設定', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            CheckboxListTile(
              title: const Text('加上「生成時間」', style: TextStyle(fontSize: 14, color: Colors.white)),
              value: showTime,
              activeColor: const Color(0xFFFFCC00),
              checkColor: Colors.black,
              dense: true,
              visualDensity: VisualDensity.compact,
              contentPadding: EdgeInsets.zero,
              onChanged: (val) => setState(() => showTime = val ?? true),
            ),
            CheckboxListTile(
              title: const Text('加上「帳號名稱 + UID」', style: TextStyle(fontSize: 14, color: Colors.white)),
              value: showAccount,
              activeColor: const Color(0xFFFFCC00),
              checkColor: Colors.black,
              dense: true,
              visualDensity: VisualDensity.compact,
              contentPadding: EdgeInsets.zero,
              onChanged: (val) => setState(() => showAccount = val ?? false),
            ),
            if (showAccount)
              Padding(
                padding: const EdgeInsets.only(left: 32, top: 4, bottom: 8, right: 16),
                child: TextField(
                  controller: nameController,
                  style: const TextStyle(fontSize: 13, color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: '請輸入帳號名稱 (選填)',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(color: Colors.white12),
            ),
            const Text('選擇要導出的卡池', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            CheckboxListTile(
              title: const Text('全選 / 取消全選', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              value: allSelected,
              activeColor: const Color(0xFFFFCC00),
              checkColor: Colors.black,
              dense: true,
              visualDensity: VisualDensity.compact,
              contentPadding: EdgeInsets.zero,
              onChanged: (val) {
                setState(() {
                  selectedBanners.updateAll((key, value) => val ?? false);
                });
              },
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.bannerNames.length,
                itemBuilder: (context, index) {
                  final name = widget.bannerNames[index];
                  return CheckboxListTile(
                    title: Text(name, style: const TextStyle(fontSize: 14, color: Colors.white70)),
                    value: selectedBanners[name],
                    activeColor: const Color(0xFFFFCC00),
                    checkColor: Colors.black,
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    contentPadding: const EdgeInsets.only(left: 16),
                    onChanged: (val) => setState(() => selectedBanners[name] = val ?? false),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消', style: TextStyle(color: Colors.white54)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFCC00)),
          onPressed: () {
            Navigator.pop(context);
            final toExport = selectedBanners.entries.where((e) => e.value).map((e) => e.key).toList();

            if (toExport.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('未選擇任何卡池')));
              return;
            }

            // 觸發回調，把結果傳回給主畫面去執行截圖
            widget.onExport(toExport, showTime, showAccount, nameController.text.trim());
          },
          child: const Text('生成圖片', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}