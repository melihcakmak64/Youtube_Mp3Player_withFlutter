import 'package:flutter/material.dart';

import 'package:youtube_downloader/view/ResultPage.dart';

class HomePage extends StatelessWidget {
  final TextEditingController searchController = TextEditingController();

  HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Youtube Downloader')),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: SizedBox(
                    width: 300,
                    child: Image.asset("assets/youtube.png"),
                  ),
                ),
                const SizedBox(height: 50),
                TextField(
                  controller: searchController,
                  decoration: const InputDecoration(
                    labelText: 'Link or title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20.0),
                ElevatedButton(
                  onPressed: () {
                    String searchTerm = searchController.text;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ResultPage(searchTerm: searchTerm),
                      ),
                    );
                  },
                  child: const Text('Search'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
