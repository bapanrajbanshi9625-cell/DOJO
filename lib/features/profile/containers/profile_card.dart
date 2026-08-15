import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ProfileCard extends StatefulWidget {
  static const Color orange = Color(0xFFF4511E);
  static const Color lightOrange = Color(0xFFFFF1E8);

  final String ownerName;

  const ProfileCard({
    super.key,
    required this.ownerName,
  });

  @override
  State<ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends State<ProfileCard> {
  File? _profileImage;

  final ImagePicker _picker = ImagePicker();

  Future<void> _changePhoto() async {
    try {
      final XFile? pickedFile =
          await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1200,
      );

      if (pickedFile == null) return;

      if (!mounted) return;

      setState(() {
        _profileImage = File(pickedFile.path);
      });
    } catch (e) {
      debugPrint(
        'Profile image error: $e',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to select profile photo.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),

      child: LayoutBuilder(
        builder: (
          BuildContext context,
          BoxConstraints constraints,
        ) {
          final bool compact =
              constraints.maxWidth < 340;

          final double photoSize =
              compact ? 88 : 96;

          return Row(
            crossAxisAlignment:
                CrossAxisAlignment.center,

            children: [
              // ======================================================
              // PROFILE PHOTO
              // ======================================================

              SizedBox(
                width: photoSize,
                height: photoSize,

                child: Stack(
                  clipBehavior: Clip.none,

                  children: [
                    Container(
                      width: photoSize,
                      height: photoSize,

                      decoration:
                          const BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            ProfileCard.lightOrange,
                      ),

                      child: ClipOval(
                        child: _profileImage != null
                            ? Image.file(
                                _profileImage!,
                                width: photoSize,
                                height: photoSize,
                                fit: BoxFit.cover,
                              )
                            : Icon(
                                Icons.person_rounded,
                                color:
                                    ProfileCard.orange,
                                size:
                                    compact ? 48 : 52,
                              ),
                      ),
                    ),

                    // ==================================================
                    // PHOTO EDIT BUTTON
                    // ==================================================

                    Positioned(
                      right: -2,
                      bottom: -2,

                      child: Material(
                        color:
                            ProfileCard.orange,
                        shape: const CircleBorder(),

                        child: InkWell(
                          onTap: _changePhoto,
                          customBorder:
                              const CircleBorder(),

                          child: const Padding(
                            padding:
                                EdgeInsets.all(7),

                            child: Icon(
                              Icons.camera_alt_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 14),

              // ======================================================
              // PROFILE DETAILS
              // ======================================================

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  mainAxisSize: MainAxisSize.min,

                  children: [
                    // ==================================================
                    // VERIFIED BADGE
                    // ==================================================

                    Container(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),

                      decoration:
                          BoxDecoration(
                        color:
                            const Color(0xFFEFFAF1),

                        borderRadius:
                            BorderRadius.circular(9),

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
                            size: 15,
                          ),

                          SizedBox(width: 4),

                          Text(
                            'Verified Owner',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 11,
                              fontWeight:
                                  FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // ==================================================
                    // OWNER NAME
                    // ==================================================

                    Text(
                      widget.ownerName.isEmpty
                          ? 'Owner'
                          : widget.ownerName,

                      maxLines: 2,

                      overflow:
                          TextOverflow.ellipsis,

                      style: TextStyle(
                        fontSize:
                            compact ? 19 : 21,
                        fontWeight:
                            FontWeight.w800,
                        color: Colors.black87,
                        height: 1.15,
                      ),
                    ),

                    const SizedBox(height: 5),

                    // ==================================================
                    // PROFILE LABEL
                    // ==================================================

                    Text(
                      'Dojo Owner Profile',
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,

                      style: TextStyle(
                        fontSize: compact ? 11 : 12,
                        color: Colors.grey.shade600,
                        fontWeight:
                            FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
