import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/info_dialog.dart';
import '../../../core/widgets/score_badge.dart';
import 'matching_pairs_controller.dart';

class MatchingPairsScreen extends ConsumerWidget {
  const MatchingPairsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(matchingPairsControllerProvider);
    final controller = ref.read(matchingPairsControllerProvider.notifier);
    final attempts = state.attempts == 0 ? 1 : state.attempts;
    final accuracy = (state.valid / attempts * 100).toStringAsFixed(1);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Matching Pairs – Relations & Functions'),
        actions: [
          IconButton(
            onPressed: () {
              InfoDialog.show(
                context,
                title: 'Matching Pairs Help',
                markdownText:
                    'Select a domain element then a codomain element to create ordered pairs. In **Relation** mode you may map one domain to many codomain values. In **Function** mode each domain must map to exactly one codomain; conflicting choices count as invalid.\n\nScore = 20 × valid − 5 × invalid + time bonus. Track injective/surjective hints to reason about your function!',
              );
            },
            icon: const Icon(Icons.info_outline),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Level ${state.level}', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(width: 12),
                Text('Mode: ${state.functionMode ? 'Function' : 'Relation'}'),
                const Spacer(),
                FilledButton.tonalIcon(
                  onPressed: controller.pauseToggle,
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
            Wrap(
              spacing: 12,
              children: [
                ChoiceChip(
                  label: const Text('Relation'),
                  selected: !state.functionMode,
                  onSelected: (_) => controller.toggleMode(),
                ),
                ChoiceChip(
                  label: const Text('Function'),
                  selected: state.functionMode,
                  onSelected: (_) => controller.toggleMode(),
                ),
                FilledButton.icon(
                  onPressed: controller.nextLevel,
                  icon: const Icon(Icons.skip_next),
                  label: const Text('Next Level'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Time: ${state.seconds}s   Valid: ${state.valid}   Attempts: ${state.attempts}   Accuracy: $accuracy%'),
            if (state.warning != null) ...[
              const SizedBox(height: 8),
              Text(state.warning!, style: const TextStyle(color: Colors.redAccent)),
            ],
            const SizedBox(height: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Domain'),
                  Wrap(
                    spacing: 8,
                    children: state.domain
                        .map(
                          (d) => ChoiceChip(
                            label: Text(d),
                            selected: false,
                            onSelected: (_) => controller.selectDomain(d),
                          ),
                        )
                        .toList(),
                  ),
                  const Divider(height: 32),
                  Text('Codomain'),
                  Wrap(
                    spacing: 8,
                    children: state.codomain
                        .map(
                          (c) => FilterChip(
                            label: Text(c),
                            onSelected: (_) => controller.selectCodomain(c),
                          ),
                        )
                        .toList(),
                  ),
                  const Divider(height: 32),
                  Expanded(
                    child: ListView(
                      children: state.relation.entries.map((entry) {
                        final values = entry.value.isEmpty ? '{ }' : '{${entry.value.join(', ')}}';
                        return ListTile(
                          title: Text('${entry.key} → $values'),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Function analysis'),
                    Text('Injective: ${controller.isInjective ? 'Yes' : 'No'}'),
                    Text('Surjective: ${controller.isSurjective ? 'Yes' : 'No'}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ScoreBadge(points: state.score, durationSec: state.seconds),
            ),
          ],
        ),
      ),
    );
  }
}
