# frozen_string_literal: true

module HykuKnapsack
  # Re-seed each work model's `valid_child_concerns` from the fully-registered
  # `Hyrax.config.curation_concerns`.
  #
  # Hyrax::NestedWorks snapshots `Hyrax.config.curation_concerns` into a class
  # attribute (`valid_child_concerns`) at class-load. A knapsack that registers
  # its work types in a deferred `after_initialize` block (e.g. because the
  # M3/flex constants aren't resolvable at initializer-evaluation time) hits an
  # ordering trap under eager loading: the work-type classes load BEFORE the
  # deferred registration runs, so the snapshot freezes to whatever concerns
  # were registered at boot (Hyku's defaults) and never picks up the knapsack's
  # types. The "Add child work" picker on the work show page then offers the
  # wrong types on eager-loaded environments (production/staging) while working
  # correctly in development (which lazy-loads classes after registration).
  #
  # This service, run after registration is complete, re-seeds every registered
  # work model from the final concern list so the class attribute is correct in
  # every environment. HykuKnapsack wires it via the engine `to_prepare` for the
  # dev-reload pass. A knapsack that DEFERS curation-concern registration to its
  # own after_initialize must also call `HykuKnapsack::ReseedValidChildConcerns
  # .call` at the end of that registration block for the eager-load boot pass —
  # the engine hooks all run before an initializer-file after_initialize.
  #
  # A work type can bar itself from ever being a child (of any parent, including
  # itself) by defining `self.valid_child_concern?` to return false. Such types
  # are excluded from every model's child list. Types that do not define the
  # method remain valid children by default.
  module ReseedValidChildConcerns
    module_function

    def call
      concerns = Hyrax.config.curation_concerns
      child_concerns = concerns.reject { |klass| barred_as_child?(klass) }
      concerns.each do |klass|
        klass.valid_child_concerns = child_concerns if klass.respond_to?(:valid_child_concerns=)
      end
    end

    def barred_as_child?(klass)
      klass.respond_to?(:valid_child_concern?) && !klass.valid_child_concern?
    end
  end
end
