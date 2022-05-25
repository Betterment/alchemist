import 'package:flutter/material.dart';

class ContactListTile extends StatelessWidget {
  const ContactListTile({
    super.key,
    required this.onPressed,
    required this.name,
    required this.email,
  })  : assert(name.length > 0, 'name must be non-empty'),
        assert(email.length > 0, 'email must be non-empty');

  final VoidCallback? onPressed;
  final String name;
  final String email;

  bool get _isEnabled => onPressed != null;

  /// Combines the first character of the [name]'s first and last names.
  String get _initials {
    final charsByPart = name.split(' ').map((part) => part.split('')).toList();
    final initialsBuffer = StringBuffer()..write(charsByPart[0][0]);
    if (charsByPart.length > 1) {
      initialsBuffer.write(charsByPart.last[0]);
    }
    return initialsBuffer.toString().toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: InkWell(
        onTap: onPressed,
        customBorder: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          enabled: _isEnabled,
          leading: CircleAvatar(
            backgroundColor: _isEnabled ? Colors.blue.shade900 : Colors.grey,
            foregroundColor: Colors.white,
            child: Text(_initials),
          ),
          title: Text(name),
          subtitle: Text(email),
        ),
      ),
    );
  }
}
