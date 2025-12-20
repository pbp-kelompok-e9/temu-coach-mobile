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
    
    // --- FIX FINAL: PAKAI FULL URL (HTTPS) ---
    // Jangan pake '/reviews/...' doang. Wajib lengkap biar ga nyasar.
    final url = 'https://erico-putra-temucoach.pbp.cs.ui.ac.id/reviews/check/booking/$bookingId/'; 

    try {
      debugPrint("🔍 REQUESTING: $url");
      final resp = await request.get(url);
      
      debugPrint("✅ SUCCESS JSON: $resp");
      
      // Parse data
      hasReviewed = resp['has_review'] == true;
      
      if (hasReviewed && resp['review'] != null) {
         // Masukin data ke userReview biar form terisi otomatis
         final reviewData = resp['review'];
         userReviewId = reviewData['id'];
         userReview = ReviewModel(
            id: reviewData['id'],
            coach: "", // Dummy, ga penting disini
            user: "",  // Dummy
            rate: reviewData['rate'] ?? 0,
            review: reviewData['review'],
            createdAt: DateTime.now(),
            updatedAt: DateTime.now()
         );
      } else {
         userReview = null;
         userReviewId = null;
      }

    } catch (e) {
      debugPrint("❌ ERROR CHECK REVIEW: $e");
      hasReviewed = false;
      userReview = null;
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

  // lib/providers/review_provider.dart

  Future<bool> deleteReview() async {
    if (userReviewId == null) {
      debugPrint("❌ DELETE ERROR: userReviewId is null");
      return false;
    }

    // --- FIX: USE FULL URL (HTTPS) ---
    final url = 'https://erico-putra-temucoach.pbp.cs.ui.ac.id/reviews/delete/$userReviewId/';

    try {
      debugPrint("🗑️ DELETING REVIEW AT: $url");
      
      // Use 'post' as your backend expects POST for deletion
      // You can pass an empty body map {} if required by the library
      final resp = await request.post(url, {});

      debugPrint("✅ DELETE RESPONSE: $resp");

      // Check for success flag from Django response
      if (resp['success'] == true) {
        hasReviewed = false;
        userReview = null;
        userReviewId = null;
        notifyListeners();
        return true;
      } else {
        debugPrint("❌ DELETE FAILED: ${resp['error']}");
        error = resp['error'];
        return false;
      }
    } catch (e) {
      debugPrint("❌ DELETE EXCEPTION: $e");
      return false;
    }
  }

  // review_provider.dart

  Future<void> fetchReviewsByCoach(int coachId) async {
    loading = true;
    error = null;
    notifyListeners();

    // --- SOLUSI: PAKAI FULL URL (HTTPS) ---
    // Jangan pake '/reviews/...' doang. Tembak langsung ke jantung servernya.
    final url = 'https://erico-putra-temucoach.pbp.cs.ui.ac.id/reviews/get_reviews_by_coach/$coachId/';
    
    debugPrint("🕵️ [DEBUG] Fetching Full URL: $url");

    try {
      final resp = await request.get(url);

      debugPrint("📦 [DEBUG] Raw Response: $resp");

      if (resp['status'] == 'success') {
        final List data = resp['reviews'] ?? [];
        
        coachReviews = data.map((e) {
          try {
            return ReviewModel.fromJson(e);
          } catch (err) {
            debugPrint("💥 Parsing Error: $err");
            throw err;
          }
        }).toList();
        
        totalReviews = coachReviews.length;
        
        if (totalReviews > 0) {
          final totalRate = coachReviews.fold<int>(0, (sum, r) => sum + r.rate);
          averageRating = totalRate / totalReviews;
        } else {
          averageRating = 0.0;
        }
      } else {
        coachReviews = [];
      }
    } catch (e) {
      debugPrint("❌ [DEBUG] ERROR: $e");
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