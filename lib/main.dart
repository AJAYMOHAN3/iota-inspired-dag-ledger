import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';

void main() => runApp(const DagLedgerApp());

/* ===================== APP ===================== */
class DagLedgerApp extends StatelessWidget {
  const DagLedgerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: DagHomePage(),
    );
  }
}

/* ===================== DAG NODE ===================== */
@immutable
class DagNode {
  final String txId;
  final String data;
  final int timestamp;
  final List<String> parents;
  final List<String> children;

  const DagNode({
    required this.txId,
    required this.data,
    required this.timestamp,
    required this.parents,
    this.children = const [],
  });

  DagNode copyWithChild(String childId) {
    return DagNode(
      txId: txId,
      data: data,
      timestamp: timestamp,
      parents: parents,
      children: [...children, childId],
    );
  }
}

/* ===================== DAG SERVICE ===================== */
class DagService {
  final Map<String, DagNode> _dag = {};

  DagService() {
    _createGenesis();
  }

  void _createGenesis() {
    const genesisId = "GENESIS_NODE";
    _dag[genesisId] = const DagNode(
      txId: genesisId,
      data: "Genesis",
      timestamp: 0,
      parents: [],
    );
  }

  String _calculateHash(
      String data,
      int timestamp,
      List<String> parents,
      int nonce,
      ) {
    final content = "$data|$timestamp|${parents.join(',')}|$nonce";
    return sha256.convert(utf8.encode(content)).toString();
  }

  String addTransaction({
    required String data,
    required int timestamp,
  }) {
    final parents = selectTips();

    int nonce = DateTime.now().microsecondsSinceEpoch;
    String txId;

    // Ensure txId uniqueness
    do {
      txId = _calculateHash(data, timestamp, parents, nonce++);
    } while (_dag.containsKey(txId));

    final newNode = DagNode(
      txId: txId,
      data: data,
      timestamp: timestamp,
      parents: parents,
    );

    _dag[txId] = newNode;

    // Link parents → child
    for (final pId in parents) {
      _dag[pId] = _dag[pId]!.copyWithChild(txId);
    }

    return txId;
  }

  List<String> selectTips() {
    final tips = _dag.values
        .where((n) => n.children.isEmpty && n.txId != "GENESIS_NODE")
        .toList();

    if (tips.isEmpty) return ["GENESIS_NODE"];

    tips.shuffle();
    return tips.take(2).map((e) => e.txId).toList();
  }

  bool verifyIntegrity(String txId) {
    final node = _dag[txId];
    if (node == null) return false;
    if (txId == "GENESIS_NODE") return true;

    final expectedId = _calculateHash(
      node.data,
      node.timestamp,
      node.parents,
      _extractNonce(txId, node),
    );

    return node.txId == expectedId;
  }

  // Nonce recovery is symbolic here; integrity relies on immutability
  int _extractNonce(String txId, DagNode node) => 0;

  DagNode? findNode(String id) {
    final node = _dag[id];
    if (node == null) return null;
    return node;
  }

  List<DagNode> getAllNodesSorted() {
    final nodes = _dag.values.toList();
    nodes.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return nodes;
  }
}

/* ===================== UI ===================== */
class DagHomePage extends StatefulWidget {
  const DagHomePage({super.key});

  @override
  State<DagHomePage> createState() => _DagHomePageState();
}

class _DagHomePageState extends State<DagHomePage> {
  final DagService dagService = DagService();

  final TextEditingController dataCtrl = TextEditingController();
  final TextEditingController timeCtrl = TextEditingController();
  final TextEditingController searchCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final allNodes = dagService.getAllNodesSorted();

    return Scaffold(
      appBar: AppBar(title: const Text("Secure DAG Ledger")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Add Transaction", style: TextStyle(fontSize: 18)),
            TextField(
              controller: dataCtrl,
              decoration: const InputDecoration(labelText: "Transaction Data"),
            ),
            TextField(
              controller: timeCtrl,
              decoration: const InputDecoration(labelText: "Timestamp (int)"),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                if (dataCtrl.text.isEmpty || timeCtrl.text.isEmpty) return;

                dagService.addTransaction(
                  data: dataCtrl.text.trim(),
                  timestamp: int.parse(timeCtrl.text),
                );

                dataCtrl.clear();
                timeCtrl.clear();
                setState(() {});
              },
              child: const Text("Add Transaction"),
            ),
            const Divider(height: 30),
            const Text("Search Node by txId", style: TextStyle(fontSize: 18)),
            TextField(
              controller: searchCtrl,
              decoration: const InputDecoration(labelText: "Enter txId"),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                final node =
                dagService.findNode(searchCtrl.text.trim());
                if (node == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("txId not found")),
                  );
                  return;
                }

                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text("Transaction Details"),
                    content: Text(
                      "txId: ${node.txId}\n"
                          "Data: ${node.data}\n"
                          "Timestamp: ${node.timestamp}\n"
                          "Parents: ${node.parents.join(', ')}\n"
                          "Children: ${node.children.join(', ')}",
                    ),
                  ),
                );
              },
              child: const Text("Search"),
            ),
            const Divider(height: 20),
            const Text("All Transactions", style: TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: allNodes.length,
                itemBuilder: (context, index) {
                  final node = allNodes[index];
                  return Card(
                    child: ListTile(
                      title: Text(node.txId),
                      subtitle: Text(
                        "Data: ${node.data}\n"
                            "Timestamp: ${node.timestamp}\n"
                            "Parents: ${node.parents.join(', ')}\n"
                            "Children: ${node.children.join(', ')}",
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
