import 'package:firebase_hybrid_ai/firebase_hybrid_ai.dart';
import 'package:material_ui/material_ui.dart';

import '../../../theme/insets.dart';
import '../home_controller.dart';
import 'option_chips.dart';
import 'response_panel.dart';
import 'sample_prompts.dart';
import 'section_header.dart';

/// Sends a prompt to the hybrid AI system and shows the response.
///
/// The user picks a sample prompt or types one, chooses how the request is routed between the device and the cloud,
/// and sends it.
class PromptSection extends StatelessWidget {
  /// Creates the section for [state].
  const new({required this.state, super.key});

  /// The controller supplying data and callbacks.
  final HomeController state;

  /// The label of each inference mode.
  static const Map<InferenceMode, String> modeLabels = <InferenceMode, String>{
    InferenceMode.preferOnDevice: 'Device first',
    InferenceMode.onlyOnDevice: 'Device only',
    InferenceMode.preferInCloud: 'Cloud first',
    InferenceMode.onlyInCloud: 'Cloud only',
  };

  /// What each inference mode does, shown under the chips.
  static String modeDescription(InferenceMode mode) {
    switch (mode) {
      case InferenceMode.preferOnDevice:
        return 'Uses the on-device model when it is installed, and the cloud otherwise.';
      case InferenceMode.onlyOnDevice:
        return 'Never uses the cloud. Fails if the on-device model is not installed.';
      case InferenceMode.preferInCloud:
        return 'Uses the cloud, and the on-device model when the device is offline.';
      case InferenceMode.onlyInCloud:
        return 'Never uses the on-device model.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final bool isEnabled = !state.isGenerating;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const Padding(
          padding: EdgeInsets.only(top: Insets.large),
          child: SectionHeader(title: 'Prompt'),
        ),
        Padding(
          padding: const EdgeInsets.only(top: Insets.small),
          child: SamplePrompts(onSelected: isEnabled ? state.onSamplePromptSelected : null),
        ),
        Padding(
          padding: const EdgeInsets.only(top: Insets.small),
          child: TextField(
            controller: state.promptController,
            enabled: isEnabled,
            minLines: 2,
            maxLines: 5,
            textInputAction: TextInputAction.newline,
            style: theme.textTheme.bodyLarge,
            decoration: InputDecoration(
              hintText: 'Pick an example above or type a prompt',
              hintStyle: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: colors.outline)),
              focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: colors.primary, width: 2)),
              disabledBorder: OutlineInputBorder(borderSide: BorderSide(color: colors.outlineVariant)),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: Insets.small),
          child: OptionChips<InferenceMode>(
            options: modeLabels,
            selected: state.mode,
            onSelected: isEnabled ? state.onModeSelected : null,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: Insets.xSmall),
          child: Text(
            modeDescription(state.mode),
            style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: Insets.medium),
          child: FilledButton(
            onPressed: state.canSend ? state.onSendPressed : null,
            child: Text(state.isGenerating ? 'Generating' : 'Send prompt'),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: Insets.medium),
          child: state.isGenerating
              ? const LinearProgressIndicator()
              : ResponsePanel(
                  result: state.generation,
                  elapsed: state.generationTime,
                  errorMessage: state.generationError,
                ),
        ),
      ],
    );
  }
}
