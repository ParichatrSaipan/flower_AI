import 'package:flutter/material.dart';
import 'home_screen.dart';

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('asset/start_screen.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 200),
                child: Image.asset(
                  'asset/logo.png',
                  width: 329,
                  height: 230,
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 150),
                    child: Container(
                      width: 348,
                      height: 75,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(23),
                        border: Border.all(
                          width: 0,
                          color: Colors.transparent,
                        ),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFFF2F2F2),
                              Color(0xFF818181),
                              Color(0xFFFFFFFF),
                            ],
                            stops: [0.0, 0.41, 1.0],
                          ),
                          borderRadius: BorderRadius.circular(23),
                        ),
                        padding: EdgeInsets.all(4.65),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Color.fromRGBO(214, 214, 214, 0.3),
                            borderRadius: BorderRadius.circular(18.35),
                          ),
                          child: TextButton(
                            onPressed: () {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (context) => const HomeScreen(showInstructions: true),
                                ),
                              );
                            },
                            style: TextButton.styleFrom(
                              textStyle: const TextStyle(
                                fontSize: 54,
                              ),
                              backgroundColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18.35),
                              ),
                              padding: EdgeInsets.zero,
                            ),
                            child: const Text(
                              "Let's start",
                              style: TextStyle(
                                fontFamily: 'Angsana New',
                                color: Colors.white,
                                height: 1.0,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

}

