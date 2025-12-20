import 'package:pbp_django_auth/pbp_django_auth.dart';

class CoachAPI {
  final CookieRequest request;

  CoachAPI(this.request);

  // GET coach profile
  Future<Map<String, dynamic>> getCoachProfile() async {
    final response = await request.get("/coach/api/coach-profile/");
    return Map<String, dynamic>.from(response);
  }

  // GET schedule list
  Future<List<dynamic>> getSchedules() async {
    final response = await request.get("/coach/api/schedule/");
    return response;
  }

  // POST add schedule
  Future<Map<String, dynamic>> addSchedule(
      String tanggal, String jamMulai, String jamSelesai) async {
    final response = await request.post(
      "/coach/add-schedule/",
      {
        "tanggal": tanggal,
        "jam_mulai": jamMulai,
        "jam_selesai": jamSelesai,
      },
    );
    return response;
  }

  // DELETE schedule
  Future<bool> deleteSchedule(int id) async {
    final response = await request.post("/coach/delete_schedule/$id/", {});
    return response['status'] == 'deleted';
  }

  // POST update coach profile
  Future<bool> updateCoachProfile(Map<String, String> data) async {
    final response =
        await request.post("/coach/update_coach_profile/", data);
    return response['status'] == 'success';
  }
}
