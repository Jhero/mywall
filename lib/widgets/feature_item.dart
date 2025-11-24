import 'package:flutter/material.dart';

class FeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const FeatureItem({
    Key? key,
    required this.icon,
    required this.title,
    required this.description,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: Colors.blue,
              size: 24,
            ),
          ),
          // const SizedBox(width: 15),
          // Expanded(
          //   child: Column(
          //     crossAxisAlignment: CrossAxisAlignment.start,
          //     // children: [
          //     //   Text(
          //     //     title,
          //     //     style: const TextStyle(
          //     //       fontSize: 18,
          //     //       fontWeight: FontWeight.bold,
          //     //     ),
          //     //   ),
          //     //   const SizedBox(height: 5),
          //     //   Text(
          //     //     description,
          //     //     style: const TextStyle(
          //     //       color: Colors.grey,
          //     //       fontSize: 14,
          //     //     ),
          //     //   ),
          //     // ],
          //   ),
          // ),
        ],
      ),
    );
  }
}