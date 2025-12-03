import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreTestPage extends StatelessWidget {
  const FirestoreTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Firestore Test")),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            final uid = FirebaseAuth.instance.currentUser!.uid;

            await FirebaseFirestore.instance
                .collection('users')
                .doc(uid)
                .set({
              'name': 'Hung',
              'time': DateTime.now(),
            });

            print("DONE");
          },
          child: const Text("Test Firestore"),
        ),
      ),
    );
  }
}
