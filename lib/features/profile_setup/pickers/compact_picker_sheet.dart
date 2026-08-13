import 'package:flutter/material.dart';

class CompactPickerSheet
    extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<String> items;
  final String? selected;
  final ValueChanged<String> onSelected;

  const CompactPickerSheet({
    super.key,
    required this.title,
    required this.icon,
    required this.items,
    required this.selected,
    required this.onSelected,
  });

  static const Color orange =
      Color(0xFFF4511E);

  static const Color lightOrange =
      Color(0xFFFFF1E8);

  static const Color textGrey =
      Color(0xFF707070);

  @override
  Widget build(BuildContext context) {
    final height =
        MediaQuery.of(context).size.height;

    return SizedBox(
      height: height * 0.35,
      child: SafeArea(
        child: Padding(
          padding:
              const EdgeInsets.fromLTRB(
            20,
            12,
            20,
            10,
          ),
          child: Column(
            children: [
              Container(
                width: 45,
                height: 5,
                decoration:
                    BoxDecoration(
                  color:
                      Colors.grey.shade300,
                  borderRadius:
                      BorderRadius.circular(
                    10,
                  ),
                ),
              ),

              const SizedBox(height: 13),

              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration:
                        const BoxDecoration(
                      color: lightOrange,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      color: orange,
                      size: 21,
                    ),
                  ),

                  const SizedBox(width: 11),

                  Expanded(
                    child: Text(
                      title,
                      style:
                          const TextStyle(
                        fontSize: 19,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 7),

              Expanded(
                child:
                    ListView.separated(
                  physics:
                      const BouncingScrollPhysics(),
                  padding:
                      const EdgeInsets.only(
                    top: 3,
                    bottom: 8,
                  ),
                  itemCount:
                      items.length,
                  separatorBuilder:
                      (_, __) =>
                          const Divider(
                    height: 1,
                  ),
                  itemBuilder:
                      (context, index) {
                    final item =
                        items[index];

                    final isSelected =
                        item == selected;

                    return SizedBox(
                      height: 48,
                      child: ListTile(
                        dense: true,
                        contentPadding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 2,
                        ),
                        onTap: () =>
                            onSelected(item),
                        leading: Icon(
                          isSelected
                              ? Icons
                                  .radio_button_checked_rounded
                              : Icons
                                  .radio_button_off_rounded,
                          color: isSelected
                              ? orange
                              : Colors.grey,
                          size: 21,
                        ),
                        title: Text(
                          item,
                          style:
                              TextStyle(
                            fontSize: 14.5,
                            fontWeight:
                                isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                          ),
                        ),
                        trailing:
                            isSelected
                                ? const Icon(
                                    Icons.check_rounded,
                                    color: orange,
                                    size: 21,
                                  )
                                : null,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
