class MyQRCodeSheet extends StatelessWidget {
  const MyQRCodeSheet({super.key});

  static const String qrData = 'ABC123';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 20),

              const Text(
                'My QR Code',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),

              IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.close),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              color: const Color(0xfff8fafc),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xffcbd5e1),
              ),
            ),
            child: const Icon(
              Icons.qr_code_2,
              size: 120,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 15),

          const Text(
            qrData,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 12),

          const Text(
            "Use your smartphone's camera or a QR code reader app to scan the QR code above.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Color(0xff6b7280),
              height: 1.5,
            ),
          ),

          const SizedBox(height: 22),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
          ),
        ],
      ),
    );
  }
}
