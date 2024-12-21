import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  MainAppState createState() => MainAppState();
}

class MainAppState extends State<MainApp> with TickerProviderStateMixin {
  List<Map<String, String>> quoteHistory = [];
  int currentIndex = -1;
  String quote = 'Swipe to get a random quote!';
  String speaker = '';
  bool isLoading = false;
  double opacity = 1.0;
  bool isNavigating = false;
  String? customQuote;
  String? customSpeaker;
  Color fieldBorderColor = Colors.grey.shade400;

  late AnimationController blobController1;
  late AnimationController blobController2;
  late Animation<Offset> blobAnimation1;
  late Animation<Offset> blobAnimation2;

  ScreenshotController screenshotController = ScreenshotController();

  @override
  void initState() {
    super.initState();
    blobController1 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )
      ..repeat(reverse: true);

    blobController2 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )
      ..repeat(reverse: true);

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
    if (customQuote != null || customSpeaker != null) {
      final shouldDiscard = await showDialog<bool>(
        context: context,
        builder: (context) =>
            AlertDialog(
              title: const Text('Warning'),
              content: const Text(
                  'Viewing another quote will discard your custom quote. Continue?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Continue'),
                ),
              ],
            ),
      );
      if (shouldDiscard != true) return;
    }

    setState(() {
      customQuote = null;
      customSpeaker = null;
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
          quoteHistory.add({'quote': newQuote, 'speaker': newSpeaker});
          currentIndex = quoteHistory.length - 1;

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

  void navigateHistory(int direction) async {
    if (isNavigating) return;
    if ((direction == 1 || direction == -1) &&
        (customQuote != null || customSpeaker != null)) {
      final shouldDiscard = await showDialog<bool>(
        context: context,
        builder: (context) =>
            AlertDialog(
              title: const Text('Warning'),
              content: const Text(
                  'Viewing a new quote will discard your custom quote. Continue?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Continue'),
                ),
              ],
            ),
      );
      if (shouldDiscard != true) return;

      setState(() {
        customQuote = null;
        customSpeaker = null;
      });
    }

    setState(() {
      isNavigating = true;

      if (quoteHistory.isNotEmpty) {
        if (direction == -1 && currentIndex > 0) {
          currentIndex--;
        } else if (direction == 1 && currentIndex < quoteHistory.length - 1) {
          currentIndex++;
        } else if (direction == 1 && currentIndex == quoteHistory.length - 1) {
          fetchData();
        }

        if (currentIndex >= 0 && currentIndex < quoteHistory.length) {
          quote = quoteHistory[currentIndex]['quote']!;
          speaker = quoteHistory[currentIndex]['speaker']!;
        }
      } else {
        fetchData();
      }
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        isNavigating = false;
      });
    });
  }

  void setCustomQuote() async {
    final custom = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final quoteController = TextEditingController();
        final speakerController = TextEditingController();

        return Padding(
          padding: MediaQuery
              .of(context)
              .viewInsets,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(51),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withAlpha(130),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(25),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.brown.shade200, Colors.brown.shade400],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(2),
                  child: TextField(
                    controller: quoteController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white.withAlpha(230),
                      hintText: 'Custom Quote',
                      hintStyle: const TextStyle(color: Colors.grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 15,
                        horizontal: 20,
                      ),
                    ),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(height: 16),
                Focus(
                  onFocusChange: (isFocused) {
                    setState(() {
                      fieldBorderColor = isFocused
                          ? Colors.brown.shade400
                          : Colors.grey.shade400;
                    });
                  },
                  child: TextField(
                    controller: speakerController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white.withAlpha(230),
                      hintText: 'Speaker',
                      hintStyle: const TextStyle(color: Colors.grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide:
                        BorderSide(color: fieldBorderColor, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 15,
                        horizontal: 20,
                      ),
                    ),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, {
                      'quote': quoteController.text,
                      'speaker': speakerController.text,
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    backgroundColor: Colors.brown.shade400,
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 20,
                    ),
                  ),
                  child: const Text(
                    'Set Custom Quote',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (custom != null) {
      setState(() {
        customQuote = custom['quote'];
        customSpeaker = custom['speaker'];
        quote = customQuote!;
        speaker = customSpeaker!;
      });
    }
  }

  Future<void> shareQuoteAsImage() async {
    try {
      final image = await screenshotController.capture();
      if (image == null) return;

      final directory = await getTemporaryDirectory();
      final imagePath = File('${directory.path}/quote.png');
      await imagePath.writeAsBytes(image);

      await Share.shareXFiles([XFile(imagePath.path)],
          text: 'Here is an inspiring quote!');
    } catch (e) {
      if (mounted) {  // Check if the widget is still mounted
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to share quote as image.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0x00f7e6ca),
      body: Stack(
        children: [
          if (isLoading)
            Positioned.fill(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Color(0xff4a4540),
                  ),
                ],
              ),
            ),
          Column(children: [
            SafeArea(
              child: Container(
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
                        color: const Color(0xff4a4540),
                        fontSize: 32,
                      ),
                    ),
                  ],
                ),
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
                child: Screenshot(
                  controller: screenshotController,
                  child: Stack(
                    children: [
                      AnimatedBuilder(
                        animation: Listenable.merge(
                            [blobController1, blobController2]),
                        builder: (context, child) {
                          return CustomPaint(
                            painter: BlobPainter(
                              blob1Position: blobAnimation1.value,
                              blob2Position: blobAnimation2.value,
                            ),
                            size: MediaQuery
                                .of(context)
                                .size,
                          );
                        },
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
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
                                    duration:
                                    const Duration(milliseconds: 500),
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment:
                                        MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            padding:
                                            const EdgeInsets.all(20.0),
                                            margin:
                                            const EdgeInsets.symmetric(
                                                horizontal: 20.0),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFFFFFF),
                                              borderRadius:
                                              BorderRadius.circular(16.0),
                                              border: Border.all(
                                                color: Colors.grey.shade400,
                                                width: 1.5,
                                              ),
                                            ),
                                            child: Text(
                                              quote,
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontFamily: 'Noto Sans',
                                                fontSize: 24,
                                                color:
                                                const Color(0xff331c08),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 7.5),
                                          Text(
                                            speaker,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 18,
                                              color: const Color(0xff503823),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  if (!isLoading)
                                    Positioned(
                                      bottom: 450,
                                      left:
                                      MediaQuery
                                          .of(context)
                                          .size
                                          .width *
                                          0.5 -
                                          25,
                                      child: AnimatedOpacity(
                                        opacity: opacity,
                                        duration:
                                        const Duration(milliseconds: 500),
                                        child: Image.asset(
                                          'assets/images/quotemark.png',
                                          width: 50,
                                          height: 50,
                                        ),
                                      ),
                                    )
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: MediaQuery
                  .of(context)
                  .size
                  .width / 3 - 30,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(20),
                          backgroundColor: Colors.white,
                        ),
                        onPressed: shareQuoteAsImage,
                        child: const Icon(
                          Icons.share,
                          color: Color(0xff4a4540),
                          size: 28.0,
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(20),
                          backgroundColor: Colors.white,
                        ),
                        onPressed: setCustomQuote,
                        child: const Icon(
                          Icons.edit,
                          color: Color(0xff4a4540),
                          size: 28.0,
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(20),
                          backgroundColor: Colors.white,
                        ),
                        onPressed: () {
                          Clipboard.setData(
                              ClipboardData(text: '$quote - $speaker'))
                              .then((_) {
                            if (mounted) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Quote copied!'),
                                  ),
                                );
                              });
                            }
                          });
                        },
                        child: const Icon(
                          Icons.copy,
                          color: Color(0xff4a4540),
                          size: 28.0,
                        ),
                      ),
                    ],
                  ),
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