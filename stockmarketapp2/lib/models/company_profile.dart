/*
  models/company_profile.dart – Public company metadata model

  • name       : The company’s full name (e.g., “Apple Inc.”).
  • ticker     : The stock ticker symbol (e.g., “AAPL”), used for lookups and display.
  • description: A brief description or industry classification (pulled from `finnhubIndustry`).
  • industry   : The sector or industry the company operates in (also from `finnhubIndustry`).
  • logoUrl    : URL to the company’s logo image, used in UI headers and lists.

  This class is constructed via the `fromJson` factory, which safely
  casts each JSON field to a `String` and falls back to an empty string
  if missing. By keeping all fields `final` and `required`, we ensure
  our UI always has a consistent, non-null set of company information
  to render.
*/

class CompanyProfile {
  final String name;
  final String description;
  final String industry;
  final String logoUrl;
  final String ticker;
  // add any other fields you like…

  CompanyProfile({
    required this.name,
    required this.description,
    required this.industry,
    required this.logoUrl,
    required this.ticker,
  });

  factory CompanyProfile.fromJson(Map<String, dynamic> json) {
    return CompanyProfile(
      name       : json['name'] as String?       ?? '',
      ticker:      json['ticker'] as String? ?? '',
      description: json['finnhubIndustry'] as String? ?? '',
      industry   : json['finnhubIndustry'] as String? ?? '',
      logoUrl    : json['logo'] as String?       ?? '',
    );
  }
}
