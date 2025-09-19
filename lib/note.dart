import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mobilt_java24_kevin_lu_flutter_v3/main.dart';


class note extends StatefulWidget {
  const note({super.key, required this.title});

  final String title;

  @override
  State<note> createState() => _noteState();
}

class _noteState extends State<note> {
  final TextEditingController _noteController = TextEditingController();
  @override
  void initState() {
    super.initState();
    //_loadNotesList(); // load note when screen opens
  }
  FirebaseAuth auth = FirebaseAuth.instance;
  late final uid = auth.currentUser?.uid;

  bool _isCursive = false;
  bool _isBold = false;
  bool _isUnderline = false;

  String? _selectedNoteId;
  String _noteContent = '';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _loadNote(String noteId) async {
    if (uid == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('notes')
        .doc(uid)
        .collection('notes')
        .doc(noteId)
        .get();

    if (doc.exists) {
      final text = doc['text'] ?? '';
      setState(() {
        _selectedNoteId = noteId;
        _noteController.text = text;
      });
    }
  }


  Future<void> _saveNote() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final text = _noteController.text.trim();
    if (text.isEmpty) return;

    final title = _getFirstLine(text);

    final newNoteRef = FirebaseFirestore.instance
        .collection('notes')
        .doc(uid)
        .collection('notes')
        .doc();

    await newNoteRef.set({
      'text': text,
      'title': title,
      'timestamp': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Note saved')),
    );

    setState(() {
      _noteController.clear(); // Clear input after save
      _selectedNoteId = null;
    });
  }
  Future<void> _updateNote() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || _selectedNoteId == null) return;

    final text = _noteController.text.trim();
    if (text.isEmpty) return;

    final title = _getFirstLine(text);

    final noteRef = FirebaseFirestore.instance
        .collection('notes')
        .doc(uid)
        .collection('notes')
        .doc(_selectedNoteId);

    await noteRef.update({
      'text': text,
      'title': title,
      'timestamp': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Note updated')),
    );

    setState(() {
      _noteController.clear();
      _selectedNoteId = null;
    });
  }

  Future<void> _deleteNote() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || _selectedNoteId == null) return;

    final noteRef = FirebaseFirestore.instance
        .collection('notes')
        .doc(uid)
        .collection('notes')
        .doc(_selectedNoteId);

    await noteRef.delete();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Note deleted')),
    );

    setState(() {
      _noteController.clear();
      _selectedNoteId = null;
    });
  }



  String _getFirstLine(String text) {
    return text.split('\n').first.trim();
  }

  void _logOut(){
    auth.signOut();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const MyHomePage(title: "Log in")),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Signed out')),
    );
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveNote,
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _updateNote,
            tooltip: 'Update Note',
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteNote,
            tooltip: 'Delete Note',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logOut,
          ),
        ],
      ),
      body: SafeArea(
        child: Row(
          children: [
            // Sidebar
            Container(
              width: 100,
              color: Colors.grey[200],
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('notes')
                    .doc(uid)
                    .collection('notes')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final notes = snapshot.data!.docs;
                  return ListView.builder(
                    itemCount: notes.length,
                    itemBuilder: (context, index) {
                      final note = notes[index];
                      return ListTile(
                        title: Text(note['title'] ?? 'Untitled'),
                        selected: _selectedNoteId == note.id,
                        onTap: () => _loadNote(note.id),
                      );
                    },
                  );
                },
              ),
            ),

            // Note editor and styling controls
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    SizedBox(
                      height: 70,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: CheckboxListTile(
                              title: const Text('Cursive'),
                              value: _isCursive,
                              onChanged: (value) {
                                setState(() {
                                  _isCursive = value ?? false;
                                });
                              },
                              controlAffinity: ListTileControlAffinity.leading,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          Flexible(
                            child: CheckboxListTile(
                              title: const Text('Bold'),
                              value: _isBold,
                              onChanged: (value) {
                                setState(() {
                                  _isBold = value ?? false;
                                });
                              },
                              controlAffinity: ListTileControlAffinity.leading,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          Flexible(
                            child: CheckboxListTile(
                              title: const Text('Underline'),
                              value: _isUnderline,
                              onChanged: (value) {
                                setState(() {
                                  _isUnderline = value ?? false;
                                });
                              },
                              controlAffinity: ListTileControlAffinity.leading,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: TextField(
                        controller: _noteController,
                        maxLines: null,
                        expands: true,
                        keyboardType: TextInputType.multiline,
                        textAlignVertical: TextAlignVertical.top,
                        decoration: const InputDecoration(
                          labelText: 'Write your note here',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                        style: TextStyle(
                          fontStyle: _isCursive ? FontStyle.italic : FontStyle.normal,
                          fontWeight: _isBold ? FontWeight.bold : FontWeight.normal,
                          decoration: _isUnderline ? TextDecoration.underline : TextDecoration.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

    );
  }
}
