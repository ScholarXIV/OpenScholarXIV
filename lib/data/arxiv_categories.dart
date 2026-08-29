class ArxivCategory {
  const ArxivCategory({
    required this.code,
    required this.label,
    required this.group,
  });

  final String code;
  final String label;
  final String group;

  String get menuLabel => "$code - $label";
  String get query => "cat:$code";
}

const featuredArxivCategoryCodes = [
  "cs.AI",
  "cs.LG",
  "cs.CV",
  "cs.CL",
  "cs.RO",
  "quant-ph",
  "stat.ML",
  "hep-th",
  "q-bio.NC",
  "eess.AS",
];

const arxivCategories = [
  ArxivCategory(
    code: "cs.AI",
    label: "Artificial Intelligence",
    group: "Computer Science",
  ),
  ArxivCategory(
    code: "cs.CL",
    label: "Computation and Language",
    group: "Computer Science",
  ),
  ArxivCategory(
    code: "cs.CV",
    label: "Computer Vision",
    group: "Computer Science",
  ),
  ArxivCategory(
    code: "cs.LG",
    label: "Machine Learning",
    group: "Computer Science",
  ),
  ArxivCategory(
    code: "cs.NE",
    label: "Neural and Evolutionary Computing",
    group: "Computer Science",
  ),
  ArxivCategory(code: "cs.RO", label: "Robotics", group: "Computer Science"),
  ArxivCategory(
    code: "cs.SE",
    label: "Software Engineering",
    group: "Computer Science",
  ),
  ArxivCategory(
    code: "cs.SI",
    label: "Social and Information Networks",
    group: "Computer Science",
  ),
  ArxivCategory(
    code: "math.AG",
    label: "Algebraic Geometry",
    group: "Mathematics",
  ),
  ArxivCategory(
    code: "math.AP",
    label: "Analysis of PDEs",
    group: "Mathematics",
  ),
  ArxivCategory(code: "math.CO", label: "Combinatorics", group: "Mathematics"),
  ArxivCategory(
    code: "math.NA",
    label: "Numerical Analysis",
    group: "Mathematics",
  ),
  ArxivCategory(
    code: "math.OC",
    label: "Optimization and Control",
    group: "Mathematics",
  ),
  ArxivCategory(code: "stat.AP", label: "Applications", group: "Statistics"),
  ArxivCategory(
    code: "stat.ML",
    label: "Machine Learning",
    group: "Statistics",
  ),
  ArxivCategory(
    code: "stat.TH",
    label: "Statistics Theory",
    group: "Statistics",
  ),
  ArxivCategory(
    code: "physics.app-ph",
    label: "Applied Physics",
    group: "Physics",
  ),
  ArxivCategory(
    code: "physics.bio-ph",
    label: "Biological Physics",
    group: "Physics",
  ),
  ArxivCategory(
    code: "physics.comp-ph",
    label: "Computational Physics",
    group: "Physics",
  ),
  ArxivCategory(
    code: "astro-ph.CO",
    label: "Cosmology and Nongalactic Astrophysics",
    group: "Physics",
  ),
  ArxivCategory(
    code: "cond-mat.mtrl-sci",
    label: "Materials Science",
    group: "Physics",
  ),
  ArxivCategory(
    code: "hep-th",
    label: "High Energy Physics - Theory",
    group: "Physics",
  ),
  ArxivCategory(code: "quant-ph", label: "Quantum Physics", group: "Physics"),
  ArxivCategory(
    code: "q-bio.BM",
    label: "Biomolecules",
    group: "Quantitative Biology",
  ),
  ArxivCategory(
    code: "q-bio.NC",
    label: "Neurons and Cognition",
    group: "Quantitative Biology",
  ),
  ArxivCategory(
    code: "q-fin.CP",
    label: "Computational Finance",
    group: "Quantitative Finance",
  ),
  ArxivCategory(
    code: "q-fin.RM",
    label: "Risk Management",
    group: "Quantitative Finance",
  ),
  ArxivCategory(code: "econ.EM", label: "Econometrics", group: "Economics"),
  ArxivCategory(
    code: "eess.AS",
    label: "Audio and Speech Processing",
    group: "Electrical Engineering",
  ),
  ArxivCategory(
    code: "eess.IV",
    label: "Image and Video Processing",
    group: "Electrical Engineering",
  ),
];
