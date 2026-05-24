import 'package:flutter/material.dart';

class SecondScreen extends StatelessWidget {
  const SecondScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SubjectBloc, SubjectState>(
      builder: (context, state) {
        return Container(
          child: Center(
            child: Text(
              'Second Screen',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
        );
      },
    );
  }
}
