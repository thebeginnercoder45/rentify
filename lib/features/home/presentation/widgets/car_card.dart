import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CarCard extends StatelessWidget {
  final String imageUrl;
  final String name;
  final String brand;
  final double price;
  final double rating;

  const CarCard({
    super.key,
    required this.imageUrl,
    required this.name,
    required this.brand,
    required this.price,
    required this.rating,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          // TODO: Navigate to car details
        },
        borderRadius: BorderRadius.circular(16.r),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16.r),
                bottomLeft: Radius.circular(16.r),
              ),
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                height: 120.h,
                width: 120.w,
                fit: BoxFit.cover,
                placeholder:
                    (context, url) => Container(color: Colors.grey[300]),
                errorWidget:
                    (context, url, error) => Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.error),
                    ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(12.r),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      brand,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        RatingBarIndicator(
                          rating: rating,
                          itemBuilder:
                              (context, index) =>
                                  Icon(Icons.star, color: Colors.amber[700]),
                          itemCount: 5,
                          itemSize: 16.r,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          rating.toString(),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    RichText(
                      text: TextSpan(
                        text: '\$${price.toStringAsFixed(0)}',
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                        children: [
                          TextSpan(
                            text: '/day',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
