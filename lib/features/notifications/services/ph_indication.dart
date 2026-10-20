/// Approximate universal-indicator chart; actual colors vary by indicator.
class PhIndication {
  final String color;
  final String classification;

  const PhIndication(this.color, this.classification);

  static const chart = <PhIndication>[
    PhIndication('Deep Red', 'Highly Acidic'),
    PhIndication('Red', 'Highly Acidic'),
    PhIndication('Red-Orange', 'Strongly Acidic'),
    PhIndication('Orange', 'Strongly Acidic'),
    PhIndication('Light Orange', 'Moderately Acidic'),
    PhIndication('Yellow', 'Slightly Acidic'),
    PhIndication('Yellow-Green', 'Mildly Acidic'),
    PhIndication('Pure Green', 'Neutral'),
    PhIndication('Blue-Green', 'Mildly Alkaline'),
    PhIndication('Light Blue', 'Slightly Alkaline'),
    PhIndication('Deep Blue', 'Moderately Alkaline'),
    PhIndication('Violet', 'Moderately Alkaline'),
    PhIndication('Deep Violet', 'Strongly Alkaline'),
    PhIndication('Purple', 'Strongly Alkaline'),
    PhIndication('Deep Purple', 'Highly Alkaline'),
  ];

  static String status(double ph) {
    if (ph < 6.5) return 'low';
    if (ph > 8.5) return 'high';
    return 'normal';
  }

  static String guidance(double ph) {
    if (ph <= 3 || ph >= 12) {
      return 'Extreme pH: potentially corrosive. Do not drink; verify the sensor and have the water tested.';
    }
    if (ph < 6.5) {
      return 'Below the recommended pH range (6.5–8.5). May increase plumbing corrosion and metal leaching. Verify the reading and water quality before drinking.';
    }
    if (ph > 8.5) {
      return 'Above the recommended pH range (6.5–8.5). May cause taste or deposit issues. Verify the reading and water quality before drinking.';
    }
    return 'Within the recommended pH range (6.5–8.5). pH alone does not confirm that water is safe to drink.';
  }
}
