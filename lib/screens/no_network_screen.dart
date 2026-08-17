ElevatedButton.icon(
  onPressed: onRetry,
  icon: const Icon(
    Icons.refresh_rounded,
    size: 21,
  ),
  label: const Text(
    'Retry',
    style: TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w800,
    ),
  ),
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.black,
    foregroundColor: Colors.white,
    elevation: 4,
    shadowColor: Colors.black.withOpacity(0.20),
    padding: const EdgeInsets.symmetric(
      horizontal: 28,
      vertical: 13,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    ),
  ),
),
