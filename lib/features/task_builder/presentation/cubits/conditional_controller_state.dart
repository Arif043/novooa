part of 'conditional_controller_cubit.dart';

class ConditionalControllerState extends Equatable {
  const ConditionalControllerState({this.nodeConfig, this.selectedBranch});

  final ConditionalNodeConfig? nodeConfig;
  final ConditionalBranch? selectedBranch;

  @override
  List<Object?> get props => [nodeConfig, selectedBranch];

  ConditionalControllerState copyWith({
    ConditionalNodeConfig? nodeConfig,
    ConditionalBranch? Function()? onSelectBranch,
  }) {
    return ConditionalControllerState(
      nodeConfig: nodeConfig ?? this.nodeConfig,
      selectedBranch: onSelectBranch != null
          ? onSelectBranch()
          : selectedBranch,
    );
  }
}
