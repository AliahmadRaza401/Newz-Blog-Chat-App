import 'package:badges/badges.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:feather_icons/feather_icons.dart';
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

class AdminChatList extends StatefulWidget {
  AdminChatList({Key? key}) : super(key: key);

  @override
  State<AdminChatList> createState() => _AdminChatListState();
}

class _AdminChatListState extends State<AdminChatList>
    with WidgetsBindingObserver {
  var uid = 'co718RpeRmKCM2fvjhXx';
  TextEditingController searchController = TextEditingController();
  List<MyUserModel> supportManList = [
    MyUserModel(
        uid: "",
        username: "Select Counselor",
        deviceToken: '',
        phone: "",
        status: 'online',
        bio: '',
        facebook: '',
        linkedIn: '',
        dribble: '',
        twitter: ''),
  ];
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getData();
    getDeviceToekn();
  }

  bool loading = true;
  bool dialogOpen = false;
  var myUserModel;

  var deviceToken = '';
  getDeviceToekn() async {
    var userData = await FirebaseHelper.getSupportMAnModelById(uid);
    setState(() {
      deviceToken = userData['deviceToken'];
    });
  }

  getData() async {
    var data = await FirebaseHelper.getSupportMan() as List<MyUserModel>;
    setState(() {
      supportManList = data;
      print('supportManList: $supportManList');
      if (supportManList.isNotEmpty) {
        dropdownUser = supportManList[0];
      }
      loading = false;
    });

    FirebaseHelper.updateAdminStatus(uid, 'online');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
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
      FirebaseHelper.updateSupportManStatus(uid, 'offline');
    } else {
      FirebaseHelper.updateSupportManStatus(uid, 'online');
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
          isEqualTo: "support",
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
          context, "Counselor Already Assign ", Colors.red);
    } else {
      print("ChatRoom Not Available");

      ChatRoomModel newChatRoom = ChatRoomModel(
        chatroomid: const Uuid().v1(),
        lastMessage: "",
        participants: {
          targetID.toString(): "support",
          userID.toString(): "user",
        },
      );

      await FirebaseFirestore.instance
          .collection('chatrooms')
          .doc(newChatRoom.chatroomid)
          .set(newChatRoom.toMap());
      chatRoom = newChatRoom;

      FCMServices.sendFCM(deviceToken, targetID.toString(), "New Refer",
          "You add a new chat as a Counselor");
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
            "Welcome Admin",
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
                        .where("participants.${'co718RpeRmKCM2fvjhXx'}",
                            isEqualTo: "admin")
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

                              participantKeys.remove('co718RpeRmKCM2fvjhXx');
                              print('uid: $uid');
                              print('participantKeys: $participantKeys');

                              return FutureBuilder(
                                future: FirebaseHelper.getUserModelById(
                                    participantKeys[0]),
                                builder: (context, userData) {
                                  if (userData.connectionState ==
                                      ConnectionState.done) {
                                    if (userData.data != null) {
                                      var targetUser = userData.data as Map;

                                      return ListTile(
                                        onLongPress: () {
                                          setState(() {
                                            selectedChatRoomId =
                                                chatRoomSnapshot.docs[index].id
                                                    .toString();
                                            selectedUser = targetUser;
                                            dialogOpen = true;
                                          });
                                        },
                                        onTap: () {
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
                                                    uid: 'co718RpeRmKCM2fvjhXx',
                                                    username: 'Admin',
                                                    phone: '+92',
                                                    facebook: "",
                                                    linkedIn: '',
                                                    twitter: "",
                                                    dribble: "",
                                                    status: "",
                                                    deviceToken: deviceToken,
                                                    bio: ''),
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
                                          targetUser['username'].toString(),
                                          style: TextStyle(
                                              fontWeight: FontWeight.w600),
                                        ),
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
              dialogOpen == false
                  ? SizedBox()
                  : Positioned(
                      bottom: 0,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          vertical: 50.h,
                          horizontal: 40.w,
                        ),
                        width: MediaQuery.of(context).size.width,
                        decoration: BoxDecoration(
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.5),
                                spreadRadius: 5,
                                blurRadius: 7,
                                offset:
                                    Offset(0, 3), // changes position of shadow
                              ),
                            ],
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(20.r),
                              topRight: Radius.circular(20.r),
                            )),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Assign Counselor",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17.sp,
                                )),
                            SizedBox(
                              height: 20.h,
                            ),
                            Text(
                                "Assign this ${selectedUser['username'].toString()} to Counselor \n to initiate a conversation",
                                style: TextStyle(
                                  fontSize: 14.sp,
                                )),
                            SizedBox(
                              height: 20.h,
                            ),
                            Text("* Counselor A assigned",
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontSize: 14.sp,
                                )),
                            SizedBox(
                              height: 20.h,
                            ),
                            loading
                                ? SizedBox()
                                : Container(
                                    alignment: Alignment.center,
                                    height: 47.h,
                                    width: 282.w,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 10.w,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(5.r),
                                      color: Color(0xffF5F5F5),
                                    ),
                                    child: DropdownButton<MyUserModel>(
                                      underline: SizedBox(),
                                      isExpanded: true,
                                      // Initial Value
                                      value: dropdownUser,

                                      // Down Arrow Icon
                                      icon:
                                          const Icon(Icons.keyboard_arrow_down),

                                      // Array list of items
                                      items: supportManList
                                          .map((MyUserModel items) {
                                        return DropdownMenuItem(
                                          value: items,
                                          child:
                                              Text(items.username.toString()),
                                        );
                                      }).toList(),

                                      onChanged: (newValue) {
                                        setState(() {
                                          dropdownUser = newValue!;
                                          print('dropdownUser: $dropdownUser');
                                        });
                                      },
                                    ),
                                  ),
                            SizedBox(
                              height: 20.h,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      dialogOpen = false;
                                      print('dialogOpen: $dialogOpen');
                                    });
                                  },
                                  child: Container(
                                    height: 47.h,
                                    width: 120.w,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(5.r),
                                      color: Color(0xffF5F5F5),
                                    ),
                                    child: Center(
                                      child: Text("Cancel"),
                                    ),
                                  ),
                                ),
                                InkWell(
                                  onTap: () {
                                    assignCounselor(
                                      context,
                                      dropdownUser.uid.toString(),
                                      selectedUser['uid'].toString(),
                                    );
                                  },
                                  child: Container(
                                    height: 47.h,
                                    width: 120.w,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(5.r),
                                      color: AppColors.darkBlueColor,
                                    ),
                                    child: Center(
                                      child: Text(
                                        "Confirm",
                                        style: TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ))
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
