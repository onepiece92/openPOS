/// Returns up to 2-letter initials from a name, or null if blank.
String? initials(String? name) {
  if (name == null || name.trim().isEmpty) return null;
  return name
      .trim()
      .split(' ')
      .where((s) => s.isNotEmpty)
      .take(2)
      .map((s) => s[0].toUpperCase())
      .join();
}
