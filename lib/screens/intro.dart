import 'package:flutter/material.dart';
import 'package:phidrillsim_connect/screens/wrapper.dart';
import 'package:phidrillsim_connect/shared/loading.dart';  // Import the loading screen

class IntroductionPage extends StatefulWidget {
  @override
  _IntroductionPageState createState() => _IntroductionPageState();
}

class _IntroductionPageState extends State<IntroductionPage> {
  PageController _pageController = PageController();
  int _currentIndex = 0;
  bool loading = true; // Add loading state

  // Sample onboarding data with images, titles, and descriptions
  final List<Map<String, String>> _onboardingItems = [
    {
      'image': 'assets/images/drill.jpg',
      'title': 'Welcome to PHIDrillSim Connect',
      'description':
          'PHIDrillSim Connect is your solution for seamless employee management and document submission. Whether you’re an employee, supervisor, or admin, the app connects you with your team and enhances workflow efficiency.',
    },
    {
      'image': 'assets/images/hands.jpg',
      'title': 'Stay Connected & Manage with Ease',
      'description':
          "Communicate with your team through department-specific and general channels. Manage employee status, track activities, and ensure secure access with role-based controls.",
    },
    {
      'image': 'assets/images/intropic_one.jpg',
      'title': 'Document Submission & Review Made Easy',
      'description':
          'Upload work-related documents, track submissions, and collaborate with supervisors for approvals or revisions. Stay on top of tasks with real-time notifications and transparent file management.',
    },
  ];

  @override
  void initState() {
    super.initState();
    // Simulate a delay to mimic image loading or data fetching
    _simulateLoading();
  }

  void _simulateLoading() async {
    // Simulate a loading state for 3 seconds
    await Future.delayed(Duration(seconds: 3));
    setState(() {
      loading = false; // Set loading to false once done
    });
  }

  @override
  Widget build(BuildContext context) {
    return loading
        ? Loading() // Show loading screen if still loading
        : Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: _onboardingItems.length,
                      onPageChanged: (index) {
                        setState(() {
                          _currentIndex = index;
                        });
                      },
                      itemBuilder: (context, index) {
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Image with same width and border radius
                            ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: Image.asset(
                                _onboardingItems[index]['image']!,
                                width: MediaQuery.of(context).size.width * 0.9,
                                height: 250,
                                fit: BoxFit.cover, // Ensure the image fits properly
                              ),
                            ),
                            SizedBox(height: 30),
                            // Title
                            Text(
                              _onboardingItems[index]['title']!,
                              style: TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 15),
                            // Description
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 25),
                              child: Text(
                                _onboardingItems[index]['description']!,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 30),
                  // Dots Indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _onboardingItems.length,
                      (index) => AnimatedContainer(
                        duration: Duration(milliseconds: 300),
                        margin: EdgeInsets.symmetric(horizontal: 5),
                        width: _currentIndex == index ? 12 : 8,
                        height: _currentIndex == index ? 12 : 8,
                        decoration: BoxDecoration(
                          color: _currentIndex == index
                              ? Theme.of(context).primaryColor
                              : Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 30),
                  // Button
                  Container(
                    margin: EdgeInsets.symmetric(vertical: 20),
                    width: MediaQuery.of(context).size.width * 0.9,
                    height: 55,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(40),
                      color: Theme.of(context).primaryColor,
                    ),
                    child: TextButton(
                      onPressed: () {
                        if (_currentIndex == _onboardingItems.length - 1) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => Wrapper()),
                          );
                        } else {
                          _pageController.nextPage(
                            duration: Duration(milliseconds: 500),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                      child: Text(
                        _currentIndex == _onboardingItems.length - 1
                            ? "Get Started"
                            : "Continue",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
  }
}
