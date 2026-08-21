class InstaWalkContainer extends StatefulWidget {
  final VoidCallback? onWalkerFound;
  final bool fullScreen;

  const InstaWalkContainer({
    super.key,
    this.onWalkerFound,
    this.fullScreen = false,
  });

  @override
  State<InstaWalkContainer> createState() =>
      _InstaWalkContainerState();
}
