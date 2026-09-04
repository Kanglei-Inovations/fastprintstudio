enum DocumentPaperType {
  normal70Gsm(
    name: '70 GSM Normal Paper',
    description: 'Economical standard xerox & everyday printing',
    sheetCost: 0.50,
    bwRatePerPage: 2.0,
    colorRatePerPage: 5.0,
  ),
  bond75Gsm(
    name: '75 GSM Executive Bond',
    description: 'Crisp bright white office documents & legal reports',
    sheetCost: 0.80,
    bwRatePerPage: 3.0,
    colorRatePerPage: 7.0,
  ),
  heavy100Gsm(
    name: '100 GSM Premium Heavyweight',
    description: 'Thick presentation, certificates & official letters',
    sheetCost: 1.50,
    bwRatePerPage: 5.0,
    colorRatePerPage: 10.0,
  ),
  glossyPhoto(
    name: 'Glossy Brochure / Presentation',
    description: 'Ultra vibrant brochures, flyers & project covers',
    sheetCost: 3.00,
    bwRatePerPage: 10.0,
    colorRatePerPage: 15.0,
  );

  final String name;
  final String description;
  final double sheetCost;
  final double bwRatePerPage;
  final double colorRatePerPage;

  const DocumentPaperType({
    required this.name,
    required this.description,
    required this.sheetCost,
    required this.bwRatePerPage,
    required this.colorRatePerPage,
  });
}

enum DocumentBindingType {
  none('None / Loose Sheets', 0.0),
  cornerStaple('Corner Staple (₹2)', 2.0),
  spiralBinding('Spiral Binding (₹30)', 30.0),
  hardBinding('Hardcover Book Binding (₹150)', 150.0);

  final String label;
  final double price;

  const DocumentBindingType(this.label, this.price);
}
