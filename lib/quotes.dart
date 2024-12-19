import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:math';
//import 'package:flutter/services.dart';

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  _MainAppState createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> with TickerProviderStateMixin {
  List<Map<String, String>> quoteHistory = [];
  int currentIndex = -1;
  String quote = 'Swipe to get a random quote!';
  String speaker = '';
  bool isLoading = false;
  double opacity = 1.0;

  late AnimationController blobController1;
  late AnimationController blobController2;
  late Animation<Offset> blobAnimation1;
  late Animation<Offset> blobAnimation2;

  @override
  void initState() {
    super.initState();
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
    ).animate(
        CurvedAnimation(parent: blobController1, curve: Curves.easeInOut));

    blobAnimation2 = Tween<Offset>(
      begin: Offset(0.8, 0.7),
      end: Offset(0.2, 0.4),
    ).animate(
        CurvedAnimation(parent: blobController2, curve: Curves.easeInOut));
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
    String url =
        'https://appcollection.in/quotify/fetch-quote.php?id=$indexNum';

    try {
      final http.Response response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        String newQuote = data['quote'];
        String newSpeaker = data['speaker'];

        setState(() {
          if (currentIndex == quoteHistory.length - 1) {
            quoteHistory.add({'quote': newQuote, 'speaker': newSpeaker});
            currentIndex++;
          }

          quote = newQuote;
          speaker = newSpeaker;
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

  void navigateHistory(int direction) {
    if (direction == -1 && currentIndex > 0) {
      // Go to the previous quote
      setState(() {
        currentIndex--;
        quote = quoteHistory[currentIndex]['quote']!;
        speaker = quoteHistory[currentIndex]['speaker']!;
      });
    } else if (direction == 1 && currentIndex < quoteHistory.length - 1) {
      // Go to the next quote
      setState(() {
        currentIndex++;
        quote = quoteHistory[currentIndex]['quote']!;
        speaker = quoteHistory[currentIndex]['speaker']!;
      });
    } else if (direction == 1) {
      fetchData();
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
          Column(
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
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onPanUpdate: (details) {
                    if (details.delta.dx > 0) {
                      navigateHistory(-1);
                    } else if (details.delta.dx < 0) {
                      navigateHistory(1);
                    }
                  },
                  child: Stack(
                    children: [
                      AnimatedOpacity(
                        opacity: opacity,
                        duration: const Duration(milliseconds: 500),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20.0),
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 20.0),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFFFFF),
                                  borderRadius: BorderRadius.circular(16.0),
                                  border: Border.all(
                                    color: Colors.grey.shade400,
                                    width: 1.5,
                                  ), // Added border for the quote container
                                ),
                                child: Text(
                                  quote,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'Noto Sans',
                                    fontSize: 24,
                                    color: const Color(0xff331c08),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 7.5),
                              const SizedBox(height: 7.5),
                              Text(
                                speaker,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 18,
                                    color: const Color(0xff503823)),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (isLoading)
                        const Center(
                            child: CircularProgressIndicator(
                          color: Color(0xff4a4540),
                        )),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
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

    canvas.drawCircle(blob1Center, size.width * 0.3, blob1Paint);
    canvas.drawCircle(blob2Center, size.width * 0.25, blob2Paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
