# frozen_string_literal: true

# Association Tracking for PaperTrail has been extracted to a separate gem. To use it, please add `paper_trail-association_tracking` to your Gemfile. If you don't use it (most people don't, that's the default) and you set `track_associations = false` somewhere (probably a rails initializer) you can remove that line now.

# PaperTrail.config.track_associations = false

# Psych 4 disabled unsafe YAML loading by default, which broke deserialization of existing `object_changes`
# rows in the `versions` table containing ActiveSupport time objects. Permit the classes we store.
module PaperTrail
  module Serializers
    module YAML
      PERMITTED_YAML_CLASSES = [
        ActiveSupport::TimeWithZone,
        ActiveSupport::TimeZone,
        Time,
        Date,
        DateTime,
        Symbol,
        BigDecimal
      ].freeze

      def self.load(string)
        ::YAML.safe_load(string, permitted_classes: PERMITTED_YAML_CLASSES, aliases: true)
      end
    end
  end
end
