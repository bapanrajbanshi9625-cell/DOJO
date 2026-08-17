class DojoWalk extends StatelessWidget {
  const DojoWalk({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dojo',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        primarySwatch: Colors.orange,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.secondary,
        ),
      ),

      home: const NetworkMonitor(
        child: SplashScreen(),
      ),
    );
  }
}
