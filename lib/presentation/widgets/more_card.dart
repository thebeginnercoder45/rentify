import 'package:flutter/material.dart';
import 'package:rentapp/data/models/car.dart';

class MoreCard extends StatelessWidget {
  final Car? car;
  final String? brand;
  final VoidCallback? onTap;

  const MoreCard({super.key, this.car, this.brand, this.onTap})
      : assert(car != null || brand != null,
            'Either car or brand must be provided');

  @override
  Widget build(BuildContext context) {
    final String displayBrand = brand ?? car?.brand ?? 'Unknown';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(15),
        decoration: BoxDecoration(
            color: Color(0xff212020),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: Offset(0, 4))
            ]),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  car != null ? car!.model : "More $displayBrand",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                if (car != null)
                  Row(
                    children: [
                      Icon(Icons.directions_car, color: Colors.white, size: 16),
                      SizedBox(width: 5),
                      Text(
                        '> ${car!.distance} km',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      SizedBox(width: 10),
                      Icon(Icons.local_gas_station,
                          color: Colors.white, size: 16),
                      SizedBox(width: 5),
                      Text(
                        car!.fuelCapacity.toString(),
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ],
                  )
                else
                  Text(
                    "View all ${displayBrand} cars",
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.7), fontSize: 14),
                  ),
              ],
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.white, size: 24)
          ],
        ),
      ),
    );
  }
}
