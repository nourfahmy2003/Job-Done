import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
<<<<<<< HEAD
import 'firebase_options.dart';
import './Views/AuthGate.dart';
import './Views/HomePage.dart';
import './Views/chatpage.dart'; 
=======
import 'firebase_options.dart';  
import './Views/AuthGate.dart';
>>>>>>> b6204569c36ca6ddad69002b8753ca10b451a41f

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
<<<<<<< HEAD
    options: DefaultFirebaseOptions.currentPlatform,
=======
    options: DefaultFirebaseOptions.currentPlatform, 
>>>>>>> b6204569c36ca6ddad69002b8753ca10b451a41f
  );
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
<<<<<<< HEAD
      debugShowCheckedModeBanner: false,
      initialRoute: '/login',
      onGenerateRoute: (settings) {
        if (settings.name == '/chat') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (_) => ChatPage(
              chatId: args['chatId'],
              receiverId: args['receiverId'],
            ),
          );
        }

        switch (settings.name) {
          case '/login':
            return MaterialPageRoute(builder: (_) => const AuthGate());
          case '/home':
            return MaterialPageRoute(builder: (_) => const HomePage());
          default:
            return MaterialPageRoute(
              builder: (_) => const Scaffold(
                body: Center(child: Text('Route not found')),
              ),
            );
        }
      },
    );
  }
}
=======
      home: AuthGate(),  
    );
  }
}
>>>>>>> b6204569c36ca6ddad69002b8753ca10b451a41f
