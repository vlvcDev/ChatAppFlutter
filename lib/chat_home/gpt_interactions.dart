import 'package:chatbot_app/auth/firebase_auth/auth_util.dart';
import 'package:dart_openai/dart_openai.dart';

class GPTService {

  Future<String?> queryGPT(String prompt, double temperature) async {
    print(currentUserDisplayName);
      final systemMessage = OpenAIChatCompletionChoiceMessageModel(
        content: [
          OpenAIChatCompletionChoiceMessageContentItemModel.text(
            "My name is $currentUserDisplayName. Give me concise and informative responses to the following questions: ",
          ),
        ],
        role: OpenAIChatMessageRole.assistant,
      );
     final userMessage = OpenAIChatCompletionChoiceMessageModel(
      content: [
        OpenAIChatCompletionChoiceMessageContentItemModel.text(
          prompt,
        ),
      ],
      role: OpenAIChatMessageRole.user,
    );

    final requestMessages = [systemMessage, userMessage];
    OpenAIChatCompletionModel chatCompletion = await OpenAI.instance.chat.create(
      model: 'gpt-4-0125-preview',
      responseFormat: {"type": "text"},
      seed: 6,
      messages: requestMessages,
      temperature: temperature,
      maxTokens: 300,
    );

    print(chatCompletion.choices.first.message); // ...
    print("Tokens: ${chatCompletion.usage.promptTokens}"); // ...
    return chatCompletion.choices.first.message.content?.first.text;
  }

  Future<String?> titleGPT(String conversation, {String model = 'gpt-4-0125-preview'}) async {
    print(currentUserDisplayName);
      final systemMessage = OpenAIChatCompletionChoiceMessageModel(
        content: [
          OpenAIChatCompletionChoiceMessageContentItemModel.text(
            "Create a short title that summarizes the given text, do not include any prefixes, delimiters, or quotations: ",
          ),
        ],
        role: OpenAIChatMessageRole.assistant,
      );
     final userMessage = OpenAIChatCompletionChoiceMessageModel(
      content: [
        OpenAIChatCompletionChoiceMessageContentItemModel.text(
          conversation,
        ),
      ],
      role: OpenAIChatMessageRole.user,
    );

    final requestMessages = [systemMessage, userMessage];
    OpenAIChatCompletionModel chatCompletion = await OpenAI.instance.chat.create(
      model: model,
      responseFormat: {"type": "text"},
      seed: 6,
      messages: requestMessages,
      temperature: 0.9,
      maxTokens: 10,
    );

    print(chatCompletion.choices.first.message); // ...
    print("Tokens: ${chatCompletion.usage.promptTokens}"); // ...
    return chatCompletion.choices.first.message.content?.first.text;
  }
}
