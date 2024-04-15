import 'package:chatbot_app/auth/firebase_auth/auth_util.dart';
import 'package:dart_openai/dart_openai.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GPTService {

  Future<String?> queryGPT(String prompt) async {
    print(currentUserDisplayName);
      final systemMessage = OpenAIChatCompletionChoiceMessageModel(
        content: [
          OpenAIChatCompletionChoiceMessageContentItemModel.text(
            "Respond as if you are experienced in Computer Science. My name is $currentUserDisplayName.",
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
    model: "gpt-4-0125-preview",
    responseFormat: {"type": "text"},
    seed: 6,
    messages: requestMessages,
    temperature: 0.7,
    maxTokens: 300,
  );

    print(chatCompletion.choices.first.message); // ...
    // ignore: prefer_interpolation_to_compose_strings
    print("Tokens: ${chatCompletion.usage.promptTokens}"); // ...
    return chatCompletion.choices.first.message.content?.first.text;
  }
}