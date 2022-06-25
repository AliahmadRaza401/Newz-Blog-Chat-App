import 'package:badges/badges.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:news_flutter/Chat_Module/chat/admin/admin_search.dart';
import 'package:news_flutter/Chat_Module/chat/supportMan/supportMan_search.dart';
import 'package:news_flutter/Chat_Module/services/fcm_services.dart';
import 'package:news_flutter/Chat_Module/utils.dart';
import 'package:news_flutter/Chat_Module/widgets/customToast.dart';
import 'package:news_flutter/Screens/DashboardScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:transition_pages_jr/transition_pages_jr.dart';
import 'package:uuid/uuid.dart';
import '../../completeChat/model/user_model.dart';
import '../../completeChat/chat_room.dart';
import '../../completeChat/model/chat_room_model.dart';
import '../../services/firebase_helper.dart';
import '../chat_welcome_screen.dart';

class UserChatList extends StatefulWidget {
  UserChatList({Key? key}) : super(key: key);

  @override
  State<UserChatList> createState() => _UserChatListState();
}

class _UserChatListState extends State<UserChatList>
    with WidgetsBindingObserver {
  // var uid = FirebaseAuth.instance.currentUser!.uid;
  TextEditingController searchController = TextEditingController();
  List<MyUserModel> supportManList = [
    MyUserModel(
        uid: "",
        username: "Select Counselor",
        phone: "",
        status: 'online',
        bio: '',
        facebook: '',
        linkedIn: '',
        dribble: '',
        twitter: '',
        deviceToken: ''),
  ];
  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    getPref();

    super.initState();
  }

  String number = '';
  String userName = '';
  String uid = '';
  getPref() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    setState(() {
      number = preferences.getString('number').toString();
      userName = preferences.getString('username').toString();
      uid = preferences.getString('uid').toString();
      print('getPref uid: ${uid}');
    });
    getData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  bool loading = true;
  bool dialogOpen = false;
  var currentUser, currentUsername;
  getData() async {
    print("Getting Data________________");
    currentUser = await FirebaseHelper.getUserModelById(uid);
    print('currentUser: $currentUser');

    FirebaseHelper.updateUserStatus(uid, 'online');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) return;
    final isBackground = state == AppLifecycleState.paused;

    if (isBackground) {
      print(
          'isBackground____________________________________________________: $isBackground');
      FirebaseHelper.updateUserStatus(uid, 'offline');
    } else {
      FirebaseHelper.updateUserStatus(uid, 'online');
    }
  }

  late MyUserModel dropdownUser;
  var selectedUser;
  String selectedChatRoomId = '';

  static ChatRoomModel? chatRoom;

  Future<ChatRoomModel?> assignCounselor(
      BuildContext context, targetID, userID) async {
    print('userID: $userID');
    print('targetID: $targetID');
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection("chatrooms")
        .where(
          "participants.${userID}",
          isEqualTo: "user",
        )
        .where(
          "participants.${targetID}",
          isEqualTo: "admin",
        )
        .get();

    if (snapshot.docs.length > 0) {
      print("ChatRoom Available");

      var docData = snapshot.docs[0].data();

      ChatRoomModel existingChatRoom =
          ChatRoomModel.fromMap(docData as Map<String, dynamic>);
      print("Exiting chat Room : ${existingChatRoom.chatroomid}");
      print("Exiting chat participants : ${existingChatRoom.participants}");
      chatRoom = existingChatRoom;

      ToastUtils.showCustomToast(
          context, "Counsoler Already Assign ", Colors.red);
    } else {
      print("ChatRoom Not Available");

      ChatRoomModel newChatRoom = ChatRoomModel(
        chatroomid: const Uuid().v1(),
        lastMessage: "",
        participants: {
          targetID.toString(): "admin",
          userID.toString(): "user",
        },
      );

      await FirebaseFirestore.instance
          .collection('chatrooms')
          .doc(newChatRoom.chatroomid)
          .set(newChatRoom.toMap());
      chatRoom = newChatRoom;

      FCMServices.sendFCM("user", targetID.toString(), "New Refer",
          "You add a new chat as a Counselor kindly proceed");
      ToastUtils.showCustomToast(
          context, "Counselor Assign Success", Colors.green);
    }
    setState(() {
      dialogOpen = false;
    });

    return chatRoom;
  }

  List participantKeys = [];
  var pUserId;

  @override
  Widget build(BuildContext context) {
    print(uid.toString());
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => DashboardScreen()),
            (Route<dynamic> route) => false);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(
            "Chats",
            style: GoogleFonts.rubik(fontSize: 18.sp, color: Colors.white),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  InkWell(
                    onTap: () {
                      RouteTransitions(
                        context: context,
                        child: SupportManSearch(),
                        animation: AnimationType.fadeIn,
                      );
                    },
                    child: const Icon(
                      FeatherIcons.search,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  SizedBox(
                    width: 20,
                  ),
                  IconButton(
                    onPressed: () async {
                      SharedPreferences preferences =
                          await SharedPreferences.getInstance();
                      preferences.setString("logStatus", "false");
                      RouteTransitions(
                        context: context,
                        child: const ChatWelcomeScreen(),
                        animation: AnimationType.fadeIn,
                      );
                    },
                    icon: Icon(
                      Icons.logout,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            )
          ],
          backgroundColor: AppColors.darkBlueColor,
        ),
        body: SafeArea(
          child: Container(
              child: Stack(
            children: [
              SingleChildScrollView(
                child: Container(
                  // color: Colors.amber,
                  height: MediaQuery.of(context).size.height * 0.9,
                  child: StreamBuilder(
                    stream: FirebaseFirestore.instance
                        .collection("chatrooms")
                        .where("participants.${uid}", isEqualTo: 'user')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.active) {
                        if (snapshot.hasData) {
                          QuerySnapshot chatRoomSnapshot =
                              snapshot.data as QuerySnapshot;

                          print(
                              ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>> ${chatRoomSnapshot.docs.length}");
                          return ListView.builder(
                            itemCount: chatRoomSnapshot.docs.length,
                            itemBuilder: (context, index) {
                              print('index: $index');
                              ChatRoomModel chatRoomModel =
                                  ChatRoomModel.fromMap(
                                      chatRoomSnapshot.docs[index].data()
                                          as Map<String, dynamic>);
                              print(chatRoomModel.chatroomid.toString());
                              Map<dynamic, dynamic> participants =
                                  chatRoomModel.participants!;
                              List<dynamic> participantKeys =
                                  participants.keys.toList();

                              participantKeys.remove(uid);
                              print('uid: $uid');
                              print('participantKeys: $participantKeys');

                              // List<RoomParicepentModel> Myparticipants = [];
                              // participants.entries.forEach((e) =>
                              //     Myparticipants.add(RoomParicepentModel(
                              //         id: e.key, name: e.value.toString())));
                              // print('Myparticipants: $Myparticipants');
                              // Myparticipants.forEach(
                              //   (e) {
                              //     print('e.name: ${e.name}');
                              //     if (e.name == "user") {
                              //       pUserId = e.id.toString();

                              //       print(
                              //           'id_________________________: $pUserId');
                              //     }
                              //   },
                              // );

                              return FutureBuilder(
                                future: FirebaseHelper.getFromAllDatabase(
                                    participantKeys[0]),
                                builder: (context, userData) {
                                  if (userData.connectionState ==
                                      ConnectionState.done) {
                                    if (userData.data != null) {
                                      var targetUser = userData.data as Map;

                                      return ListTile(
                                        onTap: () {
                                          print("oress");
                                          if (chatRoomModel != null) {
                                            RouteTransitions(
                                              context: context,
                                              child: ChatRoom(
                                                status: targetUser['status']
                                                    .toString(),
                                                targetUser: MyUserModel(
                                                  uid: targetUser['uid']
                                                      .toString(),
                                                  username:
                                                      targetUser['username']
                                                          .toString(),
                                                  phone: targetUser['phone']
                                                      .toString(),
                                                  facebook:
                                                      targetUser['facebook'],
                                                  linkedIn:
                                                      targetUser['linkedIn'],
                                                  twitter:
                                                      targetUser['twitter'],
                                                  dribble:
                                                      targetUser['dribble'],
                                                  status: targetUser['status'],
                                                  bio: targetUser['bio'],
                                                  deviceToken:
                                                      targetUser['deviceToken'],
                                                ),
                                                userModel: MyUserModel(
                                                  uid: currentUser["uid"],
                                                  username:
                                                      currentUser['username'],
                                                  phone: currentUser['phone'],
                                                  facebook:
                                                      currentUser['facebook'],
                                                  linkedIn:
                                                      currentUser['linkedIn'],
                                                  twitter:
                                                      currentUser['twitter'],
                                                  dribble:
                                                      currentUser['dribble'],
                                                  status: currentUser['status'],
                                                  bio: currentUser['bio'],
                                                  deviceToken: currentUser[
                                                      'deviceToken'],
                                                ),
                                                chatRoom: chatRoomModel,
                                              ),
                                              animation: AnimationType.fadeIn,
                                            );
                                          }
                                        },
                                        leading: Badge(
                                          shape: BadgeShape.circle,
                                          badgeColor:
                                              targetUser['status'].toString() ==
                                                      "online"
                                                  ? Colors.green
                                                  : Colors.grey,
                                          borderRadius:
                                              BorderRadius.circular(5),
                                          position: BadgePosition.bottomEnd(
                                            bottom: 0,
                                            end: 0,
                                          ),
                                          padding: const EdgeInsets.all(2),
                                          badgeContent: Container(
                                              width: 10.w,
                                              height: 10.h,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: targetUser['status']
                                                            .toString() ==
                                                        "online"
                                                    ? Colors.green
                                                    : Colors.grey,
                                              )),
                                          child: CircleAvatar(
                                            maxRadius: 30,
                                            backgroundImage: AssetImage(
                                                "Images/chat/userImage.jpeg"),
                                          ),
                                        ),
                                        title: Text(
                                            targetUser['username'].toString()),
                                        trailing: chatRoomModel.idFrom != uid
                                            ? chatRoomModel.read == false &&
                                                    chatRoomModel.count
                                                            .toString() !=
                                                        "0"
                                                ? Container(
                                                    width: 30.w,
                                                    height: 20.h,
                                                    decoration: BoxDecoration(
                                                        color: AppColors
                                                            .darkBlueColor,
                                                        shape: BoxShape.circle),
                                                    child: Center(
                                                        child: Text(
                                                      chatRoomModel.count
                                                          .toString(),
                                                      style: TextStyle(
                                                          color: white,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 8.sp),
                                                    )),
                                                  )
                                                : SizedBox()
                                            : SizedBox(),
                                        subtitle: (chatRoomModel.lastMessage
                                                    .toString() !=
                                                "")
                                            ? chatRoomModel.lastMessage
                                                        .toString() ==
                                                    "Image File"
                                                ? Row(
                                                    children: [
                                                      Icon(FeatherIcons.image,
                                                          size: 15.sp),
                                                      SizedBox(
                                                        width: 5.w,
                                                      ),
                                                      Text("Photo")
                                                    ],
                                                  )
                                                : chatRoomModel.lastMessage
                                                            .toString() ==
                                                        "audioFile"
                                                    ? Row(
                                                        children: [
                                                          Icon(
                                                            FeatherIcons.mic,
                                                            size: 15.sp,
                                                          ),
                                                          SizedBox(
                                                            width: 5.w,
                                                          ),
                                                          Text("Audio message")
                                                        ],
                                                      )
                                                    : Text(chatRoomModel
                                                        .lastMessage
                                                        .toString())
                                            : Text(
                                                "Say hi to your new friend!",
                                                style: TextStyle(
                                                  color:
                                                      AppColors.darkBlueColor,
                                                ),
                                              ),
                                      );
                                    } else {
                                      return Container(
                                        child: Center(
                                          child: Text(""),
                                        ),
                                      );
                                    }
                                  } else {
                                    return Container(
                                      child: Center(
                                        child: Text(""),
                                      ),
                                    );
                                  }
                                },
                              );
                            },
                          );
                        } else if (snapshot.hasError) {
                          return Center(
                            child: Text(snapshot.error.toString()),
                          );
                        } else {
                          return Center(
                            child: Text("No Chats"),
                          );
                        }
                      } else {
                        return Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                    },
                  ),
                ),
              ),

              // dialogOpen == false
              //     ? SizedBox()
              //     : Positioned(
              //         bottom: 0,
              //         child: Container(
              //           padding: EdgeInsets.symmetric(
              //             vertical: 50.h,
              //             horizontal: 40.w,
              //           ),
              //           width: MediaQuery.of(context).size.width,
              //           decoration: BoxDecoration(
              //               color: Colors.white,
              //               boxShadow: [
              //                 BoxShadow(
              //                   color: Colors.grey.withOpacity(0.5),
              //                   spreadRadius: 5,
              //                   blurRadius: 7,
              //                   offset:
              //                       Offset(0, 3), // changes position of shadow
              //                 ),
              //               ],
              //               borderRadius: BorderRadius.only(
              //                 topLeft: Radius.circular(20.r),
              //                 topRight: Radius.circular(20.r),
              //               )),
              //           child: Column(
              //             mainAxisAlignment: MainAxisAlignment.start,
              //             crossAxisAlignment: CrossAxisAlignment.start,
              //             children: [
              //               Text("Assign Counselor",
              //                   style: TextStyle(
              //                     fontWeight: FontWeight.bold,
              //                     fontSize: 17.sp,
              //                   )),
              //               SizedBox(
              //                 height: 20.h,
              //               ),
              //               Text(
              //                   "Assign this ${selectedUser['username'].toString()} to Counselor \n to initiate a conversation",
              //                   style: TextStyle(
              //                     fontSize: 14.sp,
              //                   )),
              //               SizedBox(
              //                 height: 20.h,
              //               ),
              //               Text("* Counselor A assigned",
              //                   style: TextStyle(
              //                     color: Colors.blue,
              //                     fontSize: 14.sp,
              //                   )),
              //               SizedBox(
              //                 height: 20.h,
              //               ),
              //               loading
              //                   ? SizedBox()
              //                   : Container(
              //                       alignment: Alignment.center,
              //                       height: 47.h,
              //                       width: 282.w,
              //                       padding: EdgeInsets.symmetric(
              //                         horizontal: 10.w,
              //                       ),
              //                       decoration: BoxDecoration(
              //                         borderRadius: BorderRadius.circular(5.r),
              //                         color: Color(0xffF5F5F5),
              //                       ),
              //                       child: DropdownButton<MyUserModel>(
              //                         underline: SizedBox(),
              //                         isExpanded: true,
              //                         // Initial Value
              //                         value: dropdownUser,

              //                         // Down Arrow Icon
              //                         icon:
              //                             const Icon(Icons.keyboard_arrow_down),

              //                         // Array list of items
              //                         items: supportManList
              //                             .map((MyUserModel items) {
              //                           return DropdownMenuItem(
              //                             value: items,
              //                             child:
              //                                 Text(items.username.toString()),
              //                           );
              //                         }).toList(),

              //                         onChanged: (newValue) {
              //                           setState(() {
              //                             dropdownUser = newValue!;
              //                             print('dropdownUser: $dropdownUser');
              //                           });
              //                         },
              //                       ),
              //                     ),
              //               SizedBox(
              //                 height: 20.h,
              //               ),
              //               Row(
              //                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //                 children: [
              //                   InkWell(
              //                     onTap: () {
              //                       setState(() {
              //                         dialogOpen = false;
              //                         print('dialogOpen: $dialogOpen');
              //                       });
              //                     },
              //                     child: Container(
              //                       height: 47.h,
              //                       width: 120.w,
              //                       decoration: BoxDecoration(
              //                         borderRadius: BorderRadius.circular(5.r),
              //                         color: Color(0xffF5F5F5),
              //                       ),
              //                       child: Center(
              //                         child: Text("Cancel"),
              //                       ),
              //                     ),
              //                   ),
              //                   InkWell(
              //                     onTap: () {
              //                       assignCounselor(
              //                         context,
              //                         dropdownUser.uid.toString(),
              //                         selectedUser['uid'].toString(),
              //                       );
              //                     },
              //                     child: Container(
              //                       height: 47.h,
              //                       width: 120.w,
              //                       decoration: BoxDecoration(
              //                         borderRadius: BorderRadius.circular(5.r),
              //                         color: AppColors.darkBlueColor,
              //                       ),
              //                       child: Center(
              //                         child: Text(
              //                           "Confirm",
              //                           style: TextStyle(
              //                             color: Colors.white,
              //                           ),
              //                         ),
              //                       ),
              //                     ),
              //                   ),
              //                 ],
              //               ),
              //             ],
              //           ),
              //         ))
            ],
          )),
        ),
      ),
    );
  }
}

class RoomParicepentModel {
  var id;
  var name;

  RoomParicepentModel({required this.id, required this.name});
}
