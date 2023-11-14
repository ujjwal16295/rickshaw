import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:unique_list/unique_list.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

const apikey =
    'Ao9YZbzlJCZReZzkhJqlxzVPQ8y1Y5P4zvrwjFpi9qtiUlUMuEXOfSdjoK3BC_op';

List<String> listitems = UniqueList();

class PriceStore extends StatefulWidget {
  String currentuser;
  PriceStore({required this.currentuser});

  @override
  State<PriceStore> createState() => _PriceStoreState();
}

class _PriceStoreState extends State<PriceStore> {
  double latitude = 0;
  double longitude = 0;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late TextEditingController endtextEditingController;
  late TextEditingController starttextEditingController;
  final firrstore = FirebaseFirestore.instance;

  var pricebyuser = TextEditingController();

  var newdata = '0';
  var traffictimeinsecond;
  double trafficprice = 0;
  late String dest1;
  late String dest2;
  Color backgroundColor = Colors.white;
  Color TextColor = Colors.blue;
  Color backgroundcolorofpricecontainer = Colors.white;
  Color textcolorofpricecontainer = Colors.blue;
  var textofbutton = "off";

  var nightpricecheck = false;

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
      if (nightpricecheck == true) {
        if (data <= 1.5) {
          newdata = (29).toString();
        } else {
          var nwdata = (29 + ((data - 1.5) * 15.33) * 1.25);
          double dt = double.parse(nwdata.toStringAsFixed(2));
          newdata = dt.toString();
        }
        if (traffictimeinsecond >= 60) {
          setState(() {
            double n = (traffictimeinsecond / 60) * 1.42;
            trafficprice = double.parse(n.toStringAsFixed(1));
          });
        }
      } else {
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
    setState(() {
      pricebyuser.text = newdata;
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
    checkifuserdataexists();
    // myBanner.load();
    super.initState();
  }

  var checkforuserdataexists = false;
  checkifuserdataexists() async {
    var userDocRef = firrstore.collection('UserData').doc(widget.currentuser);
    var document = await userDocRef.get();
    if (!document.exists) {
      setState(() {
        checkforuserdataexists = false;
      });
    } else {
      setState(() {
        checkforuserdataexists = true;
      });
    }
    gettotalprice();
  }

  addData(current, dest, price, actualprice) async {
    // var document=firrstore.collection('UserData').doc(widget.currentuser);
    // final json={
    //   "currentPlace":current,
    //   "destination":dest,
    //   "price":price,
    //   "actualprice":actualprice,
    // };
    // await document.set(json);
    String cdate = DateFormat("dd-MM-yyyy").format(DateTime.now());
    print(cdate);

    var userDocRef = firrstore.collection('UserData').doc(widget.currentuser);
    var document = await userDocRef.get();
    if (!document.exists) {
      final json = {
        "totalprice": actualprice,
        "data": [
          {
            "currentPlace": current,
            "destination": dest,
            "price": price,
            "actualprice": actualprice,
            "date": cdate,
          }
        ],
      };
      await userDocRef.set(json);
    } else {
      var docrefforchek =
          await firrstore.collection("UserData").doc(widget.currentuser).get();
      Map<String, dynamic>? data = docrefforchek.data();
      var val = data!['data'];
      var totalprice = data!["totalprice"];
      var newprice =
          (double.parse(totalprice) + double.parse(actualprice)).toString();
      val.add({
        "currentPlace": current,
        "destination": dest,
        "price": price,
        "actualprice": actualprice,
        "date": cdate,
      });
      userDocRef.update({"totalprice": newprice, "data": val});
    }
    gettotalprice();
  }

  void networkcheckforAddData(current, dest, price, actualprice) async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.mobile ||
        connectivityResult == ConnectivityResult.wifi) {
      addData(current, dest, price, actualprice);
      setState(() {
        newdata = "0";
        pricebyuser.text = "";
        endtextEditingController.text = "";
        starttextEditingController.text = "";
      });
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

  var totalpricee = "0.0";
  void gettotalprice() async {
    var userDocRef = firrstore.collection('UserData').doc(widget.currentuser);
    var document = await userDocRef.get();
    if (!document.exists) {
      print("fuck");
      setState(() {
        totalpricee = "0.0";
      });
    } else {
      print("yoyoyo idhar dekh le");
      var docrefforchek =
          await firrstore.collection("UserData").doc(widget.currentuser).get();
      Map<String, dynamic>? data = docrefforchek.data();
      var totalprice = data!["totalprice"];

      setState(() {
        totalpricee = totalprice.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (checkforuserdataexists == false) {
      checkifuserdataexists();
    }
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Rickkshaw"),
            Text(
              widget.currentuser,
              style: TextStyle(fontSize: 5),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          SizedBox(height: 5,),
          Container(
            padding: EdgeInsets.all(10),
            child: Text("Total Amount:-" + " " + double.parse(totalpricee).toStringAsFixed(2),style: TextStyle(fontWeight: FontWeight.bold,color: Colors.white),),
            decoration: BoxDecoration(
              color: Colors.blue,
                border: Border.all(color: Colors.blue),
                borderRadius: BorderRadius.all(Radius.circular(30))),
          ),
          Container(
            margin: EdgeInsets.all(10),
            decoration: BoxDecoration(
                border: Border.all(color: Colors.blue),
                borderRadius: BorderRadius.all(Radius.circular(10))),
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.only(
                      top: 24.0, bottom: 8.0, right: 8.0, left: 8.0),
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
                      starttextEditingController = controller;
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        onEditingComplete: onEditingComplete,
                        decoration: InputDecoration(
                          hintText: 'Enter your start loaction',
                          contentPadding: EdgeInsets.symmetric(
                              vertical: 10.0, horizontal: 20.0),
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(32.0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Colors.lightBlueAccent, width: 1.0),
                            borderRadius:
                                BorderRadius.all(Radius.circular(32.0)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Colors.lightBlueAccent, width: 2.0),
                            borderRadius:
                                BorderRadius.all(Radius.circular(32.0)),
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
                      endtextEditingController = controller;
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        onEditingComplete: onEditingComplete,
                        decoration: InputDecoration(
                          hintText: 'Enter your destination loaction',
                          contentPadding: EdgeInsets.symmetric(
                              vertical: 10.0, horizontal: 20.0),
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(32.0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Colors.lightBlueAccent, width: 1.0),
                            borderRadius:
                                BorderRadius.all(Radius.circular(32.0)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Colors.lightBlueAccent, width: 2.0),
                            borderRadius:
                                BorderRadius.all(Radius.circular(32.0)),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(
                  height: 10,
                ),
                Container(
                  margin: EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text("Estimated price:"),
                      SizedBox(
                        width: 10,
                      ),
                      Text(
                        "Rs." + newdata,
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text("Actual Price:"),
                      SizedBox(
                        width: 10,
                      ),
                      SizedBox(
                        width: 90,
                        child: TextField(
                          controller: pricebyuser,
                          decoration: InputDecoration(
                            enabledBorder: UnderlineInputBorder(
                              borderSide:
                                  BorderSide(color: Colors.lightBlueAccent),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide:
                                  BorderSide(color: Colors.lightBlueAccent),
                            ),
                          ),
                          onChanged: (v) {
                            setState(() {
                              pricebyuser.text = v;
                            });
                          },
                        ),
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      Text("(Optional)"),
                    ],
                  ),
                ),
                Container(
                  height: 50.0,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        if (backgroundColor == Colors.blue) {
                          backgroundColor = Colors.white;
                          textofbutton = "off";
                          TextColor = Colors.blue;
                          nightpricecheck = false;
                        } else {
                          backgroundColor = Colors.blue;
                          textofbutton = "on";
                          TextColor = Colors.white;
                          nightpricecheck = true;
                        }
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.blue,
                          style: BorderStyle.solid,
                          width: 1.0,
                        ),
                        color: backgroundColor,
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Center(
                            child: Text(
                              "Night price" + " " + textofbutton,
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
                SizedBox(
                  height: 10,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                        onPressed: () {
                          networkcheckforcurrent();
                          listitems.remove("Your Location:-");
                        },
                        child: Text("current location")),
                    SizedBox(
                      width: 10,
                    ),
                    ElevatedButton(
                        onPressed: () {
                          getPermission();
                          networkcheck(dest1, dest2);
                          // print(pricebyuser.text);
                          print(pricebyuser.text);
                        },
                        child: Text("Calculate")),
                    SizedBox(
                      width: 10,
                    ),
                    ElevatedButton(
                        onPressed: () {
                          if (endtextEditingController.text == "" ||
                              starttextEditingController == "" ||
                              newdata == "0" ||
                              pricebyuser.text == "") {
                            Fluttertoast.showToast(
                                msg: "No route selected",
                                toastLength: Toast.LENGTH_SHORT,
                                gravity: ToastGravity.CENTER,
                                timeInSecForIosWeb: 1,
                                backgroundColor: Colors.blue,
                                textColor: Colors.white,
                                fontSize: 16.0);
                          } else {
                            networkcheckforAddData(
                                dest1, dest2, newdata, pricebyuser.text);
                          }
                        },
                        child: Text("Add")),
                  ],
                )
              ],
            ),
          ),
          // ElevatedButton(onPressed: ()async{
          //   print("fuck");
          //   print(_auth.currentUser);
          //   await _auth.signOut();
          //   print("fuck");
          //   print(_auth.currentUser);
          //   if(_auth.currentUser==null){
          //     print("1");
          //     Navigator.pop(context);
          //   }

          // }, child: Text('Logout'))
          Flexible(
              flex: 1,
              child: !checkforuserdataexists
                  ? Text("No Data")
                  : StreamBuilder(
                      stream: firrstore
                          .collection("UserData")
                          .doc(widget.currentuser)
                          .get()
                          .asStream(),
                      builder: (context, snapshots) {
                        List<Widget> databubble = [];

                        if (!snapshots.hasData) {
                          return Text('No Data');
                        }
                        final data = snapshots.data!.get("data");
                        for (var i in data) {
                          var startlocation = i["currentPlace"];
                          var destination = i["destination"];
                          var price = i["price"];
                          var actualprice = i["actualprice"];
                          var date = i["date"];
                          var a = GestureDetector(
                            onTap: () {
                              if (backgroundcolorofpricecontainer ==
                                  Colors.white) {
                                setState(() {
                                  backgroundcolorofpricecontainer = Colors.blue;
                                  textcolorofpricecontainer = Colors.white;
                                });
                              } else {
                                setState(() {
                                  backgroundcolorofpricecontainer =
                                      Colors.white;
                                  textcolorofpricecontainer = Colors.blue;
                                });
                              }
                            },
                            child: Container(
                              padding: EdgeInsets.all(10),
                              margin: EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10)),
                                border: Border.all(color: Colors.blue),
                                color: backgroundcolorofpricecontainer,
                              ),
                              child: Column(
                                children: backgroundcolorofpricecontainer ==
                                        Colors.white
                                    ? [
                                        SizedBox(
                                          height: 5,
                                        ),
                                        Text(
                                          "Price:" + " " + price,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              color: textcolorofpricecontainer),
                                        ),
                                        SizedBox(
                                          height: 5,
                                        ),
                                        Text(
                                          "ActualPrice:" + " " + actualprice,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              color: textcolorofpricecontainer),
                                        ),
                                        SizedBox(
                                          height: 5,
                                        ),
                                        Text(
                                          "date:" + " " + date,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              color: textcolorofpricecontainer),
                                        ),
                                      ]
                                    : [
                                        Text(
                                          "Start:" + " " + startlocation,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              color: textcolorofpricecontainer),
                                        ),
                                        SizedBox(
                                          height: 5,
                                        ),
                                        Text(
                                          "End:" + " " + destination,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              color: textcolorofpricecontainer),
                                        ),
                                      ],
                              ),
                            ),
                          );
                          if (databubble.length == 1) {
                            print("oyyyy idhar dekh le");
                            databubble.add(BannerAdmob());
                          }
                          if (databubble.length % 3 == 0 &&
                              databubble.length > 2) {
                            print("oyyyy idhar dekh le part 2");
                            databubble.add(BannerAdmob());
                          }
                          databubble.add(a);
                        }

                        // }

                        return ListView(
                          children: databubble,
                        );
                      },
                    ))
        ],
      ),
    );
  }
}

class BannerAdmob extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _BannerAdmobState();
  }
}

class _BannerAdmobState extends State<BannerAdmob> {
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
    return _bannerReady
        ? SizedBox(
            width: _bannerAd.size.width.toDouble(),
            height: _bannerAd.size.height.toDouble(),
            child: AdWidget(ad: _bannerAd),
          )
        : Container();
  }
}
