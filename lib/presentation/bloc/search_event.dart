abstract class SearchEvent {
  const SearchEvent();
}

class SearchCarsByQuery extends SearchEvent {
  final String query;

  const SearchCarsByQuery(this.query);
}

class SearchCarsByCategory extends SearchEvent {
  final String category;

  const SearchCarsByCategory(this.category);
}

class FilterCarsByPriceRange extends SearchEvent {
  final double minPrice;
  final double maxPrice;

  const FilterCarsByPriceRange({
    required this.minPrice,
    required this.maxPrice,
  });
}

class ClearSearch extends SearchEvent {}
