
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:trying/StoreRickkshawData/PriceStore.dart';
import 'package:unique_list/unique_list.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';



const apikey =
    'Ao9YZbzlJCZReZzkhJqlxzVPQ8y1Y5P4zvrwjFpi9qtiUlUMuEXOfSdjoK3BC_op';

List<String> listitems = UniqueList();

class autocomp extends StatefulWidget {
  @override
  State<autocomp> createState() => _autocompState();
}

class _autocompState extends State<autocomp> {
  double latitude = 0;
  double longitude = 0;
  final actualprice = TextEditingController();
  late TextEditingController endtextEditingController;
  late TextEditingController starttextEditingController;
  final FirebaseAuth _auth=FirebaseAuth.instance;
  final firrstore=FirebaseFirestore.instance;
  var newdata = '0';
  var traffictimeinsecond;
  double trafficprice = 0;
  late String dest1;
  late String dest2;
  var checkForCircular=false;
  Color backgroundColor=Colors.white;
  Color TextColor=Colors.blue;
  var textofbutton="off";

  var nightpricecheck=false;

  String currentlocation = "Your Location:-";
  late String org;
  Future getCurrentLocation(lat, long) async {
    http.Response rs = await http.get(Uri.parse(
        'https://dev.virtualearth.net/REST/v1/Locations/${lat},${long}?&key=${apikey}'));
    if (rs.statusCode == 200) {
      String data = rs.body;
      var decodeadata = jsonDecode(data)['resourceSets'][0]['resources'][0]
          ['address']['formattedAddress'];
      return decodeadata;
    } else {
      Fluttertoast.showToast(
          msg: "unable to get your location",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          textColor: Colors.white,
          backgroundColor: Colors.blue[400],
          fontSize: 16.0);
    }
  }

  void loc() async {
    var a = await getCurrentLocation(latitude, longitude);
    setState(() {
      currentlocation = a;
    });
  }

  Future getdata(source, dest) async {
    http.Response rs = await http.get(Uri.parse(
        'http://dev.virtualearth.net/REST/V1/Routes?wp.0=${source},WA&wp.1=${dest},WA&optmz=timeWithTraffic&distanceUnit=km&key=${apikey}'));
    if (rs.statusCode == 200) {
      String data = rs.body;
      setState(() {
        traffictimeinsecond = (jsonDecode(data)['resourceSets'][0]['resources']
                    [0]['travelDuration'] -
                jsonDecode(data)['resourceSets'][0]['resources'][0]
                    ['travelDurationTraffic'])
            .abs();
      });
      var decodedata =
          jsonDecode(data)['resourceSets'][0]['resources'][0]['travelDistance'];
      return decodedata;
    } else {
      Fluttertoast.showToast(
          msg: "Unable to get fare",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          textColor: Colors.white,
          backgroundColor: Colors.blue[400],
          fontSize: 16.0);
    }
  }

  void updateUi(place1, place2) async {
    var data = await getdata(place1, place2);
    setState(() {
      if(nightpricecheck==true){
        if (data <= 1.5) {
          newdata = (29).toString();
        } else {
          var nwdata = (29 + ((data - 1.5) * 15.33)*1.25);
          double dt = double.parse(nwdata.toStringAsFixed(2));
          newdata = dt.toString();
        }
        if (traffictimeinsecond >= 60) {
          setState(() {
            double n = (traffictimeinsecond / 60) * 1.42;
            trafficprice = double.parse(n.toStringAsFixed(1));
          });
        }

      }else{
        if (data <= 1.5) {
          newdata = (23).toString();
        } else {
          var nwdata = (23 + (data - 1.5) * 15.33);
          double dt = double.parse(nwdata.toStringAsFixed(2));
          newdata = dt.toString();
        }
        if (traffictimeinsecond >= 60) {
          setState(() {
            double n = (traffictimeinsecond / 60) * 1.42;
            trafficprice = double.parse(n.toStringAsFixed(1));
          });
        }
      }

    });
  }

