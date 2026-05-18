import '../../shared/solver/path_to_solution_converter.dart';
import '../../shared/solver/solver_action.dart';
import '../models/logic_command.dart';

class FrontViewSolutionConverter
    extends PathToSolutionConverter<List<LogicCommandNode>> {
  final bool compressTrailingRepeatedActions;

  const FrontViewSolutionConverter({
    this.compressTrailingRepeatedActions = true,
  });

  @override
  List<LogicCommandNode> convert(List<SolverAction> actions) {
    final commandTypes = actions
        .map(_commandForAction)
        .whereType<LogicCommandType>()
        .toList();

    if (!compressTrailingRepeatedActions || commandTypes.length < 2) {
      return commandTypes
          .map((command) => LogicCommandNode.action(command: command))
          .toList();
    }

    final trailingCommand = commandTypes.last;
    var trailingRunStart = commandTypes.length - 1;
    while (trailingRunStart > 0 &&
        commandTypes[trailingRunStart - 1] == trailingCommand) {
      trailingRunStart -= 1;
    }

    final trailingRunLength = commandTypes.length - trailingRunStart;
    if (trailingRunLength < 2) {
      return commandTypes
          .map((command) => LogicCommandNode.action(command: command))
          .toList();
    }

    return <LogicCommandNode>[
      for (var i = 0; i < trailingRunStart; i += 1)
        LogicCommandNode.action(command: commandTypes[i]),
      LogicCommandNode.loop(
        children: <LogicCommandNode>[
          LogicCommandNode.action(command: trailingCommand),
        ],
      ),
    ];
  }

  LogicCommandType? _commandForAction(SolverAction action) {
    switch (action.type) {
      case SolverActionType.moveLeft:
        return LogicCommandType.moveLeft;
      case SolverActionType.moveRight:
        return LogicCommandType.moveRight;
      case SolverActionType.jumpUp:
        return LogicCommandType.jumpUp;
      case SolverActionType.climbUpLeft:
        return LogicCommandType.climbUpLeft;
      case SolverActionType.climbUpRight:
        return LogicCommandType.climbUpRight;
      case SolverActionType.moveUp:
      case SolverActionType.moveDown:
        return null;
    }
  }
}
