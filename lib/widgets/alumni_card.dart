import 'package:flutter/material.dart';
import '../models/user_model.dart';

class AlumniCard extends StatelessWidget {
  final UserModel alumni;
  final VoidCallback onTap;

  const AlumniCard({
    super.key,
    required this.alumni,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          child: Text(alumni.name[0]),
        ),
        title: Text(alumni.name),
        subtitle: Text(
          "${alumni.designation} • ${alumni.company}",
        ),
      ),
    );
  }
}
