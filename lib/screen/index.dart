import 'package:flutter/material.dart';
import 'package:zerolens100/screen/camera.dart';

genButtonStyle() {
  return ButtonStyle(
    foregroundColor:
        MaterialStateProperty.resolveWith((Set<MaterialState> states) {
      return states.contains(MaterialState.disabled) ? null : Colors.white;
    }),
    backgroundColor:
        MaterialStateProperty.resolveWith((Set<MaterialState> states) {
      return states.contains(MaterialState.disabled) ? null : Colors.pink;
    }),
  );
}

class ScreenIndex extends StatelessWidget {
  const ScreenIndex({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("🥼 0to100 7-Segment OCR Camera"),
      ),
      body: Container(
        padding: const EdgeInsets.all(8),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              Text('선택 가능한 옵션', style: Theme.of(context).textTheme.headline4),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      style: genButtonStyle(),
                      child: const Text('📷 세그먼트 OCR 카메라'),
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const ScreenCamera()));
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
