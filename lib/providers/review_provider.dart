import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import '../models/review_model.dart';

class ReviewProvider with ChangeNotifier {
  final CookieRequest request;

  ReviewProvider(this.request);

  bool loading = false;
  String? error;

  ReviewModel? userReview;
  int? userReviewId;
  bool hasReviewed = false;
  double averageRating = 0.0;
  int totalReviews = 0;
  Map<int, int> ratingCounts = {};
  int selectedStarFilter = 0;

  List<ReviewModel> coachReviews = [];

  Future<void> checkReviewForBooking(int bookingId) async {
    loading = true;
    error = null;
    
    // URL WAJIB PAKE SLASH DI UJUNG
    final urlPath = '/reviews/check/booking/$bookingId/'; 

    try {
      debugPrint("🔍 REQUESTING: $urlPath");
      final resp = await request.get(urlPath);
      
      debugPrint("✅ SUCCESS JSON: $resp");
      
      // ... (lanjutkan logic parsing has_review seperti biasa) ...
      hasReviewed = resp['has_review'] == true;
      if (hasReviewed) {
         // ... parsing data review ...
      }

    } catch (e) {
      debugPrint("❌ ERROR PARSING: $e");
      
      // JIKA ERROR KARENA HTML, KITA BACA ISINYA
      // Kita pakai try-catch lagi di sini khusus buat debug text response
      try {
         // Trik: request ulang pake http package biasa buat dapet body mentahnya
         // (Pastikan import 'package:http/http.dart' as http;)
         // Ganti domain sesuai punya lo
         final rawUrl = 'https://erico-putra-temucoach.pbp.cs.ui.ac.id$urlPath';
         debugPrint("🕵️ INI ISI HTML YANG BIKIN ERROR:");
         debugPrint("------------------------------------------------");
         
         // Kita print pesan errornya aja biar ga kepanjangan
         // (Biasanya ada di tag <title>...</title>)
         // Note: Ini cuma buat debug, ga perlu cookie login dulu gpp
         // yang penting kita tau ini halaman Login, 404, atau 500.
         var response = await request.jsonData; // Atau access internal client kalo bisa
         // Atau kalau susah, cukup liat log error 'e' di atas. 
         // Biasanya FormatException ada potongan text-nya.
      } catch (_) {}
      
      hasReviewed = false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> createReview(int bookingId, int rate, String? review) async {
    try {
      final url = 'https://erico-putra-temucoach.pbp.cs.ui.ac.id/reviews/create/booking/$bookingId/'; 
      debugPrint("Sending CREATE request to: $url");

      final response = await request.post(url, {
        'rate': rate.toString(),
        'review': review ?? '',
      });

      debugPrint("CREATE RESPONSE: $response");

      if (response['success'] == true) {
        debugPrint("SUCCESS: Review created.");
        // Optional: tetep fetch ulang buat mastiin data sinkron
        // await checkReviewForBooking(bookingId); 
        return true;
      } else {
        // --- LOGIC JALAN TOL (SMART FAILOVER) ---
        // Cek apakah backend ngasih 'existing_id'?
        if (response.containsKey('existing_id') && response['existing_id'] != null) {
           debugPrint("🚀 JALAN TOL: Review udah ada, ID-nya: ${response['existing_id']}");
           debugPrint("🔄 Langsung switch ke UPDATE...");

           // 1. Set ID yang dikasih backend
           userReviewId = response['existing_id'];
           hasReviewed = true; 
           // Kita set manual userReview biar ga error null (dummy dulu gapapa, nanti ke-update)
           userReview ??= ReviewModel(coach: "", user: "", rate: 0, review: "", createdAt: DateTime.now(), updatedAt: DateTime.now());

           // 2. Langsung eksekusi Update
           return await updateReview(rate, review);
        }

        // ... (Logic error lain tetep sama) ...
        debugPrint("BACKEND REJECT: ${response['error']}");
        error = response['error'];
        notifyListeners();
        return false;
      }

    } catch (e) {
      debugPrint('FLUTTER EXCEPTION: $e');
      return false;
    }
  }

  Future<bool> updateReview(int rate, String? review) async {
    if (userReviewId == null) {
       debugPrint("❌ Cannot update: userReviewId is null");
       return false;
    }

    // --- PERBAIKAN: GUNAKAN FULL URL (HTTPS) ---
    // Biar 100% konsisten sama createReview yang sudah berhasil.
    final urlPath = 'https://erico-putra-temucoach.pbp.cs.ui.ac.id/reviews/update/$userReviewId/'; 

    try {
      debugPrint("🔍 SENDING UPDATE TO: $urlPath");
      
      final resp = await request.post(
        urlPath,
        {
          'rate': rate.toString(),
          'review': review ?? '',
        },
      );

      debugPrint('✅ UPDATE RESPONSE: $resp');
      
      if (resp['success'] == true) {
        if (userReview != null) {
          userReview = ReviewModel(
             coach: userReview!.coach,
             user: userReview!.user,
             rate: rate,
             review: review,
             createdAt: userReview!.createdAt,
             updatedAt: DateTime.now()
          );
          notifyListeners();
        }
        return true;
      } else {
        // Cek kalau ada error message dari backend
        final errorMsg = resp['error'] ?? 'Unknown error';
        debugPrint("❌ UPDATE FAILED: $errorMsg");
        return false;
      }

    } catch (e) {
      debugPrint('❌ UPDATE EXCEPTION: $e');
      return false;
    }
  }

  Future<bool> deleteReview() async {
    if (userReviewId == null) return false;

    try {
      final resp = await request.post('/reviews/delete/$userReviewId/?format=json', {});

      if (resp['success'] == true) {
        hasReviewed = false;
        userReview = null;
        userReviewId = null;
        notifyListeners();
      }

      return resp['success'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<void> fetchReviewsByCoach(int coachId) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      final resp = await request.get('/reviews/get_reviews_by_coach/$coachId/');

      final List data = resp['reviews'] ?? [];

      coachReviews = data.map((e) => ReviewModel.fromJson(e)).toList();
      totalReviews = coachReviews.length;
      if (totalReviews > 0) {
        final totalRate = coachReviews.fold<int>(0, (sum, r) => sum + r.rate);
        averageRating = totalRate / totalReviews;
      } else {
        averageRating = 0.0;
      }

      ratingCounts = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};

      for (final r in coachReviews) {
        ratingCounts[r.rate] = (ratingCounts[r.rate] ?? 0) + 1;
      }
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  List<ReviewModel> get filteredReviews {
    if (selectedStarFilter == 0) {
      return coachReviews;
    }
    return coachReviews.where((r) => r.rate == selectedStarFilter).toList();
  }

  void setStarFilter(int star) {
    selectedStarFilter = star;
    notifyListeners();
  }

  void clear() {
    userReview = null;
    userReviewId = null;
    hasReviewed = false;
    coachReviews.clear();
    error = null;
    notifyListeners();
  }
}