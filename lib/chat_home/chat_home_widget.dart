// ignore_for_file: use_build_context_synchronously, avoid_print

import 'dart:async';

import 'package:chatbot_app/backend/backend.dart';
import 'package:firebase_core/firebase_core.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'chat_home_model.dart';
export 'chat_home_model.dart';

import 'gpt_interactions.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

final db = FirebaseFirestore.instance;

class ChatHomeWidget extends StatefulWidget {
  const ChatHomeWidget({super.key});

  @override
  @override
  // ignore: no_logic_in_create_state
  State<ChatHomeWidget> createState() {
    // Clear the chat messages when a new state is created (i.e., when a user logs in)
    _chatMessages.clear();
    return _ChatHomeWidgetState();
  }
}

class ChatMessage {
  final String message;
  final String sender;

  ChatMessage(this.message, this.sender);
}
List<ChatMessage> _chatMessages = [];

String _getConversationContext() {
  // Limit the history size to the last N messages to avoid exceeding token limits
  const int historyLimit = 10;
  List<ChatMessage> limitedHistory = _chatMessages.length > historyLimit
      ? _chatMessages.sublist(_chatMessages.length - historyLimit)
      : _chatMessages;

  return limitedHistory.map((msg) {
    // Determine the prefix based on the sender
    String prefix = msg.sender == "user" ? "User: " : "Bot: ";
    return prefix + msg.message; // Use `msg.message` to access the message text
  }).join("\n");
}

class _ChatHomeWidgetState extends State<ChatHomeWidget> with TickerProviderStateMixin {

  final GPTService _gptService = GPTService();
  final ScrollController _scrollController = ScrollController();
  // ignore: unused_field
  String _gptResponse = '';
  bool _isLoading = false;
  String _currentConversationId = '';

