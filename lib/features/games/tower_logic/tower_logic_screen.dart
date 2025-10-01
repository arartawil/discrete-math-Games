import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/info_dialog.dart';
import '../../../core/widgets/score_badge.dart';
import 'logic_gate.dart';
import 'tower_logic_controller.dart';

class TowerLogicScreen extends ConsumerStatefulWidget {
  const TowerLogicScreen({super.key});

  @override
  ConsumerState<TowerLogicScreen> createState() => _TowerLogicScreenState();
}

class _TowerLogicScreenState extends ConsumerState<TowerLogicScreen> {
  LogicGateType _selectedGate = LogicGateType.and;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(towerLogicControllerProvider);
    final controller = ref.read(towerLogicControllerProvider.notifier);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tower Defense – Logic Gates'),
        actions: [
          IconButton(
            onPressed: () {
              InfoDialog.show(
                context,
                title: 'Tower Defense Help',
                markdownText:
                    'Place towers (logic gates) on the lanes. Each enemy carries inputs (A,B) and a target output (e.g., A XOR B). When an enemy reaches a tower the gate fires. Correct outputs award +50 points and remove the enemy, incorrect responses deduct points and damage base HP. Clear waves for bonus points!\n\nUse the palette to choose gates, click a cell to place or remove towers. Adjust speed, pause to plan, and survive as many waves as you can.',
              );
            },
            icon: const Icon(Icons.info_outline),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Text('Wave ${state.wave}', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(width: 16),
                Text('HP: ${state.hp}'),
                const SizedBox(width: 16),
                Text('Score: ${state.score}'),
                const Spacer(),
                FilledButton.tonalIcon(
                  onPressed: controller.togglePause,
                  icon: Icon(state.paused ? Icons.play_arrow : Icons.pause),
                  label: Text(state.paused ? 'Resume' : 'Pause'),
                ),
                const SizedBox(width: 12),
                FilledButton.tonalIcon(
                  onPressed: controller.reset,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reset'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Speed:'),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('1x'),
                  selected: state.speedMultiplier == 1,
                  onSelected: (_) => controller.changeSpeed(1),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('2x'),
                  selected: state.speedMultiplier == 2,
                  onSelected: (_) => controller.changeSpeed(2),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('3x'),
                  selected: state.speedMultiplier == 3,
                  onSelected: (_) => controller.changeSpeed(3),
                ),
                const Spacer(),
                Text('Pending enemies: ${state.pending.length}'),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final cellSize = (constraints.maxWidth / 5).clamp(80.0, 140.0);
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (lane) {
                      return SizedBox(
                        height: cellSize,
                        child: Row(
                          children: List.generate(5, (position) {
                            final cell = BoardCell(lane, position);
                            final tower = state.towers[cell];
                            final enemy = state.enemies.where((e) => e.lane == lane && e.position == position).firstWhere(
                                  (e) => true,
                                  orElse: () => Enemy(
                                    id: -1,
                                    lane: lane,
                                    position: position,
                                    inputs: (a: false, b: false),
                                    targetLabel: '',
                                    alive: false,
                                    resolved: false,
                                  ),
                                );
                            final hasEnemy = enemy.id != -1;
                            return Expanded(
                              child: InkWell(
                                onTap: () {
                                  if (tower != null) {
                                    controller.removeTower(cell);
                                  } else {
                                    controller.placeTower(cell, _selectedGate);
                                  }
                                },
                                child: Container(
                                  margin: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.indigo.shade200, width: 2),
                                    color: tower != null
                                        ? Colors.indigo.withOpacity(0.2)
                                        : Colors.grey.withOpacity(0.1),
                                  ),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      if (tower != null)
                                        Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              switch (tower) {
                                                LogicGateType.and => Icons.download_done,
                                                LogicGateType.or => Icons.merge_type,
                                                LogicGateType.xor => Icons.all_inclusive,
                                                LogicGateType.notA => Icons.exposure_minus_1,
                                                LogicGateType.notB => Icons.exposure_plus_1,
                                              },
                                            ),
                                            Text(gateLabel(tower)),
                                          ],
                                        ),
                                      if (hasEnemy)
                                        Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text('A:${enemy.inputs.a ? 1 : 0} B:${enemy.inputs.b ? 1 : 0}'),
                                            Text(enemy.targetLabel, style: const TextStyle(fontSize: 12)),
                                          ],
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      );
                    }),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Gate Palette'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: LogicGateType.values.map((gate) {
                        final selected = gate == _selectedGate;
                        return ChoiceChip(
                          label: Text(gateLabel(gate)),
                          selected: selected,
                          onSelected: (_) {
                            setState(() => _selectedGate = gate);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 16,
                      children: LogicGateType.values
                          .map((gate) => Text('${gateLabel(gate)}: ${descriptionForGate(gate)}'))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ScoreBadge(points: state.score, durationSec: state.wave * 10),
            ),
          ],
        ),
      ),
    );
  }
}
