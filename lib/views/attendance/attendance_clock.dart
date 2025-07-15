import 'dart:async';
import 'dart:io';
import 'package:chokchey_hr_app/constants/constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:platform/platform.dart';
import '../../models/attendance_model.dart';
import '../../widgets/attendance_clock_widget.dart';
import '../../widgets/emptyAttendance.dart';

class AttendanceClock extends StatefulWidget {
  const AttendanceClock({super.key});

  @override
  _AttendanceClockState createState() => _AttendanceClockState();
}

class _AttendanceClockState extends State<AttendanceClock>
    with SingleTickerProviderStateMixin {
  late Future<AttendanceResponse> futureAttendanceResponse;

  String lastStatus = '';
  bool isEmptyAttendanceClock = true;

  dynamic late;
  dynamic long;

  LatLng currentLatLng = const LatLng(
    11.5342,
    104.8817,
  ); // default late long branch HQ
  bool _isMatchLocation = false;
  bool isRequestPermission = true;
  dynamic listTimeClock = {};
  bool isLoading = true;
  late int pageSizeParam = 20;
  late int pageNumberParam = 1;
  late String sDateParam = "";
  late String eDateParam = "";
  String onClock = "";
  String onClockLocation = "";
  bool typeClock = false;
  dynamic listAllBranch;
  dynamic _onSelectedBranchFilter;
  bool isClockIn = true;

  // fetchCurrentLocation() async {
  //   await Provider.of<ZoneByBranchProvider>(context, listen: false)
  //       .fetchZoneByBranch()
  //       .then((value) async {
  //         if (value != null &&
  //             value['ccfbranch'] != null &&
  //             value['ccfbranch']['braname'] != null) {
  //           setState(() {
  //             _onSelectedBranchFilter = value['ccfbranch']['braname'];
  //           });
  //         }
  //         late = double.parse(value['latitude']);
  //         long = double.parse(value['longitude']);

  //         await Geolocator.getCurrentPosition().then((currLocation) async {
  //           setState(() {
  //             currentLatLng = LatLng(
  //               currLocation.latitude,
  //               currLocation.longitude,
  //             );
  //           });
  //           double distanceInMeters = Geolocator.distanceBetween(
  //             late,
  //             long,
  //             currLocation.latitude,
  //             currLocation.longitude,
  //           );
  //           if (distanceInMeters <= 300) {
  //             setState(() {
  //               isRequestPermission = false;
  //               _isMatchLocation = true;
  //             });
  //           } else {
  //             setState(() {
  //               isRequestPermission = false;
  //             });
  //           }
  //         });
  //       })
  //       .catchError((onError) {})
  //       .onError((error, stackTrace) {});
  // }

  dropCurrentLocation(latitude, longitude) async {
    setState(() {
      isLoading = true;
    });
    await Geolocator.getCurrentPosition()
        .then((currLocation) async {
          setState(() {
            currentLatLng = LatLng(
              currLocation.latitude,
              currLocation.longitude,
            );
          });
          var lat = double.parse(latitude);
          var long = double.parse(longitude);
          double distanceInMeters = Geolocator.distanceBetween(
            lat,
            long,
            currLocation.latitude,
            currLocation.longitude,
          );
          if (distanceInMeters <= 300) {
            setState(() {
              isRequestPermission = false;
              _isMatchLocation = true;
              isLoading = false;
            });
          } else {
            setState(() {
              isRequestPermission = false;
              _isMatchLocation = false;
              isLoading = false;
            });
          }
        })
        .catchError((onError) {
          debugPrint('Error location----> $onError');
          setState(() {
            isLoading = false;
          });
        });
  }

  Future requestPermission() async {
    setState(() {
      isRequestPermission = true;
    });
    try {
      if (Platform.iOS == "ios") {
        bool serviceEnabled;
        LocationPermission permission;
        serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Please allow location',
                style: TextStyle(fontSize: 18),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }

        permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Please allow location',
                  style: TextStyle(fontSize: 18),
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        }

        if (permission == LocationPermission.deniedForever) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Please allow location',
                style: TextStyle(fontSize: 18),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        // await fetchCurrentLocation();
      } else {
        bool serviceEnabled;
        LocationPermission permission;

        serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          print('Location services are disabled!');
        }

        permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {}
        }
        if (permission == LocationPermission.deniedForever) {}
        // await fetchCurrentLocation();
      }
    } catch (error) {}
  }

  // Future fetchClocked() async {
  //   setState(() {
  //     isLoading = true;
  //   });

  //   try {
  //     await Provider.of<ClockLogProvider>(context, listen: false)
  //         .fetchEmployeeClock(
  //             pageSizeParam, pageNumberParam, sDateParam, eDateParam);

  //     setState(() {
  //       futureAttendanceResponse = fetchAttendanceLogs();
  //     });

  //     final response = await futureAttendanceResponse;
  //     if (response.totalList != 0) {
  //       setState(() {
  //         isEmptyAttendanceClock = false;
  //       });
  //     }
  //     if (response.lastStatus == 'Out') {
  //       setState(() {
  //         isClockIn = true;
  //       });
  //     }
  //     if (response.lastStatus == 'In') {
  //       setState(() {
  //         isClockIn = false;
  //       });
  //     }
  //     setState(() {
  //       isLoading = false;
  //     });
  //   } catch (error) {
  //     setState(() {
  //       isLoading = false;
  //     });
  //   }
  // }

  // getListBranch() async {
  //   await Provider.of<ZoneByBranchProvider>(context, listen: false)
  //       .fetchAllZoneLatLong()
  //       .then((braid) {
  //         setState(() {
  //           isLoading = false;
  //           listAllBranch = braid;
  //         });
  //       })
  //       .onError((error, stackTrace) {
  //         setState(() {
  //           isLoading = false;
  //         });
  //       })
  //       .catchError((onError) {
  //         setState(() {
  //           isLoading = false;
  //         });
  //       });
  // }

  final bool _departmentColor = false;
  final GlobalKey<FormState> _departmentKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // getListBranch();
    requestPermission();
    futureAttendanceResponse = fetchAttendanceLogs();
  }

  @override
  Widget build(BuildContext context) {
    DateTime now = DateTime.now();
    String formatDay = DateFormat('EEEEE | dd MMM yyyy').format(now);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primary,
        leading: InkWell(
          onTap: () {
            Navigator.pop(context);
          },
          child: const Icon(Icons.arrow_back_ios, color: Colors.white),
        ),
        title: const Column(
          children: [
            Text(
              "Attendance",
              style: TextStyle(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: Center(
        child: SizedBox(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Card(
                elevation: 1,
                margin: const EdgeInsets.only(left: 10, right: 10, top: 10),
                color: primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: SizedBox(
                  height: 150,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat.jm().format(DateTime.now()), // 12H not 24H
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const Padding(padding: EdgeInsets.only(top: 10)),
                        Text(
                          formatDay,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 20,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              isLoading
                  ? const SizedBox(
                    height: 250,
                    child: Center(child: SpinKitFadingCircle(color: secondary)),
                  )
                  : Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.only(
                          left: 80,
                          right: 80,
                          top: 20,
                        ),
                        child: DropdownButtonFormField<String>(
                          elevation: 4,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          key: _departmentKey,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.all(14),
                            filled: true,
                            fillColor: Colors.white,
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color:
                                    _departmentColor == true
                                        ? Colors.red
                                        : primary,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color:
                                    _departmentColor == true
                                        ? Colors.red
                                        : primary,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            hintText: _onSelectedBranchFilter ?? "Branch",
                            labelText: _onSelectedBranchFilter ?? "Branch",
                            hintStyle: TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                            ),
                            labelStyle: TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                            ),
                            prefixIcon: Icon(Icons.apartment, color: primary),
                          ),
                          icon: Icon(Icons.arrow_drop_down, color: primary),
                          onChanged: (value) {
                            for (var element in listAllBranch) {
                              if (element['zoneid'] == value) {
                                setState(() {
                                  _onSelectedBranchFilter =
                                      element['ccfbranch']['braname'];
                                });
                                dropCurrentLocation(
                                  element['latitude'],
                                  element['longitude'],
                                );
                              }
                            }
                          },
                          items:
                              listAllBranch != null && listAllBranch.isNotEmpty
                                  ? listAllBranch.map<DropdownMenuItem<String>>(
                                    (item) {
                                      return DropdownMenuItem<String>(
                                        value: item['zoneid'],
                                        child: Container(
                                          decoration: const BoxDecoration(
                                            border: Border(
                                              bottom: BorderSide(
                                                color: Colors.grey,
                                                width: 0.2,
                                              ),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Text(
                                                item['ccfbranch']['braname'],
                                                style: TextStyle(fontSize: 16),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ).toList()
                                  : null,
                        ),
                      ),
                      const Padding(padding: EdgeInsets.only(top: 20)),
                      if (_isMatchLocation)
                        isClockIn
                            ? ClockButtonWidget(
                              icon: Icons.login,
                              color: secondary,
                              textLabel: 'Clock In',
                              onPressed: () async {
                                // await postClocked("In", true);
                              },
                            )
                            : ClockButtonWidget(
                              icon: Icons.logout,
                              color: logoPink,
                              textLabel: 'Clock Out',
                              onPressed: () async {
                                // await postClocked("Out", false);
                              },
                            ),
                      if (!_isMatchLocation)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              isRequestPermission ? "Loading" : "Outside Zone",
                              style: const TextStyle(fontSize: 20),
                            ),
                            if (!isRequestPermission)
                              Icon(
                                Icons.location_off_outlined,
                                color: primary,
                                size: 25,
                              ),
                          ],
                        ),
                      if (!_isMatchLocation)
                        Text(
                          !isRequestPermission
                              ? 'Please select the right location to clock.'
                              : '',
                          style: const TextStyle(
                            fontSize: 18.0,
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),
              const Padding(padding: EdgeInsets.only(top: 20)),
              Expanded(
                child: FutureBuilder<AttendanceResponse>(
                  future: futureAttendanceResponse,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox();
                    } else if (snapshot.hasError) {
                      return Text("${snapshot.error}");
                    } else if (!snapshot.hasData || snapshot.data == null) {
                      return const Text("No data found");
                    } else {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.only(
                              left: 16,
                              top: 10.0,
                              bottom: 10.0,
                            ),
                            width: MediaQuery.of(context).size.width,
                            height: 50,
                            color: secondary,
                            child: const Text(
                              "Attendance Clocks",
                              textAlign: TextAlign.start,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Card(
                              elevation: 0.5,
                              child:
                                  isEmptyAttendanceClock
                                      ? const Center(child: EmptyAttendance())
                                      : ListView.builder(
                                        itemCount:
                                            snapshot
                                                .data!
                                                .attendanceLogs
                                                .length,
                                        itemBuilder: (context, index) {
                                          var log =
                                              snapshot
                                                  .data!
                                                  .attendanceLogs[index];
                                          return Padding(
                                            padding: const EdgeInsets.all(16.0),
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 50,
                                                  height: 50,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color:
                                                        log.status == 'In'
                                                            ? secondary
                                                            : logoPink,
                                                  ),
                                                  child: Center(
                                                    child: Text(
                                                      log.status,
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 5),
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      "${convertToAmPm(log.timeClock)} - ${getBranchName(log.branchCode)}",
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      "Date: ${getDateTimeYMD(log.timeDate.toString())}",
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                            ),
                          ),
                        ],
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<AttendanceResponse> fetchAttendanceLogs() {
    return Future.value(
      AttendanceResponse(
        totalList: 2,
        lastStatus: "Present",
        attendanceLogs: [
          AttendanceLog(
            empId: "2025-07-01",
            status: "Present",
            timeClock: "08:30 AM",
            timeDate: DateTime.parse("2025-07-01T08:30:00"),
            branchCode: "001",
            timeId: "1",
            deviceName: "Mobile",
            userInfoProfile: null,
          ),
          AttendanceLog(
            empId: "2025-07-01",
            status: "Present",
            timeClock: "08:30 AM",
            timeDate: DateTime.parse("2025-07-01T08:30:00"),
            branchCode: "001",
            timeId: "1",
            deviceName: "Mobile",
            userInfoProfile: null,
          ),
        ],
      ),
    );
  }
}
