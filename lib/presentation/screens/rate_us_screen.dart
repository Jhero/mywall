import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class RateUsScreen extends StatefulWidget {
  const RateUsScreen({Key? key}) : super(key: key);

  @override
  State<RateUsScreen> createState() => _RateUsScreenState();
}

class _RateUsScreenState extends State<RateUsScreen> {
  @override
  void initState() {
    super.initState();
    _launchPlayStore();
  }

  Future<void> _launchPlayStore() async {
    const String appId = "com.myjovan.mywall"; // ganti dengan package name
    final Uri url = Uri.parse("https://play.google.com/store/apps/details?id=$appId");

    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception("Could not open Play Store");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Bisa kosong atau kasih info
    return const Center(child: Text("Redirecting to Play Store..."));
  }
}
