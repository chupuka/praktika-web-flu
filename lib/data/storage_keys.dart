class StorageKeys {
  static const version = 1;

  static const products = 'mebel_products_v$version';
  static const categories = 'mebel_categories_v$version';
  static const manufacturers = 'mebel_manufacturers_v$version';
  static const materials = 'mebel_materials_v$version';
  static const customers = 'mebel_customers_v$version';

  static const all = [
    products,
    categories,
    manufacturers,
    materials,
    customers,
  ];
}
