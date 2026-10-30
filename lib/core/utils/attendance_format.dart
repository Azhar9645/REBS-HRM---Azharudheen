String? workedLabelFor(DateTime? checkIn, DateTime? checkOut) {
  if (checkIn == null || checkOut == null) return null;
  final worked = checkOut.difference(checkIn);
  final hours = worked.inHours;
  final minutes = worked.inMinutes % 60;
  return '${hours}h ${minutes.toString().padLeft(2, '0')}m worked';
}
