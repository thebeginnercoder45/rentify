import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rentapp/data/models/car.dart';
import 'package:rentapp/presentation/bloc/auth_bloc.dart';
import 'package:rentapp/presentation/bloc/auth_state.dart';
import 'package:rentapp/presentation/bloc/car_bloc.dart';
import 'package:rentapp/presentation/bloc/car_event.dart';
import 'package:rentapp/presentation/bloc/car_state.dart';
import 'package:rentapp/presentation/bloc/search_bloc.dart';
import 'package:rentapp/presentation/bloc/search_event.dart';
import 'package:rentapp/presentation/bloc/search_state.dart';
import 'package:rentapp/presentation/pages/auth_screen.dart';
import 'package:rentapp/presentation/pages/car_details_page.dart';
import 'package:rentapp/presentation/pages/my_bookings_screen.dart';
import 'package:rentapp/presentation/pages/profile/profile_page.dart';
import 'package:rentapp/presentation/widgets/bottom_navigation.dart';
import 'package:rentapp/presentation/pages/admin/admin_dashboard.dart';
import 'package:rentapp/utils/notification_service.dart';

class CarListScreen extends StatefulWidget {
  const CarListScreen({Key? key}) : super(key: key);

  @override
  State<CarListScreen> createState() => _CarListScreenState();
}

class _CarListScreenState extends State<CarListScreen> {
  // Premium theme colors
  static const Color primaryGold = Color(0xFFDAA520);
  static const Color accentGold = Color(0xFFF5CE69);
  static const Color lightGold = Color(0xFFF8E8B0);
  static const Color primaryBlack = Color(0xFF121212);
  static const Color darkGrey = Color(0xFF2D2D2D);
  static const Color mediumGrey = Color(0xFF4D4D4D);

  int _currentNavIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  RangeValues _priceRange = const RangeValues(500, 5000);
  bool _showFilters = false;

