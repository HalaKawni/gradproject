import 'solver_action.dart';

abstract class PathToSolutionConverter<TSolution> {
  const PathToSolutionConverter();

  TSolution convert(List<SolverAction> actions);
}