  void _getResponse() async {
    // Set the loading state to true and add the user message to the chat
    setState(() {
      _isLoading = true;
      _chatMessages.add(ChatMessage(_model.textController.text, 'User'));
    });
    // Query the GPT-4 API with the user message and the conversation context
    // The conversation context is the concatenation of the last N messages
    // If this is successful, add the bot response to the chat
    // Create a new conversation if the user has sent their first message
    // Add the conversation to the 'Conversations' collection of the current user
    // Add the messages to the 'messages' collection of the current conversation
    try {
      final String query = "${_getConversationContext()}\n${_model.textController.text}"; 
      final response = await _gptService.queryGPT(query);
      setState(() {
      _gptResponse = response!;
      _chatMessages.add(ChatMessage(response, 'GPT'));
      _isLoading = false;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 1200),
        curve: Curves.easeOut,
      );
    });
    if (_chatMessages.length == 2) {
      // Create the conversation without the ID in the title
      var conversation = createConversationsRecordData(
        postUser: currentUserReference,
        id: 1,
        title: 'id:', // Temporary title
        lastMessaged: DateTime.now(),
      );
      
      // Add the conversation to the 'Conversations' collection of the current user
      final docRef = await currentUserReference?.collection('Conversations').add(conversation);
      
      // Get the ID of the conversation
      String? conversationId = docRef?.id;

      // Set the conversationId to the conversation id
      conversation['id'] = conversationId;
      
      // Update the title with the ID
      conversation['title'] = 'id: $conversationId';

      // Query the 'titleGPT' function with the current conversation data
      try {
        final titleResponse = await _gptService.titleGPT(_getConversationContext());
        // Set the response as the new conversation title
        conversation['title'] = titleResponse;
      } catch (e) {
        print('Error: $e');
      }
      var lastUserMessage = _chatMessages[_chatMessages.length - 2];
      var lastBotMessage = _chatMessages[_chatMessages.length - 1];

      // Create a new message
      var userMessage = createMessagesRecordData(
        uid: currentUserReference,
        content: lastUserMessage.message,
        dateTime: DateTime.now(),
        conversationId: docRef,
      );
      var botMessage = createMessagesRecordData(
        uid: currentUserReference,
        content: lastBotMessage.message,
        dateTime: DateTime.now().add(const Duration(seconds: 3)),
        conversationId: docRef,
      );

      // Add the message to the 'Messages' collection of the current conversation
      await docRef?.collection('messages').add(userMessage);
      await docRef?.collection('messages').add(botMessage);

      // Update the data in the cloud
      await docRef?.set(conversation);
      
      print('Conversation created with ID: $conversationId and title: ${conversation['title']}');
    
      // Print all conversation titles of the user
      final userConversations = await currentUserReference?.collection('Conversations').get();
      userConversations?.docs.forEach((doc) {
        print('Conversation title: ${doc.data()['title']}');
      });

      _currentConversationId = conversationId!;

    } else if (_chatMessages.length >= 4) {

      final docRef = currentUserReference?.collection('Conversations').doc(_currentConversationId);
      // Create a new message
      // Get the last two messages from _chatMessages
      var lastUserMessage = _chatMessages[_chatMessages.length - 2];
      var lastBotMessage = _chatMessages[_chatMessages.length - 1];
      var message = createMessagesRecordData(
        uid: currentUserReference,
        content: lastUserMessage.message,
        dateTime: DateTime.now(),
        conversationId: docRef,
      );
      var botResponse = createMessagesRecordData(
        uid: currentUserReference,
        content: lastBotMessage.message,
        dateTime: DateTime.now().add(const Duration(seconds: 3)),
        conversationId: docRef,
      );

      // Add the message to the 'Messages' collection of the current conversation
      await docRef?.collection('messages').add(message);
      await docRef?.collection('messages').add(botResponse);

      await docRef?.update({'last_messaged': DateTime.now()});

      print('Message added to conversation with Conversation: $_currentConversationId, Message: ${message['content']}');
      print('Bot response added to conversation with ID: $_currentConversationId, Message: ${botResponse['content']}');
    }

    } catch (e) {
      print('Error: $e');
      setState(() {
        _chatMessages.add(ChatMessage('Error: $e', 'GPT'));
        _isLoading = false;
      });
    }
  }

  StreamSubscription<QuerySnapshot>? _messagesSubscription;

  Stream<QuerySnapshot> getUserConversationsStream() {
    final String? userId = currentUserReference?.id; // Handling potential null ID
    if (userId == null) {
      throw Exception('Current user ID is null');
    }
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('Conversations')  // Make sure 'Conversations' is correctly named
        .orderBy('last_messaged', descending: true)
        .snapshots();
  }

  Future<List<String?>?> fetchConversationMessages() async {
    final docRef = currentUserReference?.collection('Conversations').doc(_currentConversationId);
    final messages = await docRef?.collection('messages').orderBy('date_time', descending: false).get();
    return messages?.docs.map((doc) => doc.data()['content'] as String?).toList();
  }

  Future<void> deleteConversation(String conversationId) async {
    final FirebaseFirestore db = FirebaseFirestore.instance;

    // Reference to the conversation document
    final DocumentReference conversationRef = db.collection('users').doc(currentUserReference?.id).collection('Conversations').doc(conversationId);

    // Get all messages within the 'messages' subcollection
    final QuerySnapshot messagesSnapshot = await conversationRef.collection('messages').get();

    // Delete all messages
    for (DocumentSnapshot msgDoc in messagesSnapshot.docs) {
      await msgDoc.reference.delete();
    }

    // After all messages are deleted, delete the conversation document
    await conversationRef.delete();

    print('All messages and the conversation have been deleted.');
  }

  late ChatHomeModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  final animationsMap = {
    'textFieldOnPageLoadAnimation': AnimationInfo(
      trigger: AnimationTrigger.onPageLoad,
      applyInitialState: true,
      effects: [
        MoveEffect(
          curve: Curves.easeInOut,
          delay: 0.ms,
          duration: 600.ms,
          begin: const Offset(0.0, 100.0),
          end: const Offset(0.0, 0.0),
        ),
      ],
    ),
    'textFieldOnActionTriggerAnimation': AnimationInfo(
      trigger: AnimationTrigger.onActionTrigger,
      applyInitialState: true,
      effects: [
        MoveEffect(
          curve: Curves.easeInOut,
          delay: 0.ms,
          duration: 600.ms,
          begin: const Offset(0.0, 0.0),
          end: const Offset(0.0, -100.0),
        ),
      ],
    ),
    'buttonOnPageLoadAnimation1': AnimationInfo(
      trigger: AnimationTrigger.onPageLoad,
      effects: [
        FadeEffect(
          curve: Curves.easeInOut,
          delay: 470.ms,
          duration: 600.ms,
          begin: 0.0,
          end: 1.0,
        ),
      ],
    ),
    'buttonOnPageLoadAnimation2': AnimationInfo(
      trigger: AnimationTrigger.onPageLoad,
      effects: [
        FadeEffect(
          curve: Curves.easeInOut,
          delay: 0.ms,
          duration: 600.ms,
          begin: 0.0,
          end: 1.0,
        ),
      ],
    ),
    'rowOnPageLoadAnimation': AnimationInfo(
      trigger: AnimationTrigger.onPageLoad,
      effects: [
        MoveEffect(
          curve: Curves.easeInOut,
          delay: 0.ms,
          duration: 600.ms,
          begin: const Offset(0.0, -100.0),
          end: const Offset(0.0, 0.0),
        ),
      ],
    ),
    'buttonOnPageLoadAnimation3': AnimationInfo(
      trigger: AnimationTrigger.onPageLoad,
      effects: [
        FadeEffect(
          curve: Curves.easeInOut,
          delay: 0.ms,
          duration: 600.ms,
          begin: 0.0,
          end: 1.0,
        ),
      ],
    ),

  };

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ChatHomeModel());

    _model.textController ??= TextEditingController();
    _model.textFieldFocusNode ??= FocusNode();
    setupAnimations(
      animationsMap.values.where((anim) =>
          anim.trigger == AnimationTrigger.onActionTrigger ||
          !anim.applyInitialState),
      this,
    );
  }

  @override
  void dispose() {
    _model.dispose();
    _messagesSubscription?.cancel(); // Properly placed dispose method

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _model.unfocusNode.canRequestFocus
          ? FocusScope.of(context).requestFocus(_model.unfocusNode)
          : FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        drawer: Drawer(
          elevation: 16.0,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              Container(
                width: 328.0,
                height: 156.0,
                decoration: BoxDecoration(
                  color: FlutterFlowTheme.of(context).secondaryBackground,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Padding(
                      padding:
                          const EdgeInsetsDirectional.fromSTEB(10.0, 0.0, 0.0, 0.0),
                      child: Container(
                        width: 120.0,
                        height: 120.0,
                        clipBehavior: Clip.antiAlias,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                        ),
                        child: Image.network(
                          'https://picsum.photos/seed/518/600',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.zero,
                        scrollDirection: Axis.vertical,
                        children: [
                          Padding(
                            padding: const EdgeInsetsDirectional.fromSTEB(
                                10.0, 50.0, 0.0, 0.0),
                            child: AuthUserStreamWidget(
                              builder: (context) => Text(
                                currentUserDisplayName,
                                style: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      fontFamily: 'Roboto',
                                      fontSize: 16.0,
                                      letterSpacing: 0.0,
                                    ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsetsDirectional.fromSTEB(
                                10.0, 0.0, 0.0, 0.0),
                            child: Text(
                              currentUserEmail,
                              style: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    fontFamily: 'Roboto',
                                    fontSize: 12.0,
                                    letterSpacing: 0.0,
                                  ),
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              Padding(
                                padding: const EdgeInsetsDirectional.fromSTEB(
                                    10.0, 10.0, 0.0, 0.0),
                                child: FFButtonWidget(
                                  onPressed: () async {
                                    context.pushNamed(
                                      'Profile',
                                      extra: <String, dynamic>{
                                        kTransitionInfoKey: const TransitionInfo(
                                          hasTransition: true,
                                          transitionType:
                                              PageTransitionType.leftToRight,
                                          duration: Duration(milliseconds: 500),
                                        ),
                                      },
                                    );
                                  },
                                  text: 'Profile',
                                  options: FFButtonOptions(
                                    height: 40.0,
                                    padding: const EdgeInsetsDirectional.fromSTEB(
                                        12.0, 0.0, 12.0, 0.0),
                                    iconPadding: const EdgeInsetsDirectional.fromSTEB(
                                        0.0, 0.0, 0.0, 0.0),
                                    color:
                                        FlutterFlowTheme.of(context).tertiary,
                                    textStyle: FlutterFlowTheme.of(context)
                                        .titleSmall
                                        .override(
                                          fontFamily: 'Roboto',
                                          color: FlutterFlowTheme.of(context)
                                              .primaryText,
                                          letterSpacing: 0.0,
                                        ),
                                    elevation: 3.0,
                                    borderSide: const BorderSide(
                                      color: Colors.transparent,
                                      width: 1.0,
                                    ),
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsetsDirectional.fromSTEB(
                                    8.0, 10.0, 0.0, 0.0),
                                child: FFButtonWidget(
                                  onPressed: () async {
                                    GoRouter.of(context).prepareAuthEvent();
                                    await authManager.signOut();
                                    GoRouter.of(context)
                                        .clearRedirectLocation();

                                    context.goNamedAuth(
                                        'LoginSignup', context.mounted);
                                  },
                                  text: 'Signout',
                                  options: FFButtonOptions(
                                    height: 40.0,
                                    padding: const EdgeInsetsDirectional.fromSTEB(
                                        6.0, 0.0, 12.0, 0.0),
                                    iconPadding: const EdgeInsetsDirectional.fromSTEB(
                                        0.0, 0.0, 0.0, 0.0),
                                    color:
                                        FlutterFlowTheme.of(context).tertiary,
                                    textStyle: FlutterFlowTheme.of(context)
                                        .titleSmall
                                        .override(
                                          fontFamily: 'Roboto',
                                          color: FlutterFlowTheme.of(context)
                                              .primaryText,
                                          letterSpacing: 0.0,
                                        ),
                                    elevation: 3.0,
                                    borderSide: const BorderSide(
                                      color: Colors.transparent,
                                      width: 1.0,
                                    ),
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            FFButtonWidget(
              onPressed: () {
                // Add your onPressed code here!
                setState(() {
                  _chatMessages.clear();
                });
              },
              text: 'New Chat',
              options: FFButtonOptions(
              height: 40.0,
              padding: const EdgeInsetsDirectional.fromSTEB(34.0, 0.0, 34.0, 0.0),
              iconPadding: const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
              color: FlutterFlowTheme.of(context).secondary,
              textStyle: FlutterFlowTheme.of(context).titleSmall.override(
                fontFamily: 'Roboto',
                color: FlutterFlowTheme.of(context).alternate,
                letterSpacing: 0.0,
              ),
              elevation: 3.0,
              borderSide: const BorderSide(
                color: Colors.transparent,
                width: 1.0,
              ),
              borderRadius: BorderRadius.circular(8.0),
              ),
            ),
      Expanded(
        child: StreamBuilder<QuerySnapshot>(
          stream: getUserConversationsStream(), // Defined as shown previously
            builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.hasError) {
              return const Text('Something went wrong');
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            return ListView(
              padding: EdgeInsets.zero,
              children: snapshot.data!.docs.map((DocumentSnapshot document) {
              Map<String, dynamic> data = document.data()! as Map<String, dynamic>;
              return Row(
              children: [
                Expanded(
                child: FFButtonWidget(
                  onPressed: () async {
                  print('Conversation with ${data['title']} pressed.');
                  print('Conversation ID: ${data['id']}');
                  setState(() {
                    _currentConversationId = data['id'];
                  });
                  var messageList = await fetchConversationMessages();
                  print("message: $messageList");
                  setState(() {
                    _chatMessages.clear();
                    for (int i = 0; i < messageList!.length; i++) {
                    String sender = i % 2 == 0 ? 'User' : 'GPT';
                    _chatMessages.add(ChatMessage(messageList[i]!, sender));
                    }
                  });
                  },
                  text: data['title'] ?? "No Title",
                  options: FFButtonOptions(
                  height: 40.0,
                  padding: const EdgeInsetsDirectional.fromSTEB(24.0, 0.0, 24.0, 0.0),
                  iconPadding: const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                  color: FlutterFlowTheme.of(context).primary,
                  textStyle: FlutterFlowTheme.of(context).titleSmall.override(
                    fontFamily: 'Roboto',
                    color: FlutterFlowTheme.of(context).alternate,
                    letterSpacing: 0.0,
                  ),
                  elevation: 3.0,
                  borderSide: const BorderSide(
                    color: Colors.transparent,
                    width: 1.0,
                  ),
                  borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                ),
                IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () async {
                  await deleteConversation(data['id']);
                  setState(() {
                  _chatMessages.clear();
                  });
                },
                ),
              ],
              );
              }).toList(),
            );
          },
        ),
      ),
    ],
  ),
),
        appBar: AppBar(
          backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
          automaticallyImplyLeading: false,
          leading: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(10.0, 0.0, 0.0, 0.0),
            child: FFButtonWidget(
              onPressed: () async {
                scaffoldKey.currentState!.openDrawer();
              },
              text: 'Button',
              icon: Icon(
                Icons.account_circle_outlined,
                color: FlutterFlowTheme.of(context).secondary,
                size: 50.0,
              ),
              options: FFButtonOptions(
                height: 40.0,
                padding: const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 24.0, 0.0),
                iconPadding: const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                color: FlutterFlowTheme.of(context).secondaryBackground,
                textStyle: FlutterFlowTheme.of(context).titleSmall.override(
                      fontFamily: 'Roboto',
                      color: FlutterFlowTheme.of(context).secondaryBackground,
                      letterSpacing: 0.0,
                    ),
                elevation: 0.0,
                borderSide: const BorderSide(
                  color: Colors.transparent,
                  width: 0.0,
                ),
                borderRadius: BorderRadius.circular(8.0),
              ),
            ).animateOnPageLoad(animationsMap['buttonOnPageLoadAnimation2']!),
          ),
          title: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.asset(
                  'assets/images/geminiLogo.png',
                  width: 45.0,
                  height: 45.0,
                  fit: BoxFit.cover,
                ),
              ),
              Switch.adaptive(
                value: _model.switchValue ??= false,
                onChanged: (newValue) async {
                  setState(() => _model.switchValue = newValue);
                },
                activeColor: FlutterFlowTheme.of(context).secondary,
                activeTrackColor: FlutterFlowTheme.of(context).tertiary,
                inactiveTrackColor: FlutterFlowTheme.of(context).secondary,
                inactiveThumbColor:
                    FlutterFlowTheme.of(context).primaryBackground,
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.asset(
                  'assets/images/chatGPTLogo.jpg',
                  width: 45.0,
                  height: 45.0,
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ).animateOnPageLoad(animationsMap['rowOnPageLoadAnimation']!),
          actions: [
            FFButtonWidget(
              onPressed: () async {
                await launchURL('https://github.com/vlvcDev/');
              },
              text: '',
              icon: FaIcon(
                FontAwesomeIcons.github,
                color: FlutterFlowTheme.of(context).primary,
                size: 40.0,
              ),
              options: FFButtonOptions(
                height: 40.0,
                padding: const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                iconPadding: const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                color: FlutterFlowTheme.of(context).secondaryBackground,
                textStyle: FlutterFlowTheme.of(context).titleSmall.override(
                      fontFamily: 'Roboto',
                      color: Colors.white,
                      letterSpacing: 0.0,
                    ),
                elevation: 0.0,
                borderSide: const BorderSide(
                  color: Colors.transparent,
                  width: 0.0,
                ),
                borderRadius: BorderRadius.circular(8.0),
              ),
            ).animateOnPageLoad(animationsMap['buttonOnPageLoadAnimation3']!),
          ],
          centerTitle: true,
          elevation: 2.0,
        ),
        body: SafeArea(
          top: true,
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(0.0, 5.0, 0.0, 0.0),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  width: 395.0,
                  height: MediaQuery.of(context).size.height * 0.8 - MediaQuery.of(context).viewInsets.bottom, // Subtract the height of the keyboard
                  decoration: BoxDecoration(
                    color: FlutterFlowTheme.of(context).primaryBackground,
                  ),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    scrollDirection: Axis.vertical,
                    controller: _scrollController,
                    itemCount: _chatMessages.length,
                    itemBuilder: (context, index) {
                      return Align(
                        alignment: _chatMessages[index].sender == 'User' ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          margin: const EdgeInsets.symmetric(vertical: 5),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: _chatMessages[index].sender == 'User' ? FlutterFlowTheme.of(context).secondary : FlutterFlowTheme.of(context).tertiary,
                          ),
                          child: MarkdownBody(
                            data: _chatMessages[index].message,
                            styleSheet: MarkdownStyleSheet( 
                              a: const TextStyle(color: Colors.cyan),
                              p: TextStyle(color: FlutterFlowTheme.of(context).primaryText),
                              blockquoteDecoration: BoxDecoration(
                                color: FlutterFlowTheme.of(context).primaryBackground,
                                borderRadius: BorderRadius.circular(5),
                              ),
                              codeblockDecoration: BoxDecoration(
                                color: FlutterFlowTheme.of(context).primaryBackground,
                                
                                borderRadius: BorderRadius.circular(5),
                              ),
                              code: TextStyle(color: FlutterFlowTheme.of(context).primaryText, backgroundColor: FlutterFlowTheme.of(context).primaryBackground),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  width: 416.0,
                  height: 56.0,
                  decoration: BoxDecoration(
                    color: FlutterFlowTheme.of(context).primaryBackground,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsetsDirectional.fromSTEB(
                                    2.0, 0.0, 8.0, 0.0),
                                child: TextFormField(
                                  controller: _model.textController,
                                  focusNode: _model.textFieldFocusNode,
                                  autofocus: true,
                                  textCapitalization: TextCapitalization.none,
                                  textInputAction: TextInputAction.send,
                                  obscureText: false,
                                  decoration: InputDecoration(
                                    labelText: 'Message Here...',
                                    labelStyle: FlutterFlowTheme.of(context)
                                        .labelMedium
                                        .override(
                                          fontFamily: 'Roboto',
                                          letterSpacing: 0.0,
                                        ),
                                    hintStyle: FlutterFlowTheme.of(context)
                                        .labelMedium
                                        .override(
                                          fontFamily: 'Roboto',
                                          letterSpacing: 0.0,
                                        ),
                                    enabledBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(
                                        color: FlutterFlowTheme.of(context)
                                            .secondary,
                                        width: 2.0,
                                      ),
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    focusedBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(
                                        color: FlutterFlowTheme.of(context)
                                            .secondary,
                                        width: 2.0,
                                      ),
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    errorBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(
                                        color:
                                            FlutterFlowTheme.of(context).error,
                                        width: 2.0,
                                      ),
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    focusedErrorBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(
                                        color:
                                            FlutterFlowTheme.of(context).error,
                                        width: 2.0,
                                      ),
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    filled: true,
                                    fillColor: FlutterFlowTheme.of(context)
                                        .secondaryBackground,
                                  ),
                                  style: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .override(
                                        fontFamily: 'Roboto',
                                        letterSpacing: 0.0,
                                      ),
                                  maxLines: null,
                                  maxLength: 300,
                                  buildCounter: (context,
                                          {required currentLength,
                                          required isFocused,
                                          maxLength}) =>
                                      null,
                                  cursorColor:
                                      FlutterFlowTheme.of(context).primary,
                                  validator: _model.textControllerValidator
                                      .asValidator(context),
                                )
                                    .animateOnPageLoad(animationsMap[
                                        'textFieldOnPageLoadAnimation']!)
                                    .animateOnActionTrigger(
                                      animationsMap[
                                          'textFieldOnActionTriggerAnimation']!,
                                    ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsetsDirectional.fromSTEB(
                                  0.0, 0.0, 5.0, 0.0),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  FFButtonWidget(
                                    onPressed: _isLoading ? null : () {
                                      _getResponse();
                                      _model.textController?.clear();
                                      print('Button pressed ...');
                                    },
                                    text: '',
                                    icon: Icon(
                                      Icons.arrow_circle_up,
                                      color: FlutterFlowTheme.of(context).primary,
                                      size: 32.0,
                                    ),
                                    options: FFButtonOptions(
                                      height: 40.0,
                                      padding: const EdgeInsetsDirectional.fromSTEB(24.0, 0.0, 24.0, 0.0),
                                      iconPadding: const EdgeInsetsDirectional.fromSTEB(8.0, 0.0, 0.0, 0.0),
                                      color: FlutterFlowTheme.of(context).secondary,
                                      textStyle: FlutterFlowTheme.of(context)
                                          .titleSmall
                                          .override(
                                            fontFamily: 'Roboto',
                                            color: Colors.white,
                                            letterSpacing: 0.0,
                                          ),
                                      elevation: 3.0,
                                      borderSide: BorderSide(
                                        color: FlutterFlowTheme.of(context).secondaryBackground,
                                        width: 0.0,
                                      ),
                                      borderRadius: BorderRadius.circular(8.0),
                                      hoverColor: FlutterFlowTheme.of(context).secondary,
                                    ),
                                  ).animateOnPageLoad(animationsMap['buttonOnPageLoadAnimation1']!),
                                  if (_isLoading)
                                    const CircularProgressIndicator(), // This will be displayed over the button when _isLoading is true
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ].divide(const SizedBox(height: 6.0)),
            ),
          ),
        ),
      ),
    );
  }
}
