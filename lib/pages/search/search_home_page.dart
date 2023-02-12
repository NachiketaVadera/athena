import 'package:athena/pages/search/result_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SearchHome extends StatefulWidget {
  const SearchHome({super.key});

  @override
  State<SearchHome> createState() => _SearchHomeState();
}

class _SearchHomeState extends State<SearchHome> {
  final textController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          children: [
            CupertinoSearchTextField(controller: textController, style: const TextStyle(color: Colors.white)),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  Feedback.forTap(context);

                  final text = textController.text;

                  if (text.isEmpty) {
                    notify('search cannot be empty');
                  } else {
                    Navigator.of(context).push(
                      CupertinoPageRoute(builder: (_) => SearchResultPage(text.toLowerCase().trim())),
                    );
                  }
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('search'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void notify(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
