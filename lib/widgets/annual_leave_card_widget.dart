import 'package:flutter/material.dart';
import '../constants/constant.dart';
import 'custom_progress_bar.dart';

class AnnualLeaveBalanceWidget extends StatelessWidget {
  const AnnualLeaveBalanceWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
      decoration: BoxDecoration(
        color: primary,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Stack(
                alignment: Alignment.bottomCenter,
                children: <Widget>[
                  Text(
                    'Remaining Leave Balance',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  // Positioned(
                  //   bottom: 0,
                  //   left: 0,
                  //   right: 0,
                  //   child: Container(
                  //     height: 1,
                  //     color: Colors.white,
                  //   ),
                  // ),
                ],
              ),
              TextButton(
                onPressed: () {},
                child: const Text(
                  'View Details >',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          flex: 5,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 16,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: logoPink,
                                      shape: BoxShape.rectangle,
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(3),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  const Text(
                                    'Used Leave: 5 days',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Container(
                                    width: 16,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.rectangle,
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(12),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  const Text(
                                    'Available Leave: 17 days',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Expanded(
                          flex: 1,
                          child: Text(
                            '17',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    EllipticalProgressBar(
                      progress: 0.5,
                      backgroundColor: Colors.grey.shade200,
                      progressColor: logoPink,
                      height: 25.0,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
