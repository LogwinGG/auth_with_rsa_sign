import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_provider.dart';
import 'home_screen.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  Future<String?>? _pendingAuth;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: SingleChildScrollView(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: FutureBuilder(
                future: _pendingAuth,
                builder: (context, snapshot) {
                  final isErrored = snapshot.hasError && snapshot.connectionState != ConnectionState.waiting;

                  if(snapshot.hasData) {
                    var udid =  snapshot.data;
                    if(udid!= null && udid != '') {
                      Future(() {Navigator.push(context, MaterialPageRoute(builder: (context) => HomeScreen(udid: udid)));});
                    }
                  }
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height / 2.5,
                      ),
                      CupertinoButton.filled(
                          padding: EdgeInsets.zero,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.apple, size: 25,),
                              SizedBox(width: 2,),
                              Text('Sign in with Apple', style: TextStyle(fontSize: 19),)
                            ],
                          ),
                          onPressed: () {
                            setState(() {
                              _pendingAuth = ref.read(authProvider.notifier).authWithApple();
                            });
                          }
                      ),
                      if (snapshot.connectionState == ConnectionState.waiting) ...[
                        const SizedBox(height: 10),
                        const CircularProgressIndicator(),
                      ],

                      if(isErrored) showAlertError(context: context)
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  showAlertError({String? text, required context}) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Не удалось войти с помощью apple id'),
        content:
            Text(text ?? 'В настоящее время невозможно создать учетную запись'),
        actions: [
          CupertinoDialogAction(
            child: const Text('ОК'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
        ],
      ),
    );
  }
}
