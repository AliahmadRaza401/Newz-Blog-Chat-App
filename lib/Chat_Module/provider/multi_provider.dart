import 'package:news_flutter/Chat_Module/provider/chat_provider.dart';
import 'package:provider/provider.dart';

final multiProvider = [
 
  ChangeNotifierProvider<ChatProvider>(
    create: (_) => ChatProvider(),
  ),

];