  Future getPermission() async {
    PermissionStatus preciselocation = await Permission.location.request();
    if (preciselocation == PermissionStatus.denied) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('This permission is needed for app to work')));
    } else if (preciselocation == PermissionStatus.permanentlyDenied) {
      openAppSettings();
    } else if (preciselocation == PermissionStatus.granted) {
      return;
    }
  }

  void networkcheck(des1, des2) async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.mobile ||
        connectivityResult == ConnectivityResult.wifi) {
      updateUi(des1, des2);
    } else {
      Fluttertoast.showToast(
          msg: "check your network",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          textColor: Colors.white,
          backgroundColor: Colors.blue[400],
          fontSize: 16.0);
    }
  }
  void networkcheckForSignIn() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.mobile ||
        connectivityResult == ConnectivityResult.wifi) {
      signInwithGooogle();
    } else {
      Fluttertoast.showToast(
          msg: "check your network",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          textColor: Colors.white,
          backgroundColor: Colors.blue[400],
          fontSize: 16.0);
    }
  }

  void networkcheckforcurrent() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.mobile ||
        connectivityResult == ConnectivityResult.wifi) {
      loc();
    } else {
      Fluttertoast.showToast(
          msg: "check your network",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          textColor: Colors.white,
          backgroundColor: Colors.blue[400],
          fontSize: 16.0);
    }
  }

  Future autocompUrl(t) async {
    http.Response rs = await http.get(Uri.parse(
        'http://dev.virtualearth.net/REST/v1/Autosuggest?query=${t}&userLocation=${latitude},${longitude},8&userCircularMapView=${latitude},${longitude},2000&includeEntityTypes=Address,Place&countryFilter=in&key=${apikey}'));
    if (rs.statusCode == 200) {
      String data = rs.body;
      var loopin = jsonDecode(data)['resourceSets'][0]['resources'][0]['value'];
      for (var loc in loopin) {
        var data1 = loc['address']['formattedAddress'];
        setState(() {
          listitems.add(data1.toString());
        });
      }
    } else {
      Fluttertoast.showToast(
          msg: "unable to get place maybe your network is off ",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          textColor: Colors.white,
          backgroundColor: Colors.blue[400],
          fontSize: 16.0);
    }
    http.Response rs1 = await http.get(Uri.parse(
        'http://dev.virtualearth.net/REST/v1/Autosuggest?query=${t}&userLocation=${latitude},${longitude},5&userCircularMapView=${latitude},${longitude},2000&includeEntityTypes=Business&countryFilter=in&key=${apikey}'));
    if (rs1.statusCode == 200) {
      String datab = rs1.body;
      var loopin1 =
          jsonDecode(datab)['resourceSets'][0]['resources'][0]['value'];
      for (var loc1 in loopin1) {
        var data2 = loc1['address']['formattedAddress'];
        var data3 = loc1['name'];
        var C = data3 + "(" + data2 + ")";
        setState(() {
          listitems.add(C.toString());
        });
      }
    }
  }

  Future<void> getLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        longitude = position.longitude;
        latitude = position.latitude;
      });
    } catch (e) {
      Fluttertoast.showToast(
          msg: "unable to get your location ",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          textColor: Colors.white,
          backgroundColor: Colors.blue[400],
          fontSize: 16.0);
    }
  }

  @override
  void initState() {
    getPermission();
    getLocation();
    currentUser();
    // myBanner.load();
    super.initState();
  }
  // final GoogleSignIn _googleSignIn=GoogleSignIn();
  // _googleSignIn.signIn().then((value){
  // String? username=value!.displayName;
  // String email=value!.email;
  // String? profilePicture=value!.photoUrl;
  //
  // });

  signInwithGooogle()async{
    GoogleSignInAccount? googleUser=await GoogleSignIn().signIn();
    GoogleSignInAuthentication? googleAuth=await googleUser?.authentication;
    AuthCredential credential=GoogleAuthProvider.credential(
      accessToken: googleAuth?.accessToken,
      idToken:googleAuth?.idToken ,
    );
    UserCredential userCredential=await FirebaseAuth.instance.signInWithCredential(credential);
    print(userCredential.user?.email);
    if(userCredential.user !=null){
      currentUser();
      Navigator.push(context,MaterialPageRoute(builder: (context){
        return PriceStore(currentuser: currentuser,);
      }));
    }
    else{
      print("1");
    }
  }
  String currentuser="a";
  bool checkcurrentuser=false;

  void currentUser() async {
    try {
      final user = await _auth.currentUser;
      if (user != null) {
        setState(() {
          currentuser = user.email!;
          checkcurrentuser=true;
        });
      }
    } catch (e) {
      print(e);
    }
  }

  // final BannerAd myBanner = BannerAd(
  //   adUnitId: 'ca-app-pub-3940256099942544/6300978111',
  //   size: AdSize.banner,
  //   request: AdRequest(),
  //   listener: BannerAdListener(),
  // );
  addData(current,dest,price,actualprice)async{
    if(currentuser=="a"){
      Fluttertoast.showToast(
          msg: "Login First",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.blue,
          textColor: Colors.white,
          fontSize: 16.0
      );
    }else{

      String cdate = DateFormat("dd-MM-yyyy").format(DateTime.now());
      print(cdate);

      var userDocRef =  firrstore.collection('UserData').doc(currentuser);
      var document = await userDocRef.get();
      if(!document.exists){
        final json={
          "totalprice": actualprice,
          "data": [{
            "currentPlace":current,
            "destination":dest,
            "price":price,
            "actualprice":actualprice,
            "date":cdate,
          }],
        };
        await userDocRef.set(json);
      }else{
        var docrefforchek =
        await firrstore.collection("UserData").doc(currentuser).get();
        Map<String, dynamic>? data = docrefforchek.data();
        var val = data!['data'];
        var totalprice = data!["totalprice"];
        var newprice =
        (double.parse(totalprice) + double.parse(actualprice)).toString();
        val.add({
          "currentPlace":current,
          "destination":dest,
          "price":price,
          "actualprice":actualprice,
          "date":cdate,
        });
        userDocRef.update({
          "totalprice": newprice,
          "data": val
        });

      }
    }
    // var document=firrstore.collection('UserData').doc(widget.currentuser);
    // final json={
    //   "currentPlace":current,
    //   "destination":dest,
    //   "price":price,
    //   "actualprice":actualprice,
    // };
    // await document.set(json);


  }
  void networkcheckforAddData(current,dest,price,actualprice) async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.mobile ||
        connectivityResult == ConnectivityResult.wifi) {
      addData(current, dest, price, actualprice);
      setState(() {
        newdata="0";
        trafficprice=0.0;
        starttextEditingController.text="";
        endtextEditingController.text="";
      });
      Navigator.pop(context);
      Navigator.push(context, MaterialPageRoute(builder: (context){
        return PriceStore(currentuser: currentuser);
      }));
    } else {
      Fluttertoast.showToast(
          msg: "check your network",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          textColor: Colors.white,
          backgroundColor: Colors.blue[400],
          fontSize: 16.0);
    }
  }
  Future openDialog()=>showDialog(context: context, builder: (context)=>AlertDialog(
    title: Text("Actual Price"),
    content: TextField(decoration: InputDecoration(hintText: "ENTER ACTUAL PRICE"),controller: actualprice,onChanged: (v){setState(() {
      actualprice.text=v;
    });},),
    actions: [ElevatedButton(onPressed: (){
      if(actualprice=="0"){
        Fluttertoast.showToast(
            msg: "No route selected",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.blue,
            textColor: Colors.white,
            fontSize: 16.0
        );
      }else{
        networkcheckforAddData(dest1, dest2, newdata, actualprice.text);
      }
    }, child: Text("Save")),],
  ),
  );


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Rickkshaw'),
            checkcurrentuser?Text(currentuser,style: TextStyle(fontSize: 10),):
            ElevatedButton(onPressed: (){
networkcheckForSignIn();
            },style: ElevatedButton.styleFrom(
              foregroundColor: Colors.blue, // change text color of button
              backgroundColor: Colors.white, // change background color of button
            )
              ,child: Text("Login"),

            )
          ],
        ),
      ),
      body: checkForCircular?CircularProgressIndicator():Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding:
                EdgeInsets.only(top: 24.0, bottom: 8.0, right: 8.0, left: 8.0),
            child: Autocomplete(
              optionsBuilder: (TextEditingValue texteditvalue) {
                if (texteditvalue.text == "") {
                  setState(() {
                    dest1 = "";
                  });
                  return const Iterable<String>.empty();
                }
                autocompUrl(texteditvalue.text);
                listitems.insert(0, "Your Location:- ${currentlocation}");
                if (currentlocation == "Your Location:-" ||
                    listitems[0] == "Your Location:- Your Location:-") {
                  listitems.removeAt(0);
                }
                return listitems.where((String item) {
                  return item
                      .toLowerCase()
                      .contains(texteditvalue.text.toLowerCase());
                });
              },
              onSelected: (String item) {
                if (item.contains("(")) {
                  dest1 = item.split("(")[1].toString();
                } else if (item.contains("-")) {
                  dest1 = item.substring(15, item.length);
                } else {
                  dest1 = item;
                }
              },
              fieldViewBuilder:
                  (context, controller, focusNode, onEditingComplete) {
                starttextEditingController=controller;
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  onEditingComplete: onEditingComplete,
                  decoration: InputDecoration(
                    hintText: 'Enter your start loaction',
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(32.0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide:
                          BorderSide(color: Colors.lightBlueAccent, width: 1.0),
                      borderRadius: BorderRadius.all(Radius.circular(32.0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide:
                          BorderSide(color: Colors.lightBlueAccent, width: 2.0),
                      borderRadius: BorderRadius.all(Radius.circular(32.0)),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Autocomplete(
              optionsBuilder: (TextEditingValue texteditvalue) {
                if (texteditvalue.text == "") {
                  return const Iterable<String>.empty();
                }
                autocompUrl(texteditvalue.text);
                return listitems.where((String item) {
                  return item
                      .toLowerCase()
                      .contains(texteditvalue.text.toLowerCase());
                });
              },
              onSelected: (String item) {
                if (item.contains("(")) {
                  dest2 = item.split("(")[1].toString();
                } else {
                  dest2 = item;
                }
              },
              fieldViewBuilder:
                  (context, controller, focusNode, onEditingComplete) {
                endtextEditingController=controller;
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  onEditingComplete: onEditingComplete,
                  decoration: InputDecoration(
                    hintText: 'Enter your destination loaction',
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(32.0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide:
                          BorderSide(color: Colors.lightBlueAccent, width: 1.0),
                      borderRadius: BorderRadius.all(Radius.circular(32.0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide:
                          BorderSide(color: Colors.lightBlueAccent, width: 2.0),
                      borderRadius: BorderRadius.all(Radius.circular(32.0)),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
                onPressed: () {
                  getPermission();
                  networkcheck(dest1, dest2);

                },
                child: Text('CALCUALTE')),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(child: GestureDetector(
                onTap: (){
    setState(() {
    newdata="0";
    trafficprice=0.0;
    starttextEditingController.text="";
    endtextEditingController.text="";
    });
    },
                child: Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.blue),
                    borderRadius: BorderRadius.all(Radius.circular(30)),
                  ),
                  child: Text("Reset",style: TextStyle(color: Colors.blue),),
                ),
              )),
              SizedBox(width: 10,),
              Flexible(flex: 2,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      if(backgroundColor==Colors.blue){
                        backgroundColor=Colors.white;
                        textofbutton="off";
                        TextColor=Colors.blue;
                        nightpricecheck=false;
                      }else{
                        backgroundColor=Colors.blue;
                        textofbutton="on";
                        TextColor=Colors.white;
                        nightpricecheck=true;
                      }
                    });
                  },
                  child: Container(
                    height: 50.0,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.blue,
                          style: BorderStyle.solid,
                          width: 1.0,
                        ),
                        color:backgroundColor,
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Center(
                            child: Text(
                              "Night price"+" "+textofbutton,
                              style: TextStyle(
                                color: TextColor,
                                fontFamily: 'Montserrat',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1,
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ),
             SizedBox(width: 10,),
             Flexible(child: GestureDetector(
               onTap: (){
                 if(currentuser=="a"){
                   Fluttertoast.showToast(
                       msg: "Login First",
                       toastLength: Toast.LENGTH_SHORT,
                       gravity: ToastGravity.CENTER,
                       timeInSecForIosWeb: 1,
                       backgroundColor: Colors.blue,
                       textColor: Colors.white,
                       fontSize: 16.0
                   );
                 }else{
                   setState(() {
                     checkForCircular=true;
                   });
                   setState(() {
                     checkForCircular=false;
                   });
                   Navigator.push(context,MaterialPageRoute(builder: (context){
                     return PriceStore(currentuser: currentuser,);
                   }));
                 }
               },
               child: Container(
                 padding: EdgeInsets.all(10),
                 decoration: BoxDecoration(
                   border: Border.all(color: Colors.blue),
                   borderRadius: BorderRadius.all(Radius.circular(30)),
                 ),
                   child: Text("Rides",style: TextStyle(color: Colors.blue),),
                ),
             ))
            ],
          ),
          SizedBox(height: 10,),
          Flexible(child: GestureDetector(
            onTap: (){
              if(currentuser=="a"){
                Fluttertoast.showToast(
                    msg: "Login First",
                    toastLength: Toast.LENGTH_SHORT,
                    gravity: ToastGravity.CENTER,
                    timeInSecForIosWeb: 1,
                    backgroundColor: Colors.blue,
                    textColor: Colors.white,
                    fontSize: 16.0
                );
              }else{
                if(starttextEditingController.text==""||endtextEditingController.text==""||newdata=="0"){
                  Fluttertoast.showToast(
                      msg: "No route selected",
                      toastLength: Toast.LENGTH_SHORT,
                      gravity: ToastGravity.CENTER,
                      timeInSecForIosWeb: 1,
                      backgroundColor: Colors.blue,
                      textColor: Colors.white,
                      fontSize: 16.0
                  );

                }else{
                  setState(() {
                    actualprice.text=newdata;
                  });
                     openDialog();

                }

              }
            },
            child: Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue),
                borderRadius: BorderRadius.all(Radius.circular(30)),
              ),
              child: Center(child: Text("Save",style: TextStyle(color: Colors.blue),)),
            ),
          )),
          Flexible(
            flex: 2,
            child: Center(
              child: Text(
                "Rs." + newdata,
                style: TextStyle(fontSize: 50.0, fontWeight: FontWeight.bold),
              ),
            ),
          ),











           BannerAdmob(),
          Center(
              child: Column(
            children: [
              Text(
                'This price might increase by',
                style: TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              Text(
                'Rs. ${trafficprice}',
                style:
                    TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
              Text(
                'due to traffic',
                style: TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          )),
          GestureDetector(
            onTap: () {
              networkcheckforcurrent();
              listitems.remove("Your Location:-");
            },
            child: Container(
              margin: EdgeInsets.all(10),
              child: Text(
                "Press to get current location",
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              height: 80.0,
              width: double.infinity,
              color: Colors.blue[400],
            ),
          ),
          Center(
              child: Container(
                  margin: EdgeInsets.only(bottom: 10),
                  child: Text(
                    "Search 'your location' to get current location",
                    style: TextStyle(color: Colors.grey),
                  ))),
        ],
      ),
    );
  }
}
class BannerAdmob extends StatefulWidget{
  @override
  State<StatefulWidget> createState() {
    return _BannerAdmobState();
  }
}

class _BannerAdmobState extends State<BannerAdmob>{

  late BannerAd _bannerAd;
  bool _bannerReady = false;

  @override
  void initState() {
    super.initState();
    _bannerAd = BannerAd(
      adUnitId: "ca-app-pub-7858624809477674/7528659128",
      request: const AdRequest(),
      size: AdSize.largeBanner,
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() {
            _bannerReady = true;
          });
        },
        onAdFailedToLoad: (ad, err) {
          setState(() {
            _bannerReady = false;
          });
          ad.dispose();
        },
      ),
    );
    _bannerAd.load();
  }

  @override
  void dispose() {
    super.dispose();
    _bannerAd.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _bannerReady?SizedBox(
      width: _bannerAd.size.width.toDouble(),
      height: _bannerAd.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd),
    ):Container();
  }
}
