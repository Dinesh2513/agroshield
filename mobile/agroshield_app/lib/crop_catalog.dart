class PlantOption {
  const PlantOption(this.id, this.name);

  final String id;
  final String name;
}

class PlantCategory {
  const PlantCategory(this.id, this.name, this.plants);

  final String id;
  final String name;
  final List<PlantOption> plants;
}

// A selection catalogue, NOT a declaration of model coverage.
// These IDs must be reviewed with the backend team before API integration.
const plantCategories = <PlantCategory>[
  PlantCategory('field', 'Field crops', [
    PlantOption('rice', 'Rice'),
    PlantOption('maize', 'Maize'),
    PlantOption('wheat', 'Wheat'),
    PlantOption('cotton', 'Cotton'),
    PlantOption('groundnut', 'Groundnut'),
    PlantOption('sugarcane', 'Sugarcane'),
    PlantOption('soybean', 'Soybean'),
    PlantOption('sorghum', 'Sorghum'),
  ]),
  PlantCategory('vegetables', 'Vegetable plants', [
    PlantOption('tomato', 'Tomato'),
    PlantOption('potato', 'Potato'),
    PlantOption('bell_pepper', 'Bell pepper'),
    PlantOption('chilli', 'Chilli'),
    PlantOption('brinjal', 'Brinjal'),
    PlantOption('okra', 'Okra'),
    PlantOption('cucumber', 'Cucumber'),
    PlantOption('onion', 'Onion'),
    PlantOption('cabbage', 'Cabbage'),
    PlantOption('cauliflower', 'Cauliflower'),
    PlantOption('spinach', 'Spinach'),
    PlantOption('carrot', 'Carrot'),
  ]),
  PlantCategory('fruits', 'Fruit plants', [
    PlantOption('banana', 'Banana'),
    PlantOption('mango', 'Mango'),
    PlantOption('papaya', 'Papaya'),
    PlantOption('guava', 'Guava'),
    PlantOption('grape', 'Grape'),
    PlantOption('orange', 'Orange'),
    PlantOption('lemon', 'Lemon'),
    PlantOption('pomegranate', 'Pomegranate'),
    PlantOption('apple', 'Apple'),
    PlantOption('strawberry', 'Strawberry'),
    PlantOption('watermelon', 'Watermelon'),
  ]),
  PlantCategory('flowers', 'Flowers and ornamentals', [
    PlantOption('rose', 'Rose'),
    PlantOption('marigold', 'Marigold'),
    PlantOption('hibiscus', 'Hibiscus'),
    PlantOption('jasmine', 'Jasmine'),
    PlantOption('chrysanthemum', 'Chrysanthemum'),
  ]),
  PlantCategory('herbs', 'Herbs and spices', [
    PlantOption('coriander', 'Coriander'),
    PlantOption('mint', 'Mint'),
    PlantOption('basil', 'Basil'),
    PlantOption('turmeric', 'Turmeric'),
    PlantOption('ginger', 'Ginger'),
  ]),
  PlantCategory('other', 'Other plants', []),
];
