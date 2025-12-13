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

  List<ReviewModel> coachReviews = [];

  Future<void> checkReviewForBooking(int bookingId) async {
    loading = true;
    error = null;

    try {
      final resp = await request.get('/reviews/check/booking/$bookingId/');
      hasReviewed = resp['has_reviewed'] == true;
      if (hasReviewed) {
        userReviewId = resp['review']['id'];
        userReview = ReviewModel(
          coach: '',
          user: '',
          rate: resp['review']['rate'],
          review: resp['review']['review'],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      } else {
        userReview = null;
        userReviewId = null;
      }
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> createReview(int bookingId, int rate, String? review) async {
    try {
      final resp = await request.post('reviews/create/booking/$bookingId/', {
        'rate': rate.toString(),
        'review': review ?? '',
      });

      if (resp['success'] == true) {
        await checkReviewForBooking(bookingId);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateReview(int rate, String? review) async {
    if (userReviewId == null) {
      return false;
    }

    try {
      final resp = await request.post('/reviews/update/$userReviewId/', {
        'rate': rate.toString(),
        'review': review ?? '',
      });
      return resp['success'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteReview() async {
    if (userReviewId == null) {
      return false;
    }

    try {
      final resp = await request.post('/reviews/delete/$userReviewId/', {});

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
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
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
