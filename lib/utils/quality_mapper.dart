String _normalizeQuality(String quality) {
  // Map display quality to API quality string
  switch (quality.trim().toLowerCase()) {
    case "low (12 kbps)":
      return "12kbps";
    case "low (48 kbps)":
      return "48kbps";
    case "low (96 kbps)":
      return "96kbps";
    case "high (160 kbps)":
      return "160kbps";
    case "super (320 kbps)":
    case "high (320 kbps)":
      return "320kbps";
    default:
      // fallback: try to extract the numeric value
      final match = RegExp(r'(\d+)\s*kbps').firstMatch(quality.toLowerCase());
      if (match != null) {
        return "${match.group(1)}kbps";
      }
      return quality.trim();
  }
}
