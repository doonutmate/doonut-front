import 'package:day1/constants/colors.dart';
import 'package:day1/models/community_model.dart';
import 'package:day1/screens/calendar_screen.dart';
import 'package:day1/screens/camera/camera.dart';
import 'package:day1/screens/community/community_screen.dart';
import 'package:day1/screens/community/community_lock_screen.dart';
import 'package:day1/screens/mypage/my_page_screen.dart';
import 'package:day1/services/device_size_provider.dart';
import 'package:day1/services/community_service.dart';
import 'package:day1/widgets/molecules/custom_bottom_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../main.dart';
import '../widgets/molecules/show_Error_Popup.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _selectedIndex = 0;
  final CommunityService communityService = CommunityService();

  final List<Widget> _widgetOptions = <Widget>[
    CalendarScreen(),
    CameraScreen(cameras),
    Container(), // 커뮤니티 화면을 비워두고, 로직에서 처리합니다.
    MyPageScreen()
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() async {
    if (_selectedIndex == 2) {
      await _fetchCommunityData();
    }
  }

  Future<void> _fetchCommunityData() async {
    try {
      final result = await communityService.fetchCalendars();
      final List<Community> communities = result['communities'];
      setState(() {
        _widgetOptions[2] = CommunityScreen(communities: communities);
      });
    } catch (e) {
      if (e.toString().contains('Failed to load community with status: 400')) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => CommunityLockScreen(onTap: _onItemTapped)),
        );
      } else {
        print('Error: $e');
        showErrorPopup(context, 'Failed to load calendars: $e');
      }
    }
  }

  void _onItemTapped(int index) async {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 2) {
      await _fetchCommunityData();
    }
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    ref.watch(deviceSizeProvider.notifier).setDeviceWidth(width);
    ref.watch(deviceSizeProvider.notifier).setDeviceHeight(height);

    return Scaffold(
      backgroundColor: backGroundColor,
      body: SafeArea(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        selectedIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}