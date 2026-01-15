import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

const String _tmdbImageBase = 'https://image.tmdb.org/t/p/w342';

class MovieDetailsScreen extends StatefulWidget {
  final dynamic movie;
  final Map<int, int> ratings;
  final Set<int> likes;
  final Set<int> watchlist;
  final Function(int, int) onRatingChanged;
  final Function(int) onLikeToggled;
  final Function(int) onWatchlistToggled;

  const MovieDetailsScreen({
    Key? key,
    required this.movie,
    required this.ratings,
    required this.likes,
    required this.watchlist,
    required this.onRatingChanged,
    required this.onLikeToggled,
    required this.onWatchlistToggled,
  }) : super(key: key);

  @override
  State<MovieDetailsScreen> createState() => _MovieDetailsScreenState();
}

class _MovieDetailsScreenState extends State<MovieDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    final movieId = (widget.movie['id'] as num).toInt();
    final title = widget.movie['title'] ?? widget.movie['name'] ?? '';
    final overview = widget.movie['overview'] ?? '';
    final releaseDate = widget.movie['release_date'] ?? '';
    final rating = widget.movie['vote_average'] ?? 0.0;
    final posterPath = widget.movie['poster_path'] as String?;
    final imageUrl = posterPath != null ? '$_tmdbImageBase$posterPath' : null;

    final isLiked = widget.likes.contains(movieId);
    final isInWatchlist = widget.watchlist.contains(movieId);
    final userRating = widget.ratings[movieId] ?? 0;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 0),
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          // Background blur
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                color: Colors.black54,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Container(color: Colors.black26),
                ),
              ),
            ),
          ),
          // Content
          Positioned(
            top: MediaQuery.of(context).size.height * 0.15,
            left: 0,
            right: 0,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Poster image with glow effect if liked
                    SizedBox(
                      height: 300,
                      width: 200,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Glow effect behind poster when liked
                          if (isLiked)
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.rectangle,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.red.withOpacity(0.6),
                                      blurRadius: 30,
                                      spreadRadius: 10,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          // Poster image
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child:
                                imageUrl != null
                                    ? Image.network(imageUrl, fit: BoxFit.cover)
                                    : Container(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Info container
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF23232B),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Release date and TMDB rating
                          Row(
                            children: [
                              Text(
                                releaseDate.isNotEmpty
                                    ? releaseDate.split('-')[0]
                                    : 'N/A',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Icon(
                                Icons.star,
                                color: const Color(0xFFFFD54F),
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${rating.toStringAsFixed(1)}/10',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Overview
                          Text(
                            overview,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 20),
                          // User rating stars
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'La tua valutazione',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: List.generate(5, (i) {
                                  final idx = i + 1;
                                  return GestureDetector(
                                    onTap: () {
                                      if (userRating == idx) {
                                        widget.onRatingChanged(movieId, 0);
                                      } else {
                                        widget.onRatingChanged(movieId, idx);
                                      }
                                      setState(() {});
                                    },
                                    child: Icon(
                                      idx <= userRating
                                          ? Icons.star
                                          : Icons.star_border,
                                      color:
                                          idx <= userRating
                                              ? const Color(0xFFFFD54F)
                                              : Colors.white54,
                                      size: 24,
                                    ),
                                  );
                                }),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // Action buttons
                          Row(
                            children: [
                              // Like button
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    widget.onLikeToggled(movieId);
                                    setState(() {});
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          isLiked
                                              ? Colors.red.withOpacity(0.3)
                                              : const Color(0xFF2A2A2F),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color:
                                            isLiked
                                                ? Colors.red.withOpacity(0.5)
                                                : Colors.white24,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          isLiked
                                              ? CupertinoIcons.heart_fill
                                              : CupertinoIcons.heart,
                                          color:
                                              isLiked
                                                  ? Colors.red
                                                  : Colors.white70,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          isLiked ? 'Mi piace' : 'Mi piace',
                                          style: TextStyle(
                                            color:
                                                isLiked
                                                    ? Colors.red
                                                    : Colors.white70,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Watchlist button
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    widget.onWatchlistToggled(movieId);
                                    setState(() {});
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          isInWatchlist
                                              ? Colors.blue.withOpacity(0.3)
                                              : const Color(0xFF2A2A2F),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color:
                                            isInWatchlist
                                                ? Colors.blue.withOpacity(0.5)
                                                : Colors.white24,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          isInWatchlist
                                              ? CupertinoIcons.bookmark_fill
                                              : CupertinoIcons.bookmark,
                                          color:
                                              isInWatchlist
                                                  ? Colors.blue
                                                  : Colors.white70,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          isInWatchlist ? 'Salvato' : 'Salva',
                                          style: TextStyle(
                                            color:
                                                isInWatchlist
                                                    ? Colors.blue
                                                    : Colors.white70,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Close button
                          SizedBox(
                            width: double.infinity,
                            child: TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text(
                                'Chiudi',
                                style: TextStyle(color: Colors.white70),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
