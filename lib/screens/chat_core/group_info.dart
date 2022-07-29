import 'package:circle/screens/chat_core/add_group_members.dart';
import 'package:circle/screens/chat_core/view_nested_rooms.dart';
import 'package:circle/utils/dynamiclink_helper.dart';
import 'package:circle/widgets/single_user_tile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_firebase_chat_core/flutter_firebase_chat_core.dart';
import 'package:get/get.dart';
import '../main_circle_modified.dart';
import 'package:flutter/services.dart';

class GroupInfoScreen extends StatefulWidget {
  final types.Room groupRoom;

  const GroupInfoScreen({Key? key, required this.groupRoom}) : super(key: key);

  @override
  State<GroupInfoScreen> createState() => _GroupInfoScreenState();
}

class _GroupInfoScreenState extends State<GroupInfoScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool loading = false;
  bool updatingData = false;
  late String circleLink;


  TextEditingController groupNameController = TextEditingController();

  @override
  initState() {
    groupNameController.text = widget.groupRoom.name!;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    print(widget.groupRoom.metadata);
    return FutureBuilder(
        future: _generateLink(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return  Scaffold(
                appBar: AppBar(
                  title: const Text("Circle Info"),
                  centerTitle: true,
                ),
              body: const Center(
                child: Text("Generating group link .."),
              ),
            );
          }

          return Scaffold(
              appBar: AppBar(
                title: const Text("Circle Info"),
                centerTitle: true,
              ),
              body: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    ClipRRect(
                        borderRadius: BorderRadius.circular(50),
                        child: Image.network(
                          widget.groupRoom.imageUrl ??
                              "https://media.istockphoto.com/vectors/user-avatar-profile-icon-black-vector-illustration-vector-id1209654046?k=20&m=1209654046&s=612x612&w=0&h=Atw7VdjWG8KgyST8AXXJdmBkzn0lvgqyWod9vTb2XoE=",
                          width: 100,
                          height: 100,
                        )),
                    const SizedBox(
                      height: 10,
                    ),
                    Form(
                      key: _formKey,
                      child: TextFormField(
                          controller: groupNameController,
                          validator: (String? value) {
                            if (value == null || value.trim().isEmpty) {
                              return "Circle name can't be empty";
                            }
                            return null;
                          },
                          decoration: const InputDecoration(
                            label: Text(
                              "Circle Name",
                              style: TextStyle(fontWeight: FontWeight.normal),
                            ),
                            isDense: true,
                            enabledBorder: OutlineInputBorder(),
                            focusedBorder: OutlineInputBorder(),
                          ),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 20)),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(5)),
                      child: Row(
                        children: [
                          Expanded(child: Text(circleLink)),
                          // InkWell(
                          //   onTap: () {
                          //     Clipboard.setData(
                          //         ClipboardData(text: widget.groupRoom.id));
                          //     Get.snackbar("Success", "Text Copied");
                          //   },
                          //   child: const Icon(Icons.copy),
                          // ),
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 05,
                    ),

                    ElevatedButton(
                        onPressed: () {
                          Clipboard.setData(
                              ClipboardData(text: circleLink));
                          Get.snackbar("Success", "Link Copied");
                        },
                        child: const Text("Copy Invite Link")),
                    const SizedBox(
                      height: 20,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ((widget.groupRoom.metadata!=null) && (widget.groupRoom.metadata!["isChildCircle"] ?? false) ) ?
                            SizedBox() :
                        ElevatedButton(
                            onPressed: () {
                              Get.off(
                                  AddMembersScreen(groupRoom: widget.groupRoom));
                            },
                            child: const Text("Add Members")),
                        ((widget.groupRoom.metadata!=null) && (widget.groupRoom.metadata!["isChildCircle"] ?? false) )?
                            SizedBox() :
                        ElevatedButton(
                            onPressed: () {
                              Get.off(ViewNestedRoom(user: FirebaseAuth.instance.currentUser!, parentRoom: widget.groupRoom));
                            },
                            child: const Text("View Inner Circles"))

                      ],
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Row(
                        children: [
                          Text(
                            "${widget.groupRoom.users.length} Participants",
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),

                    // Text(groupRoom.name!,style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),),
                    Expanded(
                        child: FutureBuilder(
                          future: allowedToSeeUsers(),
                          builder: (context,snapshot) {
                            if(snapshot.connectionState == ConnectionState.waiting){
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            if(snapshot.data==false){
                              return SizedBox();
                            }
                            return ListView.builder(
                                itemCount: widget.groupRoom.users.length,
                                itemBuilder: (context, index) {
                                  types.User user = widget.groupRoom.users[index];
                                  return SingleUserTile(
                                      user: user, groupRoom: widget.groupRoom);
                                });
                          }
                        )),
                  ],
                ),
              ),
              bottomNavigationBar: !updatingData
                  ? (loading
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          child: SizedBox(
                            height: 50,
                            child: Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32.0, vertical: 16),
                          child: ElevatedButton(
                            child: const Text("Save Info"),
                            onPressed: () async {
                              if (_formKey.currentState!.validate()) {
                                print("hello");
                                await _updateGroupName();
                                Get.offAll(
                                  const MainCircle(),
                                );
                              }
                            },
                          ),
                        ))
                  : null);
        });
  }

  Future<bool> allowedToSeeUsers() async{
    if((widget.groupRoom.metadata==null) || (widget.groupRoom.metadata!["isChildCircle"] ?? false) ){
      return true;
    }

    List childCircles = widget.groupRoom.metadata?["childCircles"] ?? [];

    for (int i=0; i<childCircles.length; i++){
      types.Room room = await FirebaseChatCore.instance.room(childCircles[i]).first;
      List roomUsersIds = room.users.map((types.User user) => user.id).toList();

      if (roomUsersIds.contains(FirebaseAuth.instance.currentUser!.uid)){
        return false;
      }
    }

    return true;
  }

  Future<void> _generateLink() async {
    if ((widget.groupRoom.metadata != null) &&
        (widget.groupRoom.metadata!['link'] != null)) {
      circleLink = widget.groupRoom.metadata!['link'];
      return;
    }

    circleLink = await DynamicLinkHelper.createDynamicLink(widget.groupRoom.id);

    Map metadata = widget.groupRoom.metadata ?? {};
    metadata["link"] = circleLink;

    FirebaseFirestore.instance
        .collection("rooms")
        .doc(widget.groupRoom.id)
        .update({'metadata': metadata});
  }

  Future<void> _updateGroupName() async {
    setState(() {
      loading = true;
    });

    await FirebaseFirestore.instance
        .collection("rooms")
        .doc(widget.groupRoom.id)
        .update({"name": groupNameController.text});

    setState(() {
      loading = false;
    });
  }
}
