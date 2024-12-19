import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:math';
import 'package:flutter/services.dart'; // Clipboard API

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  _MainAppState createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> with TickerProviderStateMixin {
  List<Map<String, String>> quoteHistory = [];
  int currentIndex = -1;
  String quote = 'Swipe to get a random quote!';
  bool isLoading = false;
  double opacity = 1.0;

  late AnimationController blobController1;
  late AnimationController blobController2;
  late Animation<Offset> blobAnimation1;
  late Animation<Offset> blobAnimation2;

  @override
  void initState() {
    super.initState();
    fetchData();

    blobController1 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);

    blobController2 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat(reverse: true);

    blobAnimation1 = Tween<Offset>(
      begin: Offset(0.2, 0.3),
      end: Offset(0.8, 0.6),
    ).animate(CurvedAnimation(parent: blobController1, curve: Curves.easeInOut));

    blobAnimation2 = Tween<Offset>(
      begin: Offset(0.8, 0.7),
      end: Offset(0.2, 0.4),
    ).animate(CurvedAnimation(parent: blobController2, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    blobController1.dispose();
    blobController2.dispose();
    super.dispose();
  }

  Future<void> fetchData() async {
    setState(() {
      isLoading = true;
      opacity = 0.0;
    });

    var random = Random();
    int indexNum = random.nextInt(485);
    String url = ('https://appcollection.in/quotify/fetch-quote.php?id=$indexNum');

    try {
      final http.Response response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        String newQuote = data['quote'];

        setState(() {
          quote = newQuote;

          if (currentIndex == quoteHistory.length - 1) {
            quoteHistory.add({'quote': newQuote});
            currentIndex++;
          }

          isLoading = false;
        });

        Future.delayed(const Duration(milliseconds: 200), () {
          setState(() {
            opacity = 1.0;
          });
        });
      } else {
        setState(() {
          isLoading = false;
          opacity = 1.0;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        opacity = 1.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0x00f7e6ca),
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: Listenable.merge([blobController1, blobController2]),
            builder: (context, child) {
              return CustomPaint(
                painter: BlobPainter(
                  blob1Position: blobAnimation1.value,
                  blob2Position: blobAnimation2.value,
                ),
                size: MediaQuery.of(context).size,
              );
            },
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/applogo.png',
                        width: 54,
                        height: 54,
                        fit: BoxFit.cover,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Quotify',
                        style: GoogleFonts.playfairDisplay(
                          fontWeight: FontWeight.bold,
                          fontSize: 32,
                          color: const Color(0xFF331C08),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: GestureDetector(
                      onPanEnd: (details) {
                        if (details.velocity.pixelsPerSecond.dx < 0) {
                          showNextQuote();
                        } else if (details.velocity.pixelsPerSecond.dx > 0) {
                          showPreviousQuote();
                        }
                      },
                      child: AnimatedOpacity(
                        opacity: opacity,
                        duration: const Duration(milliseconds: 500),
                        child: Container(
                          padding: const EdgeInsets.all(20.0),
                          margin: const EdgeInsets.symmetric(horizontal: 20.0),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFFFF),
                            borderRadius: BorderRadius.circular(16.0),
                            border: Border.all(color: Colors.grey.shade400, width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withAlpha(0), // To be Altered later if required
                                  blurRadius: 12),
                            ],
                          ),
                          child: Text(
                            quote,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Noto Sans',
                              fontSize: 24,
                              color: const Color(0xff331c08),
                              fontFeatures: [],
                            ),
                          )
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 20.0), // Position the button at the bottom
                  child: ElevatedButton(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: quote));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Quote copied to clipboard!'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFF0D8), // Button color
                      foregroundColor: const Color(0xFF331C08), // Icon and text color
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(16),
                    ),
                    child: const Icon(Icons.copy, size: 28),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void showPreviousQuote() {
    if (currentIndex > 0) {
      setState(() {
        isLoading = true;
        opacity = 0.0;
      });

      Future.delayed(const Duration(milliseconds: 300), () {
        setState(() {
          currentIndex--;
          quote = quoteHistory[currentIndex]['quote']!;
          isLoading = false;
          opacity = 1.0;
        });
      });
    }
  }

  void showNextQuote() {
    if (currentIndex < quoteHistory.length - 1) {
      setState(() {
        isLoading = true;
        opacity = 0.0;
      });

      Future.delayed(const Duration(milliseconds: 300), () {
        setState(() {
          currentIndex++;
          quote = quoteHistory[currentIndex]['quote']!;
          isLoading = false;
          opacity = 1.0;
        });
      });
    } else {
      fetchData();
    }
  }
}

class BlobPainter extends CustomPainter {
  final Offset blob1Position;
  final Offset blob2Position;

  BlobPainter({
    required this.blob1Position,
    required this.blob2Position,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final blob1Paint = Paint()
      ..color = const Color(0xFFE8D59E).withAlpha(129)
      ..style = PaintingStyle.fill;

    final blob2Paint = Paint()
      ..color = const Color(0xFFD9BBB0).withAlpha(179)
      ..style = PaintingStyle.fill;

    final blob1Center = Offset(
      blob1Position.dx * size.width,
      blob1Position.dy * size.height,
    );
    final blob2Center = Offset(
      blob2Position.dx * size.width,
      blob2Position.dy * size.height,
    );

    canvas.saveLayer(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint(),
    );

    canvas.drawCircle(blob1Center, size.width * 0.3, blob1Paint);
    canvas.restore();

    canvas.saveLayer(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint(),
    );

    canvas.drawCircle(blob2Center, size.width * 0.25, blob2Paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}