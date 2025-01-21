import 'package:get/get.dart';
import 'package:w0001/controller/calendar_controller.dart';
import 'package:w0001/controller/place_list_controller.dart';
import 'package:w0001/controller/worker_controller.dart';

class FetchData {
  static Future<void> fetchAllData() async {
    CalendarController calendarController = Get.find<CalendarController>();
    WorkerController workerController = Get.find<WorkerController>();
    PlaceListController placesController = Get.find<PlaceListController>();

    calendarController.fetchTotalCost();
    calendarController.fetchAllEvents();
    workerController.fetchWorkCost();
    placesController.fetchAllPlace();
    workerController.fetchWorkerInfo();
    workerController.checkboxStates = {};
  }
}

const List<String> categoryList = [
  '식대',
  '숙박',
  '유류비',
  '철물',
  '목재',
  '금속',
  '전기',
  '조명',
  '페인트',
  '설비',
  '타일',
  '공조',
  '소방',
  '유리',
  '조경',
  '필름',
  '사인물',
  '철거',
  '청소',
  '기타주문제작',
  '기타경비',
  '개인경비',
];
