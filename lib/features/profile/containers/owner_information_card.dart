import 'package:flutter/material.dart';

import '../widgets/profile_info_row.dart';

class OwnerInformationCard
    extends StatelessWidget {
  static const Color softBlack =
      Color(0xFF303030);

  final String mobileNumber;
  final String ownerName;
  final String ownerAge;
  final String ownerGender;
  final String ownerUid;
  final String memberSince;

  final VoidCallback onChangeMobile;
  final VoidCallback onCopyUid;

  const OwnerInformationCard({
    super.key,
    required this.mobileNumber,
    required this.ownerName,
    required this.ownerAge,
    required this.ownerGender,
    required this.ownerUid,
    required this.memberSince,
    required this.onChangeMobile,
    required this.onCopyUid,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(20),

        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset:
                const Offset(0, 3),
          ),
        ],
      ),

      child: Column(
        children: [
          ProfileInfoRow(
            icon: Icons.phone_outlined,
            title: 'Mobile Number',
            value: mobileNumber,

            trailing: OutlinedButton(
              onPressed: onChangeMobile,

              style:
                  OutlinedButton.styleFrom(
                foregroundColor:
                    softBlack,

                side:
                    const BorderSide(
                  color: softBlack,
                  width: 1.2,
                ),

                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 9,
                ),

                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    20,
                  ),
                ),
              ),

              child: const Text(
                'Change',
                style: TextStyle(
                  color: softBlack,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ),
          ),

          _divider(),

          ProfileInfoRow(
            icon: Icons.person_outline,
            title: 'Full Name',
            value: ownerName,
          ),

          _divider(),

          ProfileInfoRow(
            icon: Icons.calendar_month_outlined,
            title: 'Age',
            value: ownerAge,
          ),

          _divider(),

          ProfileInfoRow(
            icon: Icons.people_outline,
            title: 'Gender',
            value: ownerGender,
          ),

          _divider(),

          ProfileInfoRow(
            icon: Icons.badge_outlined,
            title: 'Owner UID',
            value: ownerUid,
            trailing: _copyButton(),
          ),

          _divider(),

          ProfileInfoRow(
            icon: Icons.event_outlined,
            title: 'Member Since',
            value: memberSince,
          ),
        ],
      ),
    );
  }

  Widget _copyButton() {
    return Material(
      color: Colors.transparent,

      child: InkWell(
        onTap: onCopyUid,

        borderRadius:
            BorderRadius.circular(50),

        child: Container(
          width: 40,
          height: 40,

          decoration: BoxDecoration(
            color:
                softBlack.withOpacity(0.08),

            shape: BoxShape.circle,

            border: Border.all(
              color:
                  softBlack.withOpacity(0.55),
              width: 1.1,
            ),
          ),

          child: const Icon(
            Icons.copy_rounded,
            color: softBlack,
            size: 19,
          ),
        ),
      ),
    );
  }

  Widget _divider() {
    return Divider(
      height: 1,
      indent: 16,
      endIndent: 16,
      color: Colors.grey.shade200,
    );
  }
}