  // Car categories for filter tags
  final List<String> _categories = [
    'All',
    'SUV',
    'Sedan',
    'Luxury',
    'Sport',
    'Electric'
  ];
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    // Load cars when screen initializes
    context.read<CarBloc>().add(LoadCars());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onNavItemTapped(int index) {
    if (_currentNavIndex == index) return;

    switch (index) {
      case 0:
        // Home - Already in home, do nothing
        setState(() => _currentNavIndex = 0);
        break;
      case 1:
        // Navigate to My Bookings
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MyBookingsScreen()),
        ).then((_) => setState(() => _currentNavIndex = 0));
        break;
      case 2:
        // Show notification test page with options
        _showNotificationsDialog();
        setState(() => _currentNavIndex = 0);
        break;
      case 3:
        // Navigate to Profile
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ProfilePage()),
        ).then((_) => setState(() => _currentNavIndex = 0));
        break;
    }
  }

  void _showNotificationsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.notifications_active, color: primaryGold),
            SizedBox(width: 8),
            Text(
              'Notifications',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Test notification features:'),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                _sendWelcomeNotification();
                Navigator.pop(context);
              },
              icon: const Icon(Icons.notifications),
              label: const Text('Welcome Notification'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGold,
                foregroundColor: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                _sendNewCarNotification();
                Navigator.pop(context);
              },
              icon: const Icon(Icons.car_rental),
              label: const Text('New Car Notification'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGold,
                foregroundColor: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                _sendSpecialOfferNotification();
                Navigator.pop(context);
              },
              icon: const Icon(Icons.local_offer),
              label: const Text('Special Offer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGold,
                foregroundColor: Colors.black,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: primaryGold,
            ),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendWelcomeNotification() async {
    try {
      await NotificationService.instance.showNotification(
        id: 1,
        title: 'Welcome to RentApp!',
        body: 'Thank you for choosing RentApp for your car rental needs.',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Welcome notification sent!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint('Error sending notification: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send notification: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _sendNewCarNotification() async {
    try {
      await NotificationService.instance.showNotification(
        id: 2,
        title: 'New Cars Available',
        body: 'Check out our newest luxury cars added to the fleet!',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('New car notification sent!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint('Error sending notification: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send notification: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _sendSpecialOfferNotification() async {
    try {
      await NotificationService.instance.showNotification(
        id: 3,
        title: 'Special Weekend Offer!',
        body: 'Get 15% off on all premium cars this weekend. Book now!',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Special offer notification sent!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint('Error sending notification: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send notification: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _search() {
    if (_searchController.text.trim().isNotEmpty) {
      context
          .read<SearchBloc>()
          .add(SearchCarsByQuery(_searchController.text.trim()));
    } else {
      // Clear search results if search bar is empty
      context.read<SearchBloc>().add(ClearSearch());
    }
  }

  void _applyPriceFilter() {
    context.read<SearchBloc>().add(
          FilterCarsByPriceRange(
            minPrice: _priceRange.start,
            maxPrice: _priceRange.end,
          ),
        );
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _priceRange = const RangeValues(500, 5000);
      _showFilters = false;
    });
    context.read<SearchBloc>().add(ClearSearch());
  }

  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
    });

    if (category == 'All') {
      context.read<SearchBloc>().add(ClearSearch());
    } else {
      context.read<SearchBloc>().add(SearchCarsByCategory(category));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Unauthenticated) {
          // User has logged out, navigate to auth screen
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const AuthScreen()),
          );
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F8F8),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: primaryBlack,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.directions_car, color: primaryGold, size: 28),
              const SizedBox(width: 8),
              Text(
                'RentApp',
                style: GoogleFonts.poppins(
                  textStyle: const TextStyle(
                    color: primaryGold,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          centerTitle: true,
          automaticallyImplyLeading: false,
          actions: [
            Builder(
              builder: (context) {
                final authState = context.watch<AuthBloc>().state;
                if (authState is Authenticated && authState.appUser.isAdmin) {
                  return IconButton(
                    icon: const Icon(Icons.admin_panel_settings,
                        color: primaryGold),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdminDashboard(),
                        ),
                      );
                    },
                    tooltip: 'Admin Dashboard',
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        body: Column(
          children: [
            _buildSearchAndFilterBar(),
            if (_showFilters) _buildFilterOptions(),
            Expanded(
              child: BlocBuilder<SearchBloc, SearchState>(
                builder: (context, searchState) {
                  if (searchState is SearchLoaded) {
                    return _buildCarListView(context, searchState.cars);
                  } else if (searchState is SearchLoading) {
                    return _buildLoadingState();
                  } else if (searchState is SearchEmpty) {
                    return _buildEmptyState(
                      context,
                      icon: Icons.search_off,
                      title: 'No Results Found',
                      message:
                          'Try different search terms or adjust your filters',
                      buttonText: 'Clear Filters',
                      onPressed: _clearFilters,
                    );
                  } else if (searchState is SearchError) {
                    return _buildErrorState(searchState.message);
                  } else {
                    // Show regular car list if no search is active
                    return BlocBuilder<CarBloc, CarState>(
                      builder: (context, state) {
                        if (state is CarsLoading) {
                          return _buildLoadingState();
                        } else if (state is CarsLoaded) {
                          return _buildCarListView(context, state.cars);
                        } else if (state is CarsError) {
                          return _buildErrorState(state.message);
                        } else {
                          return _buildInitialState();
                        }
                      },
                    );
                  }
                },
              ),
            ),
          ],
        ),
        bottomNavigationBar: BottomNavigation(
          currentIndex: _currentNavIndex,
          onTap: _onNavItemTapped,
        ),
        floatingActionButton: Builder(
          builder: (context) {
            final authState = context.watch<AuthBloc>().state;
            if (authState is Authenticated && authState.appUser.isAdmin) {
              return FloatingActionButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdminDashboard(),
                    ),
                  );
                },
                backgroundColor: primaryGold,
                child: const Icon(Icons.admin_panel_settings),
                tooltip: 'Admin Dashboard',
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildSearchAndFilterBar() {
    return Container(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      decoration: BoxDecoration(
        color: primaryBlack,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: primaryGold.withOpacity(0.3), width: 1.0),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 55,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onSubmitted: (_) => _search(),
                      onChanged: (value) {
                        if (value.isEmpty) {
                          _clearFilters();
                        }
                      },
                      style: GoogleFonts.poppins(
                        textStyle: const TextStyle(fontSize: 14),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Find your dream car...',
                        hintStyle: GoogleFonts.poppins(
                          textStyle:
                              TextStyle(color: Colors.grey[400], fontSize: 14),
                        ),
                        prefixIcon: const Icon(Icons.search,
                            color: primaryGold, size: 22),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear,
                                    color: Colors.grey[400], size: 18),
                                onPressed: () {
                                  setState(() {
                                    _searchController.clear();
                                  });
                                  _clearFilters();
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  height: 55,
                  width: 55,
                  decoration: BoxDecoration(
                    color: primaryGold,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: Icon(
                      _showFilters ? Icons.filter_list_off : Icons.filter_list,
                      color: primaryBlack,
                      size: 26,
                    ),
                    onPressed: () {
                      setState(() {
                        _showFilters = !_showFilters;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: _categories.map((category) {
                final isSelected = _selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: FilterChip(
                    selected: isSelected,
                    label: Text(
                      category,
                      style: GoogleFonts.poppins(
                        textStyle: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected ? primaryBlack : Colors.grey[300],
                        ),
                      ),
                    ),
                    backgroundColor: Colors.grey[800],
                    selectedColor: primaryGold,
                    showCheckmark: false,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    onSelected: (_) => _onCategorySelected(category),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterOptions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: primaryGold.withOpacity(0.3), width: 1.0),
      ),
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Price Range',
                style: GoogleFonts.poppins(
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: primaryBlack,
                  ),
                ),
              ),
              TextButton(
                onPressed: _clearFilters,
                child: Text(
                  'Reset',
                  style: GoogleFonts.poppins(
                    textStyle: const TextStyle(
                      color: primaryGold,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          RangeSlider(
            values: _priceRange,
            min: 0,
            max: 10000,
            divisions: 100,
            activeColor: primaryGold,
            inactiveColor: Colors.grey[200],
            labels: RangeLabels(
              '₹${_priceRange.start.round()}',
              '₹${_priceRange.end.round()}',
            ),
            onChanged: (values) {
              setState(() {
                _priceRange = values;
              });
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '₹${_priceRange.start.round()}',
                style: GoogleFonts.poppins(
                  textStyle: TextStyle(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
              Text(
                '₹${_priceRange.end.round()}',
                style: GoogleFonts.poppins(
                  textStyle: TextStyle(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _applyPriceFilter,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlack,
                foregroundColor: primaryGold,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: primaryGold, width: 1.0),
                ),
                elevation: 0,
              ),
              child: Text(
                'Apply Filter',
                style: GoogleFonts.poppins(
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(primaryGold),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading premium cars...',
            style: GoogleFonts.poppins(
              textStyle: const TextStyle(
                color: darkGrey,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              // Force reload cars on manual retry
              context.read<CarBloc>().add(LoadCars());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGold,
              foregroundColor: primaryBlack,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialState() {
    return _buildEmptyState(
      context,
      icon: Icons.directions_car_outlined,
      title: 'No Cars Available',
      message: 'No cars are currently available for rent',
      buttonText: 'Refresh',
      onPressed: () => context.read<CarBloc>().add(LoadCars()),
    );
  }

  Widget _buildCarListView(BuildContext context, List<Car> cars) {
    return RefreshIndicator(
      color: primaryGold,
      onRefresh: () async {
        context.read<CarBloc>().add(LoadCars());
        return Future.delayed(const Duration(seconds: 1));
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: cars.length,
        itemBuilder: (context, index) {
          final car = cars[index];
          return _buildCarCard(context, car);
        },
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red[50],
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          ),
          const SizedBox(height: 16),
          Text(
            'Unable to Load Cars',
            style: GoogleFonts.poppins(
              textStyle: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: darkGrey,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                textStyle: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              context.read<CarBloc>().add(LoadCars());
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGold,
              foregroundColor: primaryBlack,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String message,
    required String buttonText,
    required VoidCallback onPressed,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.poppins(
              textStyle: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: darkGrey,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                textStyle: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGold,
              foregroundColor: primaryBlack,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 2,
            ),
            child: Text(
              buttonText,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarCard(BuildContext context, Car car) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CarDetailsPage(car: car),
          ),
        );
      },
      child: Container(
        height: 145,
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
          border: Border.all(color: primaryGold.withOpacity(0.3), width: 1.0),
        ),
        child: Row(
          children: [
            // Car Image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                bottomLeft: Radius.circular(20),
              ),
              child: SizedBox(
                width: 130,
                height: double.infinity,
                child: _buildCarImage(car),
              ),
            ),
            // Car Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Car Name and Rating
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${car.brand} ${car.model}',
                            style: GoogleFonts.poppins(
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: primaryBlack,
                              ),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: primaryGold,
                              size: 14,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${car.rating}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    // Category
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: primaryGold.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: primaryGold.withOpacity(0.5),
                          width: 1.0,
                        ),
                      ),
                      child: Text(
                        car.category,
                        style: GoogleFonts.poppins(
                          textStyle: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: primaryGold,
                          ),
                        ),
                      ),
                    ),
                    // Price
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '\₹${car.pricePerDay.toStringAsFixed(0)}/day',
                          style: GoogleFonts.poppins(
                            textStyle: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: primaryBlack,
                            ),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: primaryBlack,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          child: Text(
                            '${car.distance} km',
                            style: GoogleFonts.poppins(
                              textStyle: const TextStyle(
                                color: primaryGold,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildCarImage(Car car) {
    // Check if there is a valid image URL
    if (car.imageUrl != null && car.imageUrl!.isNotEmpty) {
      // Check if the URL is an asset path or a network URL
      if (car.imageUrl!.startsWith('assets/')) {
        // Load from assets
        return Image.asset(
          car.imageUrl!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print(
                "Error loading asset image: $error for path: ${car.imageUrl}");
            return _buildPlaceholderImage(car);
          },
        );
      } else if (car.imageUrl!.startsWith('http')) {
        // Load from network
        return Image.network(
          car.imageUrl!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print(
                "Error loading network image: $error for URL: ${car.imageUrl}");
            return _buildPlaceholderImage(car);
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(primaryGold),
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            );
          },
        );
      } else {
        // Unknown format, try as asset first
        return Image.asset(
          car.imageUrl!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print("Error loading image: $error for path: ${car.imageUrl}");
            return _buildPlaceholderImage(car);
          },
        );
      }
    } else {
      // No image URL, display placeholder with car icon
      return _buildPlaceholderImage(car);
    }
  }

  Widget _buildPlaceholderImage(Car car) {
    return Container(
      color: Colors.grey[200],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.directions_car,
            size: 50,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 4),
          Text(
            '${car.brand} ${car.model}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
