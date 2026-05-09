import 'package:flutter/material.dart';

class HowToPlayPage extends StatelessWidget {
  const HowToPlayPage({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFF1F2A44),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const SizedBox(height: 10),

            const Text(
              "Game Rules",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 8),

            Container(
              width: 140,
              height: 3,
              color: Colors.blueAccent,
            ),



            const SizedBox(height: 40),

            ruleItem(
              icon: Icons.emoji_events,
              title: "WIN",
              description: "Get 3 marks in a row.\nPlayer wins, game ends.",
              graphic: buildWinGraphic(),
            ),

            const Divider(color: Colors.white24, height: 40),

            ruleItem(
              icon: Icons.sentiment_dissatisfied,
              title: "DEFEAT",
              description: "Opponent gets 3 in a row.\nPlayer loses, game ends.",
              graphic: buildDefeatGraphic(),
            ),

            const Divider(color: Colors.white24, height: 40),

            ruleItem(
              icon: Icons.handshake,
              title: "DRAW",
              description: "Board fills, no 3 in a row.\nNo winner, game ends.",
              graphic: buildDrawGraphic(),
            ),

          ],
        ),
      ),
    );
  }

  Widget ruleItem({
    required IconData icon,
    required String title,
    required String description,
    required Widget graphic,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Icon(icon, color: Colors.amber, size: 28),

        const SizedBox(width: 14),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                description,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 10),

        graphic
      ],
    );
  }

  // WIN Graphic
  Widget buildWinGraphic() {
    return miniBoard([
      "O","O","O",
      "","X","",
      "X","",""
    ]);
  }

  // DEFEAT Graphic
  Widget buildDefeatGraphic() {
    return miniBoard([
      "X","","O",
      "X","O","",
      "X","",""
    ]);
  }

  // DRAW Graphic
  Widget buildDrawGraphic() {
    return miniBoard([
      "X","O","X",
      "O","X","O",
      "O","X","O"
    ]);
  }

  Widget miniBoard(List<String> values) {
    return SizedBox(
      width: 70,
      height: 70,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 9,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
        ),
        itemBuilder: (context, index) {
          return Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white24),
            ),
            child: Text(
              values[index],
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        },
      ),
    );
  }
}