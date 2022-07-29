import 'package:circle/screens/chat_core/enter_name_screen.dart';
import 'package:circle/screens/chat_core/rooms.dart';
import 'package:circle/screens/join_group_info.dart';
import 'package:circle/screens/login.dart';
import 'package:circle/screens/main_circle_modified.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';


void main() async{

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const App());

}

class App extends StatefulWidget {
  const App({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return AppState();
  }
}

class AppState extends State<App> {

  @override
  initState(){

    // FirebaseDynamicLinks.instance.onLink.listen((dynamicLinkData) {
    //   print("into listener");
    //   Get.to(const RoomsPage());
    //   // print(UriData.fromUri(dynamicLinkData.link));
    //   Get.snackbar("Success", "link: ${dynamicLinkData.link}");
    //   print(dynamicLinkData.link);
    // }).onError((error) {
    //   // Handle errors
    // });

    fetchLinkData();
    super.initState();
    // fetchLinkData();
  }

  void fetchLinkData() async {
    // FirebaseDynamicLinks.getInitialLInk does a call to firebase to get us the real link because we have shortened it.
    var link = await FirebaseDynamicLinks.instance.getInitialLink();

    // This link may exist if the app was opened fresh so we'll want to handle it the same way onLink will.
        if(link!=null){
      handleLinkData(link);
    }

    // This will handle incoming links if the application is already opened
    FirebaseDynamicLinks.instance.onLink.listen( (PendingDynamicLinkData dynamicLink) async {
      print("into listener");
      handleLinkData(dynamicLink);
    });
  }

  void handleLinkData(PendingDynamicLinkData data) {
    print("into handler");
    final Uri? uri = data.link;
    if(uri != null) {
      final queryParams = uri.queryParameters;
      if(queryParams.isNotEmpty) {
        String? id = queryParams["id"];
        // verify the username is parsed correctly
        print("My circle id is: $id");
        if (FirebaseAuth.instance.currentUser!=null){
          Get.to(JoinGroupInfo(
            groupId: id ?? "",
          ));
        }
        else {
          Get.to(EnterNameScreen(
            groupId: id ?? "",
          ));
        }
      }
      else{
        print("query  parameters empty");
      }
    }
    else{
      print("uri null");
    }
  }

  // void login() {}

  // Future<FirebaseApp> _initFireBase() async {
  //   WidgetsFlutterBinding.ensureInitialized();
  //   FirebaseApp firebaseApp = await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  //   return firebaseApp;
  // }

  final TextEditingController editingController = TextEditingController();
  final TextEditingController editingController1 = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
      ),
      title: 'Circle',
      home:
          (FirebaseAuth.instance.currentUser!=null) ?
      const MainCircle() : const LoginPage()
      // Center(
      //   child: Scaffold(
      //     appBar: AppBar(
      //       title: const Text('Circle'),
      //     ),
      //     body: LoginPage()
      //     // FutureBuilder(
      //     //   future: _initFireBase(),
      //     //   builder: (context, snapshot) {
      //     //     if (snapshot.connectionState == ConnectionState.done) {
      //     //       return Column(
      //     //         children: const [
      //     //           Text('Login'),
      //     //           LoginPage(),
      //     //         ],
      //     //       );
      //     //     }
      //     //     return const Center(
      //     //       child: CircularProgressIndicator(),
      //     //     );
      //     //   },
      //     // )
      //
      //   ),
      // ),
    );
  }
}
