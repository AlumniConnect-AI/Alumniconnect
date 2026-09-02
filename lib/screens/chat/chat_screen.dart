import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/chat_service.dart';
import '../../services/upload_service.dart';
import '../../config/theme.dart';
import '../alumni/alumni_profile_screen.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String peerId;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.peerId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ctrl = TextEditingController();
  final scrollCtrl = ScrollController();
  final uid = FirebaseAuth.instance.currentUser!.uid;
  bool isUploading = false;

  @override
  void initState() {
    super.initState();
    _setOnline(true);
  }

  @override
  void dispose() {
    _setOnline(false);
    ctrl.dispose();
    scrollCtrl.dispose();
    super.dispose();
  }

  void _setOnline(bool online) {
    FirebaseFirestore.instance.collection('users').doc(uid).update({
      'online': online,
      'lastSeen': FieldValue.serverTimestamp(),
      'typingTo': null,
    }).catchError((_) {});
  }

  void _setTyping(bool typing) {
    FirebaseFirestore.instance.collection('users').doc(uid).update({
      'typingTo': typing ? widget.peerId : null,
    }).catchError((_) {});
  }

  Future<void> _confirmDelete(String messageId) async {
    final theme = Theme.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Delete Message"),
        content: const Text("Do you want to delete this message?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ChatService.deleteMessage(widget.chatId, messageId);
    }
  }

  Future<void> _sendImage(File imageFile) async {
    setState(() => isUploading = true);
    try {
      final url = await UploadService.uploadImage(imageFile);
      if (url.isNotEmpty) {
        await ChatService.sendFile(
          chatId: widget.chatId,
          receiverId: widget.peerId,
          fileUrl: url,
          fileName: "Image",
          type: "image",
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Upload Error: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => isUploading = false);
    }
  }

  Future<void> _sendDocument(File file) async {
    setState(() => isUploading = true);
    try {
      final url = await UploadService.uploadDocument(file);
      if (url.isNotEmpty) {
        await ChatService.sendFile(
          chatId: widget.chatId,
          receiverId: widget.peerId,
          fileUrl: url,
          fileName: file.path.split('/').last,
          type: "document",
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Upload Error: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => isUploading = false);
    }
  }

  Future<void> _pickImage() async {
    final pickedImage = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedImage != null) {
      await _sendImage(File(pickedImage.path));
    }
  }

  Future<void> _pickFile() async {
    final res = await FilePicker.platform.pickFiles();
    if (res != null && res.files.single.path != null) {
      final pickedFile = File(res.files.single.path!);
      await _sendDocument(pickedFile);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: _chatHeader(),
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (isUploading)
              const LinearProgressIndicator(minHeight: 2, color: AppColors.primary),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: ChatService.messages(widget.chatId),
                builder: (_, snap) {
                  if (!snap.hasData) return const SizedBox();

                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    ChatService.markRead(widget.chatId);
                    if (scrollCtrl.hasClients) {
                      scrollCtrl.animateTo(
                        scrollCtrl.position.maxScrollExtent,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      );
                    }
                  });

                  final messages = snap.data!.docs;

                  return ListView.builder(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.all(12),
                    itemCount: messages.length,
                    itemBuilder: (_, i) {
                      final m = messages[i].data() as Map<String, dynamic>;
                      final isMe = m['senderId'] == uid;
                      final messageId = messages[i].id;

                      return GestureDetector(
                        onLongPress: isMe ? () => _confirmDelete(messageId) : null,
                        child: Align(
                          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: Column(
                            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                padding: const EdgeInsets.all(12),
                                constraints: BoxConstraints(
                                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                                ),
                                decoration: BoxDecoration(
                                  color: isMe
                                      ? AppColors.primary.withOpacity(0.2)
                                      : theme.cardColor,
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(16),
                                    topRight: const Radius.circular(16),
                                    bottomLeft: Radius.circular(isMe ? 16 : 0),
                                    bottomRight: Radius.circular(isMe ? 0 : 16),
                                  ),
                                  border: isMe ? null : Border.all(color: theme.dividerColor),
                                ),
                                child: _messageContent(m),
                              ),
                              if (isMe)
                                Padding(
                                  padding: const EdgeInsets.only(right: 4, bottom: 4),
                                  child: Icon(
                                    m['isRead'] == true ? Icons.done_all : Icons.done,
                                    size: 14,
                                    color: m['isRead'] == true ? AppColors.primary : theme.textTheme.bodySmall?.color,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: theme.cardColor,
                border: Border(top: BorderSide(color: theme.dividerColor)),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.image_outlined, color: AppColors.primary),
                    onPressed: isUploading ? null : _pickImage,
                  ),
                  IconButton(
                    icon: const Icon(Icons.attach_file_outlined, color: AppColors.primary),
                    onPressed: isUploading ? null : _pickFile,
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: theme.scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: ctrl,
                        enabled: !isUploading,
                        onChanged: (v) => _setTyping(v.isNotEmpty),
                        decoration: const InputDecoration(
                          hintText: "Type a message",
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: isUploading ? null : () {
                      if (ctrl.text.trim().isEmpty) return;
                      ChatService.sendText(
                        chatId: widget.chatId,
                        receiverId: widget.peerId,
                        text: ctrl.text.trim(),
                      );
                      ctrl.clear();
                      _setTyping(false);
                    },
                    child: CircleAvatar(
                      backgroundColor: isUploading ? Colors.grey : AppColors.primary,
                      radius: 22,
                      child: const Icon(Icons.send, color: Colors.black, size: 20),
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

  Widget _chatHeader() {
    final theme = Theme.of(context);
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(widget.peerId).snapshots(),
      builder: (_, snap) {
        if (!snap.hasData) return const Text("Chat");

        final u = snap.data!.data() as Map<String, dynamic>? ?? {};
        final name = u['name'] ?? "User";
        final photoUrl = u['photoURL'] as String?;
        final online = u['online'] == true;
        final typing = u['typingTo'] == uid;
        final lastSeen = u['lastSeen'] as Timestamp?;
        final isMentor = u['isMentor'] == true;

        String status;
        if (typing) {
          status = "typing...";
        } else if (online) {
          status = "online";
        } else if (lastSeen != null) {
          status = "last seen ${_timeAgo(lastSeen)}";
        } else {
          status = "offline";
        }

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AlumniProfileScreen(userId: widget.peerId),
              ),
            );
          },
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primary.withOpacity(0.1),
                backgroundImage: photoUrl != null && photoUrl.isNotEmpty 
                    ? NetworkImage(photoUrl) 
                    : null,
                child: (photoUrl == null || photoUrl.isEmpty)
                    ? Text(
                        name.isNotEmpty ? name[0].toUpperCase() : "U",
                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        name,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      if (isMentor) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.verified, color: AppColors.primary, size: 16),
                      ],
                    ],
                  ),
                  Text(
                    status,
                    style: TextStyle(
                      fontSize: 12,
                      color: typing || online ? AppColors.primary : theme.textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  Widget _messageContent(Map<String, dynamic> m) {
    if (m['type'] == 'image') {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          m['fileUrl'],
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const SizedBox(
              width: 200,
              height: 200,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          },
          errorBuilder: (_, __, ___) => Container(
            width: 200,
            height: 200,
            color: Colors.grey[300],
            child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
          ),
        ),
      );
    }

    if (m['type'] == 'file' || m['type'] == 'document') {
      return InkWell(
        onTap: () => launchUrl(Uri.parse(m['fileUrl']), mode: LaunchMode.externalApplication),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.insert_drive_file, color: AppColors.primary),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                m['fileName'] ?? "Document",
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(decoration: TextDecoration.underline),
              ),
            ),
          ],
        ),
      );
    }

    return Text(
      m['text'] ?? "",
      style: const TextStyle(fontSize: 15),
    );
  }

  String _timeAgo(Timestamp ts) {
    final diff = DateTime.now().difference(ts.toDate());
    if (diff.inMinutes < 1) return "just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    return "${diff.inDays}d ago";
  }
}
