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
    
    final url = 'https://erico-putra-temucoach.pbp.cs.ui.ac.id/reviews/check/booking/$bookingId/'; 

    try {
      final resp = await request.get(url);
      
      // Parse data
      hasReviewed = resp['has_review'] == true;
      
      if (hasReviewed && resp['review'] != null) {
         // Masukin data ke userReview biar form terisi otomatis
         final reviewData = resp['review'];
         userReviewId = reviewData['id'];
         userReview = ReviewModel(
            id: reviewData['id'],
            coach: "", 
            user: "",  
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

      final response = await request.post(url, {
        'rate': rate.toString(),
        'review': review ?? '',
      });

      if (response['success'] == true) {
        return true;
      } else {
        if (response.containsKey('existing_id') && response['existing_id'] != null) {

           userReviewId = response['existing_id'];
           hasReviewed = true; 
           
           userReview ??= ReviewModel(coach: "", user: "", rate: 0, review: "", createdAt: DateTime.now(), updatedAt: DateTime.now());

          
           return await updateReview(rate, review);
        }

        error = response['error'];
        notifyListeners();
        return false;
      }

    } catch (e) {
      return false;
    }
  }

  Future<bool> updateReview(int rate, String? review) async {
    if (userReviewId == null) {
       return false;
    }

    final urlPath = 'https://erico-putra-temucoach.pbp.cs.ui.ac.id/reviews/update/$userReviewId/'; 

    try {
      final resp = await request.post(
        urlPath,
        {
          'rate': rate.toString(),
          'review': review ?? '',
        },
      );
      
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
        return false;
      }

    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteReview() async {
    if (userReviewId == null) {
      return false;
    }

    final url = 'https://erico-putra-temucoach.pbp.cs.ui.ac.id/reviews/delete/$userReviewId/';

    try {
      final resp = await request.post(url, {});

      if (resp['success'] == true) {
        hasReviewed = false;
        userReview = null;
        userReviewId = null;
        notifyListeners();
        return true;
      } else {
        error = resp['error'];
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  Future<void> fetchReviewsByCoach(int coachId) async {
    loading = true;
    error = null;
    notifyListeners();

    final url = 'https://erico-putra-temucoach.pbp.cs.ui.ac.id/reviews/get_reviews_by_coach/$coachId/';

    try {
      final resp = await request.get(url);

      if (resp['status'] == 'success') {
        final List data = resp['reviews'] ?? [];
        
        coachReviews = data.map((e) {
          try {
            return ReviewModel.fromJson(e);
          } catch (err) {
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