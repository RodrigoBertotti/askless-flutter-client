
class Product{
  int? id;
  late final String name;
  late final int price;

  Product({required this.name, required  this.price});

  Product.fromMap(Map<String,dynamic> map){
    this.id = map['id'];
    this.name = map['name'];
    this.price = map['price'];
  }


  static List<Product> fromMapList(mapList) {
    final List<Product> res = [];
    (mapList ?? []).forEach((mapItem) => res.add(Product.fromMap(mapItem)));
    return res;
  }

  toMap() {
    return {
      'id' : id,
      'name' : name,
      'price' : price
    };
  }
}
