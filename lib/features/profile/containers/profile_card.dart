import 'package:flutter/material.dart';

class ProfileCard extends StatelessWidget {
  static const Color orange =
      Color(0xFFF4511E);

  static const Color lightOrange =
      Color(0xFFFFF1E8);

  final String ownerName;

  const ProfileCard({
    super.key,
    required this.ownerName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.fromLTRB(
        16,
        20,
        16,
        20,
      ),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(22),

        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(0.07),
            blurRadius: 14,
            offset:
                const Offset(0, 4),
          ),
        ],
      ),

      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.center,

        children: [
          Container(
            width: 112,
            height: 112,

            decoration:
                const BoxDecoration(
              shape: BoxShape.circle,
              color: lightOrange,
            ),

            child: const Icon(
              Icons.person_rounded,
              color: orange,
              size: 58,
            ),
          ),

          const SizedBox(width: 15),

          Expanded(
            child: SizedBox(
              height: 112,

              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    right: 70,
                    top: 24,

                    child: Text(
                      ownerName,

                      maxLines: 2,

                      overflow:
                          TextOverflow.ellipsis,

                      style:
                          const TextStyle(
                        fontSize: 22,
                        fontWeight:
                            FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),

                  Positioned(
                    right: 0,
                    top: 8,

                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 6,
                      ),

                      decoration:
                          BoxDecoration(
                        color:
                            const Color(
                          0xFFEFFAF1,
                        ),

                        borderRadius:
                            BorderRadius.circular(
                          10,
                        ),

                        border: Border.all(
                          color:
                              Colors.green.shade200,
                        ),
                      ),

                      child: const Row(
                        mainAxisSize:
                            MainAxisSize.min,

                        children: [
                          Icon(
                            Icons.verified_rounded,
                            color: Colors.green,
                            size: 17,
                          ),

                          SizedBox(width: 5),

                          Text(
                            'Verified Owner',
                            style:
                                TextStyle(
                              color:
                                  Colors.green,
                              fontSize: 11.5,
                              fontWeight:
                                  FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
