import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../../data/services/admob_service.dart';
import '../../../core/utils/debug_logger.dart';
import 'ad_placeholder_widget.dart';

class AdmobNativeWidget extends StatefulWidget {
  final double height;
  final EdgeInsets? margin;
  final VoidCallback? onAdLoaded;
  final VoidCallback? onAdFailed;

  const AdmobNativeWidget({
    super.key,
    this.height = 300,
    this.margin,
    this.onAdLoaded,
    this.onAdFailed,
  });

  @override
  State<AdmobNativeWidget> createState() => _AdmobNativeWidgetState();
}

class _AdmobNativeWidgetState extends State<AdmobNativeWidget> {
  NativeAd? _nativeAd;
  bool _isAdLoaded = false;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    _loadNativeAd();
  }

  Future<void> _loadNativeAd() async {
    try {
      _nativeAd = NativeAd(
        adUnitId: AdmobService.nativeAdUnitId,
        request: const AdRequest(),
        listener: NativeAdListener(
          onAdLoaded: (ad) {
            DebugLogger.logAdSuccess('Native ad loaded', adType: 'NATIVE');
            if (mounted) {
              setState(() {
                _isAdLoaded = true;
                _loadFailed = false;
              });
              widget.onAdLoaded?.call();
            }
          },
          onAdFailedToLoad: (ad, error) {
            DebugLogger.logAdError('Native ad failed to load', 
              adType: 'NATIVE', error: error);
            if (mounted) {
              setState(() {
                _loadFailed = true;
                _isAdLoaded = false;
              });
              widget.onAdFailed?.call();
            }
            ad.dispose();
          },
        ),
        nativeTemplateStyle: NativeTemplateStyle(
          templateType: TemplateType.medium,
          cornerRadius: 10.0,
          mainBackgroundColor: Colors.white,
        ),
      );

      await _nativeAd?.load();
    } catch (e) {
      DebugLogger.logAdError('Error in native ad loading', 
        adType: 'NATIVE', error: e);
      if (mounted) {
        setState(() {
          _loadFailed = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loadFailed) {
      return AdPlaceholderWidget(
        height: widget.height,
        margin: widget.margin,
        adType: 'Native',
      );
    }

    if (!_isAdLoaded || _nativeAd == null) {
      return AdPlaceholderWidget(
        height: widget.height,
        margin: widget.margin,
        isLoading: true,
        adType: 'Native',
      );
    }

    return Container(
      height: widget.height,
      margin: widget.margin,
      child: AdWidget(ad: _nativeAd!),
    );
  }
}