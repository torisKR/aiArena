import 'story_models.dart';

abstract final class StoryCatalog {
  static final List<StoryOperation> operations =
      List<StoryOperation>.unmodifiable([
        const StoryOperation(
          id: StoryOperationId.wake,
          seed: 2026080501,
          duration: Duration(seconds: 180),
          directive: Directive(
            kind: DirectiveKind.longestCommandLink,
            target: 45,
          ),
          oneTimeBonus: 15,
        ),
        const StoryOperation(
          id: StoryOperationId.echo,
          seed: 2026080502,
          duration: Duration(seconds: 180),
          directive: Directive(kind: DirectiveKind.commandRelays, target: 2),
          oneTimeBonus: 20,
        ),
        const StoryOperation(
          id: StoryOperationId.split,
          seed: 2026080503,
          duration: Duration(seconds: 180),
          directive: Directive(kind: DirectiveKind.commandKills, target: 3),
          oneTimeBonus: 25,
        ),
        const StoryOperation(
          id: StoryOperationId.crown,
          seed: 2026080504,
          duration: Duration(seconds: 180),
          directive: Directive(kind: DirectiveKind.finalRank, target: 2),
          oneTimeBonus: 30,
        ),
        const StoryOperation(
          id: StoryOperationId.lastInstruction,
          seed: 2026080505,
          duration: Duration(seconds: 180),
          directive: Directive(kind: DirectiveKind.victory, target: 1),
          oneTimeBonus: 40,
        ),
      ]);

  static StoryOperation byId(StoryOperationId id) => switch (id) {
    StoryOperationId.wake => operations[0],
    StoryOperationId.echo => operations[1],
    StoryOperationId.split => operations[2],
    StoryOperationId.crown => operations[3],
    StoryOperationId.lastInstruction => operations[4],
  };
}
