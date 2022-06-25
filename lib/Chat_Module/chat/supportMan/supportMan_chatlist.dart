import 'package:badges/badges.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:news_flutter/Chat_Module/chat/admin/admin_search.dart';
import 'package:news_flutter/Chat_Module/chat/supportMan/supportMan_search.dart';
import 'package:news_flutter/Chat_Module/utils.dart';
import 'package:news_flutter/Chat_Module/widgets/customToast.dart';
import 'package:news_flutter/Screens/DashboardScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:transition_pages_jr/transition_pages_jr.dart';
import '../../completeChat/model/user_model.dart';
import '../../completeChat/chat_room.dart';
import '../../completeChat/model/chat_room_model.dart';
import '../../services/firebase_helper.dart';
import '../chat_welcome_screen.dart';
import 'package:share_plus/share_plus.dart';

class SupportManChatList extends StatefulWidget {
  SupportManChatList({Key? key}) : super(key: key);

  @override
  State<SupportManChatList> createState() => _SupportManChatListState();
}

class _SupportManChatListState extends State<SupportManChatList>
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
        deviceToken: '',
        twitter: ''),
  ];
  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);

    super.initState();

    getPref();
    getDeviceToekn();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  bool loading = true;
  bool dialogOpen = false;

  String number = '';
  String userName = '';
  String userId = '';

  var deviceToken = '';
  getDeviceToekn() async {
    var userData = await FirebaseHelper.getSupportMAnModelById(userId);
    setState(() {
      deviceToken = userData['deviceToken'];
    });
  }

  getPref() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    setState(() {
      number = preferences.getString('number').toString();
      userName = preferences.getString('username').toString();
      userId = preferences.getString('uid').toString();
      print('userId: ${userId}');
    });

    FirebaseHelper.updateSupportManStatus(userId, 'online');
  }

  late MyUserModel dropdownUser;
  var selectedUser;
  String selectedChatRoomId = '';

  List participantKeys = [];
  var pUserId;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) return;
    final isBackground = state == AppLifecycleState.paused;

    if (isBackground) {
      print(
          'isBackground____________________________________________________: $isBackground');
      FirebaseHelper.updateSupportManStatus(userId, 'offline');
    } else {
      FirebaseHelper.updateUserStatus(userId, 'online');
    }
  }

  @override
  Widget build(BuildContext context) {
    print(userId.toString());
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
            "Support Man ${userName == null ? " " : userName}",
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
                        .where("participants.${userId}", isEqualTo: "support")
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

                              participantKeys.remove(userId);
                              print('uid: $userId');
                              print('participantKeys: $participantKeys');

                              // participantKeys = participants.keys.toList();
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

                              // Map<String, dynamic> participantKey =
                              //     chatRoomModel.participants!;
                              // participantKeys.forEach(
                              //   (element) {
                              //     print('element: $element');
                              //   },
                              // );

                              // print('participantKeys: $participantKeys');
                              // findUserIdFromList();
                              return FutureBuilder(
                                future: FirebaseHelper.getUserModelById(
                                    participantKeys[0]),
                                builder: (context, userData) {
                                  if (userData.connectionState ==
                                      ConnectionState.done) {
                                    if (userData.data != null) {
                                      var targetUser = userData.data as Map;
                                      return ListTile(
                                        // onLongPress: () {
                                        //   setState(() {
                                        //     selectedChatRoomId =
                                        //         chatRoomSnapshot.docs[index].id
                                        //             .toString();
                                        //     selectedUser = targetUser;
                                        //     dialogOpen = true;
                                        //   });
                                        // },
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
                                                    status:
                                                        targetUser['status'],
                                                    deviceToken: targetUser[
                                                        'deviceToken'],
                                                    bio: targetUser['bio']),
                                                userModel: MyUserModel(
                                                  uid: userId.toString(),
                                                  username: userName.toString(),
                                                  phone: number.toString(),
                                                  facebook: "",
                                                  linkedIn: '',
                                                  twitter: "",
                                                  dribble: "",
                                                  status: "",
                                                  bio: '',
                                                  deviceToken: deviceToken,
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
                                        trailing: chatRoomModel.idFrom != userId
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
                                        title: Text(
                                            targetUser['username'].toString()),
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
