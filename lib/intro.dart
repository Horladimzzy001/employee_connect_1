import 'package:flutter/material.dart';
import 'package:phidrillsim_connect/loading.dart';
import 'package:phidrillsim_connect/main.dart'; // Import the loading screen

// Import your AuthCheck class or screen


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
            backgroundColor: Colors.white, // Set background color to white
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Column(
                  children: [
                    // Skip Button
                    Align(
                      alignment: Alignment.topRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => AuthCheck()),
                          );
                        },
                        child: Text(
                          'Skip',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
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
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Image with same width and border radius
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: Image.asset(
                                    _onboardingItems[index]['image']!,
                                    width:
                                        MediaQuery.of(context).size.width * 0.8,
                                    height: 250,
                                    fit: BoxFit.cover, // Ensure the image fits properly
                                  ),
                                ),
                                SizedBox(height: 40),
                                // Title
                                Text(
                                  _onboardingItems[index]['title']!,
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 20),
                                // Description
                                Text(
                                  _onboardingItems[index]['description']!,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[700],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
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
                                ? Colors.blue
                                : Colors.grey[400],
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 30),
                    // Button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: () {
                            if (_currentIndex == _onboardingItems.length - 1) {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (context) => AuthCheck()),
                              );
                            } else {
                              _pageController.nextPage(
                                duration: Duration(milliseconds: 500),
                                curve: Curves.easeInOut,
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue, // Background color
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
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
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          );
  }
}
