# frozen_string_literal: true

TYPES = {
  "Terms of Service" => "concerns end user's service usage",
  "Privacy Policy" => "concerns end user's personal data",
  "Imprint" => "concerns identification of content author and hosting service for official inquiries",
  "Trackers Policy" => "concerns all tracking technologies, including cookies, session storage, fingerprints, etc.",
  "Developer Terms" => "concerns APIs and programmatic access to content",
  "Community Guidelines" => "concerns public behaviour",
  "Deceased Users" => "concerns the handling of information of a deceased individual",
  "Acceptable Use Policy" => "concerns acceptable and unacceptable usage",
  "Restricted Use Policy" => "concerns restrictions on specific usage",
  "Commercial Terms" => "concerns business or commercial usage",
  "Copyright Claims Policy" => "addresses how copyright complaints (DMCA, etc.) will be handled",
  "Law Enforcement Guidelines" => "concerns account records access",
  "Human Rights Policy" => "concerns human rights",
  "In-App Purchases Policy" => "concerns usage of in-app purchases and other virtual goods",
  "Review Guidelines" => "concerns the review process of provided content",
  "Brand Guidelines" => "concerns usage of the service provider's brand",
  "Quality Guidelines" => "concerns the quality of content produced by means of the service",
  "Data Controller Agreement" => "concerns end user's personal data by data controllers (in the sense of GDPR)",
  "Data Processor Agreement" => "concerns the status of the data processor (in the sense of GDPR) for the service provider",
  "User Consent Policy" => "concerns user consent collection and storage by data controllers (in the sense of GDPR)",
  "Closed Captioning Policy" => "concerns closed captioning on streamed content",
  "Seller Warranty" => "concerns protection of end users that act as sellers",
  "Single Sign-On Policy" => "concerns connecting user accounts to other services",
  "Vulnerability Disclosure Policy" => "concerns how to report a security vulnerability or issue",
  "Live Policy" => "concerns end user's live service usage",
  "Complaints Policy" => "concerns how generic complaints will be handled",
  "Conditions of Carriage" => "concerns benefits and limitations associated with the transportation being provided by transportation operators (airlines, buses, railways, etc.)",
  "General Conditions of Sale" => "concerns the warranty, delivery, return of goods or services bought through a monetary transaction",
  "Marketplace Buyers Conditions" => "concerns buying through a monetary transaction goods or services offered by sellers other than the marketplace itself",
  "Marketplace Sellers Conditions" => "concerns selling through a monetary transaction goods or services to buyers other than the marketplace itself",
  "Frequently Asked Questions" => "frequently asked questions about the service, its policies",
  "Merged" => "documents that have been merged",
  "Coporate Social Responsibility" => "concerns practices integrating social, environmental and profit-related considerations",
  "Social Media Policy" => "service provider guidance on how employees should act on social media",
  "Uniform Disclosure" => "used to disclose certain information to end users",
  "Affiliate Disclosure" => 
   "statement informing users that companies compensate affiliates for promoting, reviewing, or recommending their products or services",
  "Safety Guidelines" => "service provider protocols to ensure online safety",
  "Telephone Communication Guidelines" => "restrictions on telephone solicitations (i.e. telemarketing) and the use of automated phone equipment",
  "Records Keeping Policy" => "policies in handling of user records in the event of bankruptcy or data transfer",
  "Service Level Agreement" => "outlines a specific commitment between a service provider and a client",
  "Legal Information" => "documentation covering miscellaneous policies, notices, and disclaimers",
  "Policy" => "generic policies not included in privacy policy coverage",
  "About" => "generic information pages",
  "Miscellaneous Agreement" => "various agreements published by the service",
  "Ranking Parameters Description" => "concerns search engine or service provider's parameters determining ranking and the reasons for their relative importance",
  "Premium Partner Conditions" => "concerns sellers' eligibility criteria, limitations and benefits of a privileged seller status programme",
  "Platform to Business Notice" => "concerns complaints handling, mediation, transparency and other rights and information mandated by the P2B regulation",
  "Business Mediation Policy" => "concerns business users' eligibility and process of mediation after internal complaints handling failed",
  "Business Privacy Policy" => "concerns personal data of business users and of people acting on their behalf"
}.freeze

namespace :document_types do
  desc 'Create document types'
  task create_document_types: :environment do
    TYPES.each do |key, value|
      unless DocumentType.find_by_name(key).present?
        document_type = DocumentType.new(name: key, description: value, status: 'approved')
        document_type.save! validate: false
      end
    end
  end
end