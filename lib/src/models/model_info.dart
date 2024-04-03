import 'package:freezed_annotation/freezed_annotation.dart';

part 'model_info.freezed.dart';
part 'model_info.g.dart';

enum ModelProvider { bedrock, openai, anthropic, google }

enum ModelTier {
  free,
  plus,
}

@freezed
class ModelInfo with _$ModelInfo {
  factory ModelInfo({
    required String name,
    required String description,
    required String contextSize,
    required ModelProvider provider,
    required String link,
    required ModelTier tier,
  }) = _ModelInfo;

  factory ModelInfo.fromJson(Map<String, dynamic> json) =>
      _$ModelInfoFromJson(json);
}
