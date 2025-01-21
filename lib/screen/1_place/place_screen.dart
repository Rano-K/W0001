import 'package:date_picker_plus/date_picker_plus.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:w0001/controller/place_controller.dart';
import 'package:w0001/enums.dart';
import 'package:w0001/model/place_info_model.dart';
import 'package:w0001/model/total_cost_model.dart';
import 'package:w0001/screen/1_place/place_revenue_screen.dart';
import 'package:w0001/util/fetch_data.dart';
import 'package:w0001/util/funtions.dart';
import 'package:w0001/util/text_style.dart';
import 'package:w0001/widget/add_text_field.dart';
import 'package:w0001/widget/delete_dialog.dart';
import 'package:w0001/widget/save_dialog.dart';
import 'package:w0001/widget/total_cost_card.dart';
import 'package:w0001/widget/total_price_bar.dart';
import 'package:w0001/widget/segment_widget.dart';

class PlaceScreen extends GetView<PlaceController> {
  final PlaceInfoModel placeInfo;
  const PlaceScreen({super.key, required this.placeInfo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(placeInfo.pname),
        centerTitle: true,
        actions: [
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: () =>
                controller.exportAndSharePlaceInfoToExcel(placeInfo.pname),
            icon: Image.asset(
              'assets/images/excel_logo.png',
              height: 28,
              width: 28,
            ),
          ),
          IconButton(
            // visualDensity: VisualDensity.comfortable,
            onPressed: () async => Get.to(
              () => PlaceRevenueScreen(placeInfo: placeInfo),
            )?.then((value) =>
                Get.find<PlaceController>().resetRevenueTextContoller()),
            icon: Image.asset(
              'assets/images/add_money.png',
              height: 28,
              width: 28,
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size(MediaQuery.of(context).size.width, 45),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10, left: 10, right: 10),
            child: Column(
              children: [
                GetBuilder<PlaceController>(
                  builder: (controller) => Text(
                    formatDateTimeRangeToString(controller.dateTimeRange),
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey),
                  ),
                ),
                const SizedBox(height: 5),
                _selectDurationButtons(context),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          GetBuilder<PlaceController>(
            builder: (controller) => TotalPriceBar(
              totalCostList: controller.rangeFilterList,
              categoryTapCallbacks: controller.categoryTapCallbacks,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: GetBuilder<PlaceController>(
              builder: (controller) => Text(
                '${controller.selectedFilterType.category} ${getPrice(price: controller.selectedPrice)}',
                style: const TextStyle(fontSize: 17),
              ),
            ),
          ),
          Expanded(child: expenseList(context, controller.dateTimeRange.start)),
        ],
      ),
    );
  }

  Row _selectDurationButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          height: 30,
          child: GetBuilder<PlaceController>(
            builder: (controller) => ToggleButtons(
              borderWidth: 1,
              borderColor: const Color.fromARGB(255, 177, 176, 176),
              selectedBorderColor: const Color.fromARGB(255, 177, 176, 176),
              textStyle: bold14Style,
              borderRadius: BorderRadius.circular(5),
              isSelected: controller.toggleState,
              onPressed: (index) {
                controller
                    .changeDateTimeRange(index, context)
                    .then((value) => controller.closeAllSliders());
              },
              children: [
                toggleWidget(
                  width: (MediaQuery.of(context).size.width - 25) / 3,
                  height: 24,
                  child: const Text('기간 선택'),
                  icon: Icon(
                    Icons.calendar_month,
                    color: controller.selectedDayType == DayTpye.range
                        ? const Color.fromARGB(255, 5, 5, 5)
                        : const Color.fromARGB(255, 106, 116, 149),
                  ),
                ),
                toggleWidget(
                  height: 24,
                  width: (MediaQuery.of(context).size.width - 25) / 3,
                  child: const Text('전체 기간'),
                ),
                toggleWidget(
                  height: 24,
                  width: (MediaQuery.of(context).size.width - 25) / 3,
                  child: const Text('이번 달'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget expenseList(context, DateTime selectedDay) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      child: GetBuilder<PlaceController>(
        builder: (controller) => controller.filteredTotalCostList.isEmpty
            ? const Center(
                child: Text('지출 내역이 없습니다.'),
              )
            : GroupedListView(
                physics: const AlwaysScrollableScrollPhysics(),
                elements: controller.filteredTotalCostList,
                order: GroupedListOrder.DESC,
                groupBy: (element) => element.getDay,
                groupSeparatorBuilder: (value) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                      child: Text(
                        value,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
                itemBuilder: (context, element) =>
                    paymentList(context, element),
              ),
      ),
    );
  }

  Widget paymentList(context, TotalCostModel element) {
    return Slidable(
      closeOnScroll: true,
      startActionPane: element.category == 'w'
          ? ActionPane(
              motion: const DrawerMotion(),
              children: [
                SlidableAction(
                  autoClose: true,
                  borderRadius: BorderRadius.circular(10),
                  backgroundColor:
                      element.wcomplete == 1 ? Colors.blue : Colors.green,
                  icon: element.wcomplete == 1
                      ? Icons.autorenew_outlined
                      : Icons.check_circle,
                  label: element.wcomplete == 1 ? '미지급으로 변경' : '지급 완료',
                  onPressed: (context) => controller
                      .updateWComplete(element.wcomplete, element.id)
                      .then(
                        (value) => Get.dialog(
                          saveDialog(
                              text:
                                  '${element.wcomplete == 1 ? '미지급으로' : '완료로'} 변경되었습니다.'),
                        ),
                      ),
                ),
              ],
            )
          : null,
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        children: [
          SlidableAction(
            autoClose: true,
            borderRadius: BorderRadius.circular(10),
            backgroundColor: Colors.red,
            icon: Icons.delete,
            label: '삭제',
            onPressed: (context) => Get.dialog(
              deleteDialog(
                onPressed: () => controller
                    .deleteCost(element.category, element.id)
                    .then((value) {
                  FetchData.fetchAllData();
                  Get.back();
                }),
              ),
            ),
          ),
        ],
      ),
      child: Builder(
        builder: (context) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            controller.registerSlidable(context);
          });
          return InkWell(
            onTap: () {
              controller.selectedDropdownCategory = element.category;
              controller.mNameController.text = element.name;
              controller.mPriceController.text =
                  getPrice(price: element.price, isContainWon: false);
              controller.dialogDateTime = DateTime.parse(element.date);

              Get.dialog(
                editCostDialog(element, context),
              ).then((value) => controller.alertText = '');
            },
            child: TotalCostCard(
              category: element.category,
              name: element.name,
              price: element.price,
              wcomplete: element.wcomplete,
            ),
          );
        },
      ),
    );
  }

  Dialog editCostDialog(TotalCostModel element, context) {
    return Dialog(
      child: GetBuilder<PlaceController>(
        builder: (controller) => Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: const Color.fromARGB(255, 243, 243, 243),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 15),
                child: Text(
                  '수정',
                  style: bigStyle,
                ),
              ),
              TextButton.icon(
                onPressed: () async {
                  controller.dialogDateTime = await showDatePickerDialog(
                        context: context,
                        minDate: DateTime(2000),
                        maxDate: DateTime(2099),
                      ) ??
                      controller.dialogDateTime;
                  controller.update();
                },
                icon: const Icon(
                  Icons.date_range_outlined,
                  color: Color.fromARGB(255, 117, 154, 193),
                ),
                label: Text(
                  formatDateTimeWeekDayToString(controller.dialogDateTime),
                  style: smalldateStyle,
                ),
              ),
              Visibility(
                visible: element.category == 'w' ? false : true,
                child: SizedBox(
                  height: 60,
                  width: 230,
                  child: GetBuilder<PlaceController>(
                    builder: (controller) => DropdownSearch(
                      items: categoryList,
                      onChanged: (value) =>
                          controller.dropDownCategoryChangeAction(value!),
                      selectedItem: element.category,
                      dropdownDecoratorProps: DropDownDecoratorProps(
                        dropdownSearchDecoration: InputDecoration(
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 3),
                child: AddTextField(
                  tController: controller.mNameController,
                  labelText: '항목',
                  isPrice: false,
                  height: 60,
                  keyboardType: TextInputType.text,
                  readOnly: element.category == 'w' ? true : false,
                  onChanged: (value) {
                    controller.alertText = '';
                    controller.update();
                  },
                ),
              ),
              AddTextField(
                tController: controller.mPriceController,
                labelText: '금액',
                isPrice: true,
                height: 60,
                keyboardType: TextInputType.number,
                readOnly: false,
                onChanged: (value) {
                  controller.alertText = '';
                  controller.update();
                },
              ),
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Text(
                  controller.alertText,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () {
                      controller.alertText = '';
                      Get.back();
                    },
                    child: const Text(
                      '취소',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                  TextButton(
                    onPressed: () => controller
                        .updateCost(element.category, element.id,
                            controller.dialogDateTime.toString())
                        .then((value) => FetchData.fetchAllData()),
                    child: const Text('수정'),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
