import 'package:flutter/material.dart';

class BreedPicker extends StatefulWidget {
  final List<String> breeds;
  final String? selectedBreed;
  final ValueChanged<String> onSelected;

  const BreedPicker({
    super.key,
    required this.breeds,
    required this.selectedBreed,
    required this.onSelected,
  });

  @override
  State<BreedPicker> createState() =>
      _BreedPickerState();
}

class _BreedPickerState
    extends State<BreedPicker> {
  static const Color orange =
      Color(0xFFF4511E);

  static const Color lightOrange =
      Color(0xFFFFF1E8);

  static const Color textGrey =
      Color(0xFF707070);

  final TextEditingController
      searchController =
      TextEditingController();

  String search = '';

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredBreeds =
        widget.breeds.where((breed) {
      return breed
          .toLowerCase()
          .contains(
            search.toLowerCase(),
          );
    }).toList();

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
                    child: const Icon(
                      Icons.pets_rounded,
                      color: orange,
                      size: 21,
                    ),
                  ),

                  const SizedBox(width: 11),

                  const Expanded(
                    child: Text(
                      'Choose Breed',
                      style:
                          TextStyle(
                        fontSize: 19,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              SizedBox(
                height: 44,
                child: TextField(
                  controller:
                      searchController,
                  onChanged: (value) {
                    setState(() {
                      search = value;
                    });
                  },
                  decoration:
                      InputDecoration(
                    prefixIcon:
                        const Icon(
                      Icons.search_rounded,
                      color: orange,
                      size: 21,
                    ),
                    hintText:
                        'Search breed...',
                    hintStyle:
                        const TextStyle(
                      fontSize: 13.5,
                    ),
                    contentPadding:
                        EdgeInsets.zero,
                    filled: true,
                    fillColor:
                        const Color(
                      0xFFF7F7F7,
                    ),
                    border:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(
                        13,
                      ),
                      borderSide:
                          BorderSide.none,
                    ),
                    focusedBorder:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(
                        13,
                      ),
                      borderSide:
                          const BorderSide(
                        color: orange,
                        width: 1.3,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 6),

              Align(
                alignment:
                    Alignment.centerLeft,
                child: Text(
                  search.isEmpty
                      ? 'All Breeds'
                      : '${filteredBreeds.length} breeds found',
                  style:
                      const TextStyle(
                    color: textGrey,
                    fontSize: 11.5,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ),

              Expanded(
                child:
                    filteredBreeds.isEmpty
                        ? const Center(
                            child: Text(
                              'No breed found',
                              style:
                                  TextStyle(
                                color:
                                    textGrey,
                                fontSize: 13,
                              ),
                            ),
                          )
                        : ListView.separated(
                            physics:
                                const BouncingScrollPhysics(),
                            padding:
                                const EdgeInsets
                                    .only(
                              top: 2,
                              bottom: 8,
                            ),
                            itemCount:
                                filteredBreeds
                                    .length,
                            separatorBuilder:
                                (_, __) =>
                                    const Divider(
                              height: 1,
                            ),
                            itemBuilder:
                                (context, index) {
                              final breed =
                                  filteredBreeds[
                                      index];

                              final selected =
                                  breed ==
                                      widget
                                          .selectedBreed;

                              return SizedBox(
                                height: 47,
                                child: ListTile(
                                  dense: true,
                                  contentPadding:
                                      const EdgeInsets
                                          .symmetric(
                                    horizontal: 2,
                                  ),
                                  onTap: () {
                                    widget
                                        .onSelected(
                                      breed,
                                    );
                                  },
                                  leading:
                                      Container(
                                    width: 34,
                                    height: 34,
                                    decoration:
                                        const BoxDecoration(
                                      color:
                                          lightOrange,
                                      shape:
                                          BoxShape
                                              .circle,
                                    ),
                                    child:
                                        const Icon(
                                      Icons
                                          .pets_rounded,
                                      color:
                                          orange,
                                      size: 17,
                                    ),
                                  ),
                                  title: Text(
                                    breed,
                                    style:
                                        TextStyle(
                                      fontSize:
                                          13.5,
                                      fontWeight:
                                          selected
                                              ? FontWeight
                                                  .w700
                                              : FontWeight
                                                  .w500,
                                    ),
                                  ),
                                  trailing:
                                      selected
                                          ? const Icon(
                                              Icons
                                                  .check_circle_rounded,
                                              color:
                                                  orange,
                                              size:
                                                  20,
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
