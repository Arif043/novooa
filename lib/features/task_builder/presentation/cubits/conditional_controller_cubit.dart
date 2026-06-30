import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_config.dart';

part 'conditional_controller_state.dart';

class ConditionalControllerCubit extends Cubit<ConditionalControllerState> {
  ConditionalControllerCubit() : super(ConditionalControllerState());

  void load(ConditionalNodeConfig nodeConfig) => emit(state.copyWith(nodeConfig: nodeConfig));

  void selectBranch(ConditionalBranch? branch) => emit(state.copyWith(onSelectBranch: () => branch));
}
