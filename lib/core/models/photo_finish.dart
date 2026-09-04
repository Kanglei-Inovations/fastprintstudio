enum PhotoFinish {
  glossy('Glossy Photo Paper', 4.0, 0.0),
  matte('Matte Premium Paper', 5.5, 10.0);

  final String label;
  final double paperCost;
  final double extraPricePerSheet;

  const PhotoFinish(this.label, this.paperCost, [this.extraPricePerSheet = 0.0]);
}

enum PhotoLamination {
  none('No Lamination', 0.0, 0.0),
  gloss('Gloss Lamination (Heat/Cold)', 4.0, 15.0),
  matte('Matte Velvet Lamination', 6.0, 20.0);

  final String label;
  final double materialCost;
  final double extraPrice;

  const PhotoLamination(this.label, this.materialCost, this.extraPrice);
}

enum PhotoFraming {
  none('No Frame (Print Only)', 0.0, 0.0),
  tableFrame('Studio Table Stand / Mount', 35.0, 80.0),
  wallFrame('Premium Wall Frame (Glass & Border)', 70.0, 150.0);

  final String label;
  final double materialCost;
  final double extraPrice;

  const PhotoFraming(this.label, this.materialCost, this.extraPrice);
}

enum PhotoScalingMode {
  fit('Fit to Sheet (Keep Aspect Ratio)'),
  fill('Fill Sheet (Edge-to-Edge)'),
  actualSize('100% Actual Size');

  final String label;

  const PhotoScalingMode(this.label);
}
